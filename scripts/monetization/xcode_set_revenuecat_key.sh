#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat <<'USAGE'
Usage: xcode_set_revenuecat_key.sh [--env <file>] [--project-file <pbxproj>] [--key <public_sdk_key>]

Reads RevenueCat values from env and patches Xcode build settings in project.pbxproj.

Input precedence for public SDK key:
  1) --key
  2) RC_PUBLIC_SDK_KEY
  3) REVENUECAT_PUBLIC_SDK_KEY

Optional env vars used for additional patching:
  RC_ENTITLEMENT_LOOKUP_KEY (default: premium)
  RC_OFFERING_LOOKUP_KEY    (default: default)
  RC_LIFETIME_PRODUCT_ID    (fallback: RC_STORE_PRODUCT_ID)
USAGE
}

ENV_FILE=".env.hybrid"
PROJECT_FILE="LifeClock.xcodeproj/project.pbxproj"
CLI_KEY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --env)
            [[ $# -ge 2 ]] || die "--env requires a file path"
            ENV_FILE="$2"
            shift 2
            ;;
        --project-file)
            [[ $# -ge 2 ]] || die "--project-file requires a file path"
            PROJECT_FILE="$2"
            shift 2
            ;;
        --key)
            [[ $# -ge 2 ]] || die "--key requires a value"
            CLI_KEY="$2"
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

require_cmd perl rg

[[ -f "$PROJECT_FILE" ]] || die "project file not found: $PROJECT_FILE"

RC_PUBLIC_SDK_KEY="${CLI_KEY:-${RC_PUBLIC_SDK_KEY:-${REVENUECAT_PUBLIC_SDK_KEY:-}}}"
RC_ENTITLEMENT_LOOKUP_KEY="${RC_ENTITLEMENT_LOOKUP_KEY:-premium}"
RC_OFFERING_LOOKUP_KEY="${RC_OFFERING_LOOKUP_KEY:-default}"
RC_LIFETIME_PRODUCT_ID="${RC_LIFETIME_PRODUCT_ID:-${RC_STORE_PRODUCT_ID:-}}"

require_env RC_PUBLIC_SDK_KEY
[[ -n "$RC_LIFETIME_PRODUCT_ID" ]] || die "Set RC_LIFETIME_PRODUCT_ID or RC_STORE_PRODUCT_ID"

replace_setting_value() {
    local setting_key="$1"
    local setting_value="$2"

    local setting_count
    setting_count="$(rg -N --fixed-strings "${setting_key} = " "$PROJECT_FILE" | wc -l | tr -d ' ')"
    if [[ "$setting_count" == "0" ]]; then
        warn "No matches for $setting_key in $PROJECT_FILE"
        return
    fi

    SETTING_KEY="$setting_key" SETTING_VALUE="$setting_value" perl -0pi -e '
        my $k = $ENV{"SETTING_KEY"};
        my $v = $ENV{"SETTING_VALUE"};
        $v =~ s/\\/\\\\/g;
        $v =~ s/"/\\"/g;
        my $pattern = quotemeta($k) . q{ = "[^"]*";};
        my $replacement = qq{$k = "$v";};
        s/$pattern/$replacement/g;
    ' "$PROJECT_FILE"
}

replace_setting_value "INFOPLIST_KEY_REVENUECAT_PUBLIC_SDK_KEY" "$RC_PUBLIC_SDK_KEY"
replace_setting_value "INFOPLIST_KEY_REVENUECAT_ENTITLEMENT_ID" "$RC_ENTITLEMENT_LOOKUP_KEY"
replace_setting_value "INFOPLIST_KEY_REVENUECAT_OFFERING_ID" "$RC_OFFERING_LOOKUP_KEY"
replace_setting_value "INFOPLIST_KEY_REVENUECAT_LIFETIME_PRODUCT_ID" "$RC_LIFETIME_PRODUCT_ID"

public_key_matches="$(rg -N --fixed-strings "INFOPLIST_KEY_REVENUECAT_PUBLIC_SDK_KEY = \"$RC_PUBLIC_SDK_KEY\";" "$PROJECT_FILE" | wc -l | tr -d ' ')"
entitlement_matches="$(rg -N --fixed-strings "INFOPLIST_KEY_REVENUECAT_ENTITLEMENT_ID = $RC_ENTITLEMENT_LOOKUP_KEY;" "$PROJECT_FILE" | wc -l | tr -d ' ')"
offering_matches="$(rg -N --fixed-strings "INFOPLIST_KEY_REVENUECAT_OFFERING_ID = $RC_OFFERING_LOOKUP_KEY;" "$PROJECT_FILE" | wc -l | tr -d ' ')"
product_matches="$(rg -N --fixed-strings "INFOPLIST_KEY_REVENUECAT_LIFETIME_PRODUCT_ID = $RC_LIFETIME_PRODUCT_ID;" "$PROJECT_FILE" | wc -l | tr -d ' ')"

jq -cn \
    --arg project_file "$PROJECT_FILE" \
    --arg public_sdk_key "$RC_PUBLIC_SDK_KEY" \
    --arg entitlement_id "$RC_ENTITLEMENT_LOOKUP_KEY" \
    --arg offering_id "$RC_OFFERING_LOOKUP_KEY" \
    --arg lifetime_product_id "$RC_LIFETIME_PRODUCT_ID" \
    --argjson public_key_matches "$public_key_matches" \
    --argjson entitlement_matches "$entitlement_matches" \
    --argjson offering_matches "$offering_matches" \
    --argjson product_matches "$product_matches" \
    '{
        project_file: $project_file,
        public_sdk_key: $public_sdk_key,
        entitlement_id: $entitlement_id,
        offering_id: $offering_id,
        lifetime_product_id: $lifetime_product_id,
        matches: {
            public_sdk_key: $public_key_matches,
            entitlement_id: $entitlement_matches,
            offering_id: $offering_matches,
            lifetime_product_id: $product_matches
        }
    }'
