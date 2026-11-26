# Drupal Forge Manifest Action

This action creates and pushes a Docker manifest for a multi-arch image, using digests from the platform builds.

## Inputs

- `dockerhub_username` (optional): Docker Hub username. If omitted (or if `dockerhub_token` is omitted), the action uses GHCR.
- `dockerhub_token` (optional): Docker Hub token. If omitted (or if `dockerhub_username` is omitted), the action uses GHCR.
- `image_repo` (optional): Docker Hub image repository (defaults to GitHub repository)
- `ghcr_visibility` (optional): Override GHCR package visibility with `public` or `private`. When unset, it defaults to `public` only if the source repository is public and the full image repository matches it case-insensitively; otherwise it defaults to `private`. Ignored for Docker Hub.
- `image_tag` (optional): Primary image tag (defaults to the branch or tag name, in which case `latest` is also published on the default branch)
- `additional_tags` (optional): Space- or newline-separated additional image tags
- `manifest_images` (required): JSON map of platform labels to image digests

Visibility changes are best-effort. GitHub's [documented Packages REST API](https://docs.github.com/en/rest/packages/packages) does not provide an endpoint to change visibility, so this input does not guarantee the package's actual visibility. Check and change package settings manually, especially before publishing sensitive images; GitHub also restricts changing public packages back to private.

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
