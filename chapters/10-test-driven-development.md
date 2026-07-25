# 10 · 測試驅動開發（TDD）

> 來源：Hermes Agent `test-driven-development` 技能（v1.1.0）。
> 適用：新功能、bug 修復、重構、行為變更。核心：紅 → 綠 → 重構，先寫會失敗的測試。
> 與第 05 章（esggo-learning-center `npm run test` 8/8）配套作為日常驗證紀律。

## 0. 鐵律

```text
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```
先寫了實作才寫測試？**刪掉重來**，不是當參考、不是改寫、不是看一眼——delete means delete。

## 1. 紅綠重構循環

### RED — 寫會失敗的測試
```python
def test_retries_failed_operations_3_times():
    attempts = 0
    def operation():
        nonlocal attempts
        attempts += 1
        if attempts < 3:
            raise Exception('fail')
        return 'success'
    result = retry_operation(operation)
    assert result == 'success'
    assert attempts == 3
```
要求：每測試一種行為、名稱清楚（名字有 "and" 就拆）、用真程式碼非 mock、名稱描述行為非實作。

### 驗證 RED — 看它失敗（強制，不可略）
```bash
pytest tests/test_feature.py::test_specific_behavior -v
```
確認：測試失敗（不是 typo 的 error）、失敗訊息符合預期、因功能缺失而失敗。
- 立刻通過？你在測已存在行為，改測試。
- error？修 error，重跑到「正確失敗」。

### GREEN — 最小程式碼
寫最簡單能過的程式碼，不多一行。
```python
def add(a, b):
    return a + b   # 不多加
```
GREEN 階段「作弊可以」：hardcode、複製貼上、跳 edge case —— 重構再修。

### 驗證 GREEN — 看它通過（強制）
```bash
pytest tests/test_feature.py::test_specific_behavior -v   # 單測
pytest tests/ -q                                          # 全測，查回歸
```

### REFACTOR — 清理
綠了之後才做：去重複、改名、抽 helper、簡化。全程保持測試綠。重構中測試失敗？立刻復原、步子走小。

### 重複
下一個行為的下一個失敗測試。一次一個循環。

## 2. 避免水平切片

不要先寫全部測試再寫全部實作（水平切片 → 脆測試）。用**垂直追蹤彈**（tracer bullet）：
```text
WRONG: RED: test1,test2,test3  GREEN: impl1,impl2,impl3
RIGHT: RED→GREEN: test1→impl1  RED→GREEN: test2→impl2
```
一條端對端行為切片，證明路通、教會你介面、讓每個後續測試有根據。

## 3. 為什麼順序重要（常見合理化反駁）

| 藉口 | 現實 |
|------|------|
| 「太簡單不用測」 | 簡單程式也會壞，測試 30 秒 |
| 「我之後再測」 | 之後測試立刻通過，什麼都證明不了 |
| 「手動測過了」 | 臨場 ≠ 系統化，無紀錄、不能重跑 |
| 「刪掉 X 小時很浪費」 | 沉沒成本；留不可信的程式才是浪費 |
| 「當參考留著」 | 你會改它，那還是 test-after，刪 |
| 「先探索」 | 可以，丟掉探索，從 TDD 開始 |

## 4. 紅旗 — 出現就刪掉重來

- 先碼後測 / 實作後才加測 / 首次跑就通過 / 說不出為何失敗 / 「就這一次」/「手動測過了」/「TDD 太教條我很務實」

## 5. 驗證清單（宣稱完成前）

- [ ] 每個新函式/方法都有測試
- [ ] 每個測試先親眼看它失敗
- [ ] 失敗原因符合預期（缺功能，非 typo）
- [ ] 寫最小程式碼通過
- [ ] 全部測試通過
- [ ] 輸出乾淨（無 error / warning）
- [ ] 用真程式碼（mock 僅在不得已）
- [ ] edge case 與錯誤路徑覆蓋

## 6. Hermes Agent 整合

每步用 `terminal` 跑測試：
```python
terminal("pytest tests/test_feature.py::test_name -v")   # RED / GREEN
terminal("pytest tests/ -q")                              # 全測查回歸
```
用 `delegate_task` 派生子代理時，在 goal 強制 TDD（含「先寫失敗測試、親眼看失敗、最小實作、親眼看通過、重構、commit」）。bug 修復：先寫重現失敗測試，走 TDD 循環，測試證明修好且防回歸。

## 7. 測試反模式

- 測 mock 行為而非真行為
- 測實作細節而非行為/結果
- 只測 happy path（必測 edge / error / 邊界）
- 脆測試（驗證結構而非行為；重構不該弄破）

## 最後規則

```text
Production code → 測試存在且先失敗過
否則 → 不是 TDD
```
無使用者明確許可不例外。

## 相關技能 / 章節

- 第 05 章 Firebase 學習中心 verify→deploy（含 `npm run test` 8/8 驗證）
- `systematic-debugging`：bug 先寫失敗測試再修
