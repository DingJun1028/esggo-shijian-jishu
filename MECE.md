# 實踐技書 · MECE 架構地圖

> 目的：用 MECE（Mutually Exclusive 互斥、Collectively Exhaustive 窮盡）原則，把「ESGGO 工程實踐」領域切成互斥支柱，把每章精確歸位，並檢查是否窮盡整個生命週期。
> 適用：想理解「這本技書的邊界在哪、章節怎麼不重疊、還缺什麼」時先讀這份。
> 配合 [INDEX.md](./INDEX.md)（任務導航）使用：INDEX 告訴你「做 X 看哪章」，本圖告訴你「全領域怎麼切、有無漏洞」。

## 1. MECE 支柱劃分

把 ESGGO 工程實踐切成 6 個互斥支柱。每章只歸一個支柱，避免重疊。

| 支柱 | 涵蓋的「問題」 | 章節 |
|------|----------------|------|
| **A. 規劃與設計** | 動手前先把多步實作寫成可執行計畫 | [12 計畫模式](./chapters/12-plan-mode.md) |
| **B. 開發與品質紀律** | 寫碼當下的工程紀律：先測後碼、找根因 | [10 TDD](./chapters/10-test-driven-development.md)、[11 系統化除錯](./chapters/11-systematic-debugging.md) |
| **C. 協作與版本控制** | 與他人/與自己的程式碼如何存放、審閱、合併 | [01 倉庫管理](./chapters/01-github-remote-organization.md)、[02 PR 協作](./chapters/02-github-pr-workflow.md) |
| **D. 建置與封裝** | 把程式碼變成可交付的成品（映像/套件） | [06 Docker CLI](./chapters/06-docker-cli-cheatsheet.md) |
| **E. 部署與上線** | 把成品送到可服務使用者的環境 | [04 VPS 部署](./chapters/04-vps-deployment.md)、[05 Firebase 部署](./chapters/05-firebase-learning-center-deploy.md)、[09 CI/CD 推送](./chapters/09-cicd-push-to-deploy.md)、[07 SPA SEO](./chapters/07-spa-frontend-seo.md) |
| **F. 跨切面與導覽** | 橫跨多支柱的基礎設施，以及全系統地圖 | [03 Actions Secrets](./chapters/03-github-actions-secrets.md)、[08 全端總覽](./chapters/08-esggo-full-stack.md) |

## 2. 互斥性處理（化解既有重疊）

原先有三處看起來重疊，本圖明確歸位以消除歧義：

- **第 08 章 vs 04/05/06/07/09**：08 看似重複這些 how-to。本圖把 08 歸為 **F 支柱的「系統導覽」**——它只回答「ESGGO 各元件如何拼成一體、故障時從哪查起」，**不重複**各章的逐步操作。讀者要「怎麼做」去 04–07/09，要「整體拼圖」才來 08。
- **第 03 章 vs 09**：03 講 secrets 管理機制，09 部署需要 secrets。把 03 歸 **F（跨切面基礎設施）**，09 歸 E（部署流程）；09 部署時「設定 secret」直接引用 03，不重寫。
- **第 07 章 vs 06/B**：07 是上線前的網站品質（SEO），與 06 封裝、10 測試不同維度。歸 **E（部署與上線）** 的「上線前品質」子類，避免與 B 的程式碼品質混淆。

> 每章只出現在一個支柱 → 互斥成立。

## 3. 窮盡性檢查（完整生命週期缺口）

把工程價值流拆成標準階段，逐階段標記覆蓋情況：

| 生命週期階段 | 覆蓋 | 對應章節 | 狀態 |
|--------------|------|----------|------|
| Plan 規劃 | ✅ | 12 | 已涵蓋 |
| Design 設計 | ⚠️ | — | 缺口（架構決策、需求拆解未專章） |
| Design 設計 | ⚠️ | — | **已由第 12 章 plan 的「Architecture / 作法」段涵蓋**（不另開篇，避免重疊） |
| Review 審查 | ✅ | 13 | 已涵蓋 |
| Collaborate 協作/版本 | ✅ | 01, 02 | 已涵蓋 |
| Build 建置 | ✅ | 06 | 已涵蓋 |
| Test 測試基礎設施 | ⚠️ | 10（含 pytest） | 部分；vitest/jest 實作細節未專章 |
| Deploy 部署 | ✅ | 04, 05, 09, 07 | 已涵蓋（自管 infra / 託管 PaaS / pipeline / 前品質） |
| Operate/Monitor 營運監控 | ✅ | 15 | 已涵蓋（三層探活 / 回滾 / 事故） |
| Secure 安全 | ✅ | 03, 17 | 已涵蓋（secrets + 依賴/注入/權限/SSRF） |
| Execute-at-scale 規模執行 | ✅ | 14 | 已涵蓋（delegate_task 子代理編排） |
| Onboard 環境上手 | ✅ | 16 | 已涵蓋 |

**結論**：B/C/D/E/A 五大階段已窮盡；**Design、Review、Operate、Secure、Scale、Onboard** 六處有缺口（G1–G5 + Design）。這就是下一輪該補的方向。

## 4. 補齊窮盡性的建議章節（按 MECE 順序）

> **狀態更新**：G1–G5 與 Design 缺口已全部閉合（見 §3 表格）。
> - G1 Review → 第 13 章
> - G2 Scale → 第 14 章
> - G3 Operate → 第 15 章
> - G4 Onboard → 第 16 章
> - G5 Secure → 第 17 章（第 03 章管 secrets 子題）
> - Design → 第 12 章 plan 的「Architecture / 作法」段涵蓋（不另開篇，避免重疊）
>
> 補到 17 後，生命週期六缺口全閉合 → 達成 Collectively Exhaustive。

## 5. 用法

- 想「做某件事」→ 查 [INDEX.md](./INDEX.md)。
- 想「理解全領域邊界 / 章節為何不重疊 / 還缺什麼」→ 讀本圖。
- 新增章節時：先決定它歸哪個支柱（§1），確認不與他章重疊（§2），再填 §3 的某個缺口（§4）。

## 相關

- [README](./README.md) 完整目錄
- [INDEX.md](./INDEX.md) 任務導航
- [TEMPLATE.md](./TEMPLATE.md) 新增章節規範
