# Drupal Forge Docker Publish Action

## Overview

This project provides GitHub Actions and workflows for building, publishing, and managing multi-arch Docker images for Drupal Forge templates. It supports Docker Hub and GHCR publishing, digest-based pushes, manifest creation, and robust builder fallback logic.

## Features

- Multi-arch Docker image builds (e.g., linux/amd64, linux/arm64)
- Digest-based image pushes and manifest creation
- Automatic fallback from Docker Buildx cloud builder to local docker-container builder
- MySQL service integration for post-build initialization
- File hash-based change detection to skip unnecessary builds
- Early workflow-run cancellation when hash is unchanged to stop parallel matrix jobs
- Modular composite actions for platform builds and manifest publishing
- Configurable base image
- Extendable Dockerfile via `.devpanel/Dockerfile` or a custom path
- Automated linting for Dockerfiles, YAML, and Markdown

## Reusable Workflow Usage

This section applies to the reusable workflow at `.github/workflows/docker-publish.yml`.

The workflow builds `linux/amd64` on `ubuntu-26.04` and `linux/arm64` on the native `ubuntu-26.04-arm` runner, avoiding QEMU emulation for ARM builds.

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
    permissions:
      actions: write  # Optional: only needed when cancel_run_on_skip is enabled (the default behavior)
      contents: read
    uses: drupalforge/docker_publish_action/.github/workflows/docker-publish.yml@main
    with:
      dockerhub_username: ${{ vars.DOCKERHUB_USERNAME }}
      image_repo: myorg/myimage
      files_to_hash: composer.lock package.json
      base_image: devpanel/php:8.5-base
    secrets:
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
      init_env: |
        {
          "OPENAI_KEY": ${{ toJSON(secrets.OPENAI_KEY) }},
          "SERVICE_TOKEN": ${{ toJSON(secrets.SERVICE_TOKEN) }}
        }
```

### GHCR path

Use this when you want to publish to GHCR. This path is selected when Docker Hub credentials are missing, or when a private GitHub repository does not have a pre-existing Docker Hub repository. The caller must grant package permissions:

```yaml
jobs:
  build-and-push:
    permissions:
      actions: write  # Optional: only needed when cancel_run_on_skip is enabled (the default behavior)
      contents: read
      packages: write
    uses: drupalforge/docker_publish_action/.github/workflows/docker-publish.yml@main
    with:
      image_repo: myorg/myimage
      files_to_hash: composer.lock package.json
      base_image: devpanel/php:8.5-base
    secrets:
      init_env: |
        {
          "OPENAI_KEY": ${{ toJSON(secrets.OPENAI_KEY) }},
          "SERVICE_TOKEN": ${{ toJSON(secrets.SERVICE_TOKEN) }}
        }
```

Keep this `permissions` block on the calling job whenever GHCR is a possible runtime outcome, including private repositories where Docker Hub credentials are present but the target Docker Hub repository does not already exist. The `actions: write` permission is required only for the optional early-cancel behavior when a hash match is detected.

If your repository is in the [Drupal Forge](https://github.com/drupalforge) organization, there will be a _Docker build and push template_ on the Actions tab that sets this up for you.

### Initialization environment variables

Store values as individual repository secrets, such as `OPENAI_KEY` and `SERVICE_TOKEN`, and assemble the JSON object in the calling workflow. Each secret can then be updated independently, without maintaining a combined `INIT_ENV` secret:

```yaml
jobs:
  build-and-push:
    permissions:
      contents: read
      packages: write
    uses: drupalforge/docker_publish_action/.github/workflows/docker-publish.yml@main
    secrets:
      init_env: |
        {
          "OPENAI_KEY": ${{ toJSON(secrets.OPENAI_KEY) }},
          "SERVICE_TOKEN": ${{ toJSON(secrets.SERVICE_TOKEN) }},
          "SERVICE_URL": "https://example.com"
        }
```

Apply `toJSON` to each secret value, without adding quotes around the expression. This safely escapes quotes, backslashes, and other JSON characters, including those in a single-line Composer auth JSON secret. Include only the secrets needed for initialization; do not pass `toJSON(secrets)`, which would forward unrelated credentials. A missing secret evaluates to an empty string, so omit its entry if you want to use a legacy fallback instead.

For standalone composite action usage, pass it as an input instead:

```yaml
- uses: drupalforge/docker_publish_action@main
  with:
    init_env: |
      {
        "OPENAI_KEY": ${{ toJSON(secrets.OPENAI_KEY) }},
        "SERVICE_TOKEN": ${{ toJSON(secrets.SERVICE_TOKEN) }}
      }
```

An existing combined JSON secret is still supported via `init_env: ${{ secrets.INIT_ENV }}`. Pass it directly, without `toJSON`, to avoid encoding the entire object as a JSON string.

Omitting `init_env`, an empty input, and `{}` all add no variables. Otherwise, the input must be a single JSON object with string values and variable names matching `[A-Za-z_][A-Za-z0-9_]*`. Empty strings are allowed; CR, LF (multiline values), and NUL characters are not supported by Docker's environment-file format and are rejected. Invalid input fails without printing its contents.

Values are masked in subsequent workflow logs and written to a temporary permission-restricted environment file, removed when the initialization step exits, including on failure. They are passed only to the `docker exec` command running `.devpanel/init.sh`, not to Docker builds, container startup, later dump commands, or the published image's environment. Caller variables override the default database variables for initialization.

The `dp_ai_virtual_key` and `composer_auth` workflow secrets and action inputs are deprecated but retained for compatibility. Reference the existing individual secrets in `init_env` under `DP_AI_VIRTUAL_KEY` and `COMPOSER_AUTH`, respectively. Each key present in `init_env` takes precedence over its legacy input, including when its value is an empty string. If a key is absent, its legacy input remains the fallback. Keep the `COMPOSER_AUTH` secret as single-line JSON:

```yaml
secrets:
  init_env: |
    {
      "DP_AI_VIRTUAL_KEY": ${{ toJSON(secrets.DP_AI_VIRTUAL_KEY) }},
      "COMPOSER_AUTH": ${{ toJSON(secrets.COMPOSER_AUTH) }}
    }
```

Initialization scripts must not print transformed secrets or write secrets into files: filesystem changes made during initialization are included in the published image.

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
- `base_image` (optional): Base Docker image to build from (default: `devpanel/php:8.3-base`)
- `prepend_dockerfile_path` (optional): Path to a Dockerfile (relative to the app root) whose instructions are prepended before the base Dockerfile. Multi-stage builds with additional `FROM` stages are supported here. The file must not include a `# syntax=` directive. If omitted and `.devpanel/prepend.Dockerfile` exists in the app root, that file is prepended automatically.
- `dockerfile_path` (optional): Path to a Dockerfile (relative to the app root) whose instructions are appended to the base Dockerfile. This file can `COPY --from` stages defined in `prepend_dockerfile_path`. The file must not include a `# syntax=` directive (which must appear on line 1 of a Dockerfile). If omitted and `.devpanel/Dockerfile` exists in the app root, that file is appended automatically.
- `dp_ai_virtual_key` (optional, deprecated): DevPanel AI Virtual Key fallback. Use `DP_AI_VIRTUAL_KEY` in `init_env` instead.
- `composer_auth` (optional, deprecated): Composer auth JSON fallback for private package access. Use `COMPOSER_AUTH` in `init_env` instead.
- `init_env` (optional): JSON object of string environment variables available only to `.devpanel/init.sh` at runtime. See [Initialization environment variables](#initialization-environment-variables).
- `cancel_run_on_skip` (optional): Cancel the workflow run when the hash is unchanged (`skip=true`). Enabled unless set to `false`. Requires `actions: write` on `GITHUB_TOKEN` when enabled.

**Outputs:**

- `hash`: Files hash
- `skip`: Skip manifest generation
- `image`: Image digest for this platform

When `cached_hash` matches the computed `hash`, the action sets `skip=true`. Unless `cancel_run_on_skip` is set to `false`, the action also attempts to cancel the current workflow run to stop sibling jobs in a matrix. For cancellation to succeed, the caller must grant `actions: write` to `GITHUB_TOKEN`. If that permission is missing, or if the runner does not provide the `gh` CLI, the action logs a warning and continues without failing the workflow. Set `cancel_run_on_skip: false` to opt out of run-wide cancellation.

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
- Build arguments and default environment variables are set in the Dockerfile and actions; caller-defined initialization variables use `init_env`.
- Input and secret names must match between your workflow and the action.

## Lint Workflow

The repository includes a lint workflow (`.github/workflows/lint.yml`) that runs automatically on pushes to the `main` and `develop` branches, and on all pull requests, to validate:

- **Dockerfile** — checked with [Hadolint](https://github.com/hadolint/hadolint). Configuration is in `.hadolint.yaml`.
- **YAML files** — checked with [yamllint](https://yamllint.readthedocs.io/).
- **Markdown files** — checked with [markdownlint](https://github.com/DavidAnson/markdownlint). Configuration is in `.markdownlint.yaml`.
