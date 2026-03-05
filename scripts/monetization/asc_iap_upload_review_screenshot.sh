#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat <<'USAGE'
Usage: asc_iap_upload_review_screenshot.sh [--env <file>] [--file <path>]

Required env vars:
  APPLE_ISSUER_ID
  APPLE_KEY_ID
  APPLE_PRIVATE_KEY_PATH
  APPLE_APP_ID
  ASC_PRODUCT_ID

Screenshot source:
  --file <path> OR ASC_REVIEW_SCREENSHOT_PATH

Notes:
  - Accepted file types: png, jpg, jpeg
  - Uploads App Store review screenshot for the IAP (required to leave MISSING_METADATA)
USAGE
}

ENV_FILE=".env.hybrid"
SCREENSHOT_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            [[ $# -ge 2 ]] || die "--env requires a file path"
            ENV_FILE="$2"
            shift 2
            ;;
        --file)
            [[ $# -ge 2 ]] || die "--file requires a path"
            SCREENSHOT_PATH="$2"
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
require_env APPLE_ISSUER_ID APPLE_KEY_ID APPLE_PRIVATE_KEY_PATH APPLE_APP_ID ASC_PRODUCT_ID

[[ -f "$APPLE_PRIVATE_KEY_PATH" ]] || die "APPLE_PRIVATE_KEY_PATH not found: $APPLE_PRIVATE_KEY_PATH"

if [[ -z "$SCREENSHOT_PATH" ]]; then
    SCREENSHOT_PATH="${ASC_REVIEW_SCREENSHOT_PATH:-}"
fi
[[ -n "$SCREENSHOT_PATH" ]] || die "Provide screenshot via --file or ASC_REVIEW_SCREENSHOT_PATH"
[[ -f "$SCREENSHOT_PATH" ]] || die "Screenshot file not found: $SCREENSHOT_PATH"

basename_file="$(basename "$SCREENSHOT_PATH")"
ext="${basename_file##*.}"
ext_lc="$(tr '[:upper:]' '[:lower:]' <<<"$ext")"

mime_type=""
case "$ext_lc" in
    png) mime_type="image/png" ;;
    jpg|jpeg) mime_type="image/jpeg" ;;
    *)
        die "Unsupported screenshot extension: .$ext_lc (use png/jpg/jpeg)"
        ;;
esac

file_size="$(stat -f%z "$SCREENSHOT_PATH" 2>/dev/null || true)"
[[ -n "$file_size" && "$file_size" -gt 0 ]] || die "Could not determine file size for: $SCREENSHOT_PATH"

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

log "Resolving IAP ID for product_id=$ASC_PRODUCT_ID"
existing_resp="$(asc_request GET "/v1/apps/${APPLE_APP_ID}/inAppPurchasesV2?filter%5BproductId%5D=$(urlencode "$ASC_PRODUCT_ID")&limit=50")"
iap_id="$(jq -r --arg product_id "$ASC_PRODUCT_ID" '.data[]? | select(.attributes.productId == $product_id) | .id' <<<"$existing_resp" | head -n 1)"
[[ -n "$iap_id" ]] || die "IAP not found for product_id=$ASC_PRODUCT_ID"

log "Creating review screenshot container for IAP $iap_id"
create_payload="$(jq -cn \
    --arg file_name "$basename_file" \
    --arg mime_type "$mime_type" \
    --argjson file_size "$file_size" \
    --arg iap_id "$iap_id" \
    '{
        data: {
            type: "inAppPurchaseAppStoreReviewScreenshots",
            attributes: {
                fileName: $file_name,
                fileSize: $file_size
            },
            relationships: {
                inAppPurchaseV2: {
                    data: {
                        type: "inAppPurchases",
                        id: $iap_id
                    }
                }
            }
        }
    }')"
create_resp="$(asc_request POST "/v1/inAppPurchaseAppStoreReviewScreenshots" "$create_payload")"

screenshot_id="$(jq -r '.data.id // empty' <<<"$create_resp")"
[[ -n "$screenshot_id" ]] || die "Could not parse screenshot id from create response"

upload_ops="$(jq -c '.data.attributes.uploadOperations // []' <<<"$create_resp")"
ops_count="$(jq -r 'length' <<<"$upload_ops")"
(( ops_count > 0 )) || die "No uploadOperations returned for screenshot_id=$screenshot_id"

log "Uploading screenshot data ($ops_count operation(s))"
for (( i=0; i<ops_count; i++ )); do
    op="$(jq -c ".[$i]" <<<"$upload_ops")"
    method="$(jq -r '.method' <<<"$op")"
    url="$(jq -r '.url' <<<"$op")"
    offset="$(jq -r '.offset' <<<"$op")"
    length="$(jq -r '.length' <<<"$op")"
    headers_count="$(jq -r '.requestHeaders | length' <<<"$op")"

    tmp_chunk="$(mktemp)"
    dd if="$SCREENSHOT_PATH" of="$tmp_chunk" bs=1 skip="$offset" count="$length" status=none

    curl_args=( -sS -X "$method" "$url" --data-binary "@$tmp_chunk" )
    for (( h=0; h<headers_count; h++ )); do
        header_name="$(jq -r ".requestHeaders[$h].name" <<<"$op")"
        header_value="$(jq -r ".requestHeaders[$h].value" <<<"$op")"
        curl_args+=( -H "$header_name: $header_value" )
    done

    curl "${curl_args[@]}" >/dev/null
    rm -f "$tmp_chunk"
done

log "Marking screenshot as uploaded"
finalize_payload='{"data":{"type":"inAppPurchaseAppStoreReviewScreenshots","id":"'"$screenshot_id"'","attributes":{"uploaded":true}}}'
asc_request PATCH "/v1/inAppPurchaseAppStoreReviewScreenshots/${screenshot_id}" "$finalize_payload" >/dev/null

log "Waiting for asset processing"
attempt=0
max_attempts=20
state=""
while (( attempt < max_attempts )); do
    attempt=$((attempt + 1))
    check_resp="$(asc_request GET "/v1/inAppPurchaseAppStoreReviewScreenshots/${screenshot_id}")"
    state="$(jq -r '.data.attributes.assetDeliveryState.state // empty' <<<"$check_resp")"
    if [[ "$state" == "COMPLETE" ]]; then
        break
    fi
    sleep 2
done

if [[ "$state" != "COMPLETE" ]]; then
    warn "Screenshot upload created but processing state is: ${state:-unknown}"
fi

jq -cn \
    --arg iap_id "$iap_id" \
    --arg screenshot_id "$screenshot_id" \
    --arg file "$SCREENSHOT_PATH" \
    --arg state "$state" \
    '{
        iap_id: $iap_id,
        screenshot_id: $screenshot_id,
        file: $file,
        asset_state: (if $state == "" then null else $state end)
    }'
