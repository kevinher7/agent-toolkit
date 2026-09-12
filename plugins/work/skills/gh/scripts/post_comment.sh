#!/usr/bin/env bash
# Posts a regular PR comment (not a review - no approve/request changes status).
# Use for follow-up comments, status updates, rereview summaries, etc.
#
# Usage: post_comment.sh <PR_NUMBER> <BODY_FILE>
#
# Arguments:
#   PR_NUMBER  - the pull request number
#   BODY_FILE  - path to file containing the comment body text

set -euo pipefail

PR_NUMBER=$1
BODY_FILE=$2

if [ -z "$PR_NUMBER" ] || [ -z "$BODY_FILE" ]; then
    echo "Usage: $0 <pr_number> <body_file>"
    exit 1
fi

BODY=$(cat "$BODY_FILE")

gh pr comment "$PR_NUMBER" --body "$BODY"

echo "Comment posted successfully on PR #$PR_NUMBER."
