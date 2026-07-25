# 12 · 計畫模式（Plan Mode）：把實作寫成可執行計畫

> 來源：Hermes Agent `plan` 技能（v2.0.0）。
> 適用：使用者要「計畫」而非「執行」時。本回合只規劃：不實作、不改專案檔（計畫 markdown 除外）、不 commit/push/外部動作。
> 與第 10 章 TDD、第 11 章 系統化除錯配套——好計畫讓實作顯而易見。

## 0. 核心行為

- 只規劃，不實作程式碼。
- 不編輯專案檔（計畫 markdown 除外）。
- 不跑會變動的 terminal 命令、不 commit/push/外部動作。
- 可用唯讀工具檢查 repo / 上下文。
- 交付物：存到 `.hermes/plans/` 下的 markdown 計畫。

## 1. 輸出要求

寫具體可執行的 markdown 計畫，含（視情況）：
- Goal（目標）
- Current context / assumptions（現狀/假設）
- Proposed approach（作法）
- Step-by-step plan（逐步）
- Files likely to change（會動的檔案）
- Tests / validation（測試/驗證）
- Risks, tradeoffs, open questions（風險/取捨/未決）

程式相關：給**確切檔案路徑**、可能的測試標的、驗證步驟。

## 2. 儲存位置

```bash
mkdir -p .hermes/plans
# 檔名：.hermes/plans/YYYY-MM-DD_HHMMSS-<slug>.md
```
Hermes 檔案工具 backend-aware，相對路徑會留在 workspace（local / docker / ssh / modal / daytona 都一樣）。

## 3. 互動風格

- 請求夠清楚 → 直接寫計畫。
- `/plan` 無附指令 → 從對話上下文推任務。
- 真的欠指定 → 簡短釐清，勿猜。
- 存檔後簡短回覆「規劃了什麼 + 存檔路徑」。

## 4. 寫好計畫的技藝

假設實作者對此 codebase 零上下文、品味可疑——把所需全部寫下：碰哪些檔、完整程式碼、測試命令、要查的文件、如何驗證。給**一口大小（bite-sized）**任務。DRY / YAGNI / TDD / 頻繁 commit。

### 任務粒度
每個任務 = 2–5 分鐘專注工作，每步一個動作。
- ❌ 太大：`### Task 1: Build authentication system`（5 檔 50 行）
- ✅ 恰當：`### Task 1: Create User model` / `### Task 2: Add password hash field` / `### Task 3: Create hashing util`

### 計畫文件結構（必含表頭）

```markdown
# [Feature] Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** [一句話]
**Architecture:** [2–3 句]
**Tech Stack:** [關鍵技術]

---
```

### 任務結構（TDD 內嵌）

````markdown
### Task N: [名稱]
**Objective:** 一句
**Files:**
- Create: `exact/path/new_file.py`
- Modify: `exact/path/existing.py:45-67`
- Test: `tests/path/test_file.py`

**Step 1: Write failing test**
```python
def test_specific_behavior():
    assert function(input) == expected
```
**Step 2: Run test to verify failure**
Run: `pytest tests/path/test.py::test_specific_behavior -v` → Expected: FAIL "not defined"

**Step 3: Write minimal implementation**
```python
def function(input): return expected
```
**Step 4: Run test to verify pass**
Run: `pytest ... -v` → Expected: PASS

**Step 5: Commit**
```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## 5. 寫作流程

1. 理解需求（功能/設計/驗收/限制）
2. 探索 codebase（`search_files` / `read_file`）
3. 設計作法（架構/檔組織/依賴/測試策略）
4. 寫任務（順序：setup → 核心 TDD → edge → 整合 → 清理/文件）
5. 補完整細節（確切路徑/可複製程式碼/確切命令+預期輸出/驗證）
6. 審查計畫（任務有序、一口大小、路徑確切、程式碼完整、命令確切、無缺上下文、DRY/YAGNI/TDD）

## 6. 原則

- **DRY**：抽取驗證函式，別複製 3 處。
- **YAGNI**：只做現在要的，不加「未來彈性」。
  ```python
  # ❌ YAGNI
  class User:
      def __init__(self, name, email):
          self.name = name; self.email = email
          self.preferences = {}   # 還不需要
          self.metadata = {}      # 還不需要
  # ✅ YAGNI
  class User:
      def __init__(self, name, email):
          self.name = name; self.email = email
  ```
- **TDD**：每個產出程式碼的任務都含完整�DD 循環（見第 10 章）。
- **Frequent commits**：每任務後 `git add` + `git commit -m "type: desc"`。

## 7. 常見錯誤

| 壞 | 好 |
|----|----|
| 「Add authentication」 | 「Create User model with email and password_hash」 |
| 「Step 1: Add validation function」 | 同上 + 完整函式碼 |
| 「Step 3: Test it works」 | 「Run `pytest tests/test_auth.py -v`, expected: 3 passed」 |
| 「Create the model file」 | 「Create: `src/models/user.py`」 |

## 8. 執行交接

存檔後提議：
> 「Plan complete and saved. Ready to execute using subagent-driven-development — I'll dispatch a fresh subagent per task with two-stage review (spec compliance then code quality). Shall I proceed?」

執行時用 `subagent-driven-development`：每任務派全新 `delegate_task` 帶完整上下文；每任務後先做 spec 合規審查、過了再做程式碼品質審查；兩者都過才進下一任務。

## 記住

```text
Bite-sized tasks (2-5 min each)
Exact file paths
Complete code (copy-pasteable)
Exact commands with expected output
Verification steps
DRY, YAGNI, TDD
Frequent commits
```
**好計畫讓實作顯而易見。**

## 相關技能 / 章節

- 第 10 章 TDD、第 11 章 系統化除錯
- `subagent-driven-development`、`requesting-code-review`
