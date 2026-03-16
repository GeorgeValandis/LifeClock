#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=../monetization/lib.sh
source "$ROOT_DIR/scripts/monetization/lib.sh"

usage() {
    cat <<'USAGE'
Usage: access_audit.sh [--release-env <file>] [--hybrid-env <file>] [--app-id <id>]

Checks whether the currently configured App Store Connect and RevenueCat
credentials are sufficient to fetch analytics and monetization data.

Outputs JSON to stdout.
USAGE
}

RELEASE_ENV="$ROOT_DIR/.env.release"
HYBRID_ENV="$ROOT_DIR/.env.hybrid"
APP_ID_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --release-env)
            [[ $# -ge 2 ]] || die "--release-env requires a file path"
            RELEASE_ENV="$2"
            shift 2
            ;;
        --hybrid-env)
            [[ $# -ge 2 ]] || die "--hybrid-env requires a file path"
            HYBRID_ENV="$2"
            shift 2
            ;;
        --app-id)
            [[ $# -ge 2 ]] || die "--app-id requires a value"
            APP_ID_OVERRIDE="$2"
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

require_cmd curl jq ruby

make_jwt() {
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

asc_probe() {
    local env_file="$1"
    local key_label="$2"

    load_env_file "$env_file" >/dev/null 2>&1 || true
    require_env APPLE_ISSUER_ID APPLE_KEY_ID APPLE_PRIVATE_KEY_PATH APPLE_APP_ID

    local app_id jwt analytics_tmp analytics_status analytics_message \
        app_tmp app_status app_name bundle_id

    app_id="${APP_ID_OVERRIDE:-$APPLE_APP_ID}"
    jwt="$(make_jwt)"

    analytics_tmp="$(mktemp)"
    analytics_status="$(
        curl -sS \
            -H "Authorization: Bearer $jwt" \
            -H "Accept: application/json" \
            "https://api.appstoreconnect.apple.com/v1/apps/${app_id}/analyticsReportRequests" \
            -o "$analytics_tmp" \
            -w '%{http_code}'
    )"
    analytics_message="$(
        jq -r '.errors[0].detail // .errors[0].title // "ok"' "$analytics_tmp"
    )"
    rm -f "$analytics_tmp"

    app_tmp="$(mktemp)"
    app_status="$(
        curl -sS \
            -H "Authorization: Bearer $jwt" \
            -H "Accept: application/json" \
            "https://api.appstoreconnect.apple.com/v1/apps/${app_id}" \
            -o "$app_tmp" \
            -w '%{http_code}'
    )"
    app_name="$(jq -r '.data.attributes.name // empty' "$app_tmp")"
    bundle_id="$(jq -r '.data.attributes.bundleId // empty' "$app_tmp")"
    rm -f "$app_tmp"

    jq -n \
        --arg label "$key_label" \
        --arg app_id "$app_id" \
        --arg key_id "$APPLE_KEY_ID" \
        --arg analytics_status "$analytics_status" \
        --arg analytics_message "$analytics_message" \
        --arg app_status "$app_status" \
        --arg app_name "$app_name" \
        --arg bundle_id "$bundle_id" \
        '{
            label: $label,
            app_id: $app_id,
            key_id: $key_id,
            app_lookup: {
                http_status: ($app_status | tonumber),
                app_name: $app_name,
                bundle_id: $bundle_id
            },
            analytics_access: {
                http_status: ($analytics_status | tonumber),
                message: $analytics_message
            }
        }'
}

rc_probe() {
    load_env_file "$HYBRID_ENV" >/dev/null 2>&1 || true
    require_env RC_API_KEY

    local overview_tmp overview_status overview_message projects_tmp projects_status

    overview_tmp="$(mktemp)"
    overview_status="$(
        curl -sS \
            -H "Authorization: Bearer $RC_API_KEY" \
            -H "Accept: application/json" \
            "https://api.revenuecat.com/v2/projects/proj78873872/metrics/overview" \
            -o "$overview_tmp" \
            -w '%{http_code}'
    )"
    overview_message="$(
        jq -r '.message // .type // "ok"' "$overview_tmp"
    )"
    rm -f "$overview_tmp"

    projects_tmp="$(mktemp)"
    projects_status="$(
        curl -sS \
            -H "Authorization: Bearer $RC_API_KEY" \
            -H "Accept: application/json" \
            "https://api.revenuecat.com/v2/projects?limit=5" \
            -o "$projects_tmp" \
            -w '%{http_code}'
    )"

    jq -n \
        --arg projects_status "$projects_status" \
        --arg overview_status "$overview_status" \
        --arg overview_message "$overview_message" \
        --arg project_id "$(jq -r '.items[0].id // empty' "$projects_tmp")" \
        --arg project_name "$(jq -r '.items[0].name // empty' "$projects_tmp")" \
        '{
            project_lookup: {
                http_status: ($projects_status | tonumber),
                project_id: $project_id,
                project_name: $project_name
            },
            overview_metrics_access: {
                http_status: ($overview_status | tonumber),
                message: $overview_message
            }
        }'

    rm -f "$projects_tmp"
}

release_probe="$(asc_probe "$RELEASE_ENV" "release")"
hybrid_probe="$(asc_probe "$HYBRID_ENV" "hybrid")"
revenuecat_probe="$(rc_probe)"

jq -n \
    --argjson release "$release_probe" \
    --argjson hybrid "$hybrid_probe" \
    --argjson revenuecat "$revenuecat_probe" \
    '{
        generated_at: now | todate,
        app_store_connect: [$release, $hybrid],
        revenuecat: $revenuecat
    }'
