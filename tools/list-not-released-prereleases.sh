#!/usr/bin/env bash

set -euo pipefail

source "$(dirname $(readlink -f $0))/common-functions.sh"

# Listing all repositories that start with `nri-` that belongs to coreint
gh api --paginate "/teams/${TEAM_ID}/repos" --jq '.[] | select(.name | startswith("nri-")) | .name' | \
while read REPO_NAME; do
    # Get the date of the latest release.
    LATEST_RELEASE_DATE=$(
        gh release list --json publishedAt,isLatest -R "${ORG}/${REPO_NAME}" --jq '
            .[] | select(.isLatest) | .publishedAt | fromdateiso8601
        '
    )

    # List all releases, filter by prereleases that was made later than the latest release, sort by date,
    # reverse because the last one is the most recent and only grab the last prerelease
    NON_PUBLISHED_PRERELEASES=$(
        gh release list --json name,publishedAt,isPrerelease,tagName -R "${ORG}/${REPO_NAME}" --order desc --jq '
            [
                .[] | select( .isPrerelease and ((.publishedAt | fromdateiso8601) > '${LATEST_RELEASE_DATE}'))
            ]
            | sort_by(.publishedAt |= fromdateiso8601) | first
        '
    )
    if ! [ -z "${NON_PUBLISHED_PRERELEASES}" ]; then
        # Next querie uses the list release API endpoint:
        # https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#list-releases

        # gh list release is limited only to fields createdAt, isDraft, isLatest, isPrerelease, name, publishedAt, and tagName
        # We need the URL to show it to the user.

        NAME=$(jq -r .name <<<"${NON_PUBLISHED_PRERELEASES}") # Name of the release
        TAG=$(jq -r .tagName <<<"${NON_PUBLISHED_PRERELEASES}") # Tag of the release
        URL=$(gh api --paginate "/repos/${ORG}/${REPO_NAME}/releases/tags/${TAG}" --jq '.html_url') # URL of the release

        echo "  >>>  Prerelease found for ${REPO_NAME}: ${URL}"
        echo "       You can release it by running: \`gh release edit -R \"${ORG}/${REPO_NAME}\" \"$TAG\" --prerelease=false --latest'"
        echo
        if [ "$NAME" != "$TAG" ]; then
            echo "⚠️ The pre-release for $TAG is not ready: $NAME" # A title different from the tag means the pre-release is not ready. Eg.: "vX.Y.Z (artifacts-pending)"
        fi
        reference_status "${ORG}/${REPO_NAME}" "${TAG}"
    fi
done
