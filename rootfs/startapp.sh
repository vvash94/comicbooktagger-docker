#!/bin/sh
# Started by the baseimage's supervisor as the configured USER_ID/GROUP_ID.
set -u

# ComicTagger keeps its settings, Comic Vine cache and logs in $HOME/.ComicTagger,
# so point HOME at the persistent /config volume.
export HOME=/config

export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"

# Open file dialogs in the comics library by default.
cd /comics 2>/dev/null || cd /config

# shellcheck disable=SC2086
exec /opt/comictagger/bin/comictagger ${COMICTAGGER_ARGS:-}
