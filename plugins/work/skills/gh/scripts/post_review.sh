#!/usr/bin/env bash
# Posts a PR-level review (approve, request changes, or comment) without inline comments.
#
# Usage: post_review.sh <PR_NUMBER> <BODY_FILE> [EVENT]
#
# Arguments:
#   PR_NUMBER  - the pull request number
#   BODY_FILE  - path to file containing the review body text
#   EVENT      - APPROVE, REQUEST_CHANGES, or COMMENT (default: COMMENT)

set -euo pipefail

PR_NUMBER=$1
BODY_FILE=$2
EVENT=${3:-"COMMENT"}

if [ -z "$PR_NUMBER" ] || [ -z "$BODY_FILE" ]; then
    echo "Usage: $0 <pr_number> <body_file> [APPROVE|REQUEST_CHANGES|COMMENT]"
    exit 1
fi

BODY=$(cat "$BODY_FILE")

# Map event to gh cli flags
case "$EVENT" in
    APPROVE)
        FLAG="--approve"
        ;;
    REQUEST_CHANGES)
        FLAG="--request-changes"
        ;;
    COMMENT)
        FLAG="--comment"
        ;;
    *)
        echo "Invalid event: $EVENT. Must be APPROVE, REQUEST_CHANGES, or COMMENT."
        exit 1
        ;;
esac

gh pr review "$PR_NUMBER" $FLAG --body "$BODY"

echo "Review posted successfully on PR #$PR_NUMBER ($EVENT)."
