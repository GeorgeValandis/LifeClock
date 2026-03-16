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

APPSTORE_VERSION="${APPSTORE_VERSION:-$(read_build_setting MARKETING_VERSION)}"
APPSTORE_PRIMARY_LOCALE="${APPSTORE_PRIMARY_LOCALE:-en-US}"
APPSTORE_SCREENSHOT_DIR="${APPSTORE_SCREENSHOT_DIR:-.asc/screenshots}"
APPSTORE_IPHONE_DEVICE_TYPE="${APPSTORE_IPHONE_DEVICE_TYPE:-IPHONE_69}"
APPSTORE_IPAD_DEVICE_TYPE="${APPSTORE_IPAD_DEVICE_TYPE:-IPAD_PRO_3GEN_129}"
APPSTORE_IAP_PRODUCT_ID="${APPSTORE_IAP_PRODUCT_ID:-com.GA.LifeClock.lifetime}"

SCREENSHOT_ROOT="$ROOT_DIR/$APPSTORE_SCREENSHOT_DIR"
VERSION_JSON="$(run_asc versions list --app "$APPLE_APP_ID" --platform IOS --output json)"
VERSION_ID="$(jq -r --arg version "$APPSTORE_VERSION" '.data[] | select(.attributes.versionString == $version) | .id' <<<"$VERSION_JSON" | head -n 1)"
[[ -n "$VERSION_ID" ]] || die "Could not resolve iOS version ID for version $APPSTORE_VERSION"

LOCALIZATION_JSON="$(run_asc localizations list --version "$VERSION_ID" --locale "$APPSTORE_PRIMARY_LOCALE" --output json)"
LOCALIZATION_ID="$(jq -r '.data[0].id // empty' <<<"$LOCALIZATION_JSON")"
[[ -n "$LOCALIZATION_ID" ]] || die "Could not resolve version localization for locale $APPSTORE_PRIMARY_LOCALE"

log "Deleting existing screenshots for localization $APPSTORE_PRIMARY_LOCALE"
EXISTING_IDS="$(
    run_asc screenshots list --version-localization "$LOCALIZATION_ID" --output json \
        | jq -r '
            .data[]?.id,
            .sets[]?.screenshots[]?.id
        '
)"

if [[ -n "$EXISTING_IDS" ]]; then
    while IFS= read -r screenshot_id; do
        [[ -n "$screenshot_id" ]] || continue
        run_asc screenshots delete --id "$screenshot_id" --confirm >/dev/null
    done <<<"$EXISTING_IDS"
fi

[[ -d "$SCREENSHOT_ROOT/upload/iphone" ]] || die "Missing iPhone screenshots at $SCREENSHOT_ROOT/upload/iphone"
[[ -d "$SCREENSHOT_ROOT/upload/ipad" ]] || die "Missing iPad screenshots at $SCREENSHOT_ROOT/upload/ipad"

log "Uploading iPhone screenshots"
run_asc screenshots upload \
    --version-localization "$LOCALIZATION_ID" \
    --path "$SCREENSHOT_ROOT/upload/iphone" \
    --device-type "$APPSTORE_IPHONE_DEVICE_TYPE" >/dev/null

log "Uploading iPad screenshots"
run_asc screenshots upload \
    --version-localization "$LOCALIZATION_ID" \
    --path "$SCREENSHOT_ROOT/upload/ipad" \
    --device-type "$APPSTORE_IPAD_DEVICE_TYPE" >/dev/null

if [[ -f "$SCREENSHOT_ROOT/review/iap-review-iphone.png" ]]; then
    log "Uploading IAP review screenshot"
    IAP_ID="$(
        run_asc iap list --app "$APPLE_APP_ID" --output json \
            | jq -r --arg product_id "$APPSTORE_IAP_PRODUCT_ID" '
                .data[] | select(.attributes.productId == $product_id) | .id
            ' \
            | head -n 1
    )"
    [[ -n "$IAP_ID" ]] || die "Could not resolve IAP ID for product $APPSTORE_IAP_PRODUCT_ID"

    EXISTING_REVIEW_ID="$(
        run_asc iap review-screenshots get --iap-id "$IAP_ID" --output json 2>/dev/null \
            | jq -r '.data.id // empty'
    )"

    if [[ -n "$EXISTING_REVIEW_ID" ]]; then
        run_asc iap review-screenshots delete \
            --screenshot-id "$EXISTING_REVIEW_ID" \
            --confirm >/dev/null
    fi

    run_asc iap review-screenshots create \
        --iap-id "$IAP_ID" \
        --file "$SCREENSHOT_ROOT/review/iap-review-iphone.png" >/dev/null
fi
