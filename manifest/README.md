# Drupal Forge Manifest Action

This action creates and pushes a Docker manifest to Docker Hub for a multi-arch image, using digests from the platform builds.

## Inputs
- `dockerhub_username` (required): Docker Hub username
- `dockerhub_token` (required): Docker Hub token
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `manifest_images` (required): JSON map of platform labels to image digests

## Example Usage
```yaml
- uses: drupalforge/docker_publish_action/manifest@main
  with:
    dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
    dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
    image_repo: myorg/myimage
    manifest_images: '{"linux/amd64": "sha256:...", "linux/arm64": "sha256:..."}'
```
