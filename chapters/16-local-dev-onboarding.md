# 16 · 本地開發環境上手（Onboard Runbook）

> 來源：本技書各章實證（esggo-learning-center 用 pnpm 11 + Firebase；AGENTS.md 的 cwd-only 載入；ftg-tours-website 用 pnpm + React HashRouter）+ 通用 git/Node 上手流程。
> 適用：新人或換機後，把 ESGGO 各 repo 在本機跑起來。填補 MECE 的「G4 Onboard」缺口。
> 與第 05 章（學習中心 verify→deploy）、第 04 章（FTG 部署）配套——本章管「本機能跑」，那兩章管「上線」。

## 0. 前置（一次性的機器準備）

```bash
# Git 身份 + 憑證（Windows 用 git-bash / MSYS）
gh auth login                 # 或 gh auth setup-git 接既存 token
git config --global user.name "DingJun1028"
git config --global user.email "<你的信箱>"

# Node 版本管理（各 repo 不同，見 §2 對照）
# 建議 nvm / fnm 切版本；esggo-learning-center 用 node 22 系列

# pnpm（esggo 系主力套件管理器，v11）
npm i -g pnpm@11              # 記憶規範：pnpm 11，只用 pnpm audit，絕不用 npm audit
corepack enable               # 或走 corepack 鎖版本
```

## 1. 通用克隆流程

```bash
gh repo clone DingJun1028/<repo> <local-dir>   # 例：esggo-learning-center
cd <local-dir>
pnpm install                 # 或 npm ci（視 lockfile）
cp .env.example .env         # 填值（見各 repo 說明 / 第 03 章 secrets 慣例）
pnpm run dev                 # 起 dev server；Vite 通常 http://localhost:5173
```

## 2. 各 Repo 上手對照

| Repo | 套件管理 | 關鍵指令 | 本機注意 |
|------|----------|----------|----------|
| **esggo-learning-center** | pnpm 11 | `pnpm install` → `pnpm run dev`；驗證 `pnpm run test` / `pnpm run lint` / `pnpm run build` | ① **AGENTS.md 是 cwd-only**：Hermes cwd 不在本 repo 時不會自動載，需手動讀 `C:\Project\esggo-learning-center\AGENTS.md` 或先載第 05 章技能。② 繁體中文 UI 文案，無英文 fallback。③ Firebase：先 `firebase login`（必要時 `firebase use esggo-learning-center`）。 |
| **ftg-tours-website** | pnpm | `pnpm install` → `pnpm run dev` | React **HashRouter**：本機子頁走 `#` 前綴；品牌「墾趣旅遊」非「望趣旅遊」（見第 04 章 §12）。 |
| **esggo**（monorepo） | pnpm workspaces | `pnpm install` → `pnpm -r run dev` / 各 app 腳本 | 共享類型在 `packages/shared`，跨倉同步見第 08 章 §7。 |
| **youtube-automation-pipeline** | pip / uv | `pip install -r requirements.txt`（或 `uv sync`）→ `uvicorn` / FastAPI web UI | Python 3.11/3.14 混合環境（見會話 toolchain 註記）；預設免費層（Edge TTS + PIL）無 key 可跑。 |

## 3. 環境變數 / Secrets 入手

- 絕不從聊天貼真 key 到 `.env` 以外的位置；填值方式見第 03 章（write-only、貼值 or server-side mirror）。
- `.env.example` 是單一真相；缺哪個變數通常啟動會直接報「Environment variable not found」（見第 04 章 esggo-core 降級診斷）。
- Firebase 類：`.env` 的 `VITE_FB_*` 取自 Firebase Console 專案設定；詳第 05 章。

## 4. 本機驗證（動手前先綠）

照第 05 章儀式精神，本機改完先跑：
```bash
pnpm run test      # 或 npm test
pnpm run build
pnpm run lint
```
全過再考慮 commit / 開 PR（見第 02 章）。

## 5. 換機 / 多機注意（你的實際情境）

- 同一 GitHub token 跨兩台機：用 `gh auth login` 各自登入；token 不落檔案、不進 git。
- VPS 私鑰（`C:\Project\ESGGO VPS\`、actions_deploy_key）不進 git，只裝公鑰到 VPS（見第 04 章 §1）。
- Windows 路徑用 `/c/Users/...` POSIX 形式，勿反斜線（見第 04 章 §12、第 07 章）。

## 實踐清單

- [ ] gh 登入 + git 身份設好
- [ ] Node 切對版本；pnpm 11 裝好
- [ ] repo 克隆 + install + `.env` 填值
- [ ] `pnpm run dev` 起得来，`test/build/lint` 本機綠
- [ ] 必要時 Firebase / Vercel login
- [ ] 讀過該 repo 的 AGENTS.md / README（Hermes 從別處呼叫要手動讀）

## 相關技能 / 章節

- 第 05 章 Firebase 學習中心（verify→deploy）、第 04 章 VPS/FTG 部署
- 第 03 章 Secrets（.env 填值）、第 02 章 PR 協作、第 13 章 提交前審查
