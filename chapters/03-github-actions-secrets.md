# 03 · GitHub Actions Secrets / Variables 管理

> 來源：Hermes Agent `github-secrets` 技能（v1.1.0）。
> 關鍵認知：**Secrets 對所有客戶端都是 write-only**，永遠讀不回明文。

## 0. 最重要的限制（先讀）

- `gh secret list` 只回傳 **名稱 + 時間戳**；任何權限層級（`repo` / `admin` / org owner）都拿不到值。
- 沒有 `gh secret get`，也沒有能讀回值的 REST API。
- 因此「把 A 倉的 secret 複製到 B 倉」若使用者不肯貼值，只能用 **server-side mirror workflow**（見第 6 節）。
- **Variables**（`gh variable`）不同：未加密，**值可讀**（`gh variable list` / API），可直接客戶端複製。

## 1. 基本操作

```bash
# 設定 secret（stdin / 字串 / 檔案）
gh secret set API_KEY --body "$VALUE"
echo "$VALUE" | gh secret set API_KEY
cat "/c/Path/To/id_rsa" | gh secret set VPS_SSH_KEY --repo OWNER/REPO   # Windows 用此形式（--body-file 此版本不支援）

gh secret list                       # 僅名稱 + updated_at
gh secret list -R OWNER/REPO
gh secret delete API_KEY             # 互動確認

# Variables（值可見）
gh variable set DEPLOY_ENV --body production
gh variable list
gh variable delete DEPLOY_ENV
```

## 2. 非互動刪除（沒有 -y 旗標！）

`gh secret delete NAME -y` 會 `rc=1`（unknown flag）且**悄悄留下 secret** —— 自動化清理的陷阱。
改用 REST API（永遠非互動）：

```bash
gh api -X DELETE "repos/OWNER/REPO/actions/secrets/NAME"
# 成功 rc=0；再 gh secret list 確認
```

若寫 set_secrets.py 之類的 helper，`delete` 子命令請 shell 出去呼叫 `gh api -X DELETE`（不是 `gh secret delete -y`），並同時清除本地 `.env` 對應行。

## 3. 「自行查看」秘密管理員仍拿不到值

若被授權為 secret manager 並說「自己查」，請誠實處理：GitHub 是 write-only，且倉庫可能本就**沒有 secrets**（`gh secret list` 為空、本地 `.env` 也沒真值）。此時：

1. `gh secret list` 確認為空 / 只有 placeholder 名稱。
2. 明確告知：client/server 端都沒有真值，雲端接線（需真 key 的步驟）必須等使用者貼值。
3. 用 **placeholder 預飛** 證明接線是活的：設一個假 key（`sk-TEST_PLACEHOLDER_...`）→ 確認落進 GitHub + 本地 `.env` → `gh api -X DELETE` 刪掉 → 還原 `.env`。零真憑證暴露。

永遠不要儲存或回顯真 key；貼值設定後建議使用者輪換（值留在聊天紀錄）。

## 4. 先讀名稱清單

`gh secret list` 的名稱本身常透露已存內容（`VPS_HOST`、`VPS_USER`、`SSH_PRIVATE_KEY`、`OCI_*` 等）。遠端操作前先讀名稱再決定要 mirror / paste / 複用。

## 5. 跨倉鏡像 secrets（server-side）

使用者授權複製 SOURCE → TARGET 但不肯貼值：SOURCE 的 workflow 能在自身 run 內以明文讀 `${{ secrets.X }}`，再用 PAT 寫入 TARGET。

```bash
# 1) 在 SOURCE 建臨時 PAT（要有 TARGET 的 secrets:write；完整 repo scope 即滿足）
TOKEN=$(gh auth token)
gh secret set MIRROR_PAT -R OWNER/SOURCE -b "$TOKEN"

# 2) 提交一次性 workflow（模板見 references/cross-repo-secret-mirror.yml）
B64=$(base64 -w0 < references/cross-repo-secret-mirror.yml)
gh api repos/OWNER/SOURCE/contents/.github/workflows/mirror-secrets.yml \
  -X PUT -f message="chore: one-shot secret mirror" -f content="$B64"

# 3) 觸發
gh workflow run mirror-secrets.yml -R OWNER/SOURCE

# 4) 輪詢（別用 gh run watch，偶爾連線錯）
for i in $(seq 1 12); do
  st=$(gh run view --repo OWNER/SOURCE --json status,conclusion -q '"(.status) (.conclusion)"' 2>/dev/null || echo poll-error)
  echo "try $i: $st"; case "$st" in *completed*|*success*|*failure*) break;; esac; sleep 10
done

# 5) 驗證 TARGET 收到（僅名稱）
gh secret list -R OWNER/TARGET

# 6) 清理：移除暫存 PAT + workflow
gh secret delete MIRROR_PAT -R OWNER/SOURCE
SHA=$(gh api repos/OWNER/SOURCE/contents/.github/workflows/mirror-secrets.yml --jq '.sha')
gh api repos/OWNER/SOURCE/contents/.github/workflows/mirror-secrets.yml \
  -X DELETE -f message="chore: remove one-shot mirror" -f sha="$SHA"
```

### 陷阱
- `gh run watch` 不穩定（間歇 `error connecting to api.github.com`）→ 用 `gh run view --json` 輪詢。
- mirror PAT 須有 **TARGET** 的 `secrets:write`；只給 SOURCE scope 的 token 寫不進 TARGET。
- 只複製 SOURCE **實際存在**的 secret；若值在已提交程式碼 / `.env.example` placeholder，workflow 會寫空字串 → 先 `gh search code` 找，若已提交直接讀檔，不必 mirror。
- 更新既有 workflow 檔須帶當前 `sha`，否則 HTTP 422 `"sha" wasn't supplied.`。
- 不要發明額外 secret 名；清單有 `SSH_PRIVATE_KEY`/`VPS_SSH_KEY` 就別自作主張加 `SSH_PORT`，除非使用者確認。
- 永遠執行第 6 步清理，不留 `MIRROR_PAT` 或 workflow。

## 6. server-side workflow 內的注意事項

1. Log 只能顯示「有/無值」，永遠不要 `echo` 值本身。
2. 不要假設 secret 已填；debug 時檢查 runner 顯示 secret env 是否空。
3. heredoc 內 `${VAR}` **不會自動展開**：
   ```bash
   # 錯
   cat > ~/.ssh/config <<EOF
   Host vps
     Port ${SSH_PORT}
   EOF
   # 對
   printf 'Host vps\n  Port %s\n  User %s\n' "${SSH_PORT}" "${VPS_USER}" > ~/.ssh/config
   ```
4. 格式對的 secret 仍可能是無效內容：`ssh-keygen -l -f` 驗證；若 `error in libcrypto` 把內容當嫌犯，不要怪 runner。

## 7. 批次設定（使用者一次給多值）

```bash
gh secret set VITE_X --repo OWNER/REPO --body "value1"
gh secret set VITE_Y --repo OWNER/REPO --body "value2"
gh secret set VITE_Z --repo OWNER/REPO --body "value3"
```

依既有命名慣例（如 `VITE_BOOKING_URL`/`VITE_REPLAY_WEB_APP_URL`）沿用，不要另起爐灶。

## 8. 網域自動化 secret 慣例

Cloudflare / GoDaddy DNS+SSL 自動化時，全倉統一名稱：

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
- `GODADDY_API_KEY`
- `GODADDY_API_SECRET`

`whois <domain>` 顯示 Cloudflare NS 就用 Cloudflare API；GoDaddy NS 就用 GoDaddy REST。自動化前這些 credential 必須已存在目標倉。

## 9. 當值根本不是 secret

`NEXT_PUBLIC_*` / `VITE_*` 前端設定常直接 commit 在 source / build config，不必當 secret。mirror 前先 `gh search code "AIzaSy" --repo OWNER/REPO`；若已提交，直接讀檔後 `gh secret set` 客戶端設定。

## 相關技能

- `github-repo-management`（第 01 章）：倉庫設定、分支保護
- `github-pr-workflow`（第 02 章）：CI 修復、合併
- `esggo-vps-toolkit`（第 04 章）：VPS 部署用的 secret 注入
