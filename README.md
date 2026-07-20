# Drupal Forge Docker Publish Action

## Overview

This project provides GitHub Actions and workflows for building, publishing, and managing multi-arch Docker images for Drupal Forge templates. It supports Docker Hub and GHCR publishing, digest-based pushes, manifest creation, and robust builder fallback logic.

## Features

- Multi-arch Docker image builds (e.g., linux/amd64, linux/arm64)
- Digest-based image pushes and manifest creation
- Automatic fallback from Docker Buildx cloud builder to local docker-container builder
- MySQL service integration for post-build initialization
- File hash-based change detection to skip unnecessary builds
- Modular composite actions for platform builds and manifest publishing
- Configurable base image
- Extendable Dockerfile via `.devpanel/Dockerfile` or a custom path
- Automated linting for Dockerfiles, YAML, and Markdown

## Reusable Workflow Usage

This section applies to the reusable workflow at `.github/workflows/docker-publish.yml`.

The reusable workflow chooses the target registry automatically:

- If either `dockerhub_username` or `dockerhub_token` is missing, it uses GHCR.
- If both Docker Hub credentials are provided and the GitHub repo is public, it uses Docker Hub.
- If both Docker Hub credentials are provided and the GitHub repo is private, it uses Docker Hub only when the target Docker Hub repository already exists; otherwise it falls back to GHCR.

### Registry and permissions matrix

| Runtime condition | Selected registry | Required caller job permissions |
| --- | --- | --- |
| Missing `dockerhub_username` or `dockerhub_token` | GHCR | `contents: read`, `packages: write` |
| Public repo + Docker Hub credentials present | Docker Hub | None beyond your default workflow permissions |
| Private repo + Docker Hub credentials present + Docker Hub repo exists | Docker Hub | None beyond your default workflow permissions |
| Private repo + Docker Hub credentials present + Docker Hub repo does not exist | GHCR (fallback) | `contents: read`, `packages: write` |

### Docker Hub path

Use this when you want to publish to Docker Hub:

```yaml
jobs:
  build-and-push:
    uses: drupalforge/docker_publish_action/.github/workflows/docker-publish.yml@main
    with:
      dockerhub_username: ${{ vars.DOCKERHUB_USERNAME }}
      image_repo: myorg/myimage
      files_to_hash: composer.lock package.json
      base_image: devpanel/php:8.3-base-rc
    secrets:
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
      dp_ai_virtual_key: ${{ secrets.DP_AI_VIRTUAL_KEY }}
      composer_auth: ${{ secrets.COMPOSER_AUTH }}
```

### GHCR path

Use this when you want to publish to GHCR. This path is selected when Docker Hub credentials are missing, or when a private GitHub repository does not have a pre-existing Docker Hub repository. The caller must grant package permissions:

```yaml
jobs:
  build-and-push:
    permissions:
      contents: read
      packages: write
    uses: drupalforge/docker_publish_action/.github/workflows/docker-publish.yml@main
    with:
      image_repo: myorg/myimage
      files_to_hash: composer.lock package.json
      base_image: devpanel/php:8.3-base-rc
    secrets:
      dp_ai_virtual_key: ${{ secrets.DP_AI_VIRTUAL_KEY }}
      composer_auth: ${{ secrets.COMPOSER_AUTH }}
```

Keep this `permissions` block on the calling job whenever GHCR is a possible runtime outcome, including private repositories where Docker Hub credentials are present but the target Docker Hub repository does not already exist.

If your repository is in the [Drupal Forge](https://github.com/drupalforge) organization, there will be a _Docker build and push template_ on the Actions tab that sets this up for you.

## Reusable Workflow Troubleshooting

### Runtime GHCR push/login failures

If GHCR push/login fails:

- Confirm the caller grants `packages: write` and `contents: read`.
- Confirm the run actually resolved to GHCR (credentials are missing, or private-repo Docker Hub existence check did not resolve to an existing repo).
- Confirm `image_repo` is set as `owner/repo` style input (the action applies the `ghcr.io/` prefix automatically).

## Composite Actions (Standalone Usage)

This section applies when you invoke the composite actions directly in your own workflow, rather than using the reusable workflow.

For detailed standalone manifest usage notes, see `manifest/README.md`.

### Platform Build Action (`action.yml`)

Builds a platform Docker image, runs post-build initialization, and outputs the image digest and file hash. Automatically falls back to local builder if cloud builder setup or cloud build execution fails.

**Inputs:**

- `dockerhub_username` (optional): Docker Hub username. If omitted (or if `dockerhub_token` is omitted), the action uses GHCR.
- `dockerhub_token` (optional): Docker Hub token. If omitted (or if `dockerhub_username` is omitted), the action uses GHCR.
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `files_to_hash` (optional): List of files to check for changes (default: `composer.lock`)
- `cached_hash` (optional): Previously cached files hash for comparison
- `build_platform` (optional): Target platform (e.g., `linux/amd64`, `linux/arm64`)
- `base_image` (optional): Base Docker image to build from (default: `devpanel/php:8.3-base-rc`)
- `dockerfile_path` (optional): Path to a Dockerfile (relative to the app root) whose instructions are appended to the base Dockerfile. Multi-stage builds with additional `FROM` stages are supported. The file must not include a `# syntax=` directive (which must appear on line 1 of a Dockerfile). If omitted and `.devpanel/Dockerfile` exists in the app root, that file is appended automatically.
- `composer_auth` (optional): Composer auth JSON for repositories that need private package access during init steps.

**Outputs:**

- `hash`: Files hash
- `skip`: Skip manifest generation
- `image`: Image digest for this platform

### Manifest Action (`manifest/action.yml`)

Creates and pushes a multi-arch Docker manifest using digests from platform builds. Uses Docker Hub when Docker Hub credentials are provided, otherwise uses GHCR.

**Inputs:**

- `dockerhub_username` (optional): Docker Hub username. If omitted (or if `dockerhub_token` is omitted), the action uses GHCR.
- `dockerhub_token` (optional): Docker Hub token. If omitted (or if `dockerhub_username` is omitted), the action uses GHCR.
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `manifest_images` (required): JSON map of platform labels to image digests

**Outputs:**

- None

## Configuration

- The platform action expects a MySQL service to be available in your workflow.
- All environment variables and build arguments are set in the Dockerfile and actions.
- Input and secret names must match between your workflow and the action.

## Lint Workflow

The repository includes a lint workflow (`.github/workflows/lint.yml`) that runs automatically on pushes to the `main` and `develop` branches, and on all pull requests, to validate:

- **Dockerfile** — checked with [Hadolint](https://github.com/hadolint/hadolint). Configuration is in `.hadolint.yaml`.
- **YAML files** — checked with [yamllint](https://yamllint.readthedocs.io/).
- **Markdown files** — checked with [markdownlint](https://github.com/DavidAnson/markdownlint). Configuration is in `.markdownlint.yaml`.
