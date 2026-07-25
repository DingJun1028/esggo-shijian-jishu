# 13 · 提交前程式碼審查（Pre-Commit Verification）

> 來源：Hermes Agent `requesting-code-review` 技能（v2.0.0）。
> 適用：實作完功能/修 bug、`git commit`/`push` 前；使用者說「commit/ship/verify/review」；subagent 每任務後的品質閘門。
> 核心原則：**沒有任何 agent 該審自己的產出**，全新上下文才找得到你漏的。與第 12 章 plan、第 10 章 TDD 配套。

## 0. 本技能 vs github-code-review

- 本技能：commit **前**審「你自己的變更」。
- `github-code-review`：在 GitHub 上審「別人的 PR」（inline 評論）。兩者不同。

## 1. 八步流程

### Step 1 — 取 diff
```bash
git diff --cached          # 已 staged
# 空 → git diff，再不行 git diff HEAD~1 HEAD
# >15,000 字元 → 按檔拆：git diff --name-only；git diff HEAD -- specific_file.py
```

### Step 2 — 靜態安全掃描（只掃新增行）
```bash
git diff --cached | grep "^+" | grep -iE "(api_key|secret|password|token|passwd)\s*=\s*['\"][^'\"]{6,}['\"]"   # 硬編密鑰
git diff --cached | grep "^+" | grep -E "os\.system\(|subprocess.*shell=True"                                  # shell 注入
git diff --cached | grep "^+" | grep -E "\beval\(|\bexec\("                                                     # 危險 eval/exec
git diff --cached | grep "^+" | grep -E "pickle\.loads?\("                                                       # 不安全反序列化
git diff --cached | grep "^+" | grep -E "execute\(f\"|\.format\(.*SELECT|\.format\(.*INSERT"                    # SQL 注入
```

### Step 3 — 基線測試與 lint
先抓語言跑對應工具，並記錄變更前 **baseline_failures**（stash → run → pop）；**只有你的變更引入的新失敗**才擋 commit。
```bash
# 測試
python -m pytest --tb=no -q 2>&1 | tail -5          # Python
npm test -- --passWithNoTests 2>&1 | tail -5         # Node
cargo test 2>&1 | tail -5                             # Rust
go test ./... 2>&1 | tail -5                         # Go
# lint / type（有裝才跑）
ruff check . ; mypy . --ignore-missing-imports        # Python
npx eslint . ; npx tsc --noEmit                      # Node
cargo clippy -- -D warnings ; go vet ./...           # Rust / Go
```
> baseline 本就髒 → 只數新增；baseline 乾淨你引入失敗 → 回歸。

### Step 4 — 自審清單
- [ ] 無硬編密鑰/API key/憑證
- [ ] 使用者輸入有驗證
- [ ] SQL 用參數化
- [ ] 檔案操作驗證路徑（無穿越）
- [ ] 外部呼叫有錯誤處理（try/catch）
- [ ] 無殘留 debug print/console.log
- [ ] 無註解掉的老碼
- [ ] 新碼有測試（若測試套件存在）

### Step 5 — 獨立審查子代理
用 `delegate_task`（工具不可在 execute_code 內呼叫）。審查者**只拿 diff + 靜態掃描結果**，與實作者零共享上下文；fail-closed：無法解析 = 失敗。回傳只接受 JSON：
```json
{ "passed": true/false, "security_concerns": [], "logic_errors": [], "suggestions": [], "summary": "一句結論" }
```
硬性 FAIL 規則：`security_concerns` 或 `logic_errors` 非空 → `passed` 必 false；無法解析 diff → false；兩者皆空才 `passed=true`。
- SECURITY（自動 FAIL）：硬編密鑰、後門、資料外洩、shell/SQL 注入、路徑穿越、使用者輸入進 eval/exec、pickle.loads、混淆指令。
- LOGIC ERRORS（自動 FAIL）：條件錯、I/O/網路/DB 缺錯誤處理、off-by-one、競態、碼與意圖矛盾。

### Step 6 — 評估結果
彙整 Step 2/3/5。全過 → Step 8 commit。有失敗 → Step 7 自動修。
```text
VERIFICATION FAILED
Security issues: [...]
Logic errors: [...]
Regressions: [vs baseline 的新失敗]
New lint errors: [...]
Suggestions (non-blocking): [...]
```

### Step 7 — 自動修迴圈（最多 2 輪）
派**第三個** agent 上下文（非實作者、非審查者），只修回報的問題，不重構/不改名/不加功能。修完重跑 Step 1–6；過 → Step 8；失敗且 <2 次 → 再修；2 次仍失 → 上報使用者並建議 `git stash`/`git reset`。

### Step 8 — Commit
通過才：
```bash
git add -A && git commit -m "[verified] <description>"
```
`[verified]` 前綴代表獨立審查者已核可。

## 2. 常見反模式（順手標記）

```python
# ❌ SQL 注入
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
# ✅ 參數化
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# ❌ shell 注入
os.system(f"ls {user_input}")
# ✅ 安全 subprocess
subprocess.run(["ls", user_input], check=True)

# ❌ XSS
element.innerHTML = userInput
# ✅ 安全
element.textContent = userInput
```

## 3. 地雷

- 空 diff → `git status` 確認；非 git repo → 跳過並告知。
- 大 diff（>15k）→ 按檔拆審。
- `delegate_task` 回非 JSON → 嚴格 prompt 重試一次，仍非 JSON 視為 FAIL。
- 誤報 → fix prompt 註明「是刻意設計」。
- 沒測試框架 → 跳過回歸檢查，審查者結論仍跑。
- lint 工具沒裝 → 靜默跳過該項，不 fail。
- 自動修引入新問題 → 算新失敗，迴圈繼續。

## 4. 與其他章整合

- 第 12 章 plan：驗證實作符合計畫。
- 第 10 章 TDD：驗證有遵循 TDD（測試存在且過、無回歸）。
- subagent-driven-development（第 14 章）：每任務後作為品質閘門（spec 合規 + 程式碼品質兩階段審查即此流程）。

## 相關技能 / 章節

- 第 12 章 Plan、第 10 章 TDD、第 14 章 子代理編排
- `github-code-review`（審別人 PR）、`test-driven-development`
