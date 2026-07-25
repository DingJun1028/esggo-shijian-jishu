# 18 · 遠端倉庫健康檢查 Runbook（收納/清理週期化）

> 來源：本技書第 01 章「整理/收納/清理」子命令 + 第 17 章「Secrets 衛生」+ 實際 `gh repo list --json` 盤點經驗。
> 適用：把第 01 章零散的 archive/rename/delete/sync/deploy-key/secret-scanning 命令落成**週期性儀式**——避免遠端倉庫長草、密鑰過期、保護缺失。
> 與第 01 章（命令清單）、第 17 章（secret 衛生）配套——本章管「多久盤一次、按什麼順序、判斷閾值」，第 01 章管「單條命令怎麼打」，第 17 章管「secret 輪換原則」。

## 0. 盤點基準（先有清單才有判斷）

```bash
# 全帳號盤點：名稱 / 最後 push / 是否封存 / 可見度（一次看全部 repo）
gh repo list --json nameWithOwner,pushedAt,updatedAt,isArchived,visibility \
  --limit 100 \
  | python3 -c "
import sys, json, datetime
rows = json.load(sys.stdin)
today = datetime.date.today()
print(f'{'REPO':45} {'PUSHED':12} {'ARCH'} {'VIS}')
for r in sorted(rows, key=lambda x: x.get('pushedAt') or ''):
    pushed = (r.get('pushedAt') or '')[:10]
    days = (today - datetime.date.fromisoformat(pushed)).days if pushed else 9999
    print(f\"{r['nameWithOwner']:45} {pushed:12} {'Y' if r['isArchived'] else '-'} {r['visibility']:8} {days}d\")
"
```

> 把上表存成 `repo-inventory-YYYY-MM.md`，下次跑 diff 就有「長草天數」基準。

## 1. 健康檢查清單（每季 / 換機 / 年度大掃除）

逐項跑，照 §3 的閾值決定 archive / delete / 留。

| # | 檢查 | 命令 | 判斷閾值 |
|---|------|------|----------|
| 1 | 長草 repo（久未 push） | 見 §0 表格 `days` 欄 | >365 天且非模板/被 fork → 候選封存 |
| 2 | 是否該封存 | `gh repo view owner/repo --json isArchived` | 封存後唯讀保留，可逆 |
| 3 | fork 是否跟上 upstream | `git fetch upstream && git rev-list --left-right --count HEAD...upstream/main` | 右側 >0 表示落後，跑 `gh repo sync` |
| 4 | 主分支有無保護 | `gh api repos/owner/repo/branches/main/protection` | 回 404 = 未保護 → 補（見第 01 章 §6） |
| 5 | Secrets 是否過期/閒置 | `gh secret list` | 無使用跡象的舊 key → 輪換（見第 17 章 §5） |
| 6 | 推送密鑰防漏是否開 | `gh repo edit --enable-secret-scanning-push-protection` | 一次性開啟，全倉受益 |
| 7 | 描述 / topics 是否清楚 | `gh repo view owner/repo --json description,repositoryTopics` | 空描述 → 補（利於 `gh search`） |
| 8 | 部署金鑰閒置 | `gh repo deploy-key list` | 對應伺服器已下線 → 刪除公鑰 |

## 2. 處置動作（照第 01 章命令）

```bash
# 封存長草 repo（可逆，推薦優先於刪除）
gh repo archive owner/stale-repo
gh repo unarchive owner/stale-repo          # 反悔用

# 確定不要再回頭 → 刪除（⚠ 不可逆，需 --yes 二次確認）
gh repo delete owner/stale-repo --yes

# fork 落後 → 同步
gh repo sync $GH_USER/forked-repo

# 補主分支保護（curl / API，見第 01 章 §6）

# 開推送密鑰防漏
gh repo edit --enable-secret-scanning-push-protection

# 清閒置部署金鑰（先 list 看 id/title）
gh repo deploy-key list
# gh repo deploy-key delete <key-id>        # 對應伺服器已下線才刪
```

## 3. 判斷閾值（避免憑感覺）

- **封存**：>365 天未 push、但曾是有用參考（教學/模板/被 fork 的源）→ `archive`，不删。
- **刪除**：確認無引用、非任何 fork 的 upstream、且內容可從別處重建 → `delete --yes`。
- **保留但加保護**：仍活躍、多人協作 → 主分支加保護（CI 過 + 1 review）。
- **secret 輪換**：凡是貼進 chat 過、或對應服務已遷移的 key，一律視為已暴露，輪換 + 從 git 歷史清除（見第 17 章 §5）。

## 4. 自動化（已落成可執行腳本，非只建議）

本技書已把盤點自動化為可執行產物（非紙上建議）：

- `scripts/repo-inventory.sh` — 盤點腳本，本地 `gh` 登入即可跑：
  - `bash scripts/repo-inventory.sh` → 產 `inventory/repo-inventory-YYYY-MM-DD.md` 並印表格（依長草天數排序）。
  - `bash scripts/repo-inventory.sh --diff` → 與上一期比對，列出「新變長草」的 repo（本期超閾值、上期未超）。
  - 環境變數覆寫：`INVENTORY_LIMIT`（預設 300，帳號 repo 多時調高）、`STALE_DAYS`（預設 365）、`OUTDIR`（預設 `inventory/`）。
  - 已實際對 `DingJun1028` 帳號跑通：抓到 264 個 repo、52 個長草候選（>365d 未 push 且未封存）。
- `.github/workflows/repo-inventory.yml` — 可選 GitHub Actions 排程（每月 1 號 09:07 UTC），把快照上傳為 artifact。
  - **前置（必須手動設定）**：在 repo `Settings → Secrets` 新增 `REPO_INVENTORY_TOKEN`（具 `read:org` + `repo` 範圍的 PAT）。未設時 job 會 `::error::` 清楚報錯並 fail fast，不會靜默產錯。
  - 也可以完全不要本 workflow，改在本機手動跑腳本——兩者互斥、擇一即可。

其他自動化提醒：

- CI 倉庫內跑 `gh secret list` 不易（write-only），改用「每次部署失敗時懷疑 secret 過期」的反向信號（見第 03 章）。
- fork 同步：`gh repo sync` 可手動跑；多 fork 時寫迴圈遍歷 `$GH_USER/*`。

## 5. 與其他章的界線（MECE 互斥）

- 本章 = **C 支柱「協作/版本控制」的週期性收納儀式**，管「多久盤一次、按什麼順序、閾值」。
- 第 01 章 = **C 的「單條命令清單」**，本章引用它但不重列每條命令的完整語法。
- 第 17 章 = **F→Secure 的「secret 衛生原則」**，本章第 5/6 項直接引用它的輪換規範。
- 第 15 章 = **E 的「營運探活 runbook」**，結構同屬 runbook 範式但對象不同（線上服務 vs 遠端倉庫）。

## 實踐清單

- [ ] 跑過 §0 盤點，存 `repo-inventory-YYYY-MM.md` 當基準
- [ ] 長草 >365 天者標記封存候選
- [ ] fork 落後者跑 `gh repo sync`
- [ ] 活躍倉庫主分支補保護
- [ ] 全倉開 `secret-scanning-push-protection`
- [ ] 閒置 secret / 部署金鑰輪換或刪除（對照第 17 章 §5）
- [ ] 盤點腳本排 cron，月度 diff

## 相關技能 / 章節

- 第 01 章 倉庫整理（archive/rename/delete/sync/deploy-key/secret-scanning 命令）
- 第 17 章 安全強化（§5 Secrets 衛生：輪換、`.gitignore`、git 歷史清除）
- 第 03 章 Actions Secrets（write-only 限制、反向失效信號）
- 第 15 章 營運探活 runbook（同屬 runbook 範式，對象為線上服務）
- `github-repo-management` 技能 v1.1.0（第 01 章來源）
