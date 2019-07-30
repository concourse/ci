# Concourse: CI

This is where you'll find the all the CI related files for Concourse.

[See this repo in action.](https://ci.concourse-ci.org)

Currently the repo is split into five main sections:

## Deployments 
BOSH deployment related files.

## Dockerfiles
A lot of Dockerfiles are used throughout the Concourse automation. Many of those are in the `/dockerfiles` folder.

## Overrides
Overrides for `docker-compose`.

## Pipelines
Pipeline definitions live here. Some highlights:

#### `concourse.yml`
The crown jewel of this entire repo, [it's how concourse is built, tested, and shipped.](https://ci.concourse-ci.org/teams/main/pipelines/concourse)

#### `prs.yml`
This [pipeline](https://ci.concourse-ci.org/teams/main/pipelines/prs) will automatically test any opened pull requests, and then update the pull request with the results of the tests.

#### `reconfigure.yml`
Whenever any of these pipeline definitions get changed, the [reconfigure pipeline](https://ci.concourse-ci.org/teams/main/pipelines/reconfigure-pipelines) will run to reconfigure the affected pipelines.

## Tasks
Concourse specific task files, these range from testing the front end to building binaries to sending notifications to Slack.
