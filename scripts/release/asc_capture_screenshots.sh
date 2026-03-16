#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

parse_common_args "$@"
load_release_env
ensure_release_tools
require_cmd jq xcrun

APPSTORE_SCREENSHOT_DIR="${APPSTORE_SCREENSHOT_DIR:-.asc/screenshots}"
APPSTORE_IPHONE_DEVICE="${APPSTORE_IPHONE_DEVICE:-iPhone 17 Pro Max}"
APPSTORE_IPAD_DEVICE="${APPSTORE_IPAD_DEVICE:-iPad Pro 13-inch (M4)}"
APPSTORE_SIM_RUNTIME="${APPSTORE_SIM_RUNTIME:-26.0}"
SCREENSHOT_ROOT="$ROOT_DIR/$APPSTORE_SCREENSHOT_DIR"
DERIVED_DATA_PATH="$ROOT_DIR/.DerivedDataLocal/AppStoreScreenshots"
TEST_SCREENSHOT_ROOT="$ROOT_DIR/.asc/test-screenshots"

resolve_udid() {
    local device_name="$1"
    local runtime="$2"
    local runtime_key="com.apple.CoreSimulator.SimRuntime.iOS-${runtime//./-}"

    xcrun simctl list devices available -j \
        | jq -r --arg runtime "$runtime_key" --arg name "$device_name" '
            .devices[$runtime][]? | select(.name == $name) | .udid
        ' \
        | head -n 1
}

prepare_device() {
    local udid="$1"

    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b
    xcrun simctl status_bar "$udid" override \
        --time 9:41 \
        --dataNetwork wifi \
        --wifiBars 3 \
        --cellularMode active \
        --cellularBars 4 \
        --batteryState charged \
        --batteryLevel 100 >/dev/null
}

run_capture() {
    local udid="$1"

    xcodebuild test \
        -project "$ROOT_DIR/$APP_PROJECT" \
        -scheme "$APP_SCHEME" \
        -destination "platform=iOS Simulator,id=$udid" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -testLanguage en \
        -testRegion US \
        -only-testing:LifeClockUITests/AppStoreScreenshotTests \
        CODE_SIGNING_ALLOWED=NO
}

copy_upload_sets() {
    local source_dir="$1"
    local upload_dir="$2"
    local review_dir="$3"
    local review_name="$4"

    mkdir -p "$upload_dir" "$review_dir"
    find "$upload_dir" -type f -delete
    cp "$source_dir"/0[1-4]-*.png "$upload_dir"/
    cp "$source_dir"/05-paywall.png "$review_dir/$review_name"
}

IPHONE_UDID="$(resolve_udid "$APPSTORE_IPHONE_DEVICE" "$APPSTORE_SIM_RUNTIME")"
IPAD_UDID="$(resolve_udid "$APPSTORE_IPAD_DEVICE" "$APPSTORE_SIM_RUNTIME")"
[[ -n "$IPHONE_UDID" ]] || die "Could not resolve simulator for $APPSTORE_IPHONE_DEVICE (iOS $APPSTORE_SIM_RUNTIME)"
[[ -n "$IPAD_UDID" ]] || die "Could not resolve simulator for $APPSTORE_IPAD_DEVICE (iOS $APPSTORE_SIM_RUNTIME)"

prepare_device "$IPHONE_UDID"
prepare_device "$IPAD_UDID"

mkdir -p "$TEST_SCREENSHOT_ROOT/iphone" "$TEST_SCREENSHOT_ROOT/ipad"
find "$TEST_SCREENSHOT_ROOT/iphone" -type f -delete
find "$TEST_SCREENSHOT_ROOT/ipad" -type f -delete

run_capture "$IPHONE_UDID"
run_capture "$IPAD_UDID"

copy_upload_sets \
    "$TEST_SCREENSHOT_ROOT/iphone" \
    "$SCREENSHOT_ROOT/upload/iphone" \
    "$SCREENSHOT_ROOT/review" \
    "iap-review-iphone.png"

copy_upload_sets \
    "$TEST_SCREENSHOT_ROOT/ipad" \
    "$SCREENSHOT_ROOT/upload/ipad" \
    "$SCREENSHOT_ROOT/review" \
    "iap-review-ipad.png"
