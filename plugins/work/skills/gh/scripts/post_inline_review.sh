#!/usr/bin/env bash
# Posts a PR review with inline diff comments anchored to specific code lines.
#
# Usage: post_inline_review.sh <OWNER/REPO> <PR_NUMBER> <EVENT> <BODY_FILE> <COMMENTS_FILE>
#
# Arguments:
#   OWNER/REPO   - e.g., "myorg/myrepo"
#   PR_NUMBER    - the pull request number
#   EVENT        - APPROVE, REQUEST_CHANGES, or COMMENT
#   BODY_FILE    - path to file containing the overall review body text
#   COMMENTS_FILE - path to JSON file with comments array:
#                   [{"path": "file.py", "line": 42, "body": "comment text"}, ...]
#                   Optional: "start_line" for multi-line comments

set -euo pipefail

OWNER_REPO=$1
PR_NUMBER=$2
EVENT=$3
BODY_FILE=$4
COMMENTS_FILE=$5

if [ -z "$OWNER_REPO" ] || [ -z "$PR_NUMBER" ] || [ -z "$EVENT" ] || [ -z "$BODY_FILE" ] || [ -z "$COMMENTS_FILE" ]; then
    echo "Usage: $0 <owner/repo> <pr_number> <event> <body_file> <comments_file>"
    echo "  event: APPROVE, REQUEST_CHANGES, or COMMENT"
    exit 1
fi

# Validate event type
case "$EVENT" in
    APPROVE|REQUEST_CHANGES|COMMENT) ;;
    *)
        echo "Invalid event: $EVENT. Must be APPROVE, REQUEST_CHANGES, or COMMENT."
        exit 1
        ;;
esac

# Fetch the HEAD commit SHA of the PR
COMMIT_ID=$(gh pr view "$PR_NUMBER" -R "$OWNER_REPO" --json headRefOid --jq '.headRefOid')
if [ -z "$COMMIT_ID" ]; then
    echo "Error: Could not fetch HEAD commit SHA for PR #$PR_NUMBER"
    exit 1
fi

# Read body text
BODY=$(cat "$BODY_FILE")

# Build the full payload using jq
PAYLOAD_FILE=$(mktemp)
trap 'rm -f "$PAYLOAD_FILE"' EXIT

jq -n \
    --arg event "$EVENT" \
    --arg body "$BODY" \
    --arg commit_id "$COMMIT_ID" \
    --slurpfile comments "$COMMENTS_FILE" \
    '{
        event: $event,
        body: $body,
        commit_id: $commit_id,
        comments: $comments[0]
    }' > "$PAYLOAD_FILE"

# Post the review
gh api "repos/$OWNER_REPO/pulls/$PR_NUMBER/reviews" \
    --method POST \
    --input "$PAYLOAD_FILE"

echo "Review posted successfully on PR #$PR_NUMBER ($EVENT) with $(jq length "$COMMENTS_FILE") inline comment(s)."
