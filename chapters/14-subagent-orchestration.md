# 14 · 子代理編排（delegate_task 規模執行）

> 來源：Hermes Agent `delegate_task` 工具 + 各技能引用的 two-stage review 模式（plan v2.0.0 / TDD v1.1.0 / requesting-code-review v2.0.0）。
> 適用：把大任務拆給多個獨立子代理平行/串行執行；每任務用獨立審查者當品質閘門。填補 MECE 的「G2 Scale（規模執行）」缺口。
> 與第 12 章 plan（交付計畫）、第 13 章 code review（每任務閘門）配套。

## 0. 為什麼要子代理

- 推理重的子任務（除錯、研究綜述、跨檔重構）交給隔離上下文，主對話不被中間產物淹沒。
- 平行獨立工作流（A 研究 + B 研究同時跑）用 `tasks` 陣列一次派發。
- **關鍵紀律**：子代理沒有主對話歷史。所有必要資訊（檔案路徑、錯誤訊息、約束）都得透過 `context` 欄位帶進去。

## 1. 兩種模式

### 單任務（goal + context）
```python
delegate_task(
    goal="實作 <feature>，嚴格用 TDD",
    context="""跟 test-driven-development 技能：
1. 先寫失敗測試 2. 跑測試確認失敗 3. 最小實作 4. 跑過
5. 重構 6. commit
專案測試命令：pytest tests/ -q
專案結構：<相關檔案>
語言：繁體中文回報""",
    toolsets=['terminal', 'file']
)
```

### 批次平行（tasks 陣列，最多 3 併發）
```python
delegate_task(
    tasks=[
        {"goal": "研究 X", "context": "...", "role": "leaf"},
        {"goal": "研究 Y", "context": "...", "role": "leaf"},
    ],
    description="平行研究 X 與 Y"
)
# 返回一個 handle；子代理在背景跑，完成後 consolidated 結果回主對話
```

## 2. 兩階段審查（每任務的品質閘門）

來自 plan / TDD / code-review 的共同模式：每個子代理任務完成後，

1. **Spec 合規審查**：實作是否達成 goal 明列的驗收（不是「看起來不錯」）。
2. **程式碼品質審查**：走第 13 章流程（靜態掃描 + 獨立審查者 subagent + 自動修迴圈）。
3. **兩者都過**才進下一任務；任一不過 → 回原（或新）子代理修，不帶主上下文。

> 這就是 MECE 地圖 G1（審查）與 G2（規模）的接合點：第 13 章是「閘門怎麼做」，本章是「閘門在哪裡串」。

## 3. 執行交接語法（plan 技能慣例）

計畫存檔後執行時：
> 「Plan complete and saved. Ready to execute using subagent-driven-development — I'll dispatch a fresh subagent per task with two-stage review. Shall I proceed?」

實作：
- 每任務派**全新** `delegate_task` 帶**完整**上下文。
- 每任務後先 spec 審查、過了再 code quality 審查。
- 兩者皆過才進下一任務。

## 4. 子代理的邊界（重要）

- **Leaf 子代理不能**：`delegate_task` / `clarify` / `memory` / `send_message`。
- 巢狀委派此帳號**關閉**（max_spawn_depth=1）：每個子代理都是 leaf。
- 子代理回報是**自評**，非既成事實。涉及外部副作用（HTTP POST/PUT、遠端寫、建檔）時，要求回傳可驗證 handle（URL/ID/絕對路徑/HTTP 狀態）並**自己驗證**。
- 若使用者在非英文對話，context 註明「回報用中文」。

## 5. 何時用 / 何時不用

| 用 | 不用 |
|----|------|
| 推理重子任務、平行研究、跨檔重構 | 單一工具呼叫、使用者要互動 |
| 大任務要隔離上下文 | 需要即時與使用者確認 |
| 可驗證的交付物（URL/檔/PR） | 無法驗證的抽象產出 |

## 6. 實踐清單

- [ ] 任務拆到子代理能獨立完成（所有依賴寫進 context）
- [ ] 每任務目標單一、可驗收
- [ ] 平行任務無共享可變狀態
- [ ] 每任務後跑兩階段審查（spec + 品質）
- [ ] 外部副作用要求回傳可驗證 handle 並自查
- [ ] 失敗不盲重試：≥2 次失敗上報使用者

## 相關技能 / 章節

- 第 12 章 Plan（交付可執行計畫）、第 13 章 Pre-Commit 審查（每任務閘門）
- 第 10 章 TDD、第 11 章 系統化除錯（子代理做調查時 goal 寫「調查原因，勿修」）
- `claude-code` / `codex` / `opencode`（委派到外部 CLI agent）
