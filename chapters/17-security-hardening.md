# 17 · 安全強化（超 Secrets 之外）

> 來源：第 13 章 提交前審查的靜態掃描清單 + 本技書記憶規範（pnpm 11：`pnpm audit` only、絕不覆寫 undici）+ 通用應用安全實踐。
> 適用：把「安全」從「只管 secrets」（第 03 章）擴大到依賴、注入、最小權限、SSRF 等。填補 MECE 的「G5 Secure」缺口。
> 與第 03 章（secrets）、第 13 章（提交前掃描）配套——本章往上提一層成系統習慣。

## 0. 心智模型

安全不是「把 key 藏好」一件事，而是多層：
```text
Secrets（第03章）
  └─ 依賴（你引入的第三方碼）
       └─ 注入（你寫的程式碼怎麼處理外部輸入）
            └─ 權限（誰能以什麼身份做什麼）
                 └─ 暴露面（哪些端點/埠/服務對外）
```

## 1. 依賴安全（Supply Chain）

```bash
# ESGGO 規範（記憶）：pnpm 11 環境下
pnpm audit                  # ✅ 只用這個
# npm audit                # ❌ 絕不用（混合環境會錯判）
# 不要覆寫 undici         # ❌ jsdom@29 會破 vitest，別為過 audit 而強制
```
- 鎖定檔（`pnpm-lock.yaml`）進 git；`pnpm install --frozen-lockfile`（見第 09 章 CI）確保可重現。
- 升級依賴走 PR + 第 13 章審查；大版本跳動先看 changelog / breaking。
- 棄用套件（abandoned）是隱性風險：定期 `pnpm outdated` 檢視。

## 2. 注入防護（你寫的程式碼）

來自第 13 章的硬性 FAIL 清單，落成日常習慣：

| 風險 | ❌ 壞 | ✅ 好 |
|------|--------|--------|
| SQL | `cursor.execute(f"SELECT * FROM u WHERE id={x}")` | `cursor.execute("... WHERE id=?", (x,))` |
| Shell | `os.system(f"ls {u}")` | `subprocess.run(["ls", u], check=True)` |
| XSS | `el.innerHTML = userInput` | `el.textContent = userInput` |
| 反序列化 | `pickle.loads(untrusted)` | 用 JSON / 簽章過的來源 |
| 動態執行 | `eval(userInput)` / `exec(userInput)` | 不要；用白名單分派 |

- 所有外部輸入（query param / body / header / 檔名）先驗證、再使用；路徑操作防 traversal（`path.resolve` + prefix 檢查）。
- 第 13 章靜態掃描可直接掛進 pre-commit / CI（見第 09 章 workflow）。

## 3. 最小權限（Least Privilege）

- **Secrets 權限**：mirror PAT 只給目標 repo 的 `secrets:write`，不給 `repo` 全權（見第 03 章 §5）。
- **VPS SSH**：部署用專鑰（actions_deploy_key），只裝公鑰；日常操作與部署金鑰分離（見第 04 章 §1）。
- **Firebase / GCP**：OAuth Authorized domains 只列必要網域（esggo-learning-center.web.app / *.firebaseapp.com / localhost:5173，見第 08 章 §8）。
- **Cloudflare Token**：scope 只到 Zone:DNS:Edit（該 zone），不給全帳（見第 04 章 §4）。
- **容器**：非 root 跑、只開必要埠（host nginx 佔 80/443 時 docker 別再綁同埠，見第 04 章 §6）。

## 4. SSRF 與暴露面收斂

- 後端會「對外打 URL」的功用（webhook / 預覽 / 代理）是 SSRF 高風險：允許清單 + 阻內網網段（169.254 / 10./127./172.16-31./192.168.）。
- 只對外開必要埠；`docker container stats` / `ss -ltnp` 定期看誰在聽（見第 15 章探活）。
- Cloudflare 擋在 origin 前時，origin 仍不該直接暴露管理埠；用 Full(strict) + 限制來源 IP（見第 04 章 §11）。

## 5. Secrets 衛生（回扣第 03 章）

- write-only 硬限制：需要值就貼或走 server-side mirror；永不在 chat 留真 key 後不輪換。
- 本地 `.env` 進 `.gitignore`；不小心 commit 了 → 視為已洩，輪換 + 從 git 歷史清除（filter-repo / BFG）。
- 前端 `NEXT_PUBLIC_*` / `VITE_*` 是公開的，不是 secret（見第 03 章 §9）。

## 6. 把安全接進流程（不放單章就結束）

- 寫碼：§2 習慣。
- 提交前：第 13 章八步（含靜態掃描）。
- CI：第 09 章 workflow 加 `pnpm audit` + lint + 掃描。
- 部署：§3 最小權限 + §4 暴露面收斂。
- 營運：第 15 章探活 + 異常告警。

## 實踐清單

- [ ] `pnpm audit`（非 npm audit）、不覆寫 undici
- [ ] 鎖定檔進 git + `--frozen-lockfile`
- [ ] 所有外部輸入防注入（參數化 / textContent / 不 eval）
- [ ] 最小權限：SSH / PAT / Firebase / Cloudflare / 容器分層
- [ ] SSRF 允許清單 + 內網網段阻擋
- [ ] 安全掃描掛進 pre-commit 與 CI

## 相關技能 / 章節

- 第 03 章 Actions Secrets、第 13 章 提交前審查（靜態掃描）、第 09 章 CI、第 04 章 VPS 權限、第 15 章 營運探活
- 第 18 章 倉庫健康檢查 Runbook（§5 Secrets 衛生的週期化盤點與輪換儀式）
- `agent-secrets-management`（secret manager 模式）
