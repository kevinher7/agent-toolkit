---
name: fetch-review
description: Use when the user wants to fetch a PR review from github
argument-hint: "[PR URL or number]"
allowed-tools: [Bash, Read, Grep, Glob]
---

# Fetch review

Read the open review feedback on a PR, check each item against the code, and give the user a numbered list of fixes with your analysis.

The user calls this to talk through the review before acting on it. The list is where that conversation starts.

While building the list, don't edit files, post comments, or resolve threads. After you show it, stop and wait for the user.

## 1. Find the PR

`$ARGUMENTS` is a PR URL, a PR number, or empty. Empty means the current branch's PR.

```bash
gh pr view $ARGUMENTS --json number,url,title,headRefName,headRefOid,reviews,comments
```

If this fails, show the user the error and stop. Take the owner and repo from `url`.

## 2. Fetch the review threads

```bash
gh api graphql -F owner=<owner> -F repo=<repo> -F number=<number> -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first: 50) {
            nodes { author { login } body diffHunk createdAt }
          }
        }
      }
    }
  }
}'
```

## 3. Build the item list

- Skip resolved threads. Keep outdated ones, because the code may have moved without the problem going away.
- Read each whole thread. A later reply can change or withdraw the request, so use where the thread ended up.
- Review bodies from step 1 can also ask for changes. Include those.
- Top-level `comments` from step 1 can hold feedback too. Skip bot status posts such as CI results and deploy previews.
- Write one item per requested change. Merge duplicates.
- Drop praise and approvals.
- A ```` ```suggestion ```` block is the exact change the reviewer wants. Say so in the item.
- Put questions that need a reply, not a code change, in a separate list.
- Translate everything into English. Leave code, paths, and identifiers as they are. If you're unsure of a translation, quote the original.

If nothing is left, tell the user there's no open feedback on the PR and stop.

## 4. Check each item against the code

Check the code at the PR's head commit, `headRefOid`. If local `HEAD` is a different commit, read files with `git show <headRefOid>:<path>`. Run `git fetch origin <headRefName>` first if that commit isn't available locally. If the PR belongs to a different repo than the working directory, tell the user to run the skill from that repo and stop.

Read the commented line and enough of the code around it to judge the request. Use `diffHunk` to see what the reviewer was looking at. To find a fix made after the comment, run `git log --since=<createdAt> -- <path>`.

Give each item one verdict:

- **Still applies.** The problem is in the code now.
- **Partly fixed.** Say what's left.
- **Already fixed.** Name the commit. Tell the user the thread can be resolved.
- **I'd push back.** The request is wrong, or it would make the code worse. Say why.
- **Unclear.** You can't tell from the code. Say what's missing.

Every verdict names the function, line, or commit you checked. If you can't point at something, the verdict is **Unclear**.

## 5. Output

Put the most important fixes first and "Already fixed" items last. For outdated threads, use `originalLine` and add `· outdated` to the location line.

````markdown
## PR #412 · 4 open threads from @tanaka

### 1. Wrap the job retry in a lock
`src/sync/worker.py:88` · @tanaka

Two workers can pick up the same job and both write the result.

**Still applies.** `claim_job()` reads the row and updates it in two separate queries with no lock, so the race is real. A `SELECT ... FOR UPDATE` in `claim_job()` fixes it.

Before:
```python
def claim_job(job_id):
    row = db.query("SELECT * FROM jobs WHERE id = %s", job_id)
```

After:
```python
def claim_job(job_id):
    row = db.query("SELECT * FROM jobs WHERE id = %s FOR UPDATE", job_id)
```

### 2. Use `parseInt(x, 10)`
`src/api/routes.ts:34` · @tanaka

The reviewer suggested this exact change.

**Already fixed** in `a1b2c3d`. The thread can be resolved.

Before:
```ts
const page = parseInt(req.query.page);
```

After:
```ts
const page = parseInt(req.query.page, 10);
```

### Questions to answer
- `src/sync/worker.py:40` · @tanaka Why is the timeout 30s?
````

Each item title is the fix, written as an instruction. The line under the location is the reviewer's reason, shortened. Omit "Questions to answer" if there are none.

Each item ends with a "Before:" code block and an "After:" code block, tagged with the file's language. Show the same lines in both so they line up: the changed lines plus a line or two of context.

- **Still applies** and **Partly fixed**: before is the code at `headRefOid`, after is the fix you'd make. For a `suggestion` block, after is the reviewer's suggestion.
- **Already fixed**: before is the code from `diffHunk`, after is the code at `headRefOid`.
- **I'd push back** and **Unclear**: show the reviewer's requested change if it's concrete enough to write. Otherwise skip both blocks.

End after the list. Don't offer a fix plan or ask which item to start with.
