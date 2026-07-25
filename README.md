# ESGGO 實踐技書（esggo-shijian-jishu）

> ESGGO 實戰方法論總冊 —— 把零散的實踐經驗收攏成一本可檢索、可複用的技書。

本倉庫是 ESGGO 專案的「實踐技書」（實戰方法論總冊）。目標：每一項曾經踩過坑、值得下次直接照做的技能，都收錄為一章，附上可執行的命令與驗證步驟，避免重新發明輪子。

## 這本技書包含什麼

- 來自 Hermes Agent GitHub 技能庫的「遠端倉庫整理技能」整編為實踐章節
- ESGGO 各專案的實戰方法論：PR 協作、Actions secrets、VPS 部署、Firebase 學習中心部署
- 可複製貼上的命令、部署流程、排錯清單

## 目錄

| 章節 | 主題 | 狀態 | 來源 |
|------|------|------|------|
| [INDEX · 任務速查索引](./INDEX.md) | 跨章節：按任務/工具/組合流程找章 | ✅ 已收錄 | 本技書導航 |
| [MECE · 架構地圖](./MECE.md) | 領域互斥支柱劃分 + 生命週期窮盡缺口 | ✅ 已收錄 | 本技書導航 |
| [00 · 章節模板](./TEMPLATE.md) | 新增章節的寫作規範 | ✅ 已收錄 | 本技書約定 |
| [01 · GitHub 遠端倉庫整理](./chapters/01-github-remote-organization.md) | clone / create / fork / settings / 分支保護 / Releases / Actions | ✅ 已收錄 | `github-repo-management` v1.1.0 |
| [02 · GitHub PR 協作流程](./chapters/02-github-pr-workflow.md) | 分支 / 提交 / 開 PR / 監控 CI / 合併 | ✅ 已收錄 | `github-pr-workflow` v1.1.0 |
| [03 · Actions Secrets/Variables](./chapters/03-github-actions-secrets.md) | write-only 限制 / 跨倉鏡像 / 清理陷阱 | ✅ 已收錄 | `github-secrets` v1.1.0 |
| [04 · VPS 部署實踐](./chapters/04-vps-deployment.md) | OCI / nginx / certbot / Cloudflare / Docker / 健康檢查 | ✅ 已收錄 | `esggo-vps-toolkit` |
| [05 · Firebase 學習中心部署](./chapters/05-firebase-learning-center-deploy.md) | verify→deploy 儀式 / lint 目標 / 地雷 | ✅ 已收錄 | `esggo-learning-center-verify-deploy` v1.0.0 |
| [06 · Docker CLI 速查（修正版）](./chapters/06-docker-cli-cheatsheet.md) | 建映像 / 跑容器 / compose / daemon（含常見錯誤修正） | ✅ 已收錄 | `docker-cli-cheatsheet` v1.0.0 |
| [07 · SPA 前端 SEO 實踐](./chapters/07-spa-frontend-seo.md) | JSON-LD / hreflang / canonical / robots+sitemap（FTG 官網） | ✅ 已收錄 | `frontend-seo-for-spa` v1.1.0 |
| [08 · ESGGO 全域全端總覽](./chapters/08-esggo-full-stack.md) | 組件架構 / 雙重部署 / Docker / Firestore / 故障排除 | ✅ 已收錄 | `esggo-full-stack`（對齊第 04/05/06/07） |
| [09 · CI/CD 推送到 VPS](./chapters/09-cicd-push-to-deploy.md) | GitHub Actions 自動部署 / SCP / nginx reload / cron 備援 | ✅ 已收錄 | `vps-push-to-deploy` |
| [10 · 測試驅動開發 TDD](./chapters/10-test-driven-development.md) | 紅綠重構 / 鐵律 / 反模式 / Hermes 整合 | ✅ 已收錄 | `test-driven-development` v1.1.0 |
| [11 · 系統化除錯](./chapters/11-systematic-debugging.md) | 四階段找根因 / 回饋迴圈 / 三則規則 | ✅ 已收錄 | `systematic-debugging` v1.1.0 |
| [12 · 計畫模式 Plan Mode](./chapters/12-plan-mode.md) | 只規劃不執行 / 一口大小任務 / DRY·YAGNI·TDD | ✅ 已收錄 | `plan` v2.0.0 |
| [13 · 提交前程式碼審查](./chapters/13-pre-commit-code-review.md) | 靜態掃描 / 獨立審查者 / 自動修迴圈 / [verified] | ✅ 已收錄 | `requesting-code-review` v2.0.0 |
| [14 · 子代理編排](./chapters/14-subagent-orchestration.md) | delegate_task 規模執行 / 兩階段審查 / 批次平行 | ✅ 已收錄 | `delegate_task` + two-stage 模式 |
| [15 · 監控與事故響應](./chapters/15-monitoring-incident-runbook.md) | 三層探活 / 事故分級 / 回滾 runbook（G3） | ✅ 已收錄 | 第 04 章 + esggo-core 實踐 |
| [16 · 本地開發環境上手](./chapters/16-local-dev-onboarding.md) | 各 repo 上手對照 / .env / 換機注意（G4） | ✅ 已收錄 | 各章實證 + 記憶規範 |
| [17 · 安全強化](./chapters/17-security-hardening.md) | 依賴/注入/最小權限/SSRF（G5，超 secrets） | ✅ 已收錄 | 第 13 章 + pnpm 規範 |
| — | （Design 缺口由第 12 章 plan 架構段涵蓋，不另開篇） | ✅ 已涵蓋 | 第 12 章 |

## 如何使用

## 1. 先查索引：兩張導覽表

- [INDEX.md](./INDEX.md)：按「我想做… / 工具 / 組合流程」找章節（任務導向）。
- [MECE.md](./MECE.md)：領域如何切成互斥支柱、章節為何不重疊、生命週期還缺什麼（結構導向）。
2. 找章節：依目錄或 `search_files` 關鍵字檢索。
3. 照做：每章節的命令可直接複製執行；`gh` 優先，`git`+`curl` 為降級方案。
4. 補章節：複製 `TEMPLATE.md` 為 `chapters/NN-<slug>.md`，並於本目錄表補一列。

## 慣例

- 路徑以專案根目錄為基準；Windows 使用者請用 MSYS/git-bash 語法（`/c/Users/...`）。
- 命令區分 `gh`（CLI 優先）與 `git + curl`（API 降級）。
- 所有遠端操作皆以 `DingJun1028` 帳號下的倉庫為準。
- 語言：繁體中文；命令 / 程式碼保留原文。
