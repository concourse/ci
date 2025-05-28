#!/usr/bin/env bash

set -euo pipefail

migrations_path=atc/db/migration/migrations/
base_dir=concourse-base/$migrations_path
pr_dir=concourse-pr/$migrations_path

if grep skip-migrations-check concourse-pr/.git/resource/title >/dev/null; then
  echo "skipping migration check at PR's request"
  echo "pr title: $(cat concourse-pr/.git/resource/title)"
  exit 0
fi

migrations_on_base=$(mktemp)
find $base_dir -name '[0-9]*' -exec basename {} \; |
  sort > "$migrations_on_base"

actual_pr_migrations=$(mktemp)
find $pr_dir -name '[0-9]*' -exec basename {} \; |
  sort > "$actual_pr_migrations"

unique_to_base=$(comm -23 "$migrations_on_base" "$actual_pr_migrations")
[ -z "$unique_to_base" ] || {
  echo "pr removed migrations:"
  echo "$unique_to_base"
  echo "and prs cannot remove migrations."
  echo "If your PR is removing migrations that are not part of any released version of concourse you can change the title of your PR to include 'skip-migrations-check' in it to skip this check"
  exit 1
}

new_on_pr=$(comm -13 "$migrations_on_base" "$actual_pr_migrations")

expected_pr_migrations=$(mktemp)
sort -n "$migrations_on_base" >> "$expected_pr_migrations"
if [ -n "$new_on_pr" ]; then
  echo "$new_on_pr" >> "$expected_pr_migrations"
fi

# we use `-n` here and not above because comm requires its
# inputs to be *lexically* sorted but our test is about
# numerical sorting.
diff "$expected_pr_migrations" <(sort -n "$actual_pr_migrations") >/dev/null || {
  echo "pr added migrations:"
  echo "$new_on_pr"
  echo "out of order with the base branch."
  echo "new migrations in a pr must be strictly newer than those on the base branch."
  exit 1
}
