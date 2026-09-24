#!/usr/bin/env bash

# Run once after signing in to ghcr.io as Taylor000 with package write access.
# Sources are pinned so a later tag change by the original publisher is ignored.
set -euo pipefail

docker buildx imagetools create \
  --tag ghcr.io/taylor000/aurora-admin-backend:latest \
  docker.io/leishi1313/aurora-admin-backend@sha256:782f14029f15d8c319d9a039b3078669a4c833f83da3eca18fc8a59c5a57ac59

docker buildx imagetools create \
  --tag ghcr.io/taylor000/aurora-admin-frontend:latest \
  docker.io/leishi1313/aurora-admin-frontend@sha256:3a09dd59135720e8d345d3c7ccb9c73a4634710d5eb5db9ac260d1c590e50fa4

docker buildx imagetools create \
  --tag ghcr.io/taylor000/aurora-admin-backend:dev-latest \
  docker.io/leishi1313/aurora-admin-backend@sha256:0248f18442abe878ccab23c4525d7b1d88ebf8b559aeda1788cbb07cd467c2cf

docker buildx imagetools create \
  --tag ghcr.io/taylor000/aurora-admin-frontend:dev-latest \
  docker.io/leishi1313/aurora-admin-frontend@sha256:f22b447e3be7f4fff886a37f3dc425147ace18491b5f2f53706e188fcec1853f

for image in backend frontend; do
  for tag in latest dev-latest; do
    manifest=$(docker buildx imagetools inspect "ghcr.io/taylor000/aurora-admin-${image}:${tag}")
    grep -q 'linux/amd64' <<< "$manifest"
    grep -q 'linux/arm64' <<< "$manifest"
  done
done

echo 'All four Aurora image tags are mirrored for amd64 and arm64.'
