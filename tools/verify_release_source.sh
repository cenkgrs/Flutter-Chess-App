#!/usr/bin/env bash
set -euo pipefail

revision="${1:-}"
if [[ ! "$revision" =~ ^[0-9a-f]{40}$ ]]; then
  echo "usage: bash tools/verify_release_source.sh <40-character public commit>" >&2
  exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "release source check failed: working tree is not clean" >&2
  exit 3
fi

head_commit="$(git rev-parse HEAD)"
source_commit="$(git rev-parse "${revision}^{commit}")"
if [[ "$head_commit" != "$source_commit" ]]; then
  echo "release source check failed: revision does not resolve to HEAD" >&2
  exit 4
fi

source_url="https://github.com/cenkgrs/Flutter-Chess-App/tree/${revision}"
http_status="$(curl --location --silent --show-error --output /dev/null --write-out '%{http_code}' "$source_url")"
if [[ "$http_status" != "200" ]]; then
  echo "release source check failed: public source returned HTTP $http_status" >&2
  exit 5
fi

echo "source verified: $source_url"
echo "build with: --dart-define=ROK_SOURCE_REVISION=$revision"
