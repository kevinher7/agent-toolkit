#!/usr/bin/env bash
# Fetch the Nth-most-recent review (and its inline comments) from the current branch's PR.
#
# Usage: fetch_review.sh <N>
#   N: 1-indexed from latest (1 = latest review, 2 = second-to-latest, ...).
#      Defaults to 1 if omitted.
#
# On success, writes key=value lines to stdout and exits 0:
#   pr_number=<n>
#   count=<k>             # total reviews on the PR
#   selected_n=<n>        # the N that was selected
#   review_id=<id>
#   review_file=<path>    # JSON object: the selected review
#   comments_file=<path>  # JSON array: inline comments for the selected review
#
# On failure, writes a message to stderr and exits non-zero:
#   2 - argument validation (N is not a positive integer)
#   3 - no open PR for current branch
#   4 - PR has no reviews
#   5 - N exceeds review count
#   6 - jq missing

set -euo pipefail

command -v jq >/dev/null 2>&1 || {
  echo "jq is required but not installed (install via: brew install jq)" >&2
  exit 6
}

N=${1:-1}

if ! [[ "$N" =~ ^[0-9]+$ ]] || [ "$N" -lt 1 ]; then
  echo "Argument must be a positive integer (got: '$N')" >&2
  exit 2
fi

PR_NUMBER=$(gh pr view --json number --jq .number 2>/dev/null) || {
  echo "No open PR found for the current branch" >&2
  exit 3
}

ALL_REVIEWS_FILE=$(mktemp)
REVIEW_FILE=$(mktemp)
COMMENTS_FILE=$(mktemp)

# Fetch reviews (up to 100 in one page covers the vast majority of PRs) and sort newest-first.
gh api "repos/{owner}/{repo}/pulls/$PR_NUMBER/reviews?per_page=100" \
  | jq 'sort_by(.submitted_at) | reverse' \
  > "$ALL_REVIEWS_FILE"

COUNT=$(jq 'length' "$ALL_REVIEWS_FILE")

if [ "$COUNT" -eq 0 ]; then
  echo "This PR has no reviews yet" >&2
  rm -f "$ALL_REVIEWS_FILE" "$REVIEW_FILE" "$COMMENTS_FILE"
  exit 4
fi

if [ "$N" -gt "$COUNT" ]; then
  echo "Only $COUNT review(s) exist on this PR; cannot fetch review #$N" >&2
  rm -f "$ALL_REVIEWS_FILE" "$REVIEW_FILE" "$COMMENTS_FILE"
  exit 5
fi

jq ".[$((N - 1))]" "$ALL_REVIEWS_FILE" > "$REVIEW_FILE"
REVIEW_ID=$(jq -r '.id' "$REVIEW_FILE")
rm -f "$ALL_REVIEWS_FILE"

# Fetch inline diff comments belonging to this specific review.
gh api "repos/{owner}/{repo}/pulls/$PR_NUMBER/reviews/$REVIEW_ID/comments?per_page=100" \
  > "$COMMENTS_FILE"

cat <<EOF
pr_number=$PR_NUMBER
count=$COUNT
selected_n=$N
review_id=$REVIEW_ID
review_file=$REVIEW_FILE
comments_file=$COMMENTS_FILE
EOF
