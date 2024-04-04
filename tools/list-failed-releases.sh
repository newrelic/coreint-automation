#!/usr/bin/env bash

set -euo pipefail

source "$(dirname $(readlink -f $0))/common-functions.sh"

# Listing all repositories that start with `nri-` that belongs to coreint
gh api --paginate "/teams/${TEAM_ID}/repos" --jq '.[] | select(.name | startswith("nri-")) | .name' | \
while read REPO_NAME; do
    # Get the date of the latest release.
    LATEST_TAG=$(
        gh release list --json publishedAt,isLatest,tagName -R "${ORG}/${REPO_NAME}" --jq '
            .[] | select(.isLatest) | .tagName
        '
    )

    reference_status "${ORG}/${REPO_NAME}" "${LATEST_TAG}"
done
