#!/usr/bin/env bash
set -euo pipefail

log() {
    printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*" >&2
}

warn() {
    printf '[%s] WARN: %s\n' "$(date +'%H:%M:%S')" "$*" >&2
}

die() {
    printf '[%s] ERROR: %s\n' "$(date +'%H:%M:%S')" "$*" >&2
    exit 1
}

require_cmd() {
    local cmd
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || die "Missing required command: $cmd"
    done
}

load_env_file() {
    local env_file="${1:-}"
    if [[ -z "$env_file" ]]; then
        return
    fi

    if [[ -f "$env_file" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
        log "Loaded env: $env_file"
    else
        warn "Env file not found: $env_file (continuing with current environment)"
    fi
}

require_env() {
    local missing=()
    local key
    for key in "$@"; do
        if [[ -z "${!key:-}" ]]; then
            missing+=("$key")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        die "Missing required env vars: ${missing[*]}"
    fi
}

bool_is_true() {
    case "${1:-}" in
        1|true|TRUE|yes|YES|on|ON)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

urlencode() {
    jq -nr --arg value "$1" '$value | @uri'
}

normalize_rc_path() {
    local path="$1"

    path="${path#https://api.revenuecat.com/v2}"
    path="${path#http://api.revenuecat.com/v2}"
    path="${path#/v2}"

    if [[ "$path" != /* ]]; then
        path="/$path"
    fi

    printf '%s' "$path"
}
