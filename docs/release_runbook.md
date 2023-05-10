# Release
The goal of this document is to describe the release process on repos that implements the [trigger_prerelease](../.github/workflows/trigger_prerelease.yaml) workflow.

A list of repos using this workflow can be inspected [here](https://github.com/newrelic/coreint-automation/network/dependents).

## Pre-Releases

**Important Note**: Creating releases from the GH interface is not longer the recommended way. In case there is a strong reason to do it please follow the [Emergency/By-pass Release](#emergencyby-pass-release)

To have some context before releasing, the following steps of the process are automated by the [release toolkit](https://github.com/newrelic/release-toolkit#readme):
* `CHANGELOG.md` update: A new entry will be added based on unreleased entries and dependencies commits. [Details](https://github.com/newrelic/release-toolkit#render-markdown-and-update-markdown).
* GH Pre-Release creation: A GH Pre-Release is generated with Notes taken from the changelog.
* Release version calculation: Is calculated based on the Changelog entries. [Details](https://github.com/newrelic/release-toolkit#next-version).

You can check locally how the the outcomes of the release toolkit will look like by running [these steps](https://github.com/newrelic/release-toolkit/tree/main/contrib/ohi-release-notes#use-script-locally), or the make target `rt-update-changelog` if exist in the repo.

There are two ways to create pre-releases:

- Automatically: Scheduled weekly.
- Manually: Triggered from the GH Actions interface (workflow dispatch)

After the GH pre-release is created by `trigger_prerelease` workflow another workflow will be triggered on this event and will build and push the artifacts depending on the repo.

### Held releases (manual and automatic)

There are two mechanism to stop the release creation:
* Global block: This will stop any automatic release based on the [trigger_prerelease](../.github/workflows/trigger_prerelease.yaml) workflow, to be use for reasons like a code freeze. Follow [this instructions](../README.md/#automatic-releases-block-endpoint) to enable/disable this.
* Local held: By adding the `## Held` header in `CHANGELOG.md`. [Details](https://github.com/newrelic/release-toolkit#automated-releasing).

### Emergency/By-pass Release

If there is an specific strong reason not to follow any of the previously mentioned Pre-Release flows, it is possible to create a Pre-Release from the GH interface and that will trigger the pre-release pipeline.

Important care must be taken not to leave any entry under the `Unreleased` section of the `CHANGELOG.md` since this flow does not update that file and future automated releases could pick this entries that have been already been released creating misleading release notes.


## Release (manual only)

Once a pre-release has been generated successfully it can be promoted to Release by editing it from the GH interface, and un-checking the `pre-release` box. This will trigger a release workflow waiting on this event, which will build or push the release artifacts depending on the repo.
