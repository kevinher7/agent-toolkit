---
name: rereview
description: Re-check a previously reviewed PR to verify whether flagged issues have been resolved after the author pushed fixes
user-invocable: true
---

# Re-review PR

When invoked, I will check whether previously flagged review issues have been resolved.

## Input

`$ARGUMENTS` should be the PR URL or PR number. If not provided, detect from the current branch using `gh pr view --json number`.

## Git safety

Before switching branches or pulling, inspect `git status --short`. If there are local changes, stop and ask the user how to proceed. Never stash, reset, clean, or overwrite changes automatically. Use `git pull --ff-only`; stop on fetch, checkout, or pull failure.

## Process

1. **Fetch PR state and switch to branch**:
   - `gh pr view <PR> --json number,title,headRefOid,headRefName,author,comments,reviews` to get current state
   - `git fetch origin` and `git checkout <headRefName> && git pull --ff-only` to switch to the PR branch with latest changes
   - Identify the latest review that contains the structured findings table (look for `| ID | Severity |` pattern in review body or comments)

2. **Parse previous findings**:
   - Extract each issue's ID (C1, W1, I1, etc.), file path, line number(s), and description from the findings table
   - Note the commit SHA at which the review was posted (from the review metadata)

3. **Fetch changes since review**:
   - `git fetch origin`
   - Get the diff between the review commit and current HEAD of the PR branch
   - Identify which files were modified since the review

4. **Verify each issue**:
   For each previously flagged issue:
   - Check if the referenced file was modified in commits after the review
   - Read the current state of the code at the referenced file and line
   - Determine if the issue pattern described in the finding is still present
   - Classify as:
     - **RESOLVED** - The code has been changed and the issue is no longer present
     - **NOT RESOLVED** - The code is unchanged or the issue pattern persists
     - **PARTIALLY RESOLVED** - Some aspects were addressed but the core issue remains
     - **CANNOT DETERMINE** - Unable to verify (e.g., file was deleted, heavily refactored)

5. **Present results**:

### Re-review: PR #123

| ID | Original Issue | Status | Notes |
|----|---------------|--------|-------|
| C1 | Brief description | RESOLVED | Fixed in commit abc1234 |
| W1 | Brief description | NOT RESOLVED | Code unchanged at file.py:100 |
| W2 | Brief description | PARTIALLY RESOLVED | Logic updated but edge case remains |

### Summary
- X/Y issues resolved
- Z issues still outstanding (list IDs)

### Next Steps

Tell me what to do:
- **"Approve"** - approve the PR (use /work:gh to post approval)
- **"Comment on W1"** - add a follow-up inline comment
- **"Request changes on W1, W2"** - block again with updated comments
- **Language override**: say "in English" or "in Japanese" (otherwise auto-detected from PR author)

6. **Post to GitHub**: When the user decides, use the /work:gh skill to post the follow-up review with language auto-detection.

## Important Notes

- This command does NOT re-run specialized review agents. It only checks whether previously identified issues were addressed.
- For a full new review (e.g., substantial new code was added), use `/work:bee-review` or `/work:honeycomb-review` instead.
- If no previous structured review is found on the PR, inform the user and suggest running a full review first.
