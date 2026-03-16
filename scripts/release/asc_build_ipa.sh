#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

parse_common_args "$@"
load_release_env
ensure_release_tools
create_artifact_dir
write_export_options
log_release_context

archive_args=(
    xcode archive
    --project "$ROOT_DIR/$APP_PROJECT"
    --scheme "$APP_SCHEME"
    --configuration "$APP_CONFIGURATION"
    --clean
    --overwrite
    --archive-path "$ARCHIVE_PATH"
    --xcodebuild-flag=-destination
    --xcodebuild-flag="$XCODE_DESTINATION"
)

export_args=(
    xcode export
    --archive-path "$ARCHIVE_PATH"
    --export-options "$EXPORT_OPTIONS_PATH"
    --ipa-path "$IPA_PATH"
    --overwrite
)

if bool_is_true "${ALLOW_PROVISIONING_UPDATES:-false}"; then
    archive_args+=(--xcodebuild-flag=-allowProvisioningUpdates)
    export_args+=(--xcodebuild-flag=-allowProvisioningUpdates)
fi

run_asc "${archive_args[@]}"
run_asc "${export_args[@]}"

log "IPA ready: $IPA_PATH"
