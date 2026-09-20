# Update PR Workflow

This is a reference loaded by [`../SKILL.md`](../SKILL.md) when the user invokes `/work:gh update pr ...`. Follow it when updating an existing PR's title and description so they accurately reflect the current diff.

The dispatcher in SKILL.md strips the `update pr` prefix and passes any remaining tokens through as workflow input (e.g., `/work:gh update pr add note about migration order` → workflow input is `add note about migration order`). Use that input as extra context to incorporate into the description (e.g., reviewer response notes). If empty, just refresh the title/description from the diff.

## Step 1: Fetch and Gather Information
1. Run `git fetch origin` to ensure you have the latest remote state
2. Run `gh pr view --json number,baseRefName,url` to get the PR number, base branch, and URL
3. If no PR exists for the current branch, stop and inform the user

## Step 2: Get the PR Diff
1. Run `git log --oneline origin/<base>..HEAD` to see commit history
2. Run `gh pr diff --patch` to get the PR diff

## Step 3: Read Current PR Description
Run `gh pr view --json title,body` to get the existing title and description so you know what's already there.

## Step 4: Compose Updated Title and Description
Based on the diff analysis, write a new title and description. **Always re-derive the title from the diff** — do not copy the existing title verbatim. The existing title may be stale or inaccurate.
- **Title**: Clear, concise summary of what the diff actually does (use conventional commit style if applicable). Keep under ~70 characters.
- **Summary**: Brief description of what and why (not how)
- **Changes**: Bullet points of key changes
- **Testing**: How the changes can be tested
- **Breaking Changes**: Note any breaking changes clearly

If the workflow input includes additional notes (e.g., reviewer responses), incorporate them into the appropriate section rather than dumping them at the end.

## Step 5: Update the PR
1. Write the new body to a temp file using `mktemp`
2. Run `gh pr edit <number> --title "<title>" --body-file <tempfile>`
3. Clean up the temp file

## Output
After updating the PR, report:
- PR URL
- Updated title
- Summary of what changed in the description vs the previous one
