#!/usr/bin/env bash

set -euo pipefail

FILE=built-notes/notes.md

cat > $FILE <<EOF

## 📦 Bundled Resource Types

<details>

$(
  awk 'BEGIN {FS = ": "}; {
    url = sprintf("https://github.com/concourse/%s-resource/releases/tag/%s", $1, $2);
    printf "- %s: [%s](%s)\n", $1, $2, url
  }' resource-type-versions/versions.yml
)
</details>
EOF
