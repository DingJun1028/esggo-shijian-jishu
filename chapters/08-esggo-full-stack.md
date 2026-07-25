# 08 · ESGGO 全域全端總覽

> 來源：Hermes Agent `esggo-full-stack` 技能 + 本技書第 04/05/06/07 章（已驗證資料）。
> 適用：理解 ESGGO 整體系統組成、跨倉同步、雙重部署（Firebase + Vercel）、Docker、Firestore 規則、故障排除。

## 0. 組件架構

```text
ESGGO 項目組
├── esggo-vps/                 # VPS 部署腳本與設定（實際 VPS 161.118.252.147）
│   ├── deploy.sh              # 一鍵部署腳本
│   ├── nginx/                 # Nginx 配置
│   └── scripts/               # 日常運維腳本
├── esggo-learning-center/     # Firebase + React 學習平台（見第 05 章）
│   ├── src/                   # React 前端
│   ├── firebase.json          # Firebase 配置
│   └── firestore.rules        # 安全規則
└── esggo/ (monorepo)         # 主倉庫：共享類型與腳本
    ├── packages/              # 共享函式庫
    ├── apps/                  # 子應用
    └── scripts/               # 建置腳本
```

## 1. VPS 部署（與第 04 章對齊）

> 注意：本技能原文寫 Ubuntu 22.04 / certbot 有效期至 2026-10-20，與第 04 章實測（Ubuntu 24.04 aarch64）不一致。**以第 04 章為準**（161.118.252.147 / ubuntu / ARM64 / 1 OCPU）。

Nginx 路由（path-based 開發 / domain-based 生產）：
```text
/        → React SPA (dist/)
/api/    → 127.0.0.1:3000 (API)
/ftg/    → /var/www/ftg-tours
```

日常運維：
```bash
sudo systemctl status esggo-nginx esggo-api
sudo systemctl restart esggo-nginx esggo-api
pm2 logs esggo-api
tail -f /var/log/nginx/esggo-access.log
sudo certbot renew --dry-run
```
> VPS 實際有 `next-server` 跑在 3000（非 pm2）；docker compose 用 `/opt/esggo/vps/docker-compose.prod.yml`（見第 04 章第 6 節健康檢查）。

## 2. Firebase 部署（esggo-learning-center）

- 專案 ID：`esggo-learning-center`
- 分支策略：`main` → production
- 環境變數（`.env`，見第 05 章 `.env.example` 對應 `VITE_FB_*`）：
  ```bash
  VITE_FB_API_KEY=AIzaSy...
  VITE_FB_AUTH_DOMAIN=esggo-learning-center.firebaseapp.com
  VITE_FB_PROJECT_ID=esggo-learning-center
  VITE_FB_STORAGE_BUCKET=esggo-learning-center.appspot.com
  VITE_FB_MESSAGING_SENDER_ID=...
  VITE_FB_APP_ID=...
  VITE_BOOKING_URL=https://calendly.com/esggo-consulting
  VITE_ADMIN_PASS=...
  ```
- 部署命令（詳見第 05 章 verify→deploy 儀式）：
  ```bash
  firebase login
  firebase use esggo-learning-center
  firebase deploy --only hosting,firestore:rules
  vercel --prod --yes   # 備援
  ```

## 3. CI/CD 流水線（與第 09 章對齊）

- `ci.yml`：push/PR 到 main → pnpm install / build / test
- `deploy.yml`：push main → build-and-test → deploy-vercel + deploy-firebase（needs 串接）
- 必要 Secrets：見第 03 章 `github-secrets` 與第 09 章表

```yaml
# .github/workflows/ci.yml（摘要）
name: esggo-ci
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }
jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 9 }
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: pnpm }
      - run: pnpm install
      - run: pnpm run build
      - run: pnpm run test
```

## 4. Docker 容器化（與第 06 章對齊）

SPA → nginx 靜態映像：
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

推送 VPS（ARM64 見第 04 章；多架構用 `buildx`，見第 06 章）：
```bash
docker build -t esggo-learning-center .
docker save esggo-learning-center | gzip > esggo.tar.gz
scp esggo.tar.gz ubuntu@161.118.252.147:/tmp/
ssh ubuntu@161.118.252.147 "docker load < /tmp/esggo.tar.gz"
ssh ubuntu@161.118.252.147 "docker-compose down && docker-compose up -d"
```

## 5. Firestore 安全規則（概要）

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function authenticated() { return request.auth != null; }
    function isAdmin() { return authenticated() && request.auth.token.role == 'admin'; }
    match /platforms/{platformId} {
      allow read: if authenticated();
      allow write: if isAdmin();
      match /submissions/{docId} {
        allow read: if isAdmin() || resource.data.userId == request.auth.uid;
        allow create: if authenticated()
          && request.resource.data.keys().hasAll(['userId','type'])
          && request.resource.data.userId == request.auth.uid
          && request.resource.size() <= 1*1024*1024;
      }
    }
  }
}
```
> 實際已寫好 prod 版並由 `firebase deploy --only firestore:rules` 推送（見第 05 章）。

## 6. Cloudflare 設定

- 網域 `esggo.co`；SSL 模式 **Full (strict)**（見第 04 章第 11 節 HTTPS loop 修復）
- API 規則：需透過 SSH 從 VPS 端執行 API；驗證 `Authorization: Bearer <token>`
- Zone ID / Account ID 見第 04 章速查表

## 7. 版本同步（esggo ↔ esggo-learning-center）

共享類型匯出：
```javascript
// scripts/export-shared-types.js
const fs = require('fs');
fs.cpSync('./packages/shared/src/types', './esggo-learning-center/src/types', { recursive: true });
```
同步檢查：
```javascript
// scripts/check-types-sync.js
const a = fs.readFileSync('./esggo/packages/shared/src/types/package.json','utf8');
const b = fs.readFileSync('./esggo-learning-center/src/types/package.json','utf8');
console.log(a === b ? 'TYPES_IN_SYNC' : 'TYPES_OUT_OF_SYNC'); process.exit(a===b?0:1);
```

## 8. 故障排除

| 症狀 | 排查 |
|------|------|
| Node 版本不符 | `node --version` 需 20.x；functions/package.json 設 `engines.node: "20"` |
| Google OAuth 生產失敗 | Firebase Console → Auth → Google 啟用；GCP Credentials → Authorized domains 含 `esggo-learning-center.web.app` / `*.firebaseapp.com` / `localhost:5173` |
| 服務起不來 | `pm2 list` / `pm2 logs`；`sudo nginx -t`；`sudo lsof -i :3000` / `:80` |
| SSL 問題 | `sudo certbot certificates`；`sudo certbot renew`；`sudo certbot --nginx -d esggo.co -d www.esggo.co` |

> VPS 起不來優先用第 04 章 `esggo-core` 診斷六步（logs → 端口 → build → up -d → retry）。

## 9. 聯絡 / 入口

- VPS IP：`161.118.252.147`
- 主網域：`https://esggo.co`
- FTG 官網：`https://ftg.esggo.co`（見第 07 章 SEO）
- 學習中心：`https://esggo-learning-center.web.app`（見第 05 章）

## 相關技能 / 章節

- 第 04 章 VPS 部署、第 05 章 Firebase 部署、第 06 章 Docker、第 07 章 SPA SEO、第 09 章 CI/CD、第 03 章 secrets
