#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

parse_common_args "$@"
load_release_env
ensure_release_tools
require_cmd jq
require_env APPLE_APP_ID

APPSTORE_METADATA_SOURCE_DIR="${APPSTORE_METADATA_SOURCE_DIR:-appstore/metadata}"
APPSTORE_PRIMARY_LOCALE="${APPSTORE_PRIMARY_LOCALE:-en-US}"
APPSTORE_VERSION="${APPSTORE_VERSION:-$(read_build_setting MARKETING_VERSION)}"
APPSTORE_METADATA_WORK_DIR="${APPSTORE_METADATA_WORK_DIR:-.asc/metadata-push}"

SOURCE_DIR="$ROOT_DIR/$APPSTORE_METADATA_SOURCE_DIR"
WORK_DIR="$ROOT_DIR/$APPSTORE_METADATA_WORK_DIR"

[[ -f "$SOURCE_DIR/app-info/$APPSTORE_PRIMARY_LOCALE.json" ]] \
    || die "Missing app info metadata: $SOURCE_DIR/app-info/$APPSTORE_PRIMARY_LOCALE.json"
[[ -f "$SOURCE_DIR/version/$APPSTORE_PRIMARY_LOCALE.json" ]] \
    || die "Missing version metadata: $SOURCE_DIR/version/$APPSTORE_PRIMARY_LOCALE.json"

mkdir -p "$WORK_DIR/app-info" "$WORK_DIR/version/$APPSTORE_VERSION"
cp "$SOURCE_DIR/app-info/$APPSTORE_PRIMARY_LOCALE.json" "$WORK_DIR/app-info/$APPSTORE_PRIMARY_LOCALE.json"
cp "$SOURCE_DIR/version/$APPSTORE_PRIMARY_LOCALE.json" "$WORK_DIR/version/$APPSTORE_VERSION/$APPSTORE_PRIMARY_LOCALE.json"

run_asc metadata validate --dir "$WORK_DIR"
run_asc metadata push --app "$APPLE_APP_ID" --version "$APPSTORE_VERSION" --platform IOS --dir "$WORK_DIR"
