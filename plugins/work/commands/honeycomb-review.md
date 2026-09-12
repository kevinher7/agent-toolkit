---
name: honeycomb-review
description: Orchestrates multi-agent review across different domains of the honeycomb codebase for a given PR
disable-model-invocation: true
user-invocable: true
---

# Multi-Domain Code Review

This command supports two modes depending on whether a PR URL is provided.

## Important: Working Directory

**All git commands must be run in the current working directory.** Do NOT navigate to or `cd` into any other directory (e.g., a bee or honeycomb repo path). Perform all operations exactly where Claude Code is currently running.

## Git safety

Before switching branches or pulling, inspect `git status --short`. If there are local changes, stop and ask the user how to proceed. Never stash, reset, clean, or overwrite changes automatically. Use `git pull --ff-only`; stop on fetch, checkout, or pull failure.

## Mode 1: With PR URL argument

When invoked with a PR URL (e.g., `/work:honeycomb-review https://github.com/org/repo/pull/123`):

### Startup Sequence
1. Parse the PR URL to extract owner, repo, and PR number
2. Use `gh pr view <PR_URL> --json title,body,headRefName,comments,reviews` to fetch PR information:
   - Branch name (headRefName)
   - PR title and body (summary)
   - Comments and reviews
3. Run `git fetch origin` in the current directory to get the latest remote changes
4. Switch to the PR branch using `git checkout <branch_name>` in the current directory
5. Pull the latest changes using `git pull --ff-only` in the current directory
6. Get the diff using `git diff origin/develop...HEAD` in the current directory

## Mode 2: Without PR URL argument

When invoked without arguments (e.g., `/work:honeycomb-review`):

### Startup Sequence
1. Run `git fetch origin` in the current directory to get the latest remote changes
2. Get the current branch name using `git branch --show-current` in the current directory
3. Get the diff against origin/develop using `git diff origin/develop...HEAD` in the current directory
4. No PR metadata available - proceed directly to review process

## Review Process (both modes)

1. Analyze the diff to get a list of affected files and their changes
2. If PR metadata is available (Mode 1), review PR description and comments to understand context
3. Classify the files (and their diffs) across the following domains:
   - Database migrations
   - UI (frontend changes)
   - UI performance
   - Entities API
   - Data Quality (Audit and normalization)
4. Spawn the appropriate specialist agents in parallel and distribute the files and diffs. Also invoke `work:type-reviewer` once for changed `.py`, `.ts`, `.tsx`, `.js`, and `.jsx` files. Pass the project name (`honeycomb`), exact review file list, and diff. Pass the resolved plugin root `${CLAUDE_PLUGIN_ROOT}` for its helper scripts. Exclude tests from type review unless explicitly requested. Skip type review when no applicable files remain.
5. Collect and synthesize findings into a unified report. Merge duplicate type findings from domain reviewers and `work:type-reviewer` before assigning IDs. Include checker status and any failures or out-of-scope diagnostics separately; a missing or failed checker is not a pass. Do not write `.plans/TYPE-REVIEW.md` or pause for a separate type-review phase.
6. Assign sequential IDs by severity and present in this format:

### Findings

| ID | Severity | File | Line(s) | Description | Reviewer |
|----|----------|------|---------|-------------|----------|
| C1 | CRITICAL | path/to/file.py | 42-45 | Brief description | reviewer-name |
| W1 | WARNING  | path/to/file.py | 100   | Brief description | reviewer-name |
| I1 | INFO     | path/to/file.py | 12    | Brief description | reviewer-name |

For each finding, include the exact code snippet and explanation collapsed under a `<details>` tag below the table.

### Action Menu

Tell me what to do with each finding:
- **Request changes**: e.g., "C1, W1-W3"
- **Suggest** (non-blocking comment): e.g., "W5, I1"
- **Skip**: e.g., "skip C2, W4"
- **Language override**: say "in English" or "in Japanese" (otherwise auto-detected from PR author)

Example: "Request changes on C1, W1-W3. Suggest I1. Skip the rest."

I will then use the /work:gh skill to post the selected issues as inline diff comments (for issues with file+line references) or PR-level comments (for general issues).


## File classification rules

Use these plugin agent names when dispatching. Assign multiple reviewers when domains overlap.

| Domain | Agent |
|--------|-------|
| SQL, migrations, ORM, data access | `work:database-reviewer` |
| React UI and accessibility | `work:ui-reviewer` |
| React rendering, hooks, bundle performance | `work:ui-performance-reviewer` |
| Server actions, API routes, entity logic | `work:entity-api-reviewer` |
| Normalization, locks, audit integrity | `work:data-quality-reviewer` |
| Changed source files in the type-review scope | `work:type-reviewer` |
