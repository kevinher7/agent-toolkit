---
name: gh
description: GitHub PR operations. Sub-workflows dispatched from $ARGUMENTS — "create pr" opens a new PR, "update pr" refreshes title/description, "review" posts a code review (with optional inline diff comments), "comment" posts a regular PR comment. Reviews/comments support Japanese/English language auto-detection.
---

# GitHub PR Skill

## Installed resources

Set `SKILL_DIR` to `${CLAUDE_PLUGIN_ROOT}/skills/work:gh`, using the plugin-root path substituted by Claude. Resolve supporting files beneath that directory and quote shell paths. Keep the working directory in the target project.

Use `$ARGUMENTS` as the invocation input.

Single entry point for all GitHub PR operations. Dispatch on `$ARGUMENTS`:

| User intent | `$ARGUMENTS` starts with | Where to go |
|---|---|---|
| Open a new PR from the current branch | `create pr` | Read `references/create-pr.md` and follow it |
| Refresh an existing PR's title/description | `update pr` | Read `references/update-pr.md` and follow it |
| Post a code review (approve / request changes / comment, optionally with inline diff comments) | `review` | "Reviewing" section below |
| Post a regular PR comment that isn't a review | `comment` | "Commenting" section below |
| Anything else / ambiguous | (other) | Infer the closest match from intent; if truly unclear, ask the user which capability they want |

After matching, treat any tokens **after** the dispatch keyword as the workflow's own input (e.g., `/work:gh create pr --reviewer alice` → workflow input is `--reviewer alice`).

The `references/` files are loaded only when needed (progressive disclosure) — do not read them unless the user is invoking that specific sub-workflow.

---

## Language Detection (reviews & comments only)

This applies to **review and comment text only** — not to PR titles/descriptions written by create-pr / update-pr.

Use the PR author to choose the default review/comment language, unless the user explicitly overrides it. Respect higher-priority instructions.

Before composing any review or comment, run this single command (substitute the actual PR URL or number for `<PR>`):

```bash
author=$(gh pr view <PR> --json author --jq '.author.login') || exit 1
if [ ! -r "$SKILL_DIR/config/english_speakers.txt" ]; then
  echo "Missing language configuration" >&2
  exit 1
fi
if grep -qxF "$author" "$SKILL_DIR/config/english_speakers.txt"; then
  echo "ENGLISH"
else
  echo "JAPANESE"
fi
```

- If fetching the author or reading configuration fails, stop instead of defaulting to Japanese.
- Output `ENGLISH` → write all comments in **English**
- Output `JAPANESE` → write all comments in **Japanese**
- The caller can override by saying "in English" or "in Japanese"

---

## Reviewing

Choose the right script based on what you need to do:

### 1. Inline Review Comments (code-anchored)

**When to use:** You have findings with specific file paths and line numbers that should appear in the GitHub diff view.

**Script:** `"$SKILL_DIR/scripts/post_inline_review.sh"`

**Usage:**
```bash
bash "$SKILL_DIR/scripts/post_inline_review.sh" <OWNER/REPO> <PR_NUMBER> <EVENT> <BODY_FILE> <COMMENTS_FILE>
```

- `OWNER/REPO`: e.g., `myorg/myrepo`
- `PR_NUMBER`: the PR number
- `EVENT`: `APPROVE`, `REQUEST_CHANGES`, or `COMMENT`
- `BODY_FILE`: path to a temp file containing the overall review summary text
- `COMMENTS_FILE`: path to a JSON file with the comments array

**Comments JSON format:**
```json
[
  {"path": "src/file.py", "line": 42, "body": "[C1] Issue description here"},
  {"path": "src/other.py", "start_line": 10, "line": 15, "body": "[W1] Multi-line issue spanning lines 10-15"}
]
```

- `path`: file path relative to repo root
- `line`: the line number in the file (required)
- `start_line`: for multi-line comments, the first line (optional)
- `body`: the comment text, should start with the issue ID like `[C1]`

**Important:** The script automatically fetches the HEAD commit SHA. The `line` number must refer to the line in the file at HEAD of the PR branch (the RIGHT side of the diff).

### 2. PR-Level Review (no inline comments)

**When to use:** You want to approve, request changes, or leave a general review comment without anchoring to specific code lines. Also use for the overall verdict after posting inline comments.

**Script:** `"$SKILL_DIR/scripts/post_review.sh"`

**Usage:**
```bash
bash "$SKILL_DIR/scripts/post_review.sh" <PR_NUMBER> <BODY_FILE> <EVENT>
```

- `PR_NUMBER`: the PR number
- `BODY_FILE`: path to a temp file containing the review body text
- `EVENT`: `APPROVE`, `REQUEST_CHANGES`, or `COMMENT` (default: `COMMENT`)

## Commenting

### Regular PR Comment (not a review)

**When to use:** You want to leave a follow-up comment, status update, or rereview summary. This does NOT carry review status (no approve/request changes).

**Script:** `"$SKILL_DIR/scripts/post_comment.sh"`

**Usage:**
```bash
bash "$SKILL_DIR/scripts/post_comment.sh" <PR_NUMBER> <BODY_FILE>
```

- `PR_NUMBER`: the PR number
- `BODY_FILE`: path to a temp file containing the comment body text

## Typical Workflow (Reviews)

When posting review findings from a code review:

1. **Separate findings** into those with code references (file + line) and those without
2. **Build the comments JSON** for inline findings, write to a temp file
3. **Write the overall review summary** to a temp file (include any non-code-anchored findings here)
4. **Call `post_inline_review.sh`** with the appropriate event (REQUEST_CHANGES, COMMENT, etc.)
5. If there are no inline findings, use `post_review.sh` instead

## Rules

- Always write comment body to a temp file first, never pass long text as shell arguments
- Use `mktemp` for temp files and clean them up after
- Markdown formatting is supported in all comment bodies
- Include the issue ID (e.g., `[C1]`, `[W1]`) at the start of inline comments for traceability

## Layout

```
gh/
├── SKILL.md              ← this file (entry point + dispatch + reviewing/commenting)
├── references/           ← progressive-disclosure sub-workflows
│   ├── create-pr.md
│   └── update-pr.md
├── scripts/              ← bash helpers for reviewing/commenting
│   ├── post_inline_review.sh
│   ├── post_review.sh
│   └── post_comment.sh
└── config/
    └── english_speakers.txt
```
