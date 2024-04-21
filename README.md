# Concourse: CI

This is where you'll find the all the CI related files for Concourse.

[See this repo in action.](https://ci.concourse-ci.org)

Currently the repo is split into five main sections:

## Deployments 
Configuration files for BOSH- and terraform-managed deployments used in testing.

## Dockerfiles
A lot of Dockerfiles are used throughout the Concourse automation. Many of those are in the `/dockerfiles` folder.

## Overrides
Overrides for `docker compose`.

## Pipelines
Pipeline definitions live here. Some highlights:

#### `concourse.yml`
The crown jewel of this entire repo, [it's how concourse is built, tested, and shipped.](https://ci.concourse-ci.org/teams/main/pipelines/concourse)

#### `pr.yml`
This [instance group](https://ci.concourse-ci.org/?search=team%3A%22contributor%22%20group%3A%22pr%22) contains one instanced pipeline for each open pull request. `pr.yml` specifies the tests to run for each pull request, and will update the pull request with the results of the tests.

#### `reconfigure.yml`
Whenever any of these pipeline definitions get changed, the [reconfigure pipeline](https://ci.concourse-ci.org/teams/main/pipelines/reconfigure-pipelines) will run to reconfigure the affected pipelines.

This pipeline also tracks the list of pull requests and sets an instanced pipeline for each one.

#### `resources/template.jsonnet`
This is the template that gets used for all of the base resource types that are supported by the Concourse team. Each of those repos follows a similar enough structure that the same template can be used to do the basic PR-testing and shipping tasks for all of them.

The set of resource types for which we automatically test PRs against and ship images to DockerHub is determined by the `RESOURCES` parameter to the [`render-resource-pipeline-templates` task](https://github.com/concourse/ci/blob/master/tasks/render-resource-pipeline-templates.yml).

The source of truth for which resource types are bundled into Concourse is not clearly documented in public right now, but the ultimate source of truth is the set of inputs to the [`resource-types-images` job in the main pipeline](https://ci.concourse-ci.org/teams/main/pipelines/concourse/jobs/resource-types-images).

## Tasks
Concourse specific task files, these range from testing the front end to building binaries to sending notifications to Slack.
