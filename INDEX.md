# 實踐技書 · 任務速查索引（INDEX）

> 跨 12 章的任務導航。想做某件事，先查這裡再跳對應章節。
> 想知道「領域如何切成互斥支柱、章節為何不重疊、還缺什麼」→ 看 [MECE.md](./MECE.md)（結構導向）。
> 慣例：所有命令以 `gh` 優先、`git`+`curl` 降級（詳見各章）。

## 1. 按「我想做…」找章節

| 我想做 | 看章節 | 關鍵命令速記 |
|--------|--------|--------------|
| 建新 GitHub 倉庫 / fork / 設 topics / 分支保護 | [01](./chapters/01-github-remote-organization.md) | `gh repo create` / `gh repo fork` / `gh repo edit --add-topic` |
| 收納/清理遠端倉庫（封存長草 repo、改名、刪除、同步 fork、autolink、deploy-key、秘密防漏） | [01](./chapters/01-github-remote-organization.md) | `gh repo archive` / `gh repo rename` / `gh repo delete --yes` / `gh repo sync` / `gh repo edit --enable-secret-scanning-push-protection` |
| 週期性盤點/健康檢查遠端倉庫（封存/刪除/同步/保護/secret 輪換的 runbook） | [18](./chapters/18-repo-health-runbook.md) | `gh repo list --json` 盤點 / 閾值判斷 / `gh repo archive`+`gh repo sync` |
| 開分支、寫 commit、發 PR、等 CI、合併 | [02](./chapters/02-github-pr-workflow.md) | `git checkout -b feat/x` / `gh pr create` / `gh pr merge --squash` |
| 設/讀/跨倉搬 Actions secrets（含 write-only 限制） | [03](./chapters/03-github-actions-secrets.md) | `gh secret set` / `gh api -X DELETE` / mirror workflow |
| 把網站/deploy 到 VPS（nginx/certbot/Cloudflare/Docker） | [04](./chapters/04-vps-deployment.md) | `certbot --nginx` / `ssh ... reload nginx` / 健康檢查 curl |
| 部署學習中心到 Firebase（verify→deploy 儀式） | [05](./chapters/05-firebase-learning-center-deploy.md) | `firebase deploy --only hosting,firestore:rules` |
| 查 Docker 命令（建映像/跑容器/compose/daemon） | [06](./chapters/06-docker-cli-cheatsheet.md) | `docker build -t x --no-cache .` / `docker compose up -d` |
| 強化 SPA SEO（JSON-LD/hreflang/canonical/robots） | [07](./chapters/07-spa-frontend-seo.md) | `src/utils/seo.js` / `usePageSeo` / `public/sitemap.xml` |
| 理解 ESGGO 整體系統組成與故障排除 | [08](./chapters/08-esggo-full-stack.md) | 組件架構 / Firestore 規則 / 故障排除表 |
| 設定 GitHub Actions 自動部署到 VPS | [09](./chapters/09-cicd-push-to-deploy.md) | `.github/workflows/deploy-vps.yml` / rsync + reload |
| 寫程式前先寫失敗測試（紅綠重構） | [10](./chapters/10-test-driven-development.md) | RED→GREEN→REFACTOR；`pytest ::test_x -v` |
| 系統化找 bug 根因（四階段） | [11](./chapters/11-systematic-debugging.md) | 建緊迴圈 / 三則規則 / 質疑架構 |
| 把多步實作寫成可執行計畫（不執行） | [12](./chapters/12-plan-mode.md) | `.hermes/plans/` / 一口大小任務 / DRY·YAGNI·TDD |

## 2. 按「工具 / 命令」找章節

| 工具 | 主要章節 |
|------|----------|
| `gh`（repo / pr / secret / release / workflow） | 01, 02, 03 |
| `git` + `curl`（REST API 降級） | 01, 02, 03 |
| `docker` / `docker compose` | 06, 08 |
| `nginx` / `certbot` / `cloudflared` | 04, 09 |
| `firebase` / `vercel` | 05, 08 |
| `cloudflare` DNS / API / Tunnel | 04 |
| `pnpm` / `npm` / `vitest` | 05, 09 |
| `pytest` / TDD | 10, 11 |
| GitHub Actions YAML | 03, 09 |
| `delegate_task` / `subagent` / `plan` | 11, 12 |

## 3. 常見組合流程（串章節）

| 場景 | 推薦章節順序 |
|------|--------------|
| **新功能上線** | 02 PR 協作 → 09 CI/CD 自動部署 → 04/05 部署上線；先 10 TDD 寫測試 |
| **線上 bug 修復** | 11 系統化除錯（找根因）→ 10 TDD（先寫失敗測試再修）→ 02 發 PR → 09 部署 |
| **從零建專案** | 01 建倉庫+設 topics/保護 → 12 寫計畫 → 10 TDD 開發 → 09 接 CI/CD → 04/05 部署 |
| **VPS 部署 SPA** | 04 VPS 實踐（nginx/certbot）→ 09 Actions 推送 → 06 Docker 若容器化 → 07 SEO |
| **ESGGO 全端排障** | 08 全端總覽（故障表）→ 04/05 具體部署章 → 11 除錯 → 03 secrets |
| **強化官網能見度** | 07 SPA SEO → 04/09 部署生效 → 05（若學習中心） |

## 4. 驗證心法（跨章通用）

- 每章都有「地雷/陷阱」+「驗證清單」兩節，宣稱成功前必跑。
- 部署類（04/05/09）：先本地 `build` + `lint` + `test` 通過，再部署，再線上驗證。
- Secrets 類（03）：永遠記住 write-only，需要值就讓使用者貼或走 server-side mirror。
- 品質類（10/11/12）：紅綠重構、先根因後修、計畫一口大小。

## 相關

- [README](./README.md) 完整目錄
- [TEMPLATE](./TEMPLATE.md) 新增章節規範
