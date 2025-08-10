# Drupal Forge Docker Publish Action

## Overview

The Drupal Forge Docker Publish Action is a GitHub Action designed to automate the process of building and pushing Docker images for Drupal Forge templates. This action is particularly useful for repositories in the [Drupal Forge](https://github.com/drupalforge) organization, allowing seamless integration with Docker Hub.

## Features

- Automatically builds and pushes Docker images when called.
- Includes a reusable workflow with environment variables and services for Drupal Forge applications.

## Usage

To use this action in your GitHub workflow, call the reusable [docker-publish](.github/workflows/docker-publish.yml) workflow with the correct inputs and secrets:

```yaml
jobs:
  build-application:
    uses: drupalforge/docker_publish_action/.github/workflows/docker-publish.yml@main
    with:
      dockerhub_username: ${{ vars.DOCKERHUB_USERNAME }}
    secrets:
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
      dp_ai_virtual_key: ${{ secrets.DP_AI_VIRTUAL_KEY }}
```

If your repository is in the [Drupal Forge](https://github.com/drupalforge) organization, there will be a _Docker build and push template_ on the Actions tab that sets this up for you.

## Configuration

If you do not use the reusable workflow, provide the required configuration yourself. For example:

```yaml
steps:
  - uses: drupalforge/docker_publish_action@main
    env:
      WEBSERVER: ${{ job.services.webserver.id }}
    with:
      dockerhub_username: ${{ inputs.dockerhub_username }}
      dockerhub_token: ${{ secrets.dockerhub_token }}
```

### Environment Variables

- `WEBSERVER`: The ID of the running webserver container.  

### Inputs

- `dockerhub_username`: Your Docker Hub username (can be set as a repository variable).
- `dockerhub_token`: Your Docker Hub access token (set as a secret).
- `image_repo`: (optional) Your Docker Hub image repository name. Defaults to the GitHub repository name.
- `dp_ai_virtual_key` (optional): An AI virtual key from ai.drupalforge.org (set as a secret).

### Secrets

Set these in your GitHub repository:

- `DOCKERHUB_TOKEN`: Your Docker Hub access token
- `DP_AI_VIRTUAL_KEY` (optional): An AI virtual key from ai.drupalforge.org (set as a secret).

---
**Notes:**
- The `WEBSERVER` environment variable must be set to the running container ID so the action can execute commands inside the correct container.
- The action expects the `webserver` and `mysql` services to be defined in your workflow.
- Input and secret names must match between your workflow and the action.
