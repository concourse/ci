#!/usr/bin/env bash

LAST_COMMIT_SHA=$(cat repo/.git/ref)
RELEASE_VERSION=$(cat version/version)

FILE=built-notes/notes.md

chmod +x release-me/releaseme
./release-me/releaseme generate \
  --github-token=$GITHUB_TOKEN \
  --github-owner=$GITHUB_OWNER \
  --github-repo=$GITHUB_REPO \
  --github-branch=$GITHUB_BRANCH \
  --last-commit-SHA=$LAST_COMMIT_SHA \
  --release-version=$RELEASE_VERSION \
  --ignore-authors=dependabot \
  > $FILE

if [ -f resource-type-versions/versions.yml ]; then
  cat >> $FILE <<EOF

## 📦 Bundled resource types

<details>

$(
  awk 'BEGIN {FS = ": "}; {
    url = sprintf("https://github.com/concourse/%s-resource/releases/tag/%s", $1, $2);
    printf "- %s: [%s](%s)\n", $1, $2, url
  }' resource-type-versions/versions.yml
)
</details>
EOF
fi
