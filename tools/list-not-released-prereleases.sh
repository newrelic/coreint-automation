#!/usr/bin/env bash

set -euo pipefail

ORG="newrelic";
# https://docs.github.com/en/rest/teams/teams?apiVersion=2022-11-28#get-a-team-by-name
# gh api /orgs/newrelic/teams/coreint | jq .id
TEAM_ID="3626876";

# Listing all repositories that start with `nri-` that belongs to coreint
gh api --paginate "/teams/${TEAM_ID}/repos" --jq '.[] | select(.name | startswith("nri-")) | .name' | \
while read REPO_NAME; do
    # Get the date of the latest release.
    LATEST_RELEASE=$(
        gh release list --json publishedAt,isLatest -R "${ORG}/${REPO_NAME}" --jq '
            .[] | select(.isLatest) | .publishedAt | fromdateiso8601
        '
    )

    # List all releases, filter by prereleases that was made later than the latest release, sort by date,
    # reverse because the last one is the most recent and only grab the last prerelease
    NON_PUBLISHED_PRERELEASES=$(
        gh release list --json name,publishedAt,isPrerelease,isLatest,tagName -R "${ORG}/${REPO_NAME}" --jq '
            [
                .[] | select( .isPrerelease and ((.publishedAt | fromdateiso8601) > '${LATEST_RELEASE}'))
            ]
            | sort_by(.publishedAt |= fromdateiso8601) | reverse | first
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

        echo " > Prerelease found for ${REPO_NAME}: ${URL}"
        echo "# gh release edit -R \"${ORG}/${REPO_NAME}\" \"$NAME\" --prerelease=false --latest"
    fi
done
