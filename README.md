# ESGGO 實踐技書（esggo-shijian-jishu）

> ESGGO 實戰方法論總冊 —— 把零散的實踐經驗收攏成一本可檢索、可複用的技書。

本倉庫是 ESGGO 專案的「實踐技書」（實戰方法論總冊）。目標：每一項曾經踩過坑、值得下次直接照做的技能，都收錄為一章，附上可執行的命令與驗證步驟，避免重新發明輪子。

## 這本技書包含什麼

- 來自 Hermes Agent GitHub 技能庫的「遠端倉庫整理技能」整編為實踐章節
- 各專案（esggo / esggo-learning-center / ftg-tours-website / youtube-automation-pipeline 等）的實戰方法論
- 可複製貼上的命令、部署流程、排錯清單

## 目錄

| 章節 | 主題 | 狀態 |
|------|------|------|
| [01-github-remote-organization](./chapters/01-github-remote-organization.md) | GitHub 遠端倉庫整理技能 | ✅ 已收錄 |
| 02-... | （待補：VPS 部署、CI/CD、Firebase 學習中心…） | ⏳ 規劃中 |

## 如何使用

1. 找章節：依目錄或 `search_files` 關鍵字檢索。
2. 照做：每章節的命令可直接複製執行；`gh` 優先，`git`+`curl` 為降級方案。
3. 補章節：新技能請在 `chapters/` 新增 `NN-<topic>.md`，並於本目錄表補一列。

## 慣例

- 路徑以專案根目錄為基準；Windows 使用者請用 MSYS/git-bash 語法（`/c/Users/...`）。
- 命令區分 `gh`（CLI 優先）與 `git + curl`（API 降級）。
- 所有遠端操作皆以 `DingJun1028` 帳號下的倉庫為準。
