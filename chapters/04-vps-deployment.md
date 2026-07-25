# 04 · VPS 部署實踐（ESGGO 堆疊）

> 來源：Hermes Agent `esggo-vps-toolkit` 技能 + 實際 VPS（161.118.252.147，Oracle ARM64 Ubuntu 24.04）。
> 涵蓋：OCI 啟動 → SSH → nginx 路由 → certbot HTTPS → Cloudflare DNS → GitHub Actions 部署 → Docker/Next.js → 排錯。

## 0. 環境速查

| 項目 | 值 |
|------|-----|
| VPS IP | `161.118.252.147` |
| 使用者 | `ubuntu`（ARM Ampere A1 `VM.Standard.A1.Flex`，1 OCPU） |
| 作業系統 | Ubuntu 24.04 aarch64 |
| 主要網站 | `esggo.co` / `www.esggo.co` → next-server :3000 |
| FTG 官網 | `ftg.esggo.co` → `/var/www/ftg-tours`（Vite SPA，HashRouter） |
| Cloudflare Zone ID | `8dda3653e490290412f7be84a84e0dc9` |
| Cloudflare Account ID | `d9d7ecd92cbad6d858fba3e529b9cb7b` |

## 1. OCI Bootstrap 與 SSH key

- Cloud-init 會在開機生成 `/root/.ssh/authorized_keys` 前擋住 UFW；user-data 腳本必須把公鑰 append 到該檔。
- **陷阱**：Oracle 主控台**不能貼上外部產生的私鑰** —— 必須在 Oracle Console 內生成 key pair。
- 兩把 key：
  - OCI 主控台生成 pair：私鑰放 `C:\Project\ESGGO VPS\`（不進 git）。
  - 僅用於 GitHub Actions 部署的 key：`C:\Project\esggo\actions_deploy_key`，只裝**公鑰**到 VPS `~/.ssh/authorized_keys`，私鑰餵進 repo Secret `VPS_SSH_KEY`。

## 2. Nginx 路由

**Path-based（開發 / 多應用）：** 一個 site config，三角色
- `/` + `/api/` → `http://127.0.0.1:3000/`
- `/ftg/` → `/var/www/ftg-tours` 靜態 SPA
- `/api/` proxy 保留 `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`

**Domain-based（生產推薦）：** 獨立 server block
- `esggo.co` / `www.esggo.co` → `proxy_pass` 127.0.0.1:3000
- `ftg.esggo.co` → `root /var/www/ftg-tours` + `try_files $uri $uri/ /index.html`
- 每 host 各自 HTTP→HTTPS 301 block

**最佳實踐**：合併重複的 HTTP `return 404` 規則（certbot 常注入多個 HTTP block），每 `server_name` 收成一個，避免 listener 端口順序錯配。

## 3. HTTPS / Certbot

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d esggo.co -d www.esggo.co -d ftg.esggo.co   # SAN 含全部 3 主機
# 續期：systemd timer（certbot 預設裝好）
```
- **陷阱**：DNS 必須先解析（A/CNAME → VPS IP），否則 certbot 失敗。

## 4. Cloudflare DNS（API）

- Token 須有 **Zone:DNS:Edit**（zone `esggo.co`）。
- 使用前驗證：`GET https://api.cloudflare.com/client/v4/user/tokens/verify`
- 更新 A：`GET /zones/{zone}/dns_records?type=A&name=esggo.co` → `PUT /zones/{zone}/dns_records/{id}`
- 加 CNAME：`POST /zones/{zone}/dns_records`（`type=CNAME`,`name=www`,`content=esggo.co`）
- **陷阱**：plain HTTP origin 不要用 `proxied:true`，用 `proxied:false`；Page Rules API 需另外 scope，懷疑快取 redirect loop 就手動 Purge Cache（Dashboard）。

## 5. GitHub Actions 部署

### 通用 CI/CD 結構（Vite/React）
- Build job：`npm ci` → `npm run build` → upload `dist/`
- Lint job：`npm run lint`
- Test job：`npm run test:run`
- Deploy job：依賴 [build, lint, test] → download artifact → deploy

### 部署目標範例
```yaml
# GitHub Pages（靜態 SPA）
- uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./dist/

# Vercel
- uses: amondnet/vercel-action@v25
  with:
    vercel-token: ${{ secrets.VERCEL_TOKEN }}
    vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
    vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
```

### 非 Docker（VPS host-process，FTG SPA）
SSH 命令（Windows runner）：
```bash
ssh -o StrictHostKeyChecking=accept-new -i ${{ secrets.VPS_SSH_KEY }} ubuntu@161.118.252.147 'sudo systemctl reload nginx'
```
部署腳本只上傳 build 成品（SCP/rsync），nginx config 另行管理，公開目錄 `chown` 後 reload。

- **套件管理器陷阱**：同時有 `package-lock.json` 與 `pnpm-lock.yaml` 時 `npm ci` 會衝突 → 擇一固定。

## 6. Docker on ARM64 實踐

- 兩個 CLI：`docker compose`（v2 插件，推薦）`/usr/bin/docker-compose`（v1 舊）。v1 偶發 `KeyError: 'ContainerConfig'`。
- Daemon 修復：
  ```bash
  sudo rm -f /var/run/docker.pid
  sudo systemctl daemon-reload
  sudo systemctl restart docker.socket docker.service
  ```
- ARM64 限制 1 OCPU：app `cpus: "0.90"`、gateway `cpus: "0.20"`。
- pnpm 在 Docker 內 non-TTY 失敗（`ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY`）→ Dockerfile 設 `ENV CI=true` + `--config.confirmModulesPurge=false`；runner 階段複製 `node_modules`/`.next` 而非重跑 pnpm。
- Host nginx 佔 80/443，docker nginx 綁同端口會衝突 → 停 host nginx 或改連 host network。
- 容器名衝突：`docker rm -f <name>` 再 `docker compose up -d`。

## 7. Next.js + nginx 健康檢查

```bash
curl -sS -w "HTTP %{http_code}" http://127.0.0.1:3000/api/health
curl -sS -I -H "Host: esggo.co" http://127.0.0.1/api/health
```
- `esggo-core` unhealthy：先看 `docker logs --tail 120 --timestamps esggo-core`，區分「端口被佔（connection refused）」vs「app 降級（DATABASE_URL 缺失等）」。先 `docker ps` + `ss -ltnp | rg ':3000'` 排除端口衝突，再 `docker compose -f /opt/esggo/vps/docker-compose.prod.yml build --no-cache esggo` → `up -d --no-deps esggo` → 有界重試 loop 驗證。
- **陷阱**：容器 `Up` 不代表 `/health` 健康 —— `curl` 可能回 `000`。

## 8. Cloudflare HTTPS redirect loop 診斷

1. 直測 origin：`curl -sS -o /dev/null -w "%{http_code}\n" -m 8 -H "Host: esggo.co" "https://<VPS_IP>/"`
   → 200 表示 origin 乾淨，loop 在 Cloudflare / nginx 80→443。
2. 測網域：`curl -sS -I --max-redirs 2 -m 8 "https://esggo.co"` 重複 301 + `Server: cloudflare` → Cloudflare 端 loop。
3. 修復：移除 nginx 443 block 內 `return 301 https://...`（Cloudflare 終止 TLS 時 origin 不該再強制跳）；`sudo nginx -t && sudo systemctl reload nginx`；Dashboard Purge Cache 或切 Full→Full(strict) 清 edge。

## 9. Cloudflare Tunnel（VPS 快速通道）

```bash
sudo cloudflared tunnel login        # 開瀏覽器授權，cert 落到 /root/.cloudflared/<UUID>.json
sudo cloudflared tunnel create esggo-tunnel
sudo cloudflared tunnel route dns esggo-tunnel esggo.co
sudo cloudflared tunnel route dns esggo-tunnel www.esggo.co
sudo cloudflared tunnel route dns esggo-tunnel ftg.esggo.co
sudo cloudflared tunnel run esggo-tunnel
```
- 無瀏覽器 VPS：`tunnel login` 網址會過期，從本機跑並 SCP cert 到 `/root/.cloudflared/`。

## 10. 長時間 VPS 命令（tmux）

SSH 長命令約 90s 後 `Connection reset by peer` → 改 VPS 本地 tmux：
```bash
tmux kill-session -t <name> 2>/dev/null || true
tmux new-session -d -s <name> "bash /usr/local/bin/<script>.sh"
tmux capture-pane -pt <name> -S -200 2>&1 | tail -80
```

## 11. 驗證清單（宣稱成功前必跑）

| 檢查 | 命令 |
|------|------|
| Next.js 活著 | `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/api/health` |
| nginx 活著 | `curl -sS -I -H "Host: esggo.co" http://127.0.0.1/` |
| FTG 活著 | `curl -sS -o /dev/null -w "%{http_code}" -H "Host: ftg.esggo.co" http://127.0.0.1/` |
| Gateway 活著 | `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:8642/status` |
| HTTPS 端到端 | `curl -sS -I https://esggo.co/` + `curl -sS -I https://ftg.esggo.co/` |
| Build | `pnpm run build` / `npm run build` |
| Lint | `pnpm run lint` / `npm run lint` |
| Test | `pnpm run test:run` / `npm run test:run` |

## 12. 品牌與路徑慣例（FTG）

- 品牌字：**墾趣旅遊**（FTG TOURS）—— 絕非「望趣旅遊」。
- FTG 用 React **HashRouter**：子頁網址須帶 `#`（例 `ftg.esggo.co/#/corporate-travel`）；直接訪 `/corporate-travel` 會回退首頁（非 bug）。Footer 內部連結用 `<Link>` 不用 `<a href="/path">`。
- Logo 放 `public/logos/ftg-logo.png`，更新 Navbar/Footer/離線殼層每個渲染品牌識別處；勿 base64 內聯進 JSX（脹 bundle、破快取）。
- Windows git-bash 路徑：SCP/rsync 用 `C:/Project/...` POSIX 形式，勿用反斜線。

## 相關技能

- `github-secrets`（第 03 章）：VPS 部署用的 `VPS_SSH_KEY` 注入
- `esggo-learning-center-verify-deploy` 儀式（第 05 章）
- `cloudflare-*`、`spa-ssl-deployment`、`vps-push-to-deploy` 等 devops 技能
