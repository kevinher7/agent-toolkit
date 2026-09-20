# Create PR Workflow

This is a reference loaded by [`../SKILL.md`](../SKILL.md) when the user invokes `/work:gh create pr ...`. Follow it when opening a new pull request from the current branch.

The dispatcher in SKILL.md strips the `create pr` prefix and passes any remaining tokens through as workflow input (e.g., `/work:gh create pr --reviewer alice` → workflow input is `--reviewer alice`). Use that input for reviewer usernames, an explicit base branch, or other notes. If empty, just proceed with the defaults below.

## Step 1: Gather Branch Information
1. Run `git branch --show-current` to get the current branch name
2. Run `git log --oneline origin/main..HEAD` (or the appropriate base branch) to see commits
3. Run `git diff origin/main..HEAD --stat` to get an overview of changed files

## Step 2: Analyze Changes
1. Review the actual changes with `git diff origin/main..HEAD`
2. Understand the purpose and scope of the changes
3. Identify any breaking changes or dependencies

## Step 3: Prepare PR Content
1. Check for a PR template at `.github/PULL_REQUEST_TEMPLATE.md` or similar
2. Draft a comprehensive but concise summary of the changes
3. Follow the PR template structure if available

## Step 4: Create the Pull Request
1. Use `gh pr create --assignee @me` to create the PR
2. Add reviewers if specified in the workflow input with the `--reviewer` flag
3. Apply appropriate labels if applicable
4. Pass the body via a HEREDOC or `--body-file` (never as a long inline string)

## PR Description Guidelines
- **Title**: Clear, concise summary of the change (use conventional commit style if applicable). Keep under ~70 characters.
- **Summary**: Brief description of what and why (not how)
- **Changes**: Bullet points of key changes
- **Testing**: How the changes were tested
- **Breaking Changes**: Note any breaking changes clearly

## Output
After creating the PR, report:
- PR URL
- Title used
- Reviewers assigned (if any)
- Any warnings or notes about the PR
