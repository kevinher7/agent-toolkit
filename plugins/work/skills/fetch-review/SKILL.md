---
name: fetch-review
description: Fetch a review from the current branch's PR, translate it to English, and display it in chat. No argument = latest review; integer N = Nth review counting from the latest (1 = latest, 2 = previous, etc.).
---

# Fetch Review Skill

## Installed resources

Set `SKILL_DIR` to `${CLAUDE_PLUGIN_ROOT}/skills/fetch-review`, using the plugin-root path substituted by Claude. Resolve supporting files beneath that directory and quote shell paths. Keep the working directory in the target project.

Use `$ARGUMENTS` as the invocation input.

Fetches a single review from the GitHub PR associated with the current branch, translates the prose into English, and prints a structured markdown summary in chat. Read-only — never posts, edits, or modifies the PR.

## Argument

Read `$ARGUMENTS`:

- Empty or whitespace → `N=1` (the latest review)
- A positive integer → `N=<that integer>`, 1-indexed from the latest (`2` = second-to-latest, etc.)
- Anything else → tell the user the argument must be a positive integer and stop

## Workflow

### 1. Fetch the review data

Run the helper script with `N`:

```bash
bash "$SKILL_DIR/scripts/fetch_review.sh" <N>
```

The script resolves the current branch's PR, sorts all reviews newest-first, picks the Nth review, fetches its inline diff comments, writes two temp JSON files, and prints `key=value` lines to stdout.

### 2. Handle errors

If the script exits non-zero, print its stderr message verbatim to the user and stop. Possible failures:

| Exit | Meaning |
|---|---|
| 2 | Argument is not a positive integer |
| 3 | No open PR found for the current branch |
| 4 | PR has no reviews yet |
| 5 | `N` exceeds the number of reviews on this PR |
| 6 | `jq` is not installed |

### 3. Parse the stdout key=value lines

Capture: `pr_number`, `count`, `selected_n`, `review_id`, `review_file`, `comments_file`.

### 4. Read the two temp files

Use the Read tool on `review_file` and `comments_file`.

- `review_file` → single review object. Relevant fields: `body`, `state`, `submitted_at`, `html_url`, `user.login`.
- `comments_file` → JSON array of inline comments. Per-comment fields: `path`, `line`, `start_line` (may be null), `body`, `original_line` (fallback when `line` is null on outdated comments).

### 5. Translate prose into English

- If the source text is already English, pass it through unchanged. Otherwise translate naturally into fluent English.
- Translate **prose only**. Preserve code fences, inline code, file paths, identifiers, URLs, markdown lists, line breaks, and any structural formatting verbatim.
- If you genuinely cannot identify or translate a passage (e.g., an unfamiliar language), include the original text and add a short parenthetical note saying you were unsure, rather than inventing a translation.

### 6. Print the markdown summary

Use this exact shape:

```markdown
# Review #{selected_n} of {count} — @{author} · {STATE} · {YYYY-MM-DD HH:MM UTC}

{html_url}

## Body

{translated body, or _(no review body)_ if empty or null}

## Inline comments ({M} total)

### {file/path/one.py}

- **L{line}** — {translated body}
- **L{start}–{end}** — {translated body for a multi-line comment}

### {file/path/two.ts}

- **L{line}** — {translated body}
```

Rules:

- `{STATE}` is `APPROVED`, `CHANGES_REQUESTED`, or `COMMENTED`.
- `{YYYY-MM-DD HH:MM UTC}` is derived from `submitted_at` (an ISO 8601 UTC timestamp).
- Use `start_line`–`line` for multi-line comments; otherwise just `L{line}`. If `line` is null, fall back to `original_line`.
- Group comments by `path`. Within each file, sort by line ascending.
- If `comments_file` is `[]`, render `## Inline comments` then `_(none)_` on the next non-empty line, and omit the `(M total)` count.

### 7. Clean up temp files

```bash
rm -f <review_file> <comments_file>
```

## Layout

```
fetch-review/
├── SKILL.md              ← this file (dispatch + output format)
└── scripts/
    └── fetch_review.sh   ← PR resolve + reviews fetch + inline comments fetch
```
