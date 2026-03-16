#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

parse_common_args "$@"
load_release_env
ensure_release_tools
require_env APPLE_APP_ID

APPSTORE_VERSION="${APPSTORE_VERSION:-$(read_build_setting MARKETING_VERSION)}"

run_asc validate --app "$APPLE_APP_ID" --version "$APPSTORE_VERSION" --platform IOS --output table
run_asc validate iap --app "$APPLE_APP_ID" --output table
