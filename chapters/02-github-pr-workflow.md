# 02 · GitHub PR 協作流程

> 來源：Hermes Agent `github-pr-workflow` 技能（v1.1.0）。
> 適用：開發功能、修 bug、提交 PR、監控 CI、合併。慣例：`gh` 優先，`git`+`curl` 降級。

## 0. 前置

```bash
# 確認登入 + 取得 owner/repo
gh auth status
REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO"  | cut -d/ -f2)
```

## 1. 開分支

```bash
git fetch origin
git checkout main && git pull origin main
git checkout -b feat/add-user-authentication
```

分支命名：`feat/` `fix/` `refactor/` `docs/` `ci/` `test/` `chore/` `perf/`。

## 2. 提交（Conventional Commits）

```bash
git add src/auth.py tests/test_auth.py
git commit -m "feat: add JWT-based user authentication

- login/register endpoints
- password hashing + auth middleware
- unit tests for auth flow"
```

格式：`type(scope): short description`（正文以 72 字元換行）。

## 3. 推送並開 PR

```bash
git push -u origin HEAD

gh pr create \
  --title "feat: add JWT-based user authentication" \
  --body "## Summary
- Adds login/register endpoints
- JWT validation

## Test Plan
- [ ] Unit tests pass

Closes #42"
# 選項：--draft / --reviewer u1,u2 / --label enhancement / --base develop
```

curl 降級：

```bash
BRANCH=$(git branch --show-current)
curl -s -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$OWNER/$REPO/pulls \
  -d "{\"title\":\"feat: ...\",\"body\":\"...\",\"head\":\"$BRANCH\",\"base\":\"main\"}"
# 草稿加 \"draft\": true
```

## 4. 監控 CI

```bash
gh pr checks                 # 一次性
gh pr checks --watch         # 輪詢（每 10s）

# curl 降級：查合併狀態
SHA=$(git rev-parse HEAD)
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/commits/$SHA/status \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print('Overall:',d['state']); [print(' ',s['context'],s['state']) for s in d.get('statuses',[])]"
```

## 5. 自動修 CI 失敗

```bash
# 看失敗 log
gh run list --branch $(git branch --show-current) --limit 5
gh run view <RUN_ID> --log-failed

# 修好後
git add <fixed> && git commit -m "fix: resolve CI failure in <check>" && git push
```

自動修循環（最多 3 次）：① 查狀態 → ② 讀 log → ③ patch/write_file 修 → ④ 提交推送 → ⑤ 重查。仍失敗則詢問使用者。

## 6. 合併

```bash
gh pr merge --squash --delete-branch          # squash + 刪分支
gh pr merge --auto --squash --delete-branch   # 自動合併（全綠才合）
```

curl 降級（squash）：

```bash
PR_NUMBER=<n>
curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO/pulls/$PR_NUMBER/merge \
  -d '{"merge_method":"squash","commit_title":"feat: add auth (#N)"}'
BRANCH=$(git branch --show-current)
git push origin --delete $BRANCH
git checkout main && git pull origin main && git branch -d $BRANCH
```

合併方式：`merge`（merge commit）/ `squash` / `rebase`。

## 常用速查

| 動作 | gh | git + curl |
|------|-----|-----------|
| 我的 PR | `gh pr list --author @me` | `curl .../pulls?state=open` |
| PR diff | `gh pr diff` | `git diff main...HEAD` |
| 加評論 | `gh pr comment N --body "..."` | `curl -X POST .../issues/N/comments` |
| 請 review | `gh pr edit N --add-reviewer u` | `curl -X POST .../pulls/N/requested_reviewers` |
| 關 PR | `gh pr close N` | `curl -X PATCH .../pulls/N -d '{"state":"closed"}'` |
| 抓別人 PR | `gh pr checkout N` | `git fetch origin pull/N/head:pr-N` |

## 相關技能

- `github-repo-management`（第 01 章）：建倉、設定、Releases
- `github-secrets`（第 03 章）：Actions secrets/variables
- `github-code-review`、`github-issues`：審查與 issue 管理
