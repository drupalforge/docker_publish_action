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

## Actions

### 1. Platform Build Action (`platform/action.yml`)

**Description:**
Builds a platform Docker image, runs post-build initialization, and outputs the image digest and file hash.

**Inputs:**
- `dockerhub_username` (required): Docker Hub username
- `dockerhub_token` (required): Docker Hub token
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `files_to_hash` (optional): List of files to check for changes (default: `composer.lock`)
- `cached_hash` (optional): Previously cached files hash for comparison
- `build_platform` (optional): Target platform (e.g., `linux/amd64`, `linux/arm64`)

**Outputs:**
- `files_hash`: Hash of the files after build
- `digest`: Image digest for this platform

**Usage Example:**
```yaml
- uses: ./platform
  with:
    dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
    dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
    image_repo: myorg/myimage
    files_to_hash: composer.lock package.json
    cached_hash: ${{ steps.read_cached_hash.outputs.cached_hash }}
    build_platform: linux/amd64
```

### 2. Manifest Action (`manifest/action.yml`)

**Description:**
Creates and pushes a Docker manifest to Docker Hub for a multi-arch image, using digests from the platform builds.

**Inputs:**
- `dockerhub_username` (required): Docker Hub username
- `dockerhub_token` (required): Docker Hub token
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `manifest_digests` (required): JSON map of platform labels to digests

**Usage Example:**
```yaml
- uses: ./manifest
  with:
    dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
    dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
    image_repo: myorg/myimage
    manifest_digests: '{"linux/amd64": "sha256:...", "linux/arm64": "sha256:..."}'
```

## Configuration

If you do not use the reusable workflow, provide the required configuration yourself. For example:

```yaml
steps:
  - uses: drupalforge/docker_publish_action@main
    with:
      dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
```

### Inputs

- `dockerhub_username`: Your Docker Hub username (can be set as a repository variable).
- `dockerhub_token`: Your Docker Hub access token (set as a secret).
- `image_repo`: (optional) Your Docker Hub image repository name. Defaults to the GitHub repository name.
- `files_to_hash`: (optional) A list of files to check for changes. A new image will not be published if none of these files has changed. Defaults to composer.lock if not provided.
- `cached_hash`: (optional) Previously cached files hash for comparison.
- `dp_ai_virtual_key` (optional): An AI virtual key from ai.drupalforge.org (set as a secret).

### Secrets

Set these in your GitHub repository:

- `DOCKERHUB_TOKEN`: Your Docker Hub access token
- `DP_AI_VIRTUAL_KEY` (optional): An AI virtual key from ai.drupalforge.org (set as a secret).

---
**Notes:**
- The action expects the `mysql` service to be defined in your workflow.
- Input and secret names must match between your workflow and the action.
