# tmux-chatgpt-country

Shows the two-letter `loc` country code from
[ChatGPT's trace endpoint](https://chatgpt.com/cdn-cgi/trace) in tmux's
`status-right`. Requires Bash, tmux, curl, and standard Unix utilities.

## Install with TPM

Add this to `~/.tmux.conf`, before TPM's initialization line. For this private
repository, Git must have access to your GitHub account:

```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'pingdongyi/tmux-chatgpt-country'

# Optional settings (these are the defaults).
set -g @chatgpt-country-ttl 300
set -g @chatgpt-country-placeholder '??'

set -g status-right '%H:%M'

# Keep TPM initialization last.
run '~/.tmux/plugins/tpm/tpm'
```

Reload the config and press `prefix` + `I` (capital i) to install. The plugin
appends the country command to the existing `status-right`; reloading does not
add duplicates. Set your custom `status-right` before TPM initializes.

For a local checkout, use this instead of the plugin declaration:

```tmux
run-shell '/absolute/path/to/tmux-chatgpt-country/chatgpt-country.tmux'
```

## Configuration and cache

| Option | Default | Meaning |
| --- | --- | --- |
| `@chatgpt-country-ttl` | `300` | Cache lifetime in seconds; `0` refreshes on every invocation. |
| `@chatgpt-country-placeholder` | `??` | Text displayed before a valid country is cached. |

The cache is a file at
`${XDG_CACHE_HOME:-$HOME/.cache}/tmux-chatgpt-country`. Every status invocation
prints the cached country immediately, or the placeholder if unavailable.
An expired or missing cache schedules a worker using `tmux run-shell -b`.
The worker runs:

```bash
curl -s --max-time 5 https://chatgpt.com/cdn-cgi/trace | sed -n 's/^loc=//p'
```

It writes to a temporary file beside the cache, validates the two-letter code,
then atomically renames the file into place. Errors are silent, and failed
refreshes preserve the previous cache. The updated country appears on a
subsequent status update, governed by tmux's `status-interval`.
