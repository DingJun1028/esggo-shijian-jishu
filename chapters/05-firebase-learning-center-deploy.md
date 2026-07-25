# 05 · Firebase 學習中心 verify → deploy 儀式

> 來源：Hermes Agent `esggo-learning-center-verify-deploy` 技能（v1.0.0）。
> 適用：`esggo-learning-center` repo（Vite + React + Tailwind + Vitest + Firebase Hosting）。
> 這是日常迴圈；完整架構見 repo `docs/ESGGO_PLATFORM_BEST_PRACTICES.md`。

## 0. 何時用

- 改程式碼、i18n 字串、元件、路由、Firebase 對應。
- 部署學習中心到 Firebase Hosting。
- 變更前/後確認 repo 健康。

## 1. 硬性規則（來自 AGENTS.md，不可略）

- **語言**：UI 文案、輸出、錯誤訊息一律**繁體中文**，無英文 fallback。
- **驗證順序（modernity first）** —— 宣稱完成前必跑：
  ```bash
  npm run test
  npm run build
  ```
  i18n / 元件 / 路由 / Firebase 變更絕不可跳過。
- **Lint 目標**：`pnpm run lint` → 0 errors / 0 warnings。
  - **勿刪除** `src/repositories/**` + `src/db.js` 裡的 `doc/setDoc/getDoc/query/where/getDocs/serverTimestamp/writeBatch` import（Firebase 模式刻意保留；ESLint 在那裡關掉 `no-unused-vars`）。
  - `src/i18n/` 內 `no-dupe-keys` 刻意關閉（zh-TW/zh-CN 是分開的父物件）；真重複 key 是另一個清理任務。
  - 先修程式碼，再考慮動 ESLint config（`react-hooks/rules-of-hooks` 等）。

## 2. 部署儀式

**Pre-flight（任何部署前）：**
- 確認 `.firebaserc`（project `esggo-learning-center`）、`firebase.json`（hosting `public: dist`、SPA rewrite 到 `/index.html`）、`firestore.rules` 完好且 git-clean。
- 確保 `dist/` 是新的：任何 `node_modules` 重建或程式變更後先 `npm run build`，否則會上傳舊碼。
- 登入檢查：`firebase login:list` 某些環境會 HANG（瀏覽器/網路）；超時別卡住，改查 `~/.config/configstore/firebase-tools.json` 是否存在（token 在）即可。部署本身若真未認證會快速失敗。

1. **安全預設（合併）：**
   ```bash
   firebase deploy --only hosting,firestore:rules
   ```
   跳過 `functions`（firebase.json 裡 source 是 `functions/`，但非學習中心前端流程一部分）→ 安全。
2. **hosting-only 快路徑** 僅當 `.firebase.json`/`.firebaserc` 完好 **且** 本次沒動 `firestore.rules`。
3. **部署後驗證（強制，完整鏈）：**
   ```bash
   npm run build      # 確認 dist 仍建得過
   pnpm run lint      # 0 errors / 0 warnings
   npm run test       # 8/8 pass
   ```
   綠燈部署**不足夠** —— 本地重驗證抓出上傳沒浮現的回歸。
4. 元件內**絕不硬編碼目標 URL** —— `.env` 是單一真相來源。
5. 選擇性**線上驗證**：開 `https://esggo-learning-center.web.app`（browser tool）確認頁面渲染（SPA + Firebase auth init）。

## 3. 地雷

- **AGENTS.md 是 cwd-only**：只有 Hermes cwd 是此 repo 才自動載入。從別處呼叫時，讀 `C:\Project\esggo-learning-center\AGENTS.md` 或先載此技能。
- Windows CJK workspace：相信 `read_file` 讀回結果勝過 write/patch「成功」回報 —— build 抓不到沒翻譯的殘留字串。
- AGENTS.md（2026-07-20）列出的已知 runtime bug 在 `main` 上**全部確認已修**；動手「修」任何一個前先對當前程式碼重驗證。
- 當前分支是 `main`（AGENTS.md 寫 `i18n-full-translation` 是過時文字）。

## 4. 健康檢查（cron）

- `scripts/esggo_healthcheck.sh` 每日 09:00 跑 `npm test && npm build`，通過印 `[esggo-health] ... OK`，失敗印 FAIL + tail。
- 查結果：`hermes cron list`（或 `cronjob action=list`）。

## 相關技能

- `esggo-vps-toolkit`（第 04 章）：VPS / Docker / nginx 部署
- `esggo-learning-center-full`：完整技術文件
- `esggo-learning-center-best-practices`：從真實事故提煉的營運最佳實踐
