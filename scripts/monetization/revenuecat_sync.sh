#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat <<'USAGE'
Usage: revenuecat_sync.sh [--env <file>]

Required env vars:
  RC_API_KEY
  RC_BUNDLE_ID
  RC_STORE_PRODUCT_ID
  RC_PROJECT_ID or RC_PROJECT_NAME

Optional env vars:
  RC_API_BASE=https://api.revenuecat.com/v2
  RC_PROJECT_NAME=
  RC_APP_ID=
  RC_APP_NAME=LifeClock
  RC_APP_TYPE=app_store
  RC_PRODUCT_TYPE=non_consumable
  RC_PRODUCT_DISPLAY_NAME=LifeClock Lifetime
  RC_ENTITLEMENT_LOOKUP_KEY=premium
  RC_ENTITLEMENT_DISPLAY_NAME=Premium
  RC_OFFERING_LOOKUP_KEY=default
  RC_OFFERING_DISPLAY_NAME=Default Offering
  RC_PACKAGE_LOOKUP_KEY=lifetime
  RC_PACKAGE_DISPLAY_NAME=Lifetime
  RC_PACKAGE_POSITION=1
  RC_PACKAGE_ELIGIBILITY=all
  RC_SET_CURRENT_OFFERING=true

  # Optional: update app with ASC credentials in RevenueCat
  RC_APPSTORE_CONNECT_API_KEY_PATH=
  RC_APPSTORE_CONNECT_API_KEY_ID=
  RC_APPSTORE_CONNECT_API_KEY_ISSUER=
  RC_APPSTORE_CONNECT_VENDOR_NUMBER=
  RC_APPSTORE_SHARED_SECRET=
USAGE
}

ENV_FILE=".env.hybrid"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            [[ $# -ge 2 ]] || die "--env requires a file path"
            ENV_FILE="$2"
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

require_cmd curl jq mktemp
require_env RC_API_KEY RC_BUNDLE_ID RC_STORE_PRODUCT_ID

if [[ -z "${RC_PROJECT_ID:-}" && -z "${RC_PROJECT_NAME:-}" ]]; then
    die "Set RC_PROJECT_ID or RC_PROJECT_NAME"
fi

RC_API_BASE="${RC_API_BASE:-https://api.revenuecat.com/v2}"
RC_API_BASE="${RC_API_BASE%/}"

RC_APP_NAME="${RC_APP_NAME:-LifeClock}"
RC_APP_TYPE="${RC_APP_TYPE:-app_store}"
RC_PRODUCT_TYPE="${RC_PRODUCT_TYPE:-non_consumable}"
RC_PRODUCT_DISPLAY_NAME="${RC_PRODUCT_DISPLAY_NAME:-LifeClock Lifetime}"
RC_ENTITLEMENT_LOOKUP_KEY="${RC_ENTITLEMENT_LOOKUP_KEY:-premium}"
RC_ENTITLEMENT_DISPLAY_NAME="${RC_ENTITLEMENT_DISPLAY_NAME:-Premium}"
RC_OFFERING_LOOKUP_KEY="${RC_OFFERING_LOOKUP_KEY:-default}"
RC_OFFERING_DISPLAY_NAME="${RC_OFFERING_DISPLAY_NAME:-Default Offering}"
RC_PACKAGE_LOOKUP_KEY="${RC_PACKAGE_LOOKUP_KEY:-lifetime}"
RC_PACKAGE_DISPLAY_NAME="${RC_PACKAGE_DISPLAY_NAME:-Lifetime}"
RC_PACKAGE_POSITION="${RC_PACKAGE_POSITION:-1}"
RC_PACKAGE_ELIGIBILITY="${RC_PACKAGE_ELIGIBILITY:-all}"
RC_SET_CURRENT_OFFERING="${RC_SET_CURRENT_OFFERING:-true}"

RC_APPSTORE_CONNECT_API_KEY_PATH="${RC_APPSTORE_CONNECT_API_KEY_PATH:-}"
RC_APPSTORE_CONNECT_API_KEY_ID="${RC_APPSTORE_CONNECT_API_KEY_ID:-}"
RC_APPSTORE_CONNECT_API_KEY_ISSUER="${RC_APPSTORE_CONNECT_API_KEY_ISSUER:-}"
RC_APPSTORE_CONNECT_VENDOR_NUMBER="${RC_APPSTORE_CONNECT_VENDOR_NUMBER:-}"
RC_APPSTORE_SHARED_SECRET="${RC_APPSTORE_SHARED_SECRET:-}"

case "$RC_APP_TYPE" in
    app_store|mac_app_store)
        ;;
    *)
        die "RC_APP_TYPE currently supports app_store or mac_app_store"
        ;;
esac

case "$RC_PRODUCT_TYPE" in
    subscription|one_time|consumable|non_consumable|non_renewing_subscription)
        ;;
    *)
        die "RC_PRODUCT_TYPE is invalid"
        ;;
esac

case "$RC_PACKAGE_ELIGIBILITY" in
    all|google_sdk_lt_6|google_sdk_ge_6)
        ;;
    *)
        die "RC_PACKAGE_ELIGIBILITY must be all, google_sdk_lt_6, or google_sdk_ge_6"
        ;;
esac

if [[ -n "$RC_APPSTORE_CONNECT_API_KEY_PATH" && ! -f "$RC_APPSTORE_CONNECT_API_KEY_PATH" ]]; then
    die "RC_APPSTORE_CONNECT_API_KEY_PATH not found: $RC_APPSTORE_CONNECT_API_KEY_PATH"
fi

RC_LAST_STATUS=""
RC_LAST_BODY=""

rc_http() {
    local method="$1"
    local path="$2"
    local body="${3:-}"

    local normalized_path url tmp_body
    normalized_path="$(normalize_rc_path "$path")"
    url="${RC_API_BASE}${normalized_path}"
    tmp_body="$(mktemp)"

    if [[ -n "$body" ]]; then
        RC_LAST_STATUS="$(curl -sS -X "$method" "$url" \
            -H "Authorization: Bearer $RC_API_KEY" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            --data "$body" \
            -o "$tmp_body" \
            -w '%{http_code}')"
    else
        RC_LAST_STATUS="$(curl -sS -X "$method" "$url" \
            -H "Authorization: Bearer $RC_API_KEY" \
            -H "Accept: application/json" \
            -o "$tmp_body" \
            -w '%{http_code}')"
    fi

    RC_LAST_BODY="$(cat "$tmp_body")"
    rm -f "$tmp_body"
}

rc_request() {
    local method="$1"
    local path="$2"
    local body="${3:-}"

    rc_http "$method" "$path" "$body"

    if (( RC_LAST_STATUS >= 400 )); then
        printf '%s\n' "$RC_LAST_BODY" >&2
        die "RevenueCat request failed: $method $path (HTTP $RC_LAST_STATUS)"
    fi

    printf '%s\n' "$RC_LAST_BODY"
}

rc_list_all_items() {
    local path="$1"
    local next_path="$path"
    local all_items='[]'
    local guard=0

    while [[ -n "$next_path" ]]; do
        guard=$((guard + 1))
        (( guard <= 200 )) || die "Pagination guard exceeded for $path"

        local page items next_page
        page="$(rc_request GET "$next_path")" || return 1
        items="$(jq -c '.items // []' <<<"$page")"
        all_items="$(jq -cn --argjson a "$all_items" --argjson b "$items" '$a + $b')"

        next_page="$(jq -r '.next_page // empty' <<<"$page")"
        if [[ -n "$next_page" ]]; then
            next_path="$(normalize_rc_path "$next_page")"
        else
            next_path=""
        fi
    done

    printf '%s\n' "$all_items"
    return 0
}

log "Resolving RevenueCat project"
projects_json="$(rc_list_all_items "/projects?limit=100")" || die "Could not load projects. Check RC_API_KEY permissions for API v2."

project_id="${RC_PROJECT_ID:-}"

if [[ -n "$project_id" ]]; then
    project_exists="$(jq -r --arg project_id "$project_id" '[.[] | select(.id == $project_id)] | length' <<<"$projects_json")"
    [[ "$project_exists" != "0" ]] || die "RC_PROJECT_ID not found: $project_id"
else
    project_id="$(jq -r --arg project_name "$RC_PROJECT_NAME" '.[] | select(.name == $project_name) | .id' <<<"$projects_json" | head -n 1)"
    [[ -n "$project_id" ]] || die "No RevenueCat project found with RC_PROJECT_NAME=$RC_PROJECT_NAME"
fi

log "Using project_id=$project_id"

apps_json="$(rc_list_all_items "/projects/${project_id}/apps?limit=100")" || die "Could not load apps for project_id=$project_id."

app_id="${RC_APP_ID:-}"
if [[ -n "$app_id" ]]; then
    app_exists="$(jq -r --arg app_id "$app_id" '[.[] | select(.id == $app_id)] | length' <<<"$apps_json")"
    [[ "$app_exists" != "0" ]] || die "RC_APP_ID not found in project: $app_id"
else
    app_id="$(jq -r \
        --arg app_type "$RC_APP_TYPE" \
        --arg bundle_id "$RC_BUNDLE_ID" \
        --arg app_name "$RC_APP_NAME" \
        '.[]
         | select(.type == $app_type)
         | select((.app_store.bundle_id // .mac_app_store.bundle_id // "") == $bundle_id or .name == $app_name)
         | .id' <<<"$apps_json" | head -n 1)"
fi

created_app=0
if [[ -z "$app_id" ]]; then
    log "Creating RevenueCat app"

    if [[ "$RC_APP_TYPE" == "app_store" ]]; then
        app_create_payload="$(jq -cn \
            --arg name "$RC_APP_NAME" \
            --arg bundle_id "$RC_BUNDLE_ID" \
            '{name: $name, type: "app_store", app_store: {bundle_id: $bundle_id}}')"
    else
        app_create_payload="$(jq -cn \
            --arg name "$RC_APP_NAME" \
            --arg bundle_id "$RC_BUNDLE_ID" \
            '{name: $name, type: "mac_app_store", mac_app_store: {bundle_id: $bundle_id}}')"
    fi

    app_create_resp="$(rc_request POST "/projects/${project_id}/apps" "$app_create_payload")"
    app_id="$(jq -r '.id // empty' <<<"$app_create_resp")"
    [[ -n "$app_id" ]] || die "Failed to parse app ID from create response"
    created_app=1
fi

log "Using app_id=$app_id"

updated_app_credentials=0
asc_key_content=""
if [[ -n "$RC_APPSTORE_CONNECT_API_KEY_PATH" ]]; then
    asc_key_content="$(cat "$RC_APPSTORE_CONNECT_API_KEY_PATH")"
fi

if [[ -n "$asc_key_content" || -n "$RC_APPSTORE_CONNECT_API_KEY_ID" || -n "$RC_APPSTORE_CONNECT_API_KEY_ISSUER" || -n "$RC_APPSTORE_CONNECT_VENDOR_NUMBER" || -n "$RC_APPSTORE_SHARED_SECRET" ]]; then
    log "Updating RevenueCat app with App Store Connect credentials"

    if [[ "$RC_APP_TYPE" != "app_store" ]]; then
        warn "Skipping App Store credential update because RC_APP_TYPE=$RC_APP_TYPE"
    else
        app_update_payload="$(jq -cn \
            --arg bundle_id "$RC_BUNDLE_ID" \
            --arg asc_key "$asc_key_content" \
            --arg asc_key_id "$RC_APPSTORE_CONNECT_API_KEY_ID" \
            --arg asc_issuer "$RC_APPSTORE_CONNECT_API_KEY_ISSUER" \
            --arg vendor_number "$RC_APPSTORE_CONNECT_VENDOR_NUMBER" \
            --arg shared_secret "$RC_APPSTORE_SHARED_SECRET" \
            '{app_store: {bundle_id: $bundle_id}}
             | if $asc_key != "" then .app_store.app_store_connect_api_key = $asc_key else . end
             | if $asc_key_id != "" then .app_store.app_store_connect_api_key_id = $asc_key_id else . end
             | if $asc_issuer != "" then .app_store.app_store_connect_api_key_issuer = $asc_issuer else . end
             | if $vendor_number != "" then .app_store.app_store_connect_vendor_number = $vendor_number else . end
             | if $shared_secret != "" then .app_store.shared_secret = $shared_secret else . end')"

        rc_request POST "/projects/${project_id}/apps/${app_id}" "$app_update_payload" >/dev/null
        updated_app_credentials=1
    fi
fi

products_json="$(rc_list_all_items "/projects/${project_id}/products?limit=100&app_id=$(urlencode "$app_id")")" || die "Could not load products for app_id=$app_id."
product_id="$(jq -r --arg store_id "$RC_STORE_PRODUCT_ID" --arg app_id "$app_id" '.[] | select(.store_identifier == $store_id and .app_id == $app_id) | .id' <<<"$products_json" | head -n 1)"

created_product=0
if [[ -z "$product_id" ]]; then
    log "Creating RevenueCat product"
    product_create_payload="$(jq -cn \
        --arg store_identifier "$RC_STORE_PRODUCT_ID" \
        --arg app_id "$app_id" \
        --arg product_type "$RC_PRODUCT_TYPE" \
        --arg display_name "$RC_PRODUCT_DISPLAY_NAME" \
        '{
            store_identifier: $store_identifier,
            app_id: $app_id,
            type: $product_type,
            display_name: $display_name
        }')"

    product_create_resp="$(rc_request POST "/projects/${project_id}/products" "$product_create_payload")"
    product_id="$(jq -r '.id // empty' <<<"$product_create_resp")"
    [[ -n "$product_id" ]] || die "Failed to parse product ID from create response"
    created_product=1
fi

log "Using product_id=$product_id"

entitlements_json="$(rc_list_all_items "/projects/${project_id}/entitlements?limit=100")" || die "Could not load entitlements."
entitlement_id="$(jq -r --arg lookup_key "$RC_ENTITLEMENT_LOOKUP_KEY" '.[] | select(.lookup_key == $lookup_key) | .id' <<<"$entitlements_json" | head -n 1)"

created_entitlement=0
if [[ -z "$entitlement_id" ]]; then
    log "Creating RevenueCat entitlement"
    entitlement_create_payload="$(jq -cn \
        --arg lookup_key "$RC_ENTITLEMENT_LOOKUP_KEY" \
        --arg display_name "$RC_ENTITLEMENT_DISPLAY_NAME" \
        '{lookup_key: $lookup_key, display_name: $display_name}')"

    entitlement_create_resp="$(rc_request POST "/projects/${project_id}/entitlements" "$entitlement_create_payload")"
    entitlement_id="$(jq -r '.id // empty' <<<"$entitlement_create_resp")"
    [[ -n "$entitlement_id" ]] || die "Failed to parse entitlement ID from create response"
    created_entitlement=1
fi

log "Using entitlement_id=$entitlement_id"

entitlement_products="$(rc_list_all_items "/projects/${project_id}/entitlements/${entitlement_id}/products?limit=100")" || die "Could not load entitlement products."
is_product_attached_to_entitlement="$(jq -r --arg product_id "$product_id" '[.[] | select(.id == $product_id)] | length' <<<"$entitlement_products")"

attached_product_to_entitlement=0
if [[ "$is_product_attached_to_entitlement" == "0" ]]; then
    log "Attaching product to entitlement"
    attach_entitlement_payload="$(jq -cn --arg product_id "$product_id" '{product_ids: [$product_id]}')"
    rc_request POST "/projects/${project_id}/entitlements/${entitlement_id}/actions/attach_products" "$attach_entitlement_payload" >/dev/null
    attached_product_to_entitlement=1
fi

offerings_json="$(rc_list_all_items "/projects/${project_id}/offerings?limit=100")" || die "Could not load offerings."
offering_id="$(jq -r --arg lookup_key "$RC_OFFERING_LOOKUP_KEY" '.[] | select(.lookup_key == $lookup_key) | .id' <<<"$offerings_json" | head -n 1)"

created_offering=0
if [[ -z "$offering_id" ]]; then
    log "Creating RevenueCat offering"
    offering_create_payload="$(jq -cn \
        --arg lookup_key "$RC_OFFERING_LOOKUP_KEY" \
        --arg display_name "$RC_OFFERING_DISPLAY_NAME" \
        '{lookup_key: $lookup_key, display_name: $display_name}')"

    offering_create_resp="$(rc_request POST "/projects/${project_id}/offerings" "$offering_create_payload")"
    offering_id="$(jq -r '.id // empty' <<<"$offering_create_resp")"
    [[ -n "$offering_id" ]] || die "Failed to parse offering ID from create response"
    created_offering=1
fi

log "Using offering_id=$offering_id"

offering_is_current="$(jq -r --arg offering_id "$offering_id" '.[] | select(.id == $offering_id) | .is_current // false' <<<"$offerings_json" | head -n 1)"
set_offering_current=0

if bool_is_true "$RC_SET_CURRENT_OFFERING" && [[ "$offering_is_current" != "true" ]]; then
    log "Setting offering as current"
    set_current_payload='{"is_current":true}'
    rc_request POST "/projects/${project_id}/offerings/${offering_id}" "$set_current_payload" >/dev/null
    set_offering_current=1
fi

packages_json="$(rc_list_all_items "/projects/${project_id}/offerings/${offering_id}/packages?limit=100")" || die "Could not load packages for offering_id=$offering_id."
package_id="$(jq -r \
    --arg lookup_key "$RC_PACKAGE_LOOKUP_KEY" \
    --arg display_name "$RC_PACKAGE_DISPLAY_NAME" \
    '.[]
     | select(.lookup_key == $lookup_key or .display_name == $display_name)
     | .id' <<<"$packages_json" | head -n 1)"

created_package=0
if [[ -z "$package_id" ]]; then
    log "Creating RevenueCat package"
    package_create_payload="$(jq -cn \
        --arg lookup_key "$RC_PACKAGE_LOOKUP_KEY" \
        --arg display_name "$RC_PACKAGE_DISPLAY_NAME" \
        --argjson position "$RC_PACKAGE_POSITION" \
        '{lookup_key: $lookup_key, display_name: $display_name, position: $position}')"

    package_create_resp="$(rc_request POST "/projects/${project_id}/offerings/${offering_id}/packages" "$package_create_payload")"
    package_id="$(jq -r '.id // empty' <<<"$package_create_resp")"
    [[ -n "$package_id" ]] || die "Failed to parse package ID from create response"
    created_package=1
fi

log "Using package_id=$package_id"

package_products="$(rc_list_all_items "/projects/${project_id}/packages/${package_id}/products?limit=100")" || die "Could not load package products for package_id=$package_id."
is_product_attached_to_package="$(jq -r --arg product_id "$product_id" --arg eligibility "$RC_PACKAGE_ELIGIBILITY" '[.[] | select(.product.id == $product_id and .eligibility_criteria == $eligibility)] | length' <<<"$package_products")"

attached_product_to_package=0
if [[ "$is_product_attached_to_package" == "0" ]]; then
    log "Attaching product to package"
    attach_package_payload="$(jq -cn \
        --arg product_id "$product_id" \
        --arg eligibility "$RC_PACKAGE_ELIGIBILITY" \
        '{products: [{product_id: $product_id, eligibility_criteria: $eligibility}]}')"

    rc_request POST "/projects/${project_id}/packages/${package_id}/actions/attach_products" "$attach_package_payload" >/dev/null
    attached_product_to_package=1
fi

public_api_keys="$(rc_list_all_items "/projects/${project_id}/apps/${app_id}/public_api_keys?limit=100")" || die "Could not load app public API keys."
rc_public_sdk_key="$(jq -r '.[] | select(.environment == "production") | .key' <<<"$public_api_keys" | head -n 1)"
if [[ -z "$rc_public_sdk_key" ]]; then
    rc_public_sdk_key="$(jq -r '.[0].key // empty' <<<"$public_api_keys")"
fi

jq -cn \
    --arg project_id "$project_id" \
    --arg app_id "$app_id" \
    --arg product_id "$product_id" \
    --arg entitlement_id "$entitlement_id" \
    --arg offering_id "$offering_id" \
    --arg package_id "$package_id" \
    --arg rc_public_sdk_key "$rc_public_sdk_key" \
    --argjson created_app "$created_app" \
    --argjson updated_app_credentials "$updated_app_credentials" \
    --argjson created_product "$created_product" \
    --argjson created_entitlement "$created_entitlement" \
    --argjson attached_product_to_entitlement "$attached_product_to_entitlement" \
    --argjson created_offering "$created_offering" \
    --argjson set_offering_current "$set_offering_current" \
    --argjson created_package "$created_package" \
    --argjson attached_product_to_package "$attached_product_to_package" \
    '{
        project_id: $project_id,
        app_id: $app_id,
        product_id: $product_id,
        entitlement_id: $entitlement_id,
        offering_id: $offering_id,
        package_id: $package_id,
        rc_public_sdk_key: (if $rc_public_sdk_key == "" then null else $rc_public_sdk_key end),
        created_app: ($created_app == 1),
        updated_app_credentials: ($updated_app_credentials == 1),
        created_product: ($created_product == 1),
        created_entitlement: ($created_entitlement == 1),
        attached_product_to_entitlement: ($attached_product_to_entitlement == 1),
        created_offering: ($created_offering == 1),
        set_offering_current: ($set_offering_current == 1),
        created_package: ($created_package == 1),
        attached_product_to_package: ($attached_product_to_package == 1)
    }'
