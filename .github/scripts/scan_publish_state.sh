#!/usr/bin/env bash
# Compares the latest GitHub pre-release / release of every opted-in repo with what is in S3
# and writes one local JSON file with four lists:
#   prerelease.pending  open pre-release (newer than the latest release), not in the staging bucket
#   prerelease.done     open pre-release already in the staging bucket
#   release.pending     latest release, not in the prod bucket
#   release.done        latest release already in the prod bucket
# "In the bucket" = the linux/amd64 tarball <app>_linux_<version>_amd64.tar.gz exists under
# <prefix>binaries/linux/amd64/ (every publish schema uploads it).
# Staging is read with the aws CLI (needs credentials). Prod falls back to the public
# download.newrelic.com when there are no credentials. If a bucket cannot be read the entry
# is kept as pending with s3_check="unknown". Nothing is written to S3 here.
#
# usage: scan_publish_state.sh <repos.json> <queue.json> [all|prerelease|release]
#        (the optional stage limits the scan to the staging half or the prod half)
# env:   GITHUB_TOKEN        optional locally, avoids GitHub rate limits
#        GITHUB_ORG          default: newrelic
#        STAGING_BUCKET      default: nr-downloads-ohai-staging
#        PROD_BUCKET         default: nr-downloads-main
#        S3_PREFIX           default: infrastructure_agent/
#        PROD_PUBLIC_URL     default: https://download.newrelic.com
set -euo pipefail

CONFIG="${1:?usage: $0 <repos.json> <queue.json>}"
OUT_FILE="${2:?usage: $0 <repos.json> <queue.json>}"
STAGE="${3:-all}"
ORG="${GITHUB_ORG:-newrelic}"
STAGING_BUCKET="${STAGING_BUCKET:-nr-downloads-ohai-staging}"
PROD_BUCKET="${PROD_BUCKET:-nr-downloads-main}"
S3_PREFIX="${S3_PREFIX:-infrastructure_agent/}"
PROD_PUBLIC_URL="${PROD_PUBLIC_URL:-https://download.newrelic.com}"

have_aws=false
if command -v aws >/dev/null 2>&1 && { [ -n "${AWS_ACCESS_KEY_ID:-}" ] || [ -n "${AWS_PROFILE:-}" ]; }; then have_aws=true; fi

auth=()
[ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: Bearer ${GITHUB_TOKEN}")

result='{"prerelease":{"pending":[],"done":[]},"release":{"pending":[],"done":[]}}'

# prints found | missing | unknown
s3_check() { # stage bucket key
  local stage="$1" bucket="$2" key="$3" err code
  if $have_aws; then
    if err=$(aws s3api head-object --bucket "$bucket" --key "$key" 2>&1 >/dev/null); then echo found
    elif grep -qE "404|Not Found" <<<"$err"; then echo missing
    else echo unknown; fi
  elif [ "$stage" = release ]; then
    code=$(curl -s -o /dev/null -w '%{http_code}' -I "${PROD_PUBLIC_URL}/${key}" || true)
    case "$code" in 200) echo found ;; 403|404) echo missing ;; *) echo unknown ;; esac
  else
    echo unknown
  fi
}

add() { # stage src entry
  local stage="$1" src="$2" entry="$3" tag item app version s3bucket check bucket
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
  app=$(jq -r '.app_name' <<<"$item")
  version="${tag#v}"
  s3bucket=$STAGING_BUCKET; [ "$stage" = release ] && s3bucket=$PROD_BUCKET
  check=$(s3_check "$stage" "$s3bucket" "${S3_PREFIX}binaries/linux/amd64/${app}_linux_${version}_amd64.tar.gz")
  bucket=pending; [ "$check" = found ] && bucket=done
  item=$(jq -c --arg c "$check" '. + {s3_check: $c}' <<<"$item")
  echo "$(jq -r '.repo_name' <<<"$item")@${tag}: ${stage} ${bucket} (s3: ${check})"
  result=$(jq -c --arg s "$stage" --arg b "$bucket" --argjson i "$item" '.[$s][$b] += [$i]' <<<"$result")
}

while IFS= read -r entry; do
  repo=$(jq -r '.repo' <<<"$entry")

  releases=$(curl -fsS ${auth[@]+"${auth[@]}"} -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${ORG}/${repo}/releases?per_page=30") || {
    echo "::warning::${repo}: unable to fetch releases, skipping"
    continue
  }

  rel=$(jq -c '[.[] | select(.draft==false and .prerelease==false)][0] // empty' <<<"$releases")
  pre=$(jq -c --arg rel "$(jq -r '.created_at // ""' <<<"${rel:-null}")" \
    '[.[] | select(.draft==false and .prerelease==true and .created_at > $rel)][0] // empty' <<<"$releases")

  if [ -n "$pre" ] && [ "$STAGE" != release ]; then add prerelease "$pre" "$entry"; fi
  if [ -n "$rel" ] && [ "$STAGE" != prerelease ]; then add release "$rel" "$entry"; fi
done < <(jq -c '.repos[]' "$CONFIG")

mkdir -p "$(dirname "$OUT_FILE")"
jq '.' <<<"$result" > "$OUT_FILE"
echo "wrote ${OUT_FILE}: $(jq -r '[.prerelease.pending,.prerelease.done,.release.pending,.release.done]|map(length)|"prerelease pending=\(.[0]) done=\(.[1]), release pending=\(.[2]) done=\(.[3])"' "$OUT_FILE")"
