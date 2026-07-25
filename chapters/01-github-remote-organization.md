# 01 · GitHub 遠端倉庫整理技能

> 來源：Hermes Agent `github-repo-management` 技能（v1.1.0）。
> 整理目標：克隆、新建、派生、設定、分支保護、Secrets、Releases、Actions，以及遠端倉庫的日常「收納 / 清理」。
> 慣例：本機用 `gh` 優先；若 `gh` 不可用，則用 `git` + `curl` 走 GitHub REST API。

## 0. 前置：身份與遠端資訊

```bash
# 確認已登入（帳號 DingJun1028）
gh auth status

# 在倉庫內取得 owner/repo
REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO"  | cut -d/ -f2)

# 用 gh 取得 username
GH_USER=$(gh api user --jq '.login')

# 若無 gh，改用 curl（需 GITHUB_TOKEN 環境變數，不可與 gh 混用）
GH_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['login'])")
```

## 1. 克隆（clone）

```bash
# 純 git（兩種環境皆同）
git clone https://github.com/owner/repo-name.git
git clone --depth 1 https://github.com/owner/repo-name.git   # 淺克隆，省時
git clone --branch develop https://github.com/owner/repo-name.git

# gh 簡寫
gh repo clone owner/repo-name
gh repo clone owner/repo-name -- --depth 1
```

## 2. 新建倉庫（create）

```bash
# gh：建公開倉庫並克隆
gh repo create my-new-project --public --clone

# gh：從既有本地目錄推送
cd /path/to/existing/project
gh repo create my-project --source . --public --push

# 組織下建倉
gh repo create my-org/my-new-project --public --clone

# 從模板建倉
gh repo create my-new-app --template owner/template-repo --public --clone
```

curl 降級：

```bash
curl -s -X POST -H "Authorization: token ***" \
  https://api.github.com/user/repos \
  -d '{"name":"my-new-project","description":"A useful tool","private":false,"auto_init":true,"license_template":"mit"}'
```

## 3. 派生（fork）與同步

```bash
gh repo fork owner/repo-name --clone

# 加上游 + 同步
git remote add upstream https://github.com/owner/repo-name.git
git fetch upstream && git checkout main && git merge upstream/main && git push origin main

# gh 捷徑：直接把 fork 同步回 upstream 最新狀態
gh repo sync $GH_USER/repo-name
```

## 4. 倉庫資訊（view / list / search）

```bash
gh repo view owner/repo-name
gh repo list --limit 20
gh search repos "machine learning" --language python --sort stars
```

## 5. 設定（edit settings / topics）

```bash
gh repo edit --description "Updated description" --visibility public
gh repo edit --default-branch main
gh repo edit --add-topic "machine-learning,python"
gh repo edit --enable-auto-merge
gh repo edit --delete-branch-on-merge          # 合併後自動刪 head 分支
gh repo edit --enable-squash-merge             # 預設 squash 合併
gh repo edit --enable-secret-scanning           # 進階安全：秘密掃描
gh repo edit --enable-secret-scanning-push-protection   # 推送時擋住已洩漏密鑰（秘密防漏的整理動作）
```

curl 降級（topics）：

```bash
curl -s -X PUT -H "Authorization: token ***" \
  -H "Accept: application/vnd.github.mercy-preview+json" \
  https://api.github.com/repos/$OWNER/$REPO/topics \
  -d '{"names":["machine-learning","python","automation"]}'
```

## 6. 分支保護（branch protection）

```bash
# gh 沒有內建子命令，需用 curl / API
curl -s -X PUT -H "Authorization: token ***" \
  https://api.github.com/repos/$OWNER/$REPO/branches/main/protection \
  -d '{
    "required_status_checks": {"strict": true, "contexts": ["ci/test","ci/lint"]},
    "enforce_admins": false,
    "required_pull_request_reviews": {"required_approving_review_count": 1},
    "restrictions": null
  }'
```

## 7. Secrets（Actions 秘密變數）

```bash
gh secret set API_KEY --body "your-secret-value"
gh secret set SSH_KEY < ~/.ssh/id_rsa
gh secret list
gh secret delete API_KEY
```

> 注意：Secrets 值寫入後不可讀回。需要跨倉庫同步時，請用 server-side workflow 技巧（見第 03 章 `github-secrets`）。

## 8. Releases（發佈）

```bash
gh release create v1.0.0 --title "v1.0.0" --generate-notes
gh release create v1.0.0 ./dist/binary --title "v1.0.0" --notes "Release notes"
gh release list
gh release download v1.0.0 --dir ./downloads
```

## 9. GitHub Actions（workflows / runs）

```bash
gh workflow list
gh run list --limit 10
gh run view <RUN_ID> --log-failed
gh run rerun <RUN_ID> --failed
gh workflow run ci.yml --ref main
gh workflow run deploy.yml -f environment=staging
```

## 10. Gists

```bash
gh gist create script.py --public --desc "Useful script"
gh gist list
```

## 11. 整理 / 收納 / 清理（本技書核心：讓遠端倉庫不長草）

`gh repo` 自帶多個「整理」子命令，章節 1–10 多半是建置，這一節專管「收納與清理」：

```bash
# 封存（archive）：保留唯讀，不再活躍開發
gh repo archive owner/repo-name
gh repo unarchive owner/repo-name          # 解除封存

# 重新命名（rename）：改 repo 名稱（會自動重定向舊 URL）
gh repo rename new-name

# 設定「預設倉庫」：讓本機目錄的 gh 指令不必每次打 owner/repo
gh repo set-default owner/repo-name

# 刪除（delete）：⚠ 不可逆，需二次確認
gh repo delete owner/repo-name --yes

# 同步 fork 回上游最新（見第 3 節）
gh repo sync $GH_USER/repo-name

# 自動連結（autolink）：把 issue/PR 編號自動轉成連結
gh repo autolink create owner/repo-name --template https://example.com/issue/<num> --key PREFIX

# 部署金鑰（deploy-key）：給 CI/伺服器一把只讀或讀寫的 SSH key
gh repo deploy-key add ~/.ssh/id_ed25519.pub --title "ci-runner" --readonly
gh repo deploy-key list
```

curl 降級（封存 / 刪除）：

```bash
# 封存
curl -s -X PUT -H "Authorization: token ***" \
  https://api.github.com/repos/$OWNER/$REPO \
  -d '{"archived": true}'

# 刪除（不可逆）
curl -s -X DELETE -H "Authorization: token ***" \
  https://api.github.com/repos/$OWNER/$REPO
```

## 12. 實踐收納清單（本技書專用）

整理遠端倉庫時，依序檢查：

1. [ ] 倉庫描述 / topics 是否清楚（便於 `gh search`）
2. [ ] default branch 是否為 `main`
3. [ ] 是否需要分支保護（CI 必過 + 1 review）
4. [ ] Secrets 是否齊全且未過期
5. [ ] 是否啟用 auto-merge / issues / wiki
6. [ ] 是否需要 Release 標記版本
7. [ ] fork 的 upstream 是否定期同步
8. [ ] 長草的倉庫是否已 `archive`，確定不要的是否已 `delete`

## 13. 驗證清單（宣稱成功前必跑）

| 檢查 | 命令 |
|------|------|
| 登入身份正確 | `gh auth status` |
| 遠端預設分支為 main | `gh repo view owner/repo --json defaultBranchRef -q .defaultBranchRef.name` |
| 倉庫可見 / 描述正確 | `gh repo view owner/repo --json name,description,visibility` |
| fork 已跟上 upstream | `git fetch upstream && git rev-list --left-right --count HEAD...upstream/main`（右側為 0 表示已同步） |
| 分支保護已生效 | `curl .../branches/main/protection`（應回 JSON，非 404） |
| Secrets 在列（值不可讀） | `gh secret list` |
| 封存狀態 | `gh repo view owner/repo --json isArchived -q .isArchived` |

## 速查表

| 動作 | gh | git + curl |
|------|-----|-----------|
| Clone | `gh repo clone o/r` | `git clone https://github.com/o/r.git` |
| Create | `gh repo create name --public` | `curl POST /user/repos` |
| Fork | `gh repo fork o/r --clone` | `curl POST /repos/o/r/forks` |
| Sync fork | `gh repo sync u/r` | `git fetch upstream && merge && push` |
| Info | `gh repo view o/r` | `curl GET /repos/o/r` |
| Settings | `gh repo edit --...` | `curl PATCH /repos/o/r` |
| Archive | `gh repo archive o/r` | `curl PATCH /repos/o/r {"archived":true}` |
| Rename | `gh repo rename new` | `curl PATCH /repos/o/r {"name":...}` |
| Delete | `gh repo delete o/r --yes` | `curl DELETE /repos/o/r` |
| Release | `gh release create v1.0` | `curl POST /repos/o/r/releases` |
| Workflows | `gh workflow list` | `curl GET /repos/o/r/actions/workflows` |
| CI rerun | `gh run rerun ID` | `curl POST /repos/o/r/actions/runs/ID/rerun` |
| Secret | `gh secret set KEY` | `curl PUT /repos/o/r/actions/secrets/KEY` (+ 加密) |

## 相關技能

- `github-auth`：HTTPS token / SSH key / gh 登入
- `github-pr-workflow`：分支、提交、開 PR、CI、合併（第 02 章）
- `github-issues`：建立 / 分類 / 標籤 / 指派 issue
- `github-secrets`：Actions secrets & variables 管理（第 03 章）
- `github-wiki-publishing`：GitHub Wiki 多頁發佈
