#!/usr/bin/env bash
# repo-inventory.sh — 遠端倉庫健康檢查盤點腳本（本技書第 18 章 §4 自動化）
#
# 用法：
#   ./scripts/repo-inventory.sh                 # 輸出到 inventory/repo-inventory-YYYY-MM-DD.md 並印表格
#   ./scripts/repo-inventory.sh --diff          # 額外與上一期比對，列出「新變長草」的 repo
#   OUTDIR=/tmp INVENTORY_LIMIT=200 ./scripts/repo-inventory.sh
#
# 前置：gh 已登入（gh auth status）。private repo 需 token 含 read:org/repo 範圍。
# 對齊第 18 章 §0 盤點基準與 §3 判斷閾值（>365 天未 push → 封存候選）。

set -euo pipefail

OUTDIR="${OUTDIR:-inventory}"
LIMIT="${INVENTORY_LIMIT:-300}"
STALE_DAYS="${STALE_DAYS:-365}"
TODAY="$(date +%F)"
OUT="$OUTDIR/repo-inventory-$TODAY.md"

command -v gh >/dev/null 2>&1 || { echo "ERROR: gh 未安裝或不在 PATH" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: gh 未登入，請先 gh auth login" >&2; exit 1; }

mkdir -p "$OUTDIR"

# 用 gh 抓全帳號 repo，python3 算長草天數並產生 Markdown 表格
# 存到「目前工作目錄」下的暫檔：native gh 與 MSYS python 對 PWD 的解析一致
# （不能用 /tmp：gh 是 Windows 原生二進位，會寫到 C:\tmp，而 MSYS python 讀的是虛擬 /tmp）
TMP_JSON=".repo-inventory-tmp.json"
gh repo list --json nameWithOwner,pushedAt,updatedAt,isArchived,visibility --limit "$LIMIT" > "$TMP_JSON"

python3 - "$OUT" "$TODAY" "$STALE_DAYS" "$TMP_JSON" <<'PY'
import sys, json, datetime

out, today_s, stale_s, tmp = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
rows = json.load(open(tmp, encoding="utf-8"))
stale_days = int(stale_s)
today = datetime.date.fromisoformat(today_s)

def days_since(s):
    if not s:
        return 99999
    return (today - datetime.date.fromisoformat(s[:10])).days

enriched = []
for r in rows:
    d = days_since(r.get("pushedAt"))
    enriched.append((d, r))

enriched.sort(key=lambda x: x[0], reverse=True)  # 最長草的排最上面

stale = [e for e in enriched if e[0] > stale_days and not e[1].get("isArchived")]

lines = []
lines.append(f"# 遠端倉庫盤點 — {today_s}")
lines.append("")
lines.append(f"- 帳號：`{enriched[0][1]['nameWithOwner'].split('/')[0] if enriched else '?'}`")
lines.append(f"- 總數：{len(enriched)} 個 repo")
lines.append(f"- 長草候選（>{stale_days} 天未 push 且未封存）：{len(stale)} 個")
lines.append("")
lines.append("| REPO | pushedAt | 未push天數 | 封存 | 可見度 |")
lines.append("|------|----------|-----------|------|--------|")
for d, r in enriched:
    lines.append(f"| {r['nameWithOwner']} | {(r.get('pushedAt') or '')[:10]} | {d} | {'Y' if r.get('isArchived') else '-'} | {r.get('visibility','')} |")
lines.append("")

with open(out, "w", encoding="utf-8") as f:
    f.write("\n".join(lines))

# 終端也印一遍（長草候選優先）
print(f"總 repo：{len(enriched)}，長草候選（>{stale_days}d）：{len(stale)}")
print(f"已寫入：{out}")
if stale:
    print("長草候選：")
    for d, r in stale:
        print(f"  - {r['nameWithOwner']}  ({d}d, {r.get('visibility','')})")
PY

# 可選：與上一期 diff
if [ "${1:-}" = "--diff" ]; then
  PREV="$(ls -1 "$OUTDIR"/repo-inventory-*.md 2>/dev/null | grep -v "$OUT" | sort | tail -1 || true)"
  if [ -n "$PREV" ]; then
    echo "=== 與上一期 ($PREV) 比對 ==="
    # 抓本期的長草名單，檢查上一期是否已是長草（已是就不算「新變長草」）
    python3 - "$OUT" "$PREV" "$STALE_DAYS" <<'PY'
import sys, re
cur, prev, stale_s = sys.argv[1], sys.argv[2], int(sys.argv[3])
def parse(path):
    m = {}
    for line in open(path, encoding="utf-8"):
        mm = re.match(r"\|\s*([^|]+/[^|]+)\s*\|\s*([\d-]+)?\s*\|\s*(\d+)\s*\|", line)
        if mm:
            m[mm.group(1).strip()] = int(mm.group(3))
    return m
c, p = parse(cur), parse(prev)
new_stale = [repo for repo, d in c.items() if d > stale_s and (repo not in p or p[repo] <= stale_s)]
print("新變長草（本期超閾值、上期未超）：")
if new_stale:
    for r in sorted(new_stale):
        print(f"  - {r}  (本期 {c[r]}d)")
else:
    print("  （無）")
PY
  else
    echo "（尚無上一期檔案可 diff）"
  fi
fi
