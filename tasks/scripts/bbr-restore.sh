#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace


# installs the tools that we need
#
install -m 0755 bbr-cli/bbr-*-linux-amd64       /usr/local/bin/bbr
install -m 0755 bosh-cli/bosh-cli-*-linux-amd64 /usr/local/bin/bosh
apt update -y && apt install -y postgresql-client


# gather psql access info
#
export PGPASSWORD=concourse
pg_username=concourse
pg_host=$(bosh instances --dns | grep "db" | awk '{print $4}' | head -n1)


# enable stat_staments (needed as we use in `prod`'s db)
#
psql \
	--host $pg_host \
	-U $pg_username \
	-d atc \
	-c 'CREATE EXTENSION pg_stat_statements;'


# perform the restore against the database leveraging `bbr`
#
tar xvf ./backup-tarball/prod-db-backup.tar
bbr deployment restore --artifact-path=$(find bbr_artifacts/ -name 'concourse-prod*')


# pause all pipelines
#
psql \
	--host $pg_host \
	-U $pg_username \
	-d atc \
	-c 'UPDATE public.pipelines SET paused=TRUE'
