#!/usr/bin/env bash
# 批次封存長草 public repo（第 18 章 runbook 處置：archive 優先於 delete）
# 讀 .archive-list.lf.txt（LF 乾淨，每行一個 owner/repo），逐一 gh repo archive --yes 並驗證 isArchived=true
set -uo pipefail
cd "$(dirname "$0")/.."

LIST=.archive-list.lf.txt
: > .archive-result.log
ok=0; fail=0
while IFS= read -r r; do
  r="${r%$'\r'}"; r="$(echo "$r" | tr -d '\r')"   # 雙重保險去 CR
  [ -z "$r" ] && continue
  gh repo archive "$r" --yes >/dev/null 2>&1
  st=$(gh repo view "$r" --json isArchived -q .isArchived 2>/dev/null | tr -d '\r')
  printf '%s\t%s\n' "$r" "$st" | tr -d '\r' >> .archive-result.log
  if [ "$st" = "true" ]; then ok=$((ok+1)); else fail=$((fail+1)); fi
done < "$LIST"
echo "DONE ok=$ok fail=$fail"
