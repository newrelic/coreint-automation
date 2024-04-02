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
    LATEST_TAG=$(
        gh release list --json publishedAt,isLatest,tagName -R "${ORG}/${REPO_NAME}" --jq '
            .[] | select(.isLatest) | .tagName
        '
    )

    # Get all statuses of the tag
    # Ref: https://docs.github.com/en/rest/commits/statuses?apiVersion=2022-11-28
    # Save you a click:
    #  'status': queued, in_progress, completed
    #  'conclusion': action_required, cancelled, failure, neutral, success, skipped, stale, timed_out 
    STATUSES=$(gh api "/repos/${ORG}/${REPO_NAME}/commits/${LATEST_TAG}/check-runs" \
        --jq '.check_runs[] | .status + ";" + .conclusion + ";" + .name + ";" + .html_url'
    )
    #outputs something like:
    # completed;success;security / Trivy security scan;https://github.com/newrelic/nri-mssql/actions/runs/8090423977/job/22107883691
    # completed;skipped;prerelease / Create prerelease;https://github.com/newrelic/nri-mssql/actions/runs/8062545746/job/22022509783
    # completed;failure;prerelease / Check block endpoint;https://github.com/newrelic/nri-mssql/actions/runs/8062545746/job/22022501960
    if [ -z "${STATUSES}" ]; then
        # $STATUSES can be empty if no is has no runs
        # It is a corner case on legacy repos: nri-snmp and nri-zookeeper
        continue
    fi
    # Test if it has a job running at the moment.
    if cut -d\; -f1 <<<"${STATUSES}" | grep -E "in_progress" > /dev/null 2>&1; then
        echo "⚠️ The repository ${REPO_NAME} has a job in progress. Skipping status checks."
        continue
    fi
    # Test if any run failed.
    if cut -d\; -f2 <<<"${STATUSES}" | grep -E "(failure|neutral|stale|timed_out)" > /dev/null 2>&1; then
        # A run failed. Pretty printing to make them human readable.
        echo "A failing or inconsistent job has been found in the integration ${REPO_NAME}:"
        echo "============================================================================="
        while IFS=';' read STATUS CONCLUSION JOB_NAME URL; do
            if grep -E "(failure|neutral|stale|timed_out)" <<<"${CONCLUSION}" > /dev/null 2>&1; then
                printf "‼️ %s on %s URL: %s\n" "${CONCLUSION}" "${JOB_NAME}" "${URL}" 
            fi
        done <<<"${STATUSES}"
        echo
    fi
done
