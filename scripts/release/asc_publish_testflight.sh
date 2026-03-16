#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

BUILD_FIRST="false"

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
        *)
            die "Unknown argument: ${shifted_args[0]}"
            ;;
    esac
done

load_release_env
ensure_release_tools
require_env APPLE_APP_ID ASC_TESTFLIGHT_GROUPS

if [[ ! -f "$IPA_PATH" ]] || bool_is_true "$BUILD_FIRST"; then
    build_cmd=("$SCRIPT_DIR/asc_build_ipa.sh")
    if [[ -n "$ENV_FILE" ]]; then
        build_cmd+=(--env "$ENV_FILE")
    fi
    "${build_cmd[@]}"
fi

publish_args=(
    publish testflight
    --app "$APPLE_APP_ID"
    --ipa "$IPA_PATH"
    --group "$ASC_TESTFLIGHT_GROUPS"
    --platform "$APP_PLATFORM"
    --wait
    --timeout "$ASC_WAIT_TIMEOUT"
)

if [[ -n "${ASC_TESTFLIGHT_NOTES:-}" ]]; then
    publish_args+=(--test-notes "$ASC_TESTFLIGHT_NOTES")
fi

if [[ -n "${ASC_TESTFLIGHT_LOCALE:-}" ]]; then
    publish_args+=(--locale "$ASC_TESTFLIGHT_LOCALE")
fi

run_asc "${publish_args[@]}"
