#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat <<'USAGE'
Usage: asc_iap_upsert.sh [--env <file>] [--dry-run]

Required env vars:
  APPLE_ISSUER_ID
  APPLE_KEY_ID
  APPLE_PRIVATE_KEY_PATH
  APPLE_APP_ID
  ASC_PRODUCT_ID
  ASC_IAP_NAME

Optional env vars:
  ASC_IAP_TYPE=NON_CONSUMABLE                    # CONSUMABLE | NON_CONSUMABLE | NON_RENEWING_SUBSCRIPTION
  ASC_FAMILY_SHARABLE=true|false
  ASC_REVIEW_NOTE=
  ASC_LOCALE=de-DE
  ASC_LOCALIZED_NAME=
  ASC_LOCALIZED_DESCRIPTION=
  ASC_ENABLE_ALL_TERRITORIES=true|false          # create availability with all territories if missing
  ASC_AVAILABLE_IN_NEW_TERRITORIES=true|false
  ASC_PRICE_BASE_TERRITORY=DEU
  ASC_PRICE_CUSTOMER=7.99
  ASC_PRICE_START_DATE=YYYY-MM-DD
USAGE
}

ENV_FILE=".env.hybrid"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            [[ $# -ge 2 ]] || die "--env requires a file path"
            ENV_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
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

require_cmd curl jq ruby mktemp
require_env APPLE_ISSUER_ID APPLE_KEY_ID APPLE_PRIVATE_KEY_PATH APPLE_APP_ID ASC_PRODUCT_ID ASC_IAP_NAME

[[ -f "$APPLE_PRIVATE_KEY_PATH" ]] || die "APPLE_PRIVATE_KEY_PATH not found: $APPLE_PRIVATE_KEY_PATH"

ASC_IAP_TYPE="${ASC_IAP_TYPE:-NON_CONSUMABLE}"
ASC_FAMILY_SHARABLE="${ASC_FAMILY_SHARABLE:-}"
ASC_REVIEW_NOTE="${ASC_REVIEW_NOTE:-}"
ASC_LOCALE="${ASC_LOCALE:-}"
ASC_LOCALIZED_NAME="${ASC_LOCALIZED_NAME:-$ASC_IAP_NAME}"
ASC_LOCALIZED_DESCRIPTION="${ASC_LOCALIZED_DESCRIPTION:-}"
ASC_ENABLE_ALL_TERRITORIES="${ASC_ENABLE_ALL_TERRITORIES:-false}"
ASC_AVAILABLE_IN_NEW_TERRITORIES="${ASC_AVAILABLE_IN_NEW_TERRITORIES:-true}"
ASC_PRICE_BASE_TERRITORY="${ASC_PRICE_BASE_TERRITORY:-}"
ASC_PRICE_CUSTOMER="${ASC_PRICE_CUSTOMER:-}"
ASC_PRICE_START_DATE="${ASC_PRICE_START_DATE:-}"

case "$ASC_IAP_TYPE" in
    CONSUMABLE|NON_CONSUMABLE|NON_RENEWING_SUBSCRIPTION)
        ;;
    *)
        die "ASC_IAP_TYPE must be CONSUMABLE, NON_CONSUMABLE, or NON_RENEWING_SUBSCRIPTION"
        ;;
esac

if [[ -n "$ASC_FAMILY_SHARABLE" && "$ASC_FAMILY_SHARABLE" != "true" && "$ASC_FAMILY_SHARABLE" != "false" ]]; then
    die "ASC_FAMILY_SHARABLE must be empty, true, or false"
fi

if [[ -n "$ASC_ENABLE_ALL_TERRITORIES" && "$ASC_ENABLE_ALL_TERRITORIES" != "true" && "$ASC_ENABLE_ALL_TERRITORIES" != "false" ]]; then
    die "ASC_ENABLE_ALL_TERRITORIES must be true or false"
fi

if [[ -n "$ASC_AVAILABLE_IN_NEW_TERRITORIES" && "$ASC_AVAILABLE_IN_NEW_TERRITORIES" != "true" && "$ASC_AVAILABLE_IN_NEW_TERRITORIES" != "false" ]]; then
    die "ASC_AVAILABLE_IN_NEW_TERRITORIES must be true or false"
fi

if [[ -n "$ASC_PRICE_CUSTOMER" ]]; then
    ASC_PRICE_CUSTOMER="${ASC_PRICE_CUSTOMER/,/.}"
    [[ "$ASC_PRICE_CUSTOMER" =~ ^[0-9]+(\.[0-9]{1,2})?$ ]] || die "ASC_PRICE_CUSTOMER must be numeric (e.g. 7.99 or 7,99)"
    [[ -n "$ASC_PRICE_BASE_TERRITORY" ]] || die "ASC_PRICE_BASE_TERRITORY is required when ASC_PRICE_CUSTOMER is set"
fi

if [[ -n "$ASC_PRICE_START_DATE" ]]; then
    [[ "$ASC_PRICE_START_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || die "ASC_PRICE_START_DATE must be YYYY-MM-DD"
fi

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

    if (( DRY_RUN )) && [[ "$method" != "GET" ]]; then
        log "DRY RUN: $method $path"
        if [[ -n "$body" ]]; then
            printf '%s\n' "$body" >&2
        fi
        printf '{}\n'
        return
    fi

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

asc_try_request() {
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
}

asc_list_all() {
    local initial_path="$1"
    local all_data='[]'
    local next_path="$initial_path"
    local guard=0

    while [[ -n "$next_path" ]]; do
        guard=$((guard + 1))
        (( guard <= 300 )) || die "ASC pagination guard exceeded for $initial_path"

        local page page_data next_url
        page="$(asc_request GET "$next_path")"
        page_data="$(jq -c '.data // []' <<<"$page")"
        all_data="$(jq -cn --argjson a "$all_data" --argjson b "$page_data" '$a + $b')"

        next_url="$(jq -r '.links.next // empty' <<<"$page")"
        if [[ -n "$next_url" ]]; then
            next_path="${next_url#https://api.appstoreconnect.apple.com}"
        else
            next_path=""
        fi
    done

    printf '%s\n' "$all_data"
}

log "Checking IAP in App Store Connect for product_id=$ASC_PRODUCT_ID"

existing_resp="$(asc_request GET "/v1/apps/${APPLE_APP_ID}/inAppPurchasesV2?filter%5BproductId%5D=$(urlencode "$ASC_PRODUCT_ID")&limit=50")"
iap_id="$(jq -r --arg product_id "$ASC_PRODUCT_ID" '.data[]? | select(.attributes.productId == $product_id) | .id' <<<"$existing_resp" | head -n 1)"

created_iap=0
created_localization=0
localization_id=""
created_availability=0
created_price_schedule=0
effective_price_point_id=""
effective_price_territory=""
effective_price_customer=""

if [[ -z "$iap_id" ]]; then
    create_payload="$(jq -cn \
        --arg app_id "$APPLE_APP_ID" \
        --arg product_id "$ASC_PRODUCT_ID" \
        --arg name "$ASC_IAP_NAME" \
        --arg iap_type "$ASC_IAP_TYPE" \
        --arg family_sharable "$ASC_FAMILY_SHARABLE" \
        --arg review_note "$ASC_REVIEW_NOTE" \
        '{
            data: {
                type: "inAppPurchases",
                attributes: {
                    productId: $product_id,
                    name: $name,
                    inAppPurchaseType: $iap_type
                },
                relationships: {
                    app: {
                        data: {
                            type: "apps",
                            id: $app_id
                        }
                    }
                }
            }
        }
        | if $family_sharable == "true" or $family_sharable == "false" then .data.attributes.familySharable = ($family_sharable == "true") else . end
        | if $review_note != "" then .data.attributes.reviewNote = $review_note else . end
        ')"

    create_resp="$(asc_request POST "/v2/inAppPurchases" "$create_payload")"
    iap_id="$(jq -r '.data.id // empty' <<<"$create_resp")"
    [[ -n "$iap_id" ]] || die "IAP create response did not include data.id"
    created_iap=1
    log "Created IAP: $iap_id"
else
    log "IAP already exists: $iap_id"
fi

if [[ -n "$ASC_LOCALE" ]]; then
    localizations_resp="$(asc_request GET "/v2/inAppPurchases/${iap_id}/inAppPurchaseLocalizations?limit=200")"
    localization_id="$(jq -r --arg locale "$ASC_LOCALE" '.data[]? | select(.attributes.locale == $locale) | .id' <<<"$localizations_resp" | head -n 1)"

    if [[ -z "$localization_id" ]]; then
        localization_payload="$(jq -cn \
            --arg iap_id "$iap_id" \
            --arg locale "$ASC_LOCALE" \
            --arg name "$ASC_LOCALIZED_NAME" \
            --arg description "$ASC_LOCALIZED_DESCRIPTION" \
            '{
                data: {
                    type: "inAppPurchaseLocalizations",
                    attributes: {
                        name: $name,
                        locale: $locale
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
            }
            | if $description != "" then .data.attributes.description = $description else . end
            ')"

        localization_create_resp="$(asc_request POST "/v1/inAppPurchaseLocalizations" "$localization_payload")"
        localization_id="$(jq -r '.data.id // empty' <<<"$localization_create_resp")"
        [[ -n "$localization_id" ]] || die "Localization create response did not include data.id"
        created_localization=1
        log "Created localization: $localization_id ($ASC_LOCALE)"
    else
        log "Localization already exists: $localization_id ($ASC_LOCALE)"
    fi
fi

if bool_is_true "$ASC_ENABLE_ALL_TERRITORIES"; then
    asc_try_request GET "/v1/inAppPurchaseAvailabilities/${iap_id}" ""
    if [[ "$ASC_LAST_STATUS" == "404" ]]; then
        log "Creating availability for all territories"
        territories_json="$(asc_list_all "/v1/territories?limit=200")"
        territories_data="$(jq -c '[.[] | {type: "territories", id: .id}]' <<<"$territories_json")"
        availability_payload="$(jq -cn \
            --arg iap_id "$iap_id" \
            --arg available_in_new "$ASC_AVAILABLE_IN_NEW_TERRITORIES" \
            --argjson territories "$territories_data" \
            '{
                data: {
                    type: "inAppPurchaseAvailabilities",
                    attributes: {
                        availableInNewTerritories: ($available_in_new == "true")
                    },
                    relationships: {
                        inAppPurchase: {
                            data: {
                                type: "inAppPurchases",
                                id: $iap_id
                            }
                        },
                        availableTerritories: {
                            data: $territories
                        }
                    }
                }
            }')"
        asc_request POST "/v1/inAppPurchaseAvailabilities" "$availability_payload" >/dev/null
        created_availability=1
    elif (( ASC_LAST_STATUS >= 400 )); then
        printf '%s\n' "$ASC_LAST_BODY" >&2
        die "ASC request failed: GET /v1/inAppPurchaseAvailabilities/${iap_id} (HTTP $ASC_LAST_STATUS)"
    else
        log "Availability already exists: ${iap_id}"
    fi
fi

if [[ -n "$ASC_PRICE_CUSTOMER" ]]; then
    log "Resolving price point for ${ASC_PRICE_BASE_TERRITORY} at ${ASC_PRICE_CUSTOMER}"
    price_points="$(asc_list_all "/v2/inAppPurchases/${iap_id}/pricePoints?filter%5Bterritory%5D=$(urlencode "$ASC_PRICE_BASE_TERRITORY")&limit=200")"
    effective_price_point_id="$(jq -r --arg price "$ASC_PRICE_CUSTOMER" '.[] | select(.attributes.customerPrice == $price) | .id' <<<"$price_points" | head -n 1)"
    [[ -n "$effective_price_point_id" ]] || die "No price point found for territory=$ASC_PRICE_BASE_TERRITORY and customer price=$ASC_PRICE_CUSTOMER"
    effective_price_territory="$ASC_PRICE_BASE_TERRITORY"
    effective_price_customer="$ASC_PRICE_CUSTOMER"

    asc_try_request GET "/v1/inAppPurchasePriceSchedules/${iap_id}?include=baseTerritory,manualPrices" ""
    if [[ "$ASC_LAST_STATUS" == "404" ]]; then
        log "Creating price schedule"
        effective_start_date="$ASC_PRICE_START_DATE"
        if [[ -z "$effective_start_date" ]]; then
            effective_start_date="$(date +%F)"
        fi

        price_schedule_payload="$(jq -cn \
            --arg iap_id "$iap_id" \
            --arg territory "$ASC_PRICE_BASE_TERRITORY" \
            --arg start_date "$effective_start_date" \
            --arg price_point_id "$effective_price_point_id" \
            '{
                data: {
                    type: "inAppPurchasePriceSchedules",
                    relationships: {
                        inAppPurchase: {
                            data: {
                                type: "inAppPurchases",
                                id: $iap_id
                            }
                        },
                        baseTerritory: {
                            data: {
                                type: "territories",
                                id: $territory
                            }
                        },
                        manualPrices: {
                            data: [
                                {
                                    type: "inAppPurchasePrices",
                                    id: "${price1}"
                                }
                            ]
                        }
                    }
                },
                included: [
                    {
                        type: "inAppPurchasePrices",
                        id: "${price1}",
                        attributes: {
                            startDate: $start_date
                        },
                        relationships: {
                            inAppPurchasePricePoint: {
                                data: {
                                    type: "inAppPurchasePricePoints",
                                    id: $price_point_id
                                }
                            }
                        }
                    }
                ]
            }')"
        asc_request POST "/v1/inAppPurchasePriceSchedules" "$price_schedule_payload" >/dev/null
        created_price_schedule=1
    elif (( ASC_LAST_STATUS >= 400 )); then
        printf '%s\n' "$ASC_LAST_BODY" >&2
        die "ASC request failed: GET /v1/inAppPurchasePriceSchedules/${iap_id} (HTTP $ASC_LAST_STATUS)"
    else
        log "Price schedule already exists: ${iap_id}"
    fi
fi

jq -cn \
    --arg app_id "$APPLE_APP_ID" \
    --arg product_id "$ASC_PRODUCT_ID" \
    --arg iap_id "$iap_id" \
    --arg iap_type "$ASC_IAP_TYPE" \
    --arg iap_name "$ASC_IAP_NAME" \
    --arg locale "$ASC_LOCALE" \
    --arg localization_id "$localization_id" \
    --arg effective_price_point_id "$effective_price_point_id" \
    --arg effective_price_territory "$effective_price_territory" \
    --arg effective_price_customer "$effective_price_customer" \
    --argjson created_iap "$created_iap" \
    --argjson created_localization "$created_localization" \
    --argjson created_availability "$created_availability" \
    --argjson created_price_schedule "$created_price_schedule" \
    '{
        app_id: $app_id,
        product_id: $product_id,
        iap_id: $iap_id,
        iap_type: $iap_type,
        iap_name: $iap_name,
        locale: (if $locale == "" then null else $locale end),
        localization_id: (if $localization_id == "" then null else $localization_id end),
        effective_price_point_id: (if $effective_price_point_id == "" then null else $effective_price_point_id end),
        effective_price_territory: (if $effective_price_territory == "" then null else $effective_price_territory end),
        effective_price_customer: (if $effective_price_customer == "" then null else $effective_price_customer end),
        created_iap: ($created_iap == 1),
        created_localization: ($created_localization == 1),
        created_availability: ($created_availability == 1),
        created_price_schedule: ($created_price_schedule == 1)
    }'
