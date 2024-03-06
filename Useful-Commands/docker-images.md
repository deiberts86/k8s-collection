# Docker Images (Locally saved images)
- Requirements
  - Docker Daemon or Podman
  - pigz (for better computation and compression)
  - Linux host or Mac

```sh
# Save images to a tarball while using PigZip with anything starting with 'docker.io'
docker save $(docker images --format "{{.Repository}}:{{.Tag}}" | grep '^docker.io') | pigz > images.tar.gz
# Decompress images and log output (usually to air gap)
pigz -dc images.tar.gz | docker load
```

# Push to registry (like Harbor, Artifactory, etc.)
- grepping for image repository starting with `docker.io` and pushing to a harbor registry

```sh
docker login habor.10-7-2-65.sslip.io -u admin
docker images --format "{{.Repository}}:{{.Tag}}" | grep "^docker.io/" | while IFS=':' read -r repo tag; do
    image_name=$(basename $repo)
    new_repo="harbor.10-7-2-65.sslip.io/docker.io/$image_name"
    new_tag="$tag"
    echo "Tagging: $repo:$tag -> $new_repo:$new_tag"
    if docker tag "$repo:$tag" "$new_repo:$new_tag"; then
        echo "Pushing: $new_repo:$new_tag"
        docker push "$new_repo:$new_tag" || echo "Failed to push $new_repo:$new_tag"
    else
        echo "Failed to tag $repo:$tag"
    fi
done
```