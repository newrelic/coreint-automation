#!/usr/bin/env bash
# Scans the opted-in repos for a pre-release newer than the latest release and
# writes one queue entry (JSON) per repo into <out_dir>.
#
# usage: scan_prereleases.sh <repos.json> <out_dir>
# env:   GITHUB_TOKEN (optional locally, avoids rate limits), GITHUB_ORG (default: newrelic)
set -euo pipefail

CONFIG="${1:?usage: $0 <repos.json> <out_dir>}"
OUT_DIR="${2:?usage: $0 <repos.json> <out_dir>}"
ORG="${GITHUB_ORG:-newrelic}"
mkdir -p "$OUT_DIR"

auth=()
[ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

queued=0
while IFS= read -r entry; do
  repo=$(jq -r '.repo' <<<"$entry")

  releases=$(curl -fsS ${auth[@]+"${auth[@]}"} -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${ORG}/${repo}/releases?per_page=30") || {
    echo "::warning::${repo}: unable to fetch releases, skipping"
    continue
  }

  # Releases come back newest first. Only a pre-release created after the latest
  # full release is waiting for promotion.
  pre=$(jq -c '[.[] | select(.draft==false)] | (map(select(.prerelease==false))[0].created_at // "") as $rel
    | map(select(.prerelease==true and .created_at > $rel))[0] // empty' <<<"$releases")

  if [ -z "$pre" ]; then
    echo "${repo}: no pending pre-release"
    continue
  fi

  tag=$(jq -r '.tag_name' <<<"$pre")
  jq -n --argjson cfg "$(jq -c '.defaults' "$CONFIG")" --argjson e "$entry" --argjson pre "$pre" \
        --arg org "$ORG" --arg tag "$tag" '
    ($cfg + $e) as $c
    | {
        repo_name: "\($org)/\($c.repo)",
        app_name: "nri-\($c.integration)",
        integration: $c.integration,
        tag: $tag,
        release_url: $pre.html_url,
        assets: [$pre.assets[].name],
        test_package: $c.test_package,
        publish_schema: $c.publish_schema,
        publish_schema_url: ($c.publish_schema_url | gsub("\\{tag\\}"; $tag)),
        upload_fips_packages: $c.upload_fips_packages,
        publish_schema_fips: $c.publish_schema_fips,
        publish_schema_url_fips: ($c.publish_schema_url_fips | gsub("\\{tag\\}"; $tag)),
        config_verified: ($c.verified // false)
      }' > "${OUT_DIR}/${repo}-${tag}.json"
  echo "${repo}: queued ${tag}"
  queued=$((queued + 1))
done < <(jq -c '.repos[]' "$CONFIG")

echo "queued ${queued} entr$([ "$queued" -eq 1 ] && echo y || echo ies) in ${OUT_DIR}"
