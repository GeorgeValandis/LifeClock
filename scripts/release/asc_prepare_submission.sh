#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ENV_ARGS=()
if [[ "${1:-}" == "--env" ]]; then
    [[ $# -ge 2 ]] || {
        printf 'ERROR: --env requires a file path\n' >&2
        exit 1
    }
    ENV_ARGS=(--env "$2")
fi

"$SCRIPT_DIR/asc_sync_metadata.sh" "${ENV_ARGS[@]}"
"$SCRIPT_DIR/asc_configure_listing.sh" "${ENV_ARGS[@]}"
"$SCRIPT_DIR/asc_capture_screenshots.sh" "${ENV_ARGS[@]}"
"$SCRIPT_DIR/asc_upload_screenshots.sh" "${ENV_ARGS[@]}"
"$SCRIPT_DIR/asc_publish_appstore.sh" "${ENV_ARGS[@]}" --build
"$SCRIPT_DIR/asc_validate_submission.sh" "${ENV_ARGS[@]}"
