#!/usr/bin/env bash

# Load the fixed stable Aurora images stored on the image-archives branch.
set -euo pipefail

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  aarch64) arch=arm64 ;;
  *) echo 'Only x86_64 and aarch64 are supported.' >&2; exit 1 ;;
esac

base_url='https://raw.githubusercontent.com/Taylor000/Aurora-panel/image-archives/images'
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

load_image() {
  local image=$1 parts=$2 expected=$3 archive suffix part manifest
  archive="$workdir/${image}-${arch}.tar.gz"

  for ((part=0; part<parts; part++)); do
    printf -v suffix '%03d' "$part"
    echo "Downloading ${image}-${arch} part ${suffix} ..."
    curl --fail --silent --show-error --location --retry 3 --connect-timeout 20 \
      --output "$workdir/${image}-${arch}.part-${suffix}" \
      "$base_url/${image}-${arch}.tar.gz.part-${suffix}"
  done

  cat "$workdir/${image}-${arch}.part-"* > "$archive"
  printf '%s  %s\n' "$expected" "$archive" | sha256sum --check --status || {
    echo "Checksum failed for ${image}-${arch}." >&2
    return 1
  }

  docker load --input "$archive"
  manifest=$(docker image inspect --format '{{.Os}}/{{.Architecture}}' "aurora-admin-${image}:latest")
  if [[ $manifest != "linux/$arch" ]]; then
    echo "Wrong platform for aurora-admin-${image}:latest: $manifest" >&2
    return 1
  fi
  echo "Loaded aurora-admin-${image}:latest ($manifest)."

  rm -f "$archive" "$workdir/${image}-${arch}.part-"*
}

if [[ $arch == amd64 ]]; then
  load_image backend 3 85088dd6b5357df814431d6d12d3d1d9e0f4d5454fa7470c17795627473ee9e7
  load_image frontend 1 c520adf82c0b7dc31eea356ab3abeee2baca2f72a4be02233ae31f534499fb8b
else
  load_image backend 3 05a8cd08b63f13e8a38e7c557c9e3e1b50280502a75ab15767f131537f54e8bd
  load_image frontend 1 73469f484de1918de282b7df05030730963a2758e7ea0c01251315b2514454eb
fi
