#!/usr/bin/env bash

set -euo pipefail

.buildkite/scripts/bootstrap.sh

echo "--- Build API Docs"
node --max-old-space-size=12000 scripts/build_api_docs

if [[ "${PUBLISH_API_DOCS_CHANGES:-}" == "true" ]]; then
  echo "--- Publish API Docs"

  git config --global user.name kibanamachine
  git config --global user.email '42973632+kibanamachine@users.noreply.github.com'

  branch="api_docs_$(date +%F_%H-%M-%S)"
  git checkout -b "$branch"
  git add ./*.docnav.json
  git add api_docs
  git commit -m "[api-docs] Daily api_docs build"

  git push origin "$branch"

  prUrl=$(gh pr create --repo elastic/kibana --base main --head "$branch" --title "[test/api-docs] $(date +%F) Daily api_docs build" --body "Generated by $BUILDKITE_BUILD_URL" --label "release_note:skip" --label "docs")
  echo "Opened PR: $prUrl"
  gh pr merge --repo elastic/kibana --auto --squash "$prUrl"

  GH_TOKEN="$KIBANA_CI_GITHUB_TOKEN" gh pr review --repo elastic/kibana --approve -b "Automated review from $BUILDKITE_BUILD_URL" "$prUrl"
fi
