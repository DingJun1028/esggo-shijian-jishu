# 15 · 監控與事故響應（Operate / Incident Runbook）

> 來源：本技書第 04 章 VPS 健康檢查清單 + esggo-vps-toolkit 的 `esggo-core` 診斷實踐，整理成系統化 runbook。
> 適用：ESGGO 堆疊上線後的營運監控、健康探活、事故分級與回滾。填補 MECE 的「G3 Operate」缺口。
> 與第 04 章（健康檢查命令）、第 11 章（系統化除錯）配套——本章管「線上營運」，第 11 章管「找根因」。

## 0. 監控對象清單（ESGGO 堆疊）

| 服務 | 探活端點 / 命令 | 預期 |
|------|-----------------|------|
| Next.js (esggo-core) | `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/api/health` | 200 |
| nginx | `curl -sS -I -H "Host: esggo.co" http://127.0.0.1/` | 200 |
| FTG SPA | `curl -sS -o /dev/null -w "%{http_code}" -H "Host: ftg.esggo.co" http://127.0.0.1/` | 200 |
| Gateway | `curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:8642/status` | 200 |
| HTTPS 端到端 | `curl -sS -I https://esggo.co/` + `curl -sS -I https://ftg.esggo.co/` | 200, 無 redirect loop |
| 容器資源 | `docker container stats` | CPU/記憶在額度內（ARM64 1 OCPU） |

> 完整命令見第 04 章 §11 驗證清單。

## 1. 三層探活（Layered Probing）

不要把「容器 Up」當作「服務健康」。依序三層：

1. **Process 層**：`docker ps` / `ss -ltnp | rg ':3000'` —— 進程在、端口在聽。
2. **App 層**：`curl 127.0.0.1:3000/api/health` —— 應用真的回 200（不是 `000` / connection refused）。
3. **Edge 層**：`curl -sS -I https://esggo.co/` —— Cloudflare→nginx→app 整條鏈通，且無 redirect loop。

任一層斷，先定位層次再動手，別盲目重啟。

## 2. 事故分級

| 級別 | 定義 | 響應 |
|------|------|------|
| P1 全站不可用 | esggo.co / ftg.esggo.co 皆 5xx 或 timeout | 立即、先回滾再查 |
| P2 單服務降級 | 某服務 unhealthy 但站點可達 | 限時修復、必要時隔離 |
| P3 功能異常 | 頁面可載但某流程報錯 | 排程修、補監控 |
| P4 觀測缺失 | 某指標無覆蓋/告警漏 | 事後補，不佔用事故頻寬 |

## 3. 事故響應 runbook（P1/P2）

```text
0) 止血：能回滾先回滾（git revert + 重新部署，見第 09 章），不要邊救邊改。
1) 定位層次：跑 §1 三層探活，記下斷在哪層。
2) 看證據：
   - 容器：`docker logs --tail 120 --timestamps esggo-core`
   - 端口：`docker ps --format "table {{.Names}}\t{{.Ports}}"` + `ss -ltnp | rg ':3000'`
   - nginx：`sudo nginx -t` + `sudo systemctl status nginx`
3) 區分兩種失敗形狀：
   - 端口被佔（connection refused）→ 必有別的容器/程序佔 3000，先清佔用再起。
   - 應用降級（Prisma/DATABASE_URL 缺失、Redis 失敗、gateway fetch 失敗）
     → 容器可能仍 200/503，但 cron 會拋錯；查 env/secret（見第 03 章）是否就位。
4) 重建（ARM64 必用 compose，勿裸 docker build）：
   docker compose -f /opt/esggo/vps/docker-compose.prod.yml build --no-cache esggo
   docker compose -f /opt/esggo/vps/docker-compose.prod.yml up -d --no-deps esggo
5) 有界重試驗證：
   for i in {1..12}; do
     curl -sS -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/api/health && break
     sleep 5
   done
6) 容器名衝突（手動 docker run 實驗殘留）：
   docker rm -f esggo-core && docker compose -f /opt/esggo/vps/docker-compose.prod.yml up -d
7) 清 cache（疑 Cloudflare 舊）：Dashboard Purge Cache 或切 Full→Full(strict)（見第 04 章 §11）。
8) 通報：P1 在修復後於變更紀錄標註根因（走第 11 章找根因，勿只症狀修）。
```

## 4. 回滾策略

- **程式碼回滾**：`git revert <bad_commit>` → 重新觸發第 09 章 Actions 部署（或 VPS cron 部署）。
- **映像回滾**：`docker compose` 用上一個 tag；compose 文件 `image: esggo-core:prev`。
- **配置回滾**：nginx / Cloudflare 變更單獨、可審查（見第 04 章 §7「部署腳本只上傳成品，nginx config 另行管理」）。
- 回滾優先於排查：P1 場景先恢復服務，根因調查留待事後（第 11 章）。

## 5. 告警與觀測缺口（當前實況）

- 現有：`scripts/esggo_healthcheck.sh`（學習中心每日 09:00 `npm test && npm build`，見第 05 章）。
- **缺口**：VPS 端無主動告警推送；esggo-core 探活靠人工 `curl`。建議補：
  - 簡易探活 cron + `curl` 失敗時 `tmux` 寫 log 或發 Telegram/Discord（見第 04 章 §17 tmux 長命令模式）。
  - 容器 `restart: unless-stopped` 已減少手動介入；仍需資源額度監控（ARM64 1 OCPU，`docker container stats`）。

## 6. 與其他章的界線（MECE 互斥）

- 本章 = **E 支柱「營運監控/事故」**，管「上線後活著沒、掛了怎麼救」。
- 第 11 章 系統化除錯 = **B 支柱「開發期找根因」**，管「為什麼壞」。
- 第 04 章 健康檢查 = **E 的「上線前/部署後命令清單」**，本章引用它但不重複列指令。
- 第 09 章 CI/CD = **E 的「部署動作」**，回滾走它的重新部署。

## 實踐清單

- [ ] 三層探活（process/app/edge）例行跑過、記基準值
- [ ] P1/P2 事故先回滾再查
- [ ] 容器名衝突先用 `docker rm -f` 清再 `compose up`
- [ ] ARM64 重建走 `compose --no-cache`，勿裸 `docker build`
- [ ] 修復後走第 11 章找根因，標註於變更紀錄
- [ ] 補主動告警（VPS 端 curl + 通知）

## 相關技能 / 章節

- 第 04 章 VPS 部署（健康檢查命令）、第 11 章 系統化除錯（根因）、第 09 章 CI/CD（回滾重部署）、第 03 章 secrets（env 缺失排查）
