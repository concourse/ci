#!/usr/bin/env bash

set -euo pipefail

export PATH=/usr/local/concourse/bin:$PATH

concourse generate-key -t rsa -f /etc/concourse/session_signing_key
concourse generate-key -t ssh -f /etc/concourse/host_key
concourse generate-key -t ssh -f /etc/concourse/worker_key

cp /etc/concourse/worker_key.pub /etc/concourse/authorized_worker_keys

chgrp concourse /etc/concourse/*
chmod g+r /etc/concourse/*

systemctl enable /usr/local/concourse/system/concourse-web.service
systemctl restart concourse-web.service

systemctl enable /usr/local/concourse/system/concourse-worker.service
systemctl restart concourse-worker.service
