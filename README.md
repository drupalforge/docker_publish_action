# Drupal Forge Docker Publish Action

## Overview

This project provides GitHub Actions and workflows for building, publishing, and managing multi-arch Docker images for Drupal Forge templates. It supports digest-based pushes, manifest creation, and robust builder fallback logic.

## Features

- Multi-arch Docker image builds (e.g., linux/amd64, linux/arm64)
- Digest-based image pushes and manifest creation
- Automatic fallback from Docker Buildx cloud builder to local docker-container builder
- MySQL service integration for post-build initialization
- File hash-based change detection to skip unnecessary builds
- Modular composite actions for platform builds and manifest publishing

## Usage

To use the reusable workflow, call it from your repository:

```yaml
jobs:
  build-and-push:
    uses: drupalforge/docker_publish_action/.github/workflows/docker-publish.yml@main
    with:
      dockerhub_username: ${{ vars.DOCKERHUB_USERNAME }}
      image_repo: myorg/myimage
      files_to_hash: composer.lock package.json
    secrets:
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
      dp_ai_virtual_key: ${{ secrets.DP_AI_VIRTUAL_KEY }}
```

If your repository is in the [Drupal Forge](https://github.com/drupalforge) organization, there will be a _Docker build and push template_ on the Actions tab that sets this up for you.

## Actions

### Platform Build Action (`action.yml`)

Builds a platform Docker image, runs post-build initialization, and outputs the image digest and file hash. Automatically falls back to local builder if cloud builder is unavailable.

**Inputs:**
- `dockerhub_username` (required): Docker Hub username
- `dockerhub_token` (required): Docker Hub token
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `files_to_hash` (optional): List of files to check for changes (default: `composer.lock`)
- `cached_hash` (optional): Previously cached files hash for comparison
- `build_platform` (optional): Target platform (e.g., `linux/amd64`, `linux/arm64`)

**Outputs:**
- `hash`: Files hash
- `skip`: Skip manifest generation
- `image`: Image digest for this platform

### Manifest Action (`manifest/action.yml`)

Creates and pushes a Docker manifest to Docker Hub for a multi-arch image, using digests from platform builds.

**Inputs:**
- `dockerhub_username` (required): Docker Hub username
- `dockerhub_token` (required): Docker Hub token
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `manifest_images` (required): JSON map of platform labels to image digests

**Outputs:**
- None

## Configuration

- The platform action expects a MySQL service to be available in your workflow.
- All environment variables and build arguments are set in the Dockerfile and actions.
- Input and secret names must match between your workflow and the action.
