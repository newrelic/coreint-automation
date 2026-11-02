#!/usr/bin/env bash
# Scans the opted-in repos and writes one local JSON file split in two lists:
#   pending: a pre-release newer than the latest release exists (still to be published to prod)
#   done:    the latest release has no newer pre-release (nothing waiting)
# Nothing is written to S3.
#
# usage: scan_prereleases.sh <repos.json> <queue.json>
# env:   GITHUB_TOKEN (optional locally, avoids rate limits), GITHUB_ORG (default: newrelic)
set -euo pipefail

CONFIG="${1:?usage: $0 <repos.json> <queue.json>}"
OUT_FILE="${2:?usage: $0 <repos.json> <queue.json>}"
ORG="${GITHUB_ORG:-newrelic}"

auth=()
[ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

pending='[]'
done_list='[]'
while IFS= read -r entry; do
  repo=$(jq -r '.repo' <<<"$entry")

  releases=$(curl -fsS ${auth[@]+"${auth[@]}"} -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${ORG}/${repo}/releases?per_page=30") || {
    echo "::warning::${repo}: unable to fetch releases, skipping"
    continue
  }

  # Newest full release, and a pre-release created after it (if any).
  rel=$(jq -c '[.[] | select(.draft==false and .prerelease==false)][0] // empty' <<<"$releases")
  pre=$(jq -c --arg rel "$(jq -r '.created_at // ""' <<<"${rel:-null}")" \
    '[.[] | select(.draft==false and .prerelease==true and .created_at > $rel)][0] // empty' <<<"$releases")

  if [ -n "$pre" ]; then
    state=pending; src=$pre
  elif [ -n "$rel" ]; then
    state=done; src=$rel
  else
    echo "${repo}: no releases"
    continue
  fi

  tag=$(jq -r '.tag_name' <<<"$src")
  item=$(jq -n --argjson cfg "$(jq -c '.defaults' "$CONFIG")" --argjson e "$entry" --argjson src "$src" \
        --arg org "$ORG" --arg tag "$tag" '
    ($cfg + $e) as $c
    | {
        repo_name: "\($org)/\($c.repo)",
        app_name: "nri-\($c.integration)",
        integration: $c.integration,
        tag: $tag,
        release_url: $src.html_url,
        assets: [$src.assets[].name],
        test_package: $c.test_package,
        publish_schema: $c.publish_schema,
        publish_schema_url: ($c.publish_schema_url | gsub("\\{tag\\}"; $tag)),
        upload_fips_packages: $c.upload_fips_packages,
        publish_schema_fips: $c.publish_schema_fips,
        publish_schema_url_fips: ($c.publish_schema_url_fips | gsub("\\{tag\\}"; $tag)),
        config_verified: ($c.verified // false)
      }')
  echo "${repo}: ${state} ${tag}"
  if [ "$state" = pending ]; then
    pending=$(jq -c --argjson i "$item" '. + [$i]' <<<"$pending")
  else
    done_list=$(jq -c --argjson i "$item" '. + [$i]' <<<"$done_list")
  fi
done < <(jq -c '.repos[]' "$CONFIG")

mkdir -p "$(dirname "$OUT_FILE")"
jq -n --argjson p "$pending" --argjson d "$done_list" '{pending: $p, done: $d}' > "$OUT_FILE"
echo "wrote ${OUT_FILE}: $(jq '.pending|length' "$OUT_FILE") pending, $(jq '.done|length' "$OUT_FILE") done"
