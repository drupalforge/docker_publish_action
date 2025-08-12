# Drupal Forge Platform Build Action

This action builds and pushes a platform Docker image for a Drupal Forge template, runs post-build initialization, and outputs the image digest and file hash.

## Features
- Multi-arch support (linux/amd64, linux/arm64, etc.)
- Digest-based image pushes
- MySQL service integration for post-build scripts
- Automatic fallback from Docker Buildx cloud builder to local docker-container builder
- File hash-based change detection

## Inputs
- `dockerhub_username` (required): Docker Hub username
- `dockerhub_token` (required): Docker Hub token
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `files_to_hash` (optional): List of files to check for changes (default: `composer.lock`)
- `cached_hash` (optional): Previously cached files hash for comparison
- `build_platform` (optional): Target platform (e.g., `linux/amd64` or `linux/arm64`)
- `dp_ai_virtual_key` (optional): A virtual key for AI integration.

## Outputs
- `hash`: Hash of the files after build
- `skip`: Skip manifest generation
- `image`: Image digest for this platform

## Example Usage
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

## Builder Fallback Logic
This action first tries to use the Docker Buildx cloud builder. If unavailable, it automatically falls back to the local docker-container builder for compatibility.
