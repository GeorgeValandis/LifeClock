#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat <<'USAGE'
Usage: run_hybrid_setup.sh [--env <file>] [--skip-asc] [--skip-revenuecat] [--skip-xcode]

Runs Option B (hybrid) setup in sequence:
  1) App Store Connect IAP upsert
  2) RevenueCat sync (app/product/entitlement/offering/package)
  3) Xcode project key patch
USAGE
}

ENV_FILE=".env.hybrid"
SKIP_ASC=0
SKIP_RC=0
SKIP_XCODE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            [[ $# -ge 2 ]] || die "--env requires a file path"
            ENV_FILE="$2"
            shift 2
            ;;
        --skip-asc)
            SKIP_ASC=1
            shift
            ;;
        --skip-revenuecat)
            SKIP_RC=1
            shift
            ;;
        --skip-xcode)
            SKIP_XCODE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

load_env_file "$ENV_FILE"
require_cmd jq

asc_summary='null'
rc_summary='null'
xcode_summary='null'

if (( SKIP_ASC == 0 )); then
    log "Step 1/3: App Store Connect"
    asc_summary="$("$SCRIPT_DIR/asc_iap_upsert.sh" --env "$ENV_FILE")"
fi

if (( SKIP_RC == 0 )); then
    log "Step 2/3: RevenueCat"
    rc_summary="$("$SCRIPT_DIR/revenuecat_sync.sh" --env "$ENV_FILE")"
fi

if (( SKIP_XCODE == 0 )); then
    log "Step 3/3: Xcode project patch"
    rc_public_sdk_key=""
    if [[ "$rc_summary" != "null" ]]; then
        rc_public_sdk_key="$(jq -r '.rc_public_sdk_key // empty' <<<"$rc_summary")"
    fi

    if [[ -n "$rc_public_sdk_key" ]]; then
        xcode_summary="$("$SCRIPT_DIR/xcode_set_revenuecat_key.sh" --env "$ENV_FILE" --key "$rc_public_sdk_key")"
    else
        xcode_summary="$("$SCRIPT_DIR/xcode_set_revenuecat_key.sh" --env "$ENV_FILE")"
    fi
fi

jq -cn \
    --argjson asc "$asc_summary" \
    --argjson revenuecat "$rc_summary" \
    --argjson xcode "$xcode_summary" \
    '{
        app_store_connect: $asc,
        revenuecat: $revenuecat,
        xcode: $xcode
    }'
