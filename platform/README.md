# Drupal Forge Platform Build Action

This action builds and pushes a platform Docker image for a Drupal Forge template, runs post-build initialization, and outputs the image digest and file hash.

## Inputs
- `dockerhub_username` (required): Docker Hub username
- `dockerhub_token` (required): Docker Hub token
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `files_to_hash` (optional): List of files to check for changes (default: `composer.lock`)
- `cached_hash` (optional): Previously cached files hash for comparison
- `build_platform` (optional): Target platform (e.g., `linux/amd64`, `linux/arm64`)

## Outputs
- `files_hash`: Hash of the files after build
- `digest`: Image digest for this platform

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
