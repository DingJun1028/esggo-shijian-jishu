# 19 · 前端測試基礎設施（vitest / jest 實作細節）

> 來源：Hermes Agent `test-driven-development` 技能（v1.1.0）的「第 10 章只含 pytest」缺口補齊 + ESGGO 實戰（esggo-learning-center 的 vitest 堆疊）+ pnpm 11 規範（記憶）。
> 適用：用 vitest 或 jest 跑前端/Node 單元的「工具層」——runner 設定、環境、globals、斷言、覆蓋率、CI 接法。
> 與第 10 章（TDD 紀律：紅綠重構、先失敗）配套——**本章管「runner 怎麼裝怎麼跑」，第 10 章管「為什麼先寫失敗測試」**。兩章不重疊：第 10 章的範例是 pytest，本章補 vitest/jest 的具體設定與坑。

## 0. 為什麼單開一篇（MECE 互斥）

- 第 10 章 = **B 支柱「開發期品質紀律」**：紅綠重構循環、鐵律、反模式——與語言/框架無關的心法。
- 本章 = **生命週期 Test 階段的「runner 實作細節」**：vitest/jest 的 config、環境、globals、覆蓋率、CI 接法。
- 重疊處理：第 10 章講「先寫失敗測試」時以 pytest 舉例；本章不重講心法，只補「同一套心法在 vitest 怎麼落地」。要心法去第 10 章，要 vitest/jest 具體操作來本章。

## 1. vitest 基礎設定（實戰：esggo-learning-center）

```js
// vitest.config.js — 真實專案配置
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',   // DOM 相關元件測試需要；純邏輯用 'node'
    globals: true,          // 允許全域 describe/it/expect，不用每行 import
  },
});
```

- 測試檔位置慣例：緊貼原始碼，`src/__tests__/*.test.js` 或 `src/**/*.spec.js`。
- 斷言來源：從 `vitest` import `describe, it, expect`（globals:true 時也可不 import）。
- React 元件測試需 `@testing-library/react` + `@vitejs/plugin-react`；jsdom 提供 DOM。

```bash
# pnpm 11 環境（ESGGO 規範，見記憶）
pnpm add -D vitest @vitejs/plugin-react jsdom @testing-library/react @testing-library/jest-dom
pnpm test                  # 跑 vitest run（package.json script 即 "vitest run"）
pnpm vitest run           # 同上，顯式寫全
pnpm vitest run src/__tests__/content.test.js   # 單檔（注意：用 pnpm vitest run，勿用 pnpm test run）
```

> ⚠️ **`pnpm test run` 是陷阱**：pnpm 會把 `run` 當作傳給 vitest 的 filter 參數，變成 `vitest run "run"` → "No test files found"。要帶路徑請用 `pnpm vitest run <path>`，或乾脆不帶參數 `pnpm test`。該專案已驗證：`pnpm vitest run` 實跑 8/8 通過。

## 2. jest 基礎設定（對照 vitest）

```js
// jest.config.js
module.exports = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  transform: { '^.+\\.(t|j)sx?$': 'babel-jest' },  // 或 ts-jest / @swc/jest
};
```

| 維度 | vitest | jest |
|------|--------|------|
| 設定檔 | `vitest.config.js`（繼承 vite） | `jest.config.js` |
| 環境 | `environment: 'jsdom'\|'node'` | `testEnvironment: 'jsdom'\|'node'` |
| 跑單次 | `vitest run` | `jest --ci` |
| ESM/TS | 原生支援（vite 同款） | 需 transform（babel/ts-jest/swc） |
| 速度 | 基於 esbuild，快 | 較慢，但生態最大 |

> 選擇：新專案用 vitest（與 vite 共享 config、零額外 transform）；舊 jest 專案遷移成本視 babel 設定而定，不強制。

## 3. 覆蓋率（coverage）

```bash
# vitest 覆蓋率（需先裝 provider，見下方陷阱）
pnpm add -D @vitest/coverage-v8
pnpm vitest run --coverage            # 預設 v8 provider
```

```js
// vitest.config.js 加
test: {
  coverage: {
    provider: 'v8',
    include: ['src/**/*.{js,ts}'],
    exclude: ['src/**/*.test.*', 'src/__tests__/**'],
    thresholds: { lines: 80, functions: 80 },  // CI 低於門檻就 fail
  },
}
```

- jest 對應：`jest --coverage` + `collectCoverageFrom`；provider 用 `babel` 或 `v8`。

> ⚠️ **未裝 provider 就 `--coverage` 會直接報 MISSING DEPENDENCY**（`Cannot find dependency '@vitest/coverage-v8'`）。esggo-learning-center 實測如此——裝了 `vitest` 不等於有 coverage，需另行 `pnpm add -D @vitest/coverage-v8`。

## 4. CI 接法（對齊第 09 章 Actions）

```yaml
# .github/workflows/ci.yml（節錄）
- name: Test
  run: pnpm vitest run --coverage
# 上傳覆蓋率（選用）
- uses: actions/upload-artifact@v4
  with:
    name: coverage
    path: coverage/
```

- 關鍵：CI 用 `vitest run`（非互動 `vitest`），否則 runner 掛住導致 CI 逾時。
- 注意 pnpm 陷阱：workflow 裡直接寫 `pnpm vitest run`，不要寫 `pnpm test run`（後者會把 run 當 filter，見 §1 陷阱）。
- 鎖定檔 `--frozen-lockfile`（見第 09 章）確保可重現。

## 5. 地雷 / 陷阱（實戰，重要）

- **`pnpm test run` 是陷阱（pnpm 把 `run` 當 filter）**：`pnpm test run <path>` 實際執行 `vitest run "run" <path>` → "No test files found"。帶路徑用 `pnpm vitest run <path>`；不帶參數用 `pnpm test`（script 即 `vitest run`）。該專案實測 `pnpm vitest run` 8/8 通過。
- **`--coverage` 未裝 provider 直接報 MISSING DEPENDENCY**：`vitest` 不含 coverage，需另 `pnpm add -D @vitest/coverage-v8`，否則 `vitest run --coverage` 失敗。
- **`pnpm audit` only，絕不 `npm audit`**：混合環境（pnpm 11 + 系統 npm）`npm audit` 會錯判依賴樹。也不要為過 audit 強制覆寫 `undici`（`jsdom@29` 會破 vitest，見記憶）。
- **搜尋測試檔別掃 node_modules**：`grep -rl vitest .` 在全 repo 會卡死（node_modules 巨大）。限縮到 config/package.json：`grep -rl vitest --include=*.js --include=*.json .` 或 `find src -name '*.test.js'`。
- **globals 沒開就全局用 describe/it/expect** → ReferenceError。要嘛 `globals:true`，要嘛每檔 `import { describe,it,expect } from 'vitest'`。
- **jsdom 沒開就測 DOM** → `document is not defined`。React 元件測試 `environment:'jsdom'` 必開。
- **vitest 互動模式進 CI** → runner 不退，CI 60s 逾時。CI 永遠 `vitest run`。
- **測 mock 而非行為**：同第 10 章反模式；vitest 的 `vi.fn()` 很好用但別只斷言它被呼叫幾次，要斷言行為結果。
- **`@testing-library` 查 DOM 用 role/text 而非實作 class**：`screen.getByRole` / `getByText`，重構不破測試（對齊第 10 章「脆測試」警語）。

## 6. 驗證清單（宣稱測試綠了前必跑）

| 檢查 | 命令 |
|------|------|
| 單測跑通（紅→綠） | `pnpm vitest run src/__tests__/x.test.js` |
| 全測無回歸 | `pnpm test`（= `vitest run`）|
| 覆蓋率達門檻 | `pnpm vitest run --coverage`（需先裝 `@vitest/coverage-v8`）|
| 依賴審計（pnpm） | `pnpm audit`（非 `npm audit`）|
| CI 腳本用 `run` | 確認 workflow 是 `pnpm vitest run`，非 `pnpm test run` |

## 7. 實戰清單

- [ ] vitest/jest config 就位（environment 正確：jsdom vs node）
- [ ] globals 設定一致（config 與 test 檔 import 不衝突）
- [ ] 測試檔命名/位置慣例統一
- [ ] coverage provider + 門檻設定，CI 低於門檻會 fail
- [ ] CI 用 `vitest run` / `jest --ci`（不退、不掛）
- [ ] `pnpm audit` 通過，未動 `undici`
- [ ] 搜尋限縮到 config/源碼，不掃 node_modules

## 相關技能 / 章節

- 第 10 章 TDD（紅綠重構心法、先寫失敗測試）—— 本章的「為什麼」層
- 第 09 章 CI/CD（Actions 跑 `vitest run`、frozen-lockfile）
- 第 17 章 安全強化（§1 `pnpm audit` only、不覆寫 undici）
- 第 05 章 學習中心 verify→deploy（`npm run test` 8/8 驗證紀律）
- `test-driven-development` 技能 v1.1.0（第 10 章來源）
