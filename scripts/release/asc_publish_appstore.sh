#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

BUILD_FIRST="false"
SUBMIT_OVERRIDE=""

parse_common_args "$@"
shifted_args=()
if [[ ${#COMMON_REMAINDER[@]} -gt 0 ]]; then
    shifted_args=("${COMMON_REMAINDER[@]}")
fi
while [[ ${#shifted_args[@]} -gt 0 ]]; do
    case "${shifted_args[0]}" in
        --build)
            BUILD_FIRST="true"
            shifted_args=("${shifted_args[@]:1}")
            ;;
        --submit)
            SUBMIT_OVERRIDE="true"
            shifted_args=("${shifted_args[@]:1}")
            ;;
        *)
            die "Unknown argument: ${shifted_args[0]}"
            ;;
    esac
done

load_release_env
ensure_release_tools
require_env APPLE_APP_ID

if [[ ! -f "$IPA_PATH" ]] || bool_is_true "$BUILD_FIRST"; then
    build_cmd=("$SCRIPT_DIR/asc_build_ipa.sh")
    if [[ -n "$ENV_FILE" ]]; then
        build_cmd+=(--env "$ENV_FILE")
    fi
    "${build_cmd[@]}"
fi

publish_args=(
    publish appstore
    --app "$APPLE_APP_ID"
    --ipa "$IPA_PATH"
    --platform "$APP_PLATFORM"
    --wait
    --timeout "$ASC_WAIT_TIMEOUT"
)

if bool_is_true "${ASC_APPSTORE_SUBMIT:-false}" || [[ "$SUBMIT_OVERRIDE" == "true" ]]; then
    publish_args+=(--submit --confirm)
fi

run_asc "${publish_args[@]}"
