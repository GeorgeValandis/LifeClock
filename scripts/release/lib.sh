#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Reuse the existing shell helpers used by the other asc automation scripts.
# shellcheck disable=SC1091
source "$ROOT_DIR/scripts/monetization/lib.sh"

ENV_FILE=""
declare -a COMMON_REMAINDER=()

parse_common_args() {
    COMMON_REMAINDER=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --env)
                [[ $# -ge 2 ]] || die "--env requires a path"
                ENV_FILE="$2"
                shift 2
                ;;
            *)
                COMMON_REMAINDER+=("$1")
                shift
                ;;
        esac
    done
}

load_release_env() {
    load_env_file "$ENV_FILE"

    APP_PROJECT="${APP_PROJECT:-LifeClock.xcodeproj}"
    APP_SCHEME="${APP_SCHEME:-LifeClock}"
    APP_CONFIGURATION="${APP_CONFIGURATION:-Release}"
    APP_PLATFORM="${APP_PLATFORM:-IOS}"
    XCODE_DESTINATION="${XCODE_DESTINATION:-generic/platform=iOS}"
    APPLE_TEAM_ID="${APPLE_TEAM_ID:-LPPZFWPAN7}"
    ARTIFACT_DIR="${ARTIFACT_DIR:-.asc/artifacts}"
    ASC_PROFILE_NAME="${ASC_PROFILE_NAME:-LifeClock}"
    ASC_WAIT_TIMEOUT="${ASC_WAIT_TIMEOUT:-45m}"
    APPSTORE_EXPORT_METHOD="${APPSTORE_EXPORT_METHOD:-app-store-connect}"
    APPSTORE_EXPORT_SIGNING_STYLE="${APPSTORE_EXPORT_SIGNING_STYLE:-automatic}"
    APPSTORE_APP_BUNDLE_ID="${APPSTORE_APP_BUNDLE_ID:-com.GA.LifeClock}"
    APPSTORE_WIDGET_BUNDLE_ID="${APPSTORE_WIDGET_BUNDLE_ID:-com.GA.LifeClock.widget}"
    APPSTORE_APP_PROFILE_NAME="${APPSTORE_APP_PROFILE_NAME:-}"
    APPSTORE_WIDGET_PROFILE_NAME="${APPSTORE_WIDGET_PROFILE_NAME:-}"
    APPSTORE_SIGNING_CERTIFICATE="${APPSTORE_SIGNING_CERTIFICATE:-}"

    if [[ "$ARTIFACT_DIR" = /* ]]; then
        ARTIFACT_DIR_ABS="$ARTIFACT_DIR"
    else
        ARTIFACT_DIR_ABS="$ROOT_DIR/${ARTIFACT_DIR#./}"
    fi
    ARCHIVE_PATH="$ARTIFACT_DIR_ABS/$APP_SCHEME.xcarchive"
    IPA_PATH="$ARTIFACT_DIR_ABS/$APP_SCHEME.ipa"
    EXPORT_OPTIONS_PATH="$ARTIFACT_DIR_ABS/ExportOptions-app-store.plist"
}

ensure_release_tools() {
    require_cmd asc xcodebuild
}

run_asc() {
    if [[ -n "${ASC_PROFILE_NAME:-}" ]]; then
        asc --profile "$ASC_PROFILE_NAME" "$@"
    else
        asc "$@"
    fi
}

create_artifact_dir() {
    mkdir -p "$ARTIFACT_DIR_ABS"
}

write_export_options() {
    {
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>${APPSTORE_EXPORT_METHOD}</string>
  <key>signingStyle</key>
  <string>${APPSTORE_EXPORT_SIGNING_STYLE}</string>
  <key>teamID</key>
  <string>${APPLE_TEAM_ID}</string>
  <key>destination</key>
  <string>export</string>
EOF

    if [[ -n "$APPSTORE_SIGNING_CERTIFICATE" ]]; then
    cat <<EOF
  <key>signingCertificate</key>
  <string>${APPSTORE_SIGNING_CERTIFICATE}</string>
EOF
    fi

    if [[ -n "$APPSTORE_APP_PROFILE_NAME" || -n "$APPSTORE_WIDGET_PROFILE_NAME" ]]; then
    cat <<EOF
  <key>provisioningProfiles</key>
  <dict>
EOF
        if [[ -n "$APPSTORE_APP_PROFILE_NAME" ]]; then
    cat <<EOF
    <key>${APPSTORE_APP_BUNDLE_ID}</key>
    <string>${APPSTORE_APP_PROFILE_NAME}</string>
EOF
        fi
        if [[ -n "$APPSTORE_WIDGET_PROFILE_NAME" ]]; then
    cat <<EOF
    <key>${APPSTORE_WIDGET_BUNDLE_ID}</key>
    <string>${APPSTORE_WIDGET_PROFILE_NAME}</string>
EOF
        fi
    cat <<EOF
  </dict>
EOF
    fi

    cat <<EOF
</dict>
</plist>
EOF
    } >"$EXPORT_OPTIONS_PATH"
}

read_build_setting() {
    local key="$1"
    xcodebuild \
        -project "$ROOT_DIR/$APP_PROJECT" \
        -scheme "$APP_SCHEME" \
        -configuration "$APP_CONFIGURATION" \
        -showBuildSettings 2>/dev/null \
        | awk -F' = ' -v key="$key" '$1 ~ "^[[:space:]]*" key "$" { print $2; exit }'
}

log_release_context() {
    local version build
    version="$(read_build_setting MARKETING_VERSION || true)"
    build="$(read_build_setting CURRENT_PROJECT_VERSION || true)"
    log "Scheme: $APP_SCHEME"
    log "Configuration: $APP_CONFIGURATION"
    log "Version: ${version:-unknown} (${build:-unknown})"
    log "Artifacts: $ARTIFACT_DIR_ABS"
}
