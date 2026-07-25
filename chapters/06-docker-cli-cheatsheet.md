# 06 · Docker CLI 速查（修正版）

> 來源：Hermes Agent `docker-cli-cheatsheet` 技能（v1.0.0）。
> 說明：本表為「已修正」版本。常見 cheat sheet 有三處經典錯誤（見 ⚠ 標記），本技書採修正版，避免照抄 bug。
> 適用：建映像、跑容器、排錯 Docker host、寫 Dockerfile/compose。

## 0. 速查總表（對照原始貼上的錯誤）

| 主題 | 原始貼上（有誤） | 修正版 |
|------|------------------|--------|
| 無快取建映像 | `docker build -t name . no-cache` ❌ | `docker build -t name --no-cache .` ✅（`--no-cache` 在 `.` 之前）|
| 清所有未用映像 | `docker image prune` ❌（只清 dangling）| `docker image prune -a` ✅ |
| 啟動 daemon | `docker -d` ❌（舊 flag，現代無效）| `sudo systemctl start docker` ✅ |
| 進容器 shell | `... sh`（部分映像無 sh）| 試 `bash` / `ash` ✅ |

## 1. 建映像（Build）

```bash
docker build -t <image_name> .                       # 從 cwd 的 Dockerfile 建
docker build -t <image_name> --no-cache .            # ⚠ --no-cache 放在 context '.' 之前
docker build -t <image_name> -f path/Dockerfile .    # 自訂 Dockerfile 路徑
docker buildx build --platform linux/amd64,linux/arm64 -t <image> .   # 多架構（ESGGO VPS 是 arm64）
```
⚠ 常見錯誤 `docker build -t name . no-cache`：把 `no-cache` 放在 build context `.` **之後**，會失敗。`--no-cache` 是 build flag，必須放在最後的 `.` 參數之前。

## 2. 映像（Images）

```bash
docker images                  # 列本地映像
docker rmi <image_name|id>     # 刪映像
docker image prune             # 只刪 dangling（未標籤）映像
docker image prune -a          # ⚠ 加 -a 才會刪「所有」未用映像（不只 dangling）
docker search <term>           # 搜 Docker Hub
docker pull <image_name>       # 從 registry 拉
docker push <user>/<image>     # 發佈到 Docker Hub（須先登入）
docker login -u <user>         # 登入 registry
```

## 3. 跑容器（Run）

```bash
docker run <image>                              # 建 + 跑（隨機名）
docker run --name <cname> <image>               # 自訂名稱
docker run -d <image>                           # detached（背景）
docker run --rm <image>                         # ⚠ 容器結束自動移除（極常用）
docker run -p <host>:<container> <image>        # 暴露端口（例 -p 8080:80）
docker run -v <host>:<container> <image>        # 掛 volume
docker run -e KEY=val <image>                   # 設環境變數
docker run -it <image> sh                       # 互動 + TTY，跑 shell
```

## 4. 生命週期（Lifecycle）

```bash
docker start <cname|id>        # 啟動已停容器
docker stop  <cname|id>        # 優雅停止
docker restart <cname|id>
docker rm <cname|id>           # 移除已停容器
docker rm -f <cname|id>        # 強制移除運行中容器

# 批次清理（實用）
docker stop $(docker ps -q)                       # 停所有運行中
docker rm $(docker ps -a -q)                       # 移除所有容器
docker container prune                             # 移除所有已停容器
```

## 5. 檢查 / 排錯（Inspect / debug）

```bash
docker ps                       # 運行中容器
docker ps -a                    # 所有容器（運行 + 已停）
docker logs -f <cname>          # 跟隨 log（串流）
docker inspect <cname|id>       # 原始 JSON 設定/狀態
docker container stats          # 即時 CPU/記憶/IO 每容器
docker exec -it <cname> sh      # 進運行中容器 shell
# ⚠ 部分映像沒有 sh（distroless/alpine 變體）—— 改試 bash 或 ash
```

## 6. Volumes & Networks（實際部署常需）

```bash
docker volume ls
docker volume create <vname>
docker volume rm <vname>
docker network ls
docker network create <nname>
```

## 7. Compose（你最常用到的命令）

```bash
docker compose up -d           # 建（如需）+ 背景啟所有服務
docker compose down            # 停 + 移除容器/網路（保留 volume）
docker compose down -v         # 連 volume 一起移除
docker compose ps              # 服務狀態
docker compose logs -f <svc>   # 跟隨某服務 log
```
參考專案：https://github.com/docker/awesome-compose

## 8. Daemon / Host

⚠ `docker -d` 是**舊的 daemon flag**，現代安裝**不會**啟動 daemon。
```bash
# Linux（systemd）：
sudo systemctl start docker
sudo systemctl enable docker
docker info                     # 系統級資訊（確認 daemon 已起）
docker --help                  # 說明；也可 docker <子命令> --help
```
macOS/Windows 用 **Docker Desktop** app（https://docs.docker.com/desktop），沒有 `docker -d`。

> ESGGO VPS 實務：見第 04 章 `esggo-vps-toolkit` —— ARM64 上 `docker compose`（v2 插件）優於舊 `docker-compose` v1；daemon 修復用 `rm -f /var/run/docker.pid` + restart `docker.socket docker.service`。

## 9. 概念速記

- **Image**：獨立、可執行的套件 —— 程式碼 + runtime + 函式庫 + 設定。
- **Container**：image 的 runtime 實例；跨主機行為一致。
- **Docker Hub**：分享映像的 registry —— https://hub.docker.com
- 文件：https://docs.docker.com

## 相關技能

- `esggo-vps-toolkit`（第 04 章）：ARM64 Docker / compose / daemon 修復實戰
- `docker-cli-cheatsheet`（本技能來源）
