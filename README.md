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
| [00 · 章節模板](./TEMPLATE.md) | 新增章節的寫作規範 | ✅ 已收錄 | 本技書約定 |
| [01 · GitHub 遠端倉庫整理](./chapters/01-github-remote-organization.md) | clone / create / fork / settings / 分支保護 / Releases / Actions | ✅ 已收錄 | `github-repo-management` v1.1.0 |
| [02 · GitHub PR 協作流程](./chapters/02-github-pr-workflow.md) | 分支 / 提交 / 開 PR / 監控 CI / 合併 | ✅ 已收錄 | `github-pr-workflow` v1.1.0 |
| [03 · Actions Secrets/Variables](./chapters/03-github-actions-secrets.md) | write-only 限制 / 跨倉鏡像 / 清理陷阱 | ✅ 已收錄 | `github-secrets` v1.1.0 |
| [04 · VPS 部署實踐](./chapters/04-vps-deployment.md) | OCI / nginx / certbot / Cloudflare / Docker / 健康檢查 | ✅ 已收錄 | `esggo-vps-toolkit` |
| [05 · Firebase 學習中心部署](./chapters/05-firebase-learning-center-deploy.md) | verify→deploy 儀式 / lint 目標 / 地雷 | ✅ 已收錄 | `esggo-learning-center-verify-deploy` v1.0.0 |
| [06 · Docker CLI 速查（修正版）](./chapters/06-docker-cli-cheatsheet.md) | 建映像 / 跑容器 / compose / daemon（含常見錯誤修正） | ✅ 已收錄 | `docker-cli-cheatsheet` v1.0.0 |
| 07 · ... | （待補：esggo 全端、CI/CD 流水線、SEO for SPA…） | ⏳ 規劃中 | — |

## 如何使用

1. 找章節：依目錄或 `search_files` 關鍵字檢索。
2. 照做：每章節的命令可直接複製執行；`gh` 優先，`git`+`curl` 為降級方案。
3. 補章節：複製 `TEMPLATE.md` 為 `chapters/NN-<slug>.md`，並於本目錄表補一列。

## 慣例

- 路徑以專案根目錄為基準；Windows 使用者請用 MSYS/git-bash 語法（`/c/Users/...`）。
- 命令區分 `gh`（CLI 優先）與 `git + curl`（API 降級）。
- 所有遠端操作皆以 `DingJun1028` 帳號下的倉庫為準。
- 語言：繁體中文；命令 / 程式碼保留原文。
