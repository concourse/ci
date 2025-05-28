#!/usr/bin/env sh

set -euo

apk add --quiet --no-progress wget

wget "${CONCOURSE_URL}/api/v1/cli?arch=amd64&platform=linux" -O /fly
chmod +x /fly

set +x

/fly login -t ci -c "$CONCOURSE_URL" -u "$ADMIN_USERNAME" -p "$ADMIN_PASSWORD"

set -x

cd teams/teams

for team in *.yml; do
  /fly -t ci set-team --team-name "${team%.yml}" -c "$team" --non-interactive
done
