# Drupal Forge Manifest Action

This action creates and pushes a Docker manifest for a multi-arch image, using digests from the platform builds.

## Inputs

- `dockerhub_username` (optional): Docker Hub username. If omitted (or if `dockerhub_token` is omitted), the action uses GHCR.
- `dockerhub_token` (optional): Docker Hub token. If omitted (or if `dockerhub_username` is omitted), the action uses GHCR.
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `manifest_images` (required): JSON map of platform labels to image digests

When using GHCR, ensure the calling workflow grants:

```yaml
permissions:
  contents: read
  packages: write
```

## Example Usage

```yaml
- uses: drupalforge/docker_publish_action/manifest@main
  with:
    dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
    dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
    image_repo: myorg/myimage
    manifest_images: '{"linux/amd64": "sha256:...", "linux/arm64": "sha256:..."}'
```
