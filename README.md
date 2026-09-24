# Aurora image archive

These are Docker `save` archives of the stable Aurora backend and frontend images for AMD64 and ARM64. Each gzip archive is split into numbered parts smaller than GitHub's 100 MiB per-file limit. Concatenate the parts in numeric order and verify the complete archive against `SHA256SUMS` before loading it with `docker load`.

The source images were downloaded on 2026-09-24 from these fixed Docker Hub index digests:

- Backend: `docker.io/leishi1313/aurora-admin-backend@sha256:782f14029f15d8c319d9a039b3078669a4c833f83da3eca18fc8a59c5a57ac59`
- Frontend: `docker.io/leishi1313/aurora-admin-frontend@sha256:3a09dd59135720e8d345d3c7ccb9c73a4634710d5eb5db9ac260d1c590e50fa4`

The install script on `main` downloads these parts from this repository and loads the images locally. Installation does not contact the source image publisher.
