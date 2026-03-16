#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

parse_common_args "$@"
require_cmd node
require_cmd sips

CHROME_BIN="${CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
[[ -x "$CHROME_BIN" ]] || die "Google Chrome not found at $CHROME_BIN"

HTML_RENDERER="$ROOT_DIR/appstore/creative-builder/render_marketing_screenshots.mjs"
[[ -f "$HTML_RENDERER" ]] || die "Missing renderer at $HTML_RENDERER"

node "$HTML_RENDERER"

TMP_PROFILE="$(mktemp -d /tmp/lifeclock-marketing-chrome.XXXXXX)"
trap 'rm -rf "$TMP_PROFILE"' EXIT

render_device() {
    local device="$1"
    local width="$2"
    local height="$3"
    local html_dir="$ROOT_DIR/.asc/marketing-screenshots/html/$device"
    local output_dir="$ROOT_DIR/.asc/screenshots/upload/$device"

    [[ -d "$html_dir" ]] || die "Missing generated HTML directory $html_dir"
    mkdir -p "$output_dir"

    find "$output_dir" -maxdepth 1 -type f -name '*.png' -delete

    while IFS= read -r html_path; do
        local png_name
        png_name="$(basename "${html_path%.html}.png")"
        local png_path="$output_dir/$png_name"
        rm -f "$png_path"

        "$CHROME_BIN" \
            --headless=new \
            --disable-gpu \
            --hide-scrollbars \
            --allow-file-access-from-files \
            --disable-background-networking \
            --no-first-run \
            --no-default-browser-check \
            --user-data-dir="$TMP_PROFILE" \
            --window-size="${width},${height}" \
            --force-device-scale-factor=1 \
            --screenshot="$png_path" \
            "file://$html_path" >/dev/null 2>&1 &
        local chrome_pid=$!

        local attempts=0
        until [[ -f "$png_path" ]]; do
            sleep 0.2
            attempts=$((attempts + 1))
            if (( attempts > 100 )); then
                kill "$chrome_pid" >/dev/null 2>&1 || true
                wait "$chrome_pid" >/dev/null 2>&1 || true
                die "Timed out rendering $html_path"
            fi
        done

        sleep 0.3
        kill "$chrome_pid" >/dev/null 2>&1 || true
        wait "$chrome_pid" >/dev/null 2>&1 || true

        local actual_width actual_height
        actual_width="$(sips -g pixelWidth "$png_path" | awk '/pixelWidth/ {print $2}')"
        actual_height="$(sips -g pixelHeight "$png_path" | awk '/pixelHeight/ {print $2}')"
        [[ "$actual_width" == "$width" && "$actual_height" == "$height" ]] || {
            die "Unexpected output size for $png_path: ${actual_width}x${actual_height}"
        }
    done < <(find "$html_dir" -maxdepth 1 -type f -name '*.html' | sort)
}

log "Rendering iPhone marketing screenshots"
render_device iphone 1320 2868

log "Rendering iPad marketing screenshots"
render_device ipad 2064 2752

log "Marketing screenshots exported to .asc/screenshots/upload"
