#!/usr/bin/env bash

set -euo pipefail

source "$(dirname $(readlink -f $0))/common-functions.sh"

# Listing all repositories that start with `nri-` that belongs to coreint
gh api --paginate "/teams/${TEAM_ID}/repos" --jq '.[] | select(.name | startswith("nri-")) | .name' | \
while read REPO_NAME; do
    PRS=$(gh pr list -R "${ORG}/${REPO_NAME}" \
        --json "isDraft,author,number,title,url" \
        --jq ' .[] | select(.isDraft == false) | "#" + (.number|tostring) + ";" + .title + " (" + .author.login + ");" + .url'
    )
    if [ -z "$PRS" ]; then
        exit 0
    fi

    echo "⚠️ The repository ${REPO_NAME} has has unmerged PRs that are not marked as draft:"
    column -t -s\; <<<"${PRS}"

    echo
done
