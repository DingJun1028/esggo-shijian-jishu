# 09 · CI/CD 流水線：GitHub Actions 推送到 VPS 自動部署

> 來源：Hermes Agent `vps-push-to-deploy` 技能 + 本技書第 03 章（secrets）/ 第 04 章（VPS）。
> 適用：把靜態站 / SPA 的 `git push` 變成 Vercel 式自動部署到 Linux VPS（SCP + nginx reload）。
> 與第 08 章 esggo 全端 CI/CD 互補（本章程式碼優先、可直接套用）。

## 0. 前置

- GitHub repo 含源碼
- VPS 有 SSH 存取 + `sudo systemctl reload nginx`
- GitHub Secrets：`VPS_SSH_KEY`（私鑰，多行）、`VPS_HOST`（IP）、`VPS_USER`（通常 `ubuntu`）
- 本地與 CI 皆需 Node.js + pnpm（見第 03 章設定 secret）

## 1. Workflow 模板

建 `.github/workflows/deploy-vps.yml`：
```yaml
name: Deploy to VPS via SCP + reload nginx
on:
  push:
    branches: [master, main]
    paths:
      - '<project-dir>/**'
      - '.github/workflows/deploy-vps.yml'
jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      VPS_HOST: ${{ secrets.VPS_HOST }}
      VPS_USER: ${{ secrets.VPS_USER }}
      VPS_TARGET: /var/www/<site>
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with: { node-version: 22, cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm run build
      - name: Deploy to VPS
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.VPS_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa
          ssh -o StrictHostKeyChecking=accept-new ${{ env.VPS_USER }}@${{ env.VPS_HOST }} \
            "sudo mkdir -p ${{ env.VPS_TARGET }} && sudo chown -R ${{ env.VPS_USER }}:${{ env.VPS_USER }} ${{ env.VPS_TARGET }}"
          rsync -az --delete -e "ssh -o StrictHostKeyChecking=accept-new" dist/ \
            ${{ env.VPS_USER }}@${{ env.VPS_HOST }}:${{ env.VPS_TARGET }}/
          ssh ${{ env.VPS_USER }}@${{ env.VPS_HOST }} "sudo systemctl reload nginx && echo 'nginx reloaded'"
      - name: Verify deploy
        run: |
          curl -sS https://<domain>/ | grep -q '<site-indicator>' && echo 'deploy verified' || echo 'verify failed'
```

## 2. 分支 / 發佈最佳實踐

- 用 feature branch + PR，**不要**直接 commit 到 `master`/`main`
- 保護部署分支，合併前要求 PR review
- 分支前綴：`ci/` `fix/` `feat/`；約定式提交 `ci:` `fix:` `feat:` `chore:`

## 3. SPA 專屬步驟（Cloudflare 後方）

1. 若 Rocket Loader 無法關閉 → inline JS patch：修補 bundle 內 `import.meta` 引用，把 bundle 內聯進 `index.html`，並 escape `</script>` 防 HTML 解析截斷。
2. 內聯 patch 後**整份替換** `index.html`，避免重複內聯區塊堆積（`Path('dist/index.html').write_text(fixed_html)`）。
3. nginx config 加：`location / { add_header Cache-Control "no-store" always; }`

> FTG 官網 `ftg.esggo.co` 是 React **HashRouter**（見第 04 章），子頁走 `#` 前綴；VPS 部署用 SCP 到 `/var/www/ftg-tours` 後 reload nginx。

## 4. Secrets 設定

GitHub repo Settings → Secrets and variables → Actions：

| Secret | 值 |
|--------|-----|
| `VPS_SSH_KEY` | 私鑰內容（多行） |
| `VPS_HOST` | VPS IP 或主機名 |
| `VPS_USER` | SSH 使用者（通常 `ubuntu`） |

> 設定 / 清理細節見第 03 章 `github-secrets`（write-only、mirror、非互動刪除）。

## 5. 常見問題

- **ssh-keyscan 失敗**：加 `-p 22 -H`，或用 `StrictHostKeyChecking=no`
- **Permission denied**：確認 `VPS_SSH_KEY` 是私鑰不是公鑰
- **scp 找不到**：workflow 內 `apt-get install -y openssh-client`
- **nginx reload 失敗**：檢查 sudoers 的密碼免輸 sudo
- **Cloudflare 仍給舊 HTML**：手動 Purge Cache 或加 API purge 步驟
- **Actions job 不啟動（立即 billing 錯）**：不是 YAML 語法錯；免費/新帳號先確認 Actions 分鐘數與付款方式有效，再 re-run
- **帳號級 billing 鎖**：free-tier / private repo 可能 job 前就被擋；先解 billing，別調 YAML

## 6. 離線備援：VPS cron 部署

GitHub Actions 不可用時，用唯讀 SSH deploy key + VPS cron：
1. VPS 生成 `ed25519` deploy key，加到 GitHub Deploy Key（read-only）
2. VPS 上 clone repo
3. 寫 `~/deploy-scripts/deploy-<site>.sh`：
   - `git fetch origin && git reset --hard origin/master`
   - `pnpm install --frozen-lockfile && pnpm run build`
   - 必要時 inline-patch `dist/index.html`（Cloudflare / Rocket Loader）
   - 整份替換 `index.html`
   - `sudo rsync -az --delete $REPO_DIR/dist/ /var/www/<site>/`
   - `sudo systemctl reload nginx`
4. `chmod +x`、手動測試、再加 cron

## 7. 與 Vercel 式對比

得到的：push main 自動部署 / 部署前 build 驗證 / Actions UI 可看 log / `git revert` 快速回滾。

限制：GitHub Actions 免費公開倉 2000 min/月；Vercel Hobby 100GB 流量；build timeout GitHub 6h vs Vercel 45min。

## 相關技能 / 章節

- 第 03 章 Actions Secrets、第 04 章 VPS 部署、第 08 章 esggo 全端 CI/CD
- `spa-deploy-and-cdn-debug`、`cloudflare-rocket-loader-spa-fix` 等 devops 技能
