# 07 · SPA 前端 SEO 實踐（zh-Hant / zh-CN / en）

> 來源：Hermes Agent `frontend-seo-for-spa` 技能（v1.1.0）。
> 適用：Vite/React SPA（如 FTG 墾趣旅遊官網 ftg.esggo.co）強化 SEO：JSON-LD、hreflang、canonical、per-page 中繼、robots/sitemap。
> 與第 04 章 VPS 部署、第 05 章 verify→deploy 儀式配套。

## 0. 固定品牌契約（避免文案漂移）

跨 meta / JSON-LD / sitemap / 靜態資源保持一致的錨點：

- 中文品牌句：`台灣最懂戶外健康與永續行動的旅行解方品牌。`
- 中文完整句：`提供企業員工旅遊、家庭日、ESG Team Day、Employee Wellbeing Retreat、ESG Impact Note 等客製方案。`
- 品牌別名：`墾趣旅遊`；`FTG TOURS`
- Favicon：永遠用 `/favicon.svg`，不要引入 `/vite.css` 或 `/vite.svg` 等別名。

## 1. `index.html` 檢查清單

- `<title>` 與品牌句一致
- `<meta name="description">` 含品牌句 + 核心服務
- `<meta name="keywords">` 含 zh + en 服務關鍵字
- `<link rel="canonical">` 指向線上根網址
- `<link rel="alternate" hreflang="...">` 覆蓋 `zh-Hant` / `zh-CN` / `en` / `x-default`
- `<meta name="robots" content="index, follow">`
- OG：`og:title` / `og:description` / `og:url` / `og:type`
- JSON-LD Organization：`@type=Organization`、`name`、`url`、`logo`、`description`、`contactPoint`、`address`
- **只有一個 `</head>`**；Twitter / JSON-LD 標籤都放在 head 內
- 品牌文案規則：title 寫 `墾趣旅遊`，所有 Twitter/OG title 也必須寫 `墾趣旅遊`

## 2. JSON-LD 引導

建 `src/utils/seo.js` 匯出：
- `organizationJsonLd`：Organization + contactPoint + PostalAddress + logo + sameAs
- `localBusinessJsonLd(service)`：LocalBusiness + serviceType
- `webSiteJsonLd`：WebSite + `inLanguage: ['zh-Hant','zh-CN','en']`

在 `src/main.jsx` 渲染前注入一次，用 `data-ftg-seo` 守衛避免重複。

## 3. 每頁 SEO hook

- 每個路由頁用 `usePageSeo({ title, description, path, keywords })`
- 每頁 `description` 須與品牌句一致
- canonical 須等於路由路徑；避免結尾斜線漂移

## 4. `public/robots.txt`

```text
User-agent: *
Allow: /
Disallow: /private/
Sitemap: https://ftg.esggo.co/sitemap.xml
```

## 5. `public/sitemap.xml`

- XML urlset，首頁 `priority 1.0` 排第一
- 每個公開路由一個 `<url>`，含 `changefreq` 與 `priority`
- 所有 `<loc>` 用 canonical 線網域，勿用 `http://localhost`

## 6. 部署腳本衛生（與第 04 章一致）

- 部署腳本**只**上傳 build 成品到目標目錄
- 站點掛在共享 nginx 時，**不要**從部署腳本寫 `/etc/nginx/sites-available/*`
- 上傳後 `chown -R $VPS_USER:$VPS_USER $TARGET_DIR` 可接受
- 必要時從 CI reload nginx；config 變更走獨立、已審查的 nginx-config 步驟

## 7. build / lint / test 順序

```bash
pnpm install
pnpm build
pnpm lint
# 無測試 runner 就回報 "No test files found"；勿發明測試
```

## 8. 地雷（重要）

- **`vite.svg` 漂移**：Vite 模板常引用 `/vite.svg`，全站改 `/favicon.svg`。
- 刪除未用的 `useLocation` import（lint 雜訊）。
- hreflang 算中繼變更：SEO 編輯後重 lint。
- JSON-LD 重複：每頁載入只注入一次，用 `data-ftg-seo` 守衛。
- 描述漂移：品牌句須同時出現在 meta / JSON-LD / sitemap 首頁 / 每頁 description。
- **head 結構**：加 JSON-LD/OG/Twitter 時勿插入第二個 `</head>` 或提早關 head。
- **子代理工作目錄紀律**：改 `C:\Project\ftg-tours-website` 時勿寫到 `C:\Users\dingj\ftg-tours-website` 等其他路徑；編輯/提交前先確認 cwd。
- **Windows/MSYS 部署**：缺 `rsync` 時用 `scp`；先傳到 VPS `/tmp/ftg-deploy/` 再 reload nginx。
- **媒體堆疊 hero**：旅遊照放 `public/subpage-images/`，用 `/subpage-images/...` 引用而非 base64；配單層 `bg-ftg-forest/75` 覆蓋，文字 `relative z-10`；輪播只用 fade（interval 6000ms / transition 800ms）。
- **Logo 檔案格式交換**：`.jpg`→`.png` 時 Navbar 與 Footer 同時改同副名，重建後 grep 建出 JS 有無舊 base64/舊檔名殘留，經 `/tmp/ftg-deploy/` 重部署並確認 VPS 路徑。
- **Windows 路徑引號**：bash 下 `C:\Users\...` 引號會失敗，用 `/c/Users/...` 或 `C:/Users/...`。

## 9. 驗證證據（宣稱完成前回報）

```text
path: C:\Project\ftg-tours-website
build: pnpm run build
lint: pnpm run lint
json validation: node -e ...   # 匯出的 schema 物件可 stringify
```
並列出修改檔案 + 一行變更摘要。

## 相關技能

- `esggo-vps-toolkit`（第 04 章）：FTG SPA 的 VPS 部署 / nginx / scp 實戰
- `esggo-learning-center-verify-deploy`（第 05 章）：verify→deploy 儀式
- `frontend-seo-for-spa`（本技能來源）
