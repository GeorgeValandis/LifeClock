#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

parse_common_args "$@"
load_release_env
ensure_release_tools
require_env APPLE_ISSUER_ID APPLE_KEY_ID APPLE_PRIVATE_KEY_PATH

[[ -f "$APPLE_PRIVATE_KEY_PATH" ]] || die "Private key not found: $APPLE_PRIVATE_KEY_PATH"

log "Saving App Store Connect credentials in Keychain as profile: $ASC_PROFILE_NAME"
asc auth login \
    --name "$ASC_PROFILE_NAME" \
    --key-id "$APPLE_KEY_ID" \
    --issuer-id "$APPLE_ISSUER_ID" \
    --private-key "$APPLE_PRIVATE_KEY_PATH" \
    --network

run_asc auth status
