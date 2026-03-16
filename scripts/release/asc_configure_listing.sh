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
APPSTORE_PRIMARY_CATEGORY="${APPSTORE_PRIMARY_CATEGORY:-LIFESTYLE}"
APPSTORE_SECONDARY_CATEGORY="${APPSTORE_SECONDARY_CATEGORY:-HEALTH_AND_FITNESS}"
APPSTORE_REVIEW_FIRST_NAME="${APPSTORE_REVIEW_FIRST_NAME:-Georgios}"
APPSTORE_REVIEW_LAST_NAME="${APPSTORE_REVIEW_LAST_NAME:-Avenidis}"
APPSTORE_REVIEW_EMAIL="${APPSTORE_REVIEW_EMAIL:-support@georgevalandis.com}"
APPSTORE_REVIEW_PHONE="${APPSTORE_REVIEW_PHONE:-+49 173 4625411}"
APPSTORE_REVIEW_NOTES_FILE="${APPSTORE_REVIEW_NOTES_FILE:-appstore/review/notes.txt}"
APPSTORE_AGE_RATING_INFO_URL="${APPSTORE_AGE_RATING_INFO_URL:-https://georgevalandis.com/privacy-datenschutzerklaerung/}"
APPSTORE_SET_AVAILABILITY="${APPSTORE_SET_AVAILABILITY:-true}"
APPSTORE_DEMO_ACCOUNT_NAME="${APPSTORE_DEMO_ACCOUNT_NAME:-Not required}"
APPSTORE_DEMO_ACCOUNT_PASSWORD="${APPSTORE_DEMO_ACCOUNT_PASSWORD:-Not required}"

VERSION_JSON="$(run_asc versions list --app "$APPLE_APP_ID" --platform IOS --output json)"
VERSION_ID="$(jq -r --arg version "$APPSTORE_VERSION" '.data[] | select(.attributes.versionString == $version) | .id' <<<"$VERSION_JSON" | head -n 1)"
[[ -n "$VERSION_ID" ]] || die "Could not resolve iOS version ID for version $APPSTORE_VERSION"

if [[ -f "$ROOT_DIR/$APPSTORE_REVIEW_NOTES_FILE" ]]; then
    REVIEW_NOTES="$(cat "$ROOT_DIR/$APPSTORE_REVIEW_NOTES_FILE")"
else
    REVIEW_NOTES="LifeClock does not require a user account or demo login."
fi

log "Setting categories"
run_asc categories set --app "$APPLE_APP_ID" --primary "$APPSTORE_PRIMARY_CATEGORY" --secondary "$APPSTORE_SECONDARY_CATEGORY" >/dev/null

if bool_is_true "$APPSTORE_SET_AVAILABILITY"; then
    log "Setting worldwide availability"
    TERRITORIES="$(
        run_asc pricing territories list --output json \
            | jq -r '.data[].id' \
            | paste -sd, -
    )"
    [[ -n "$TERRITORIES" ]] || die "Could not resolve pricing territories"

    if ! run_asc pricing availability set \
        --app "$APPLE_APP_ID" \
        --territory "$TERRITORIES" \
        --available true \
        --available-in-new-territories true >/dev/null
    then
        warn "App availability could not be created through the public ASC CLI path. Configure Pricing and Availability once in App Store Connect."
    fi
fi

log "Setting age rating declaration"
run_asc age-rating set \
    --app "$APPLE_APP_ID" \
    --advertising false \
    --age-assurance false \
    --gambling false \
    --health-or-wellness-topics false \
    --loot-box false \
    --messaging-and-chat false \
    --parental-controls false \
    --unrestricted-web-access false \
    --user-generated-content false \
    --alcohol-tobacco-drug-use NONE \
    --contests NONE \
    --gambling-simulated NONE \
    --guns-or-other-weapons NONE \
    --medical-treatment NONE \
    --profanity-humor NONE \
    --sexual-content-graphic-nudity NONE \
    --sexual-content-nudity NONE \
    --horror-fear NONE \
    --mature-suggestive NONE \
    --violence-cartoon NONE \
    --violence-realistic NONE \
    --violence-realistic-graphic NONE \
    --developer-age-rating-info-url "$APPSTORE_AGE_RATING_INFO_URL" >/dev/null

log "Creating or updating review details"
REVIEW_JSON="$(run_asc review details-for-version --version-id "$VERSION_ID" --output json)"
REVIEW_ID="$(jq -r '.data.id // empty' <<<"$REVIEW_JSON")"

if [[ -n "$REVIEW_ID" ]]; then
    run_asc review details-update \
        --id "$REVIEW_ID" \
        --contact-first-name "$APPSTORE_REVIEW_FIRST_NAME" \
        --contact-last-name "$APPSTORE_REVIEW_LAST_NAME" \
        --contact-email "$APPSTORE_REVIEW_EMAIL" \
        --contact-phone "$APPSTORE_REVIEW_PHONE" \
        --demo-account-name "$APPSTORE_DEMO_ACCOUNT_NAME" \
        --demo-account-password "$APPSTORE_DEMO_ACCOUNT_PASSWORD" \
        --demo-account-required false \
        --notes "$REVIEW_NOTES" >/dev/null
else
    run_asc review details-create \
        --version-id "$VERSION_ID" \
        --contact-first-name "$APPSTORE_REVIEW_FIRST_NAME" \
        --contact-last-name "$APPSTORE_REVIEW_LAST_NAME" \
        --contact-email "$APPSTORE_REVIEW_EMAIL" \
        --contact-phone "$APPSTORE_REVIEW_PHONE" \
        --demo-account-name "$APPSTORE_DEMO_ACCOUNT_NAME" \
        --demo-account-password "$APPSTORE_DEMO_ACCOUNT_PASSWORD" \
        --demo-account-required false \
        --notes "$REVIEW_NOTES" >/dev/null
fi
