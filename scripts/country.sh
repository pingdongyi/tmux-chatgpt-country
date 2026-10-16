#!/usr/bin/env bash

exec 2>/dev/null

cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-chatgpt-country"

# Only tmux's background worker enters this branch. Keep all network and write
# operations out of the status command's foreground path.
if [[ "${1:-}" == --refresh ]]; then
    cache_file="${2:-$cache_file}"
    mkdir -p -- "$(dirname -- "$cache_file")" || exit 0
    temp_file="$(mktemp "${cache_file}.tmp.XXXXXX")" || exit 0
    trap 'rm -f -- "$temp_file"' EXIT
    trap 'exit 0' HUP INT TERM
    set -o pipefail
    if curl -s --max-time 5 https://chatgpt.com/cdn-cgi/trace |
        sed -n 's/^loc=//p' > "$temp_file"; then
        country="$(cat -- "$temp_file")"
        # Never replace a good cached value with an empty/error response.
        if [[ "$country" =~ ^[A-Z]{2}$ ]]; then
            mv -f -- "$temp_file" "$cache_file"
        fi
    fi
    exit 0
fi

country="$(cat -- "$cache_file")"
if [[ ! "$country" =~ ^[A-Z]{2}$ ]]; then
    country="$(tmux show-option -gqv @chatgpt-country-placeholder)"
    country="${country:-??}"
fi
# Print before checking freshness or asking tmux to launch a refresh.
printf '%s\n' "$country"

ttl="$(tmux show-option -gqv @chatgpt-country-ttl)"
[[ "$ttl" =~ ^[0-9]{1,9}$ ]] || ttl=300
ttl=$((10#$ttl))

# GNU stat (Linux), then BSD stat (macOS).
modified="$(stat -c %Y -- "$cache_file" || stat -f %m "$cache_file")"
now="$(date +%s)"
if [[ "$modified" =~ ^[0-9]+$ && "$now" =~ ^[0-9]+$ ]]; then
    (( now - modified >= ttl )) || exit 0
fi

script_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/$(basename -- "${BASH_SOURCE[0]}")"
quoted_script="'${script_path//\'/\'\\\'\'}'"
quoted_cache="'${cache_file//\'/\'\\\'\'}'"
tmux run-shell -b "$quoted_script --refresh $quoted_cache" >/dev/null
exit 0
