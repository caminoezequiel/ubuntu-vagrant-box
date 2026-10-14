#!/bin/bash
# Publishes the built box as a GitHub Release of this repository.
# Usage: ./publish.sh [tag]    (default tag: vYYYY.MM.DD)
set -euo pipefail

cd "$(dirname "$0")"

box=$(ls -t ubuntu-*-server-amd64-virtualbox.box 2>/dev/null | head -n1 || true)
if [[ -z "$box" ]]; then
  echo "No box found. Run 'packer build ubuntu.pkr.hcl' first." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree has uncommitted changes; commit and push them so the release matches the template." >&2
  exit 1
fi

tag=${1:-v$(date +%Y.%m.%d)}
sha=$(sha256sum "$box" | cut -d' ' -f1)
size=$(du -h "$box" | cut -f1)

echo "Publishing $box ($size) as $tag"
# Tag the local HEAD; GitHub rejects it if that commit has not been pushed
gh release create "$tag" "$box" \
  --target "$(git rev-parse HEAD)" \
  --title "$tag" \
  --notes "$(cat <<EOF
Box: \`$box\` ($size)
SHA256: \`$sha\`
Built from commit $(git rev-parse --short HEAD).
EOF
)"

url="https://github.com/$(gh repo view --json nameWithOwner --jq .nameWithOwner)/releases/download/$tag/$box"

cat <<EOF

Done. Use it in a Vagrantfile with:

  config.vm.box = "${box%-amd64-virtualbox.box}"
  config.vm.box_url = "$url"
  config.vm.box_download_checksum_type = "sha256"
  config.vm.box_download_checksum = "$sha"
EOF
