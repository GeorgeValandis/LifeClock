#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat <<'USAGE'
Usage: asc_upload_app_screenshots.sh [--env <file>] --display-type <type> --file <path> [--file <path> ...]

Required env vars:
  APPLE_ISSUER_ID
  APPLE_KEY_ID
  APPLE_PRIVATE_KEY_PATH
  APPLE_APP_ID

Optional env vars:
  ASC_APP_LOCALE=en-US
  ASC_PLATFORM=IOS

Example:
  scripts/monetization/asc_upload_app_screenshots.sh --env .env.hybrid \
    --display-type APP_IPHONE_65 \
    --file /abs/path/shot1.png --file /abs/path/shot2.png
USAGE
}

ENV_FILE=".env.hybrid"
DISPLAY_TYPE=""
FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            [[ $# -ge 2 ]] || die "--env requires a file path"
            ENV_FILE="$2"
            shift 2
            ;;
        --display-type)
            [[ $# -ge 2 ]] || die "--display-type requires a value"
            DISPLAY_TYPE="$2"
            shift 2
            ;;
        --file)
            [[ $# -ge 2 ]] || die "--file requires a path"
            FILES+=("$2")
            shift 2
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
require_cmd curl jq ruby stat dd
require_env APPLE_ISSUER_ID APPLE_KEY_ID APPLE_PRIVATE_KEY_PATH APPLE_APP_ID

[[ -f "$APPLE_PRIVATE_KEY_PATH" ]] || die "APPLE_PRIVATE_KEY_PATH not found: $APPLE_PRIVATE_KEY_PATH"
[[ -n "$DISPLAY_TYPE" ]] || die "--display-type is required"
(( ${#FILES[@]} > 0 )) || die "Provide at least one --file path"

ASC_APP_LOCALE="${ASC_APP_LOCALE:-en-US}"
ASC_PLATFORM="${ASC_PLATFORM:-IOS}"

for file in "${FILES[@]}"; do
    [[ -f "$file" ]] || die "Screenshot file not found: $file"
done

asc_build_jwt() {
    ruby <<'RUBY'
require "json"
require "openssl"
require "base64"

def b64url(bytes)
  Base64.urlsafe_encode64(bytes, padding: false)
end

now = Time.now.to_i
header = { alg: "ES256", kid: ENV.fetch("APPLE_KEY_ID"), typ: "JWT" }
payload = {
  iss: ENV.fetch("APPLE_ISSUER_ID"),
  iat: now,
  exp: now + 1200,
  aud: "appstoreconnect-v1"
}

signing_input = "#{b64url(header.to_json)}.#{b64url(payload.to_json)}"
key = OpenSSL::PKey.read(File.read(ENV.fetch("APPLE_PRIVATE_KEY_PATH")))
digest = OpenSSL::Digest::SHA256.digest(signing_input)
signature_der = key.dsa_sign_asn1(digest)
asn1 = OpenSSL::ASN1.decode(signature_der).value
r = asn1[0].value.to_s(2).rjust(32, "\x00")
s = asn1[1].value.to_s(2).rjust(32, "\x00")
signature_jose = b64url(r + s)

puts "#{signing_input}.#{signature_jose}"
RUBY
}

ASC_JWT=""
ASC_LAST_STATUS=""
ASC_LAST_BODY=""

asc_http() {
    local method="$1"
    local path="$2"
    local body="${3:-}"
    local url="https://api.appstoreconnect.apple.com${path}"
    local tmp_body
    tmp_body="$(mktemp)"

    if [[ -n "$body" ]]; then
        ASC_LAST_STATUS="$(curl -g -sS -X "$method" "$url" \
            -H "Authorization: Bearer $ASC_JWT" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            --data "$body" \
            -o "$tmp_body" \
            -w '%{http_code}')"
    else
        ASC_LAST_STATUS="$(curl -g -sS -X "$method" "$url" \
            -H "Authorization: Bearer $ASC_JWT" \
            -H "Accept: application/json" \
            -o "$tmp_body" \
            -w '%{http_code}')"
    fi

    ASC_LAST_BODY="$(cat "$tmp_body")"
    rm -f "$tmp_body"
}

asc_request() {
    local method="$1"
    local path="$2"
    local body="${3:-}"

    if [[ -z "$ASC_JWT" ]]; then
        ASC_JWT="$(asc_build_jwt)"
    fi

    asc_http "$method" "$path" "$body"
    if [[ "$ASC_LAST_STATUS" == "401" ]]; then
        ASC_JWT="$(asc_build_jwt)"
        asc_http "$method" "$path" "$body"
    fi

    if (( ASC_LAST_STATUS >= 400 )); then
        printf '%s\n' "$ASC_LAST_BODY" >&2
        die "ASC request failed: $method $path (HTTP $ASC_LAST_STATUS)"
    fi

    printf '%s\n' "$ASC_LAST_BODY"
}

log "Resolving appStoreVersion (platform=$ASC_PLATFORM)"
version_resp="$(asc_request GET "/v1/apps/${APPLE_APP_ID}/appStoreVersions?filter%5Bplatform%5D=${ASC_PLATFORM}&limit=1")"
version_id="$(jq -r '.data[0].id // empty' <<<"$version_resp")"
[[ -n "$version_id" ]] || die "No appStoreVersion found for platform=$ASC_PLATFORM"

log "Resolving localization ($ASC_APP_LOCALE)"
loc_resp="$(asc_request GET "/v1/appStoreVersions/${version_id}/appStoreVersionLocalizations?limit=50")"
loc_id="$(jq -r --arg locale "$ASC_APP_LOCALE" '.data[]? | select(.attributes.locale == $locale) | .id' <<<"$loc_resp" | head -n 1)"
[[ -n "$loc_id" ]] || die "No appStoreVersionLocalization found for locale=$ASC_APP_LOCALE"

log "Resolving screenshot set ($DISPLAY_TYPE)"
set_resp="$(asc_request GET "/v1/appStoreVersionLocalizations/${loc_id}/appScreenshotSets?limit=200")"
set_id="$(jq -r --arg t "$DISPLAY_TYPE" '.data[]? | select(.attributes.screenshotDisplayType == $t) | .id' <<<"$set_resp" | head -n 1)"

if [[ -z "$set_id" ]]; then
    log "Creating screenshot set"
    set_payload="$(jq -cn \
        --arg display_type "$DISPLAY_TYPE" \
        --arg loc_id "$loc_id" \
        '{
            data: {
                type: "appScreenshotSets",
                attributes: {
                    screenshotDisplayType: $display_type
                },
                relationships: {
                    appStoreVersionLocalization: {
                        data: {
                            type: "appStoreVersionLocalizations",
                            id: $loc_id
                        }
                    }
                }
            }
        }')"
    set_create_resp="$(asc_request POST "/v1/appScreenshotSets" "$set_payload")"
    set_id="$(jq -r '.data.id // empty' <<<"$set_create_resp")"
    [[ -n "$set_id" ]] || die "Could not parse appScreenshotSet id"
fi

uploaded=()

for file in "${FILES[@]}"; do
    file_name="$(basename "$file")"
    ext="${file_name##*.}"
    ext_lc="$(tr '[:upper:]' '[:lower:]' <<<"$ext")"
    case "$ext_lc" in
        png) mime_type="image/png" ;;
        jpg|jpeg) mime_type="image/jpeg" ;;
        *) die "Unsupported extension for $file_name (use png/jpg/jpeg)" ;;
    esac

    file_size="$(stat -f%z "$file" 2>/dev/null || true)"
    [[ -n "$file_size" && "$file_size" -gt 0 ]] || die "Could not determine file size for: $file"

    log "Creating app screenshot container: $file_name"
    shot_payload="$(jq -cn \
        --arg file_name "$file_name" \
        --argjson file_size "$file_size" \
        --arg set_id "$set_id" \
        '{
            data: {
                type: "appScreenshots",
                attributes: {
                    fileName: $file_name,
                    fileSize: $file_size
                },
                relationships: {
                    appScreenshotSet: {
                        data: {
                            type: "appScreenshotSets",
                            id: $set_id
                        }
                    }
                }
            }
        }')"
    shot_resp="$(asc_request POST "/v1/appScreenshots" "$shot_payload")"
    shot_id="$(jq -r '.data.id // empty' <<<"$shot_resp")"
    [[ -n "$shot_id" ]] || die "Could not parse appScreenshot id"

    ops="$(jq -c '.data.attributes.uploadOperations // []' <<<"$shot_resp")"
    ops_count="$(jq -r 'length' <<<"$ops")"
    (( ops_count > 0 )) || die "No upload operations for screenshot id=$shot_id"

    log "Uploading binary for screenshot id=$shot_id"
    for (( i=0; i<ops_count; i++ )); do
        op="$(jq -c ".[$i]" <<<"$ops")"
        method="$(jq -r '.method' <<<"$op")"
        url="$(jq -r '.url' <<<"$op")"
        offset="$(jq -r '.offset' <<<"$op")"
        length="$(jq -r '.length' <<<"$op")"
        headers_count="$(jq -r '.requestHeaders | length' <<<"$op")"

        tmp_chunk="$(mktemp)"
        dd if="$file" of="$tmp_chunk" bs=1 skip="$offset" count="$length" status=none
        curl_args=( -sS -X "$method" "$url" --data-binary "@$tmp_chunk" )
        for (( h=0; h<headers_count; h++ )); do
            header_name="$(jq -r ".requestHeaders[$h].name" <<<"$op")"
            header_value="$(jq -r ".requestHeaders[$h].value" <<<"$op")"
            curl_args+=( -H "$header_name: $header_value" )
        done
        curl "${curl_args[@]}" >/dev/null
        rm -f "$tmp_chunk"
    done

    finalize_payload='{"data":{"type":"appScreenshots","id":"'"$shot_id"'","attributes":{"uploaded":true}}}'
    asc_request PATCH "/v1/appScreenshots/${shot_id}" "$finalize_payload" >/dev/null

    state=""
    for _ in {1..25}; do
        check_resp="$(asc_request GET "/v1/appScreenshots/${shot_id}")"
        state="$(jq -r '.data.attributes.assetDeliveryState.state // empty' <<<"$check_resp")"
        if [[ "$state" == "COMPLETE" ]]; then
            break
        fi
        sleep 2
    done

    uploaded+=( "{\"id\":\"$shot_id\",\"file\":\"$file\",\"state\":\"${state:-UNKNOWN}\"}" )
done

uploaded_json="$(printf '%s\n' "${uploaded[@]}" | jq -s '.')"

jq -cn \
    --arg version_id "$version_id" \
    --arg localization_id "$loc_id" \
    --arg screenshot_set_id "$set_id" \
    --arg display_type "$DISPLAY_TYPE" \
    --argjson uploaded "$uploaded_json" \
    '{
        version_id: $version_id,
        localization_id: $localization_id,
        screenshot_set_id: $screenshot_set_id,
        display_type: $display_type,
        uploaded: $uploaded
    }'
