#!/bin/bash
# Publishes every built box as one GitHub Release of this repository.
# Usage: ./publish.sh [tag]    (default tag: vYYYY.MM.DD)
set -euo pipefail
cd "$(dirname "$0")"

shopt -s nullglob
boxes=(*.box)
if (( ${#boxes[@]} == 0 )); then
  echo "No box found. Run 'packer build .' first." >&2
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree has uncommitted changes; commit and push them so the release matches the template." >&2
  exit 1
fi

tag=${1:-v$(date +%Y.%m.%d)}
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
notes="Built from commit $(git rev-parse --short HEAD)."
for box in "${boxes[@]}"; do
  notes+="

\`\`\`ruby
config.vm.box = \"${box%.box}\"
config.vm.box_url = \"https://github.com/$repo/releases/download/$tag/$box\"
config.vm.box_download_checksum_type = \"sha256\"
config.vm.box_download_checksum = \"$(sha256sum "$box" | cut -d' ' -f1)\"
\`\`\`"
done

# Tags the local HEAD; GitHub rejects it if that commit has not been pushed
gh release create "$tag" "${boxes[@]}" --target "$(git rev-parse HEAD)" --title "$tag" --notes "$notes"
echo "$notes"
