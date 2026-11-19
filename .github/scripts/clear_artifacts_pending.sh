#!/usr/bin/env bash
# Removes the " (artifacts-pending)" suffix from the title of the open pre-releases that are already in S3.
# For every opted-in repo it takes the pre-releases (not drafts) whose title ends with "(artifacts-pending)",
# and when the linux tarball of the tag is in the staging bucket it renames the pre-release to its tag, which
# makes it promotable. "In the bucket" is the same check as scan_publish_state.sh: the main tarball, and the
# fips tarball too for the repos that upload fips packages. Pre-releases that are not there yet are left as they are.
#
# usage: clear_artifacts_pending.sh <repos.json> [dry-run]
# env:   GH_TOKEN        token that can edit the releases of the repos (COREINT_BOT_TOKEN)
#        GITHUB_ORG      default: newrelic
#        STAGING_BUCKET  default: nr-downloads-ohai-staging
#        S3_PREFIX       default: infrastructure_agent_v2/
#        the aws CLI needs staging credentials
set -euo pipefail

CONFIG="${1:?usage: $0 <repos.json> [dry-run]}"
DRY_RUN="${2:-}"
ORG="${GITHUB_ORG:-newrelic}"
BUCKET="${STAGING_BUCKET:-nr-downloads-ohai-staging}"
S3_PREFIX="${S3_PREFIX:-infrastructure_agent_v2/}"
SUFFIX='(artifacts-pending)'

# prints found | missing | unknown
s3_check() { # key
  local err
  if err=$(aws s3api head-object --bucket "$BUCKET" --key "$1" 2>&1 >/dev/null); then echo found
  elif grep -qE "404|Not Found" <<<"$err"; then echo missing
  else echo unknown; fi
}

cleared=0 waiting=0 unknown=0 failed=0
rows=""

while IFS= read -r entry; do
  repo=$(jq -r '.repo' <<<"$entry")
  cfg=$(jq -c --argjson e "$entry" '.defaults + $e' "$CONFIG")
  app=$(jq -r '.app_name // "nri-\(.integration)"' <<<"$cfg")
  arch=$(jq -r '.marker_arch // "amd64"' <<<"$cfg")
  fips=$(jq -r '.upload_fips_packages' <<<"$cfg")

  if ! releases=$(gh api "repos/${ORG}/${repo}/releases?per_page=30"); then
    echo "::warning::${repo}: unable to fetch releases, skipping"
    failed=$((failed + 1))
    continue
  fi

  while IFS= read -r tag; do
    [ -n "$tag" ] || continue
    version="${tag#v}"
    main=$(s3_check "${S3_PREFIX}binaries/linux/${arch}/${app}_linux_${version}_${arch}.tar.gz")
    fips_check=n/a
    [ "$fips" = true ] && fips_check=$(s3_check "${S3_PREFIX}binaries/linux/${arch}/${app}-fips_linux_${version}_${arch}.tar.gz")

    if [ "$main" = found ] && { [ "$fips_check" = found ] || [ "$fips_check" = n/a ]; }; then
      if [ -n "$DRY_RUN" ]; then
        state="would clear"
      elif gh release edit "$tag" --repo "${ORG}/${repo}" --title "$tag" >/dev/null; then
        state="cleared"
      else
        state="edit failed"
      fi
      case "$state" in "edit failed") failed=$((failed + 1)) ;; *) cleared=$((cleared + 1)) ;; esac
    elif [ "$main" = missing ] || [ "$fips_check" = missing ]; then
      state="waiting for S3"; waiting=$((waiting + 1))
    else
      state="S3 unknown"; unknown=$((unknown + 1))
    fi
    echo "${ORG}/${repo}@${tag}: ${state} (main: ${main}, fips: ${fips_check})"
    rows+="| ${ORG}/${repo} | ${tag} | ${state} | ${main} | ${fips_check} |"$'\n'
  done < <(jq -r --arg s "$SUFFIX" \
    '.[] | select(.draft==false and .prerelease==true and ((.name // "") | endswith($s))) | .tag_name' <<<"$releases")
done < <(jq -c '.repos[]' "$CONFIG")

echo "cleared=${cleared} waiting=${waiting} unknown=${unknown} failed=${failed}${DRY_RUN:+ (dry run)}"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Clear artifacts-pending (${BUCKET}/${S3_PREFIX})${DRY_RUN:+ - dry run}"
    echo
    echo "cleared: ${cleared}, waiting for S3: ${waiting}, S3 unknown: ${unknown}, failed: ${failed}"
    echo
    if [ -n "$rows" ]; then
      echo "| Repo | Tag | Result | S3 main | S3 fips |"
      echo "|---|---|---|---|---|"
      printf '%s' "$rows"
    else
      echo "No open pre-release with (artifacts-pending) in the title."
    fi
  } >> "$GITHUB_STEP_SUMMARY"
fi
[ "$failed" -eq 0 ]
