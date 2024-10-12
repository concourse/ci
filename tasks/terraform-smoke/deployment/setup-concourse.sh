#!/usr/bin/env bash

set -euo pipefail

adduser --system --group concourse
mkdir -p /etc/concourse
chgrp concourse /etc/concourse

tar -zxf /tmp/concourse.tgz -C /usr/local
mkdir -p /usr/local/concourse/system
mkdir -p /etc/systemd/system/concourse-web.service.d
mkdir -p /etc/systemd/system/concourse-worker.service.d
