#!/usr/bin/env bash

# TPM executes this file when loading the plugin.
exec 2>/dev/null

plugin_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)" || exit 0
script_path="$plugin_dir/scripts/country.sh"
# Single-quote the path for tmux's shell, including paths containing spaces.
quoted_path="'${script_path//\'/\'\\\'\'}'"
country_command="#($quoted_path)"
status_right="$(tmux show-option -gqv status-right)" || exit 0
country_format='#{chatgpt_country}'

# Let the user choose the label and position in their status-right format.
if [[ "$status_right" == *"$country_format"* ]]; then
    status_right="${status_right//"$country_format"/"$country_command"}"
    tmux set-option -g status-right "$status_right" >/dev/null
# Preserve automatic placement when no format variable is configured.
elif [[ "$status_right" != *"$country_command"* ]]; then
    tmux set-option -g status-right "${status_right:+$status_right }$country_command" >/dev/null
fi
exit 0
