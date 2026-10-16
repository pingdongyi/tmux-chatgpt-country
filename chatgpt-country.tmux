#!/usr/bin/env bash

# TPM executes this file when loading the plugin.
exec 2>/dev/null

plugin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || exit 0
script_path="$plugin_dir/scripts/country.sh"
# Single-quote the path for tmux's shell, including paths containing spaces.
quoted_path="'${script_path//\'/\'\\\'\'}'"
country_command="#($quoted_path)"
status_right="$(tmux show-option -gqv status-right)" || exit 0

# Reloading the config must not append another copy.
if [[ "$status_right" != *"$country_command"* ]]; then
    tmux set-option -g status-right "${status_right:+$status_right }$country_command" >/dev/null
fi
exit 0
