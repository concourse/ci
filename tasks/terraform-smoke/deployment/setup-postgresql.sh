#!/usr/bin/env bash

set -euo pipefail

apt-get update
apt-get -y install postgresql

sudo -i -u postgres createuser concourse
sudo -i -u postgres createdb --owner=concourse concourse
