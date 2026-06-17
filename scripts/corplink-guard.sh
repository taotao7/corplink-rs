#!/bin/bash
# Guard wrapper for corplink-rs under launchd.
#
# Why: lark (feishu) login is interactive (QR scan). If corplink is launched
# without a valid session it prints QR codes forever to the log and hammers the
# server. This wrapper ONLY launches corplink when a session already exists
# (config state == "Login"), so it can silently reuse the saved session across
# restarts/reboots but never tries an interactive login unattended.
#
# To (re)establish a session, run a manual foreground login:
#   cd /Users/tao/workspace/corplink-rs && ./target/release/corplink-rs config/config.json
# scan the QR once; that saves state=Login. After that this wrapper keeps it up.

set -u
DIR="/Users/tao/workspace/corplink-rs"
BIN="$DIR/target/release/corplink-rs"
CFG="$DIR/config/config.json"

cd "$DIR" || exit 1

# Is there a usable session? state must be "Login".
state="$(/usr/bin/python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("state") or "")' "$CFG" 2>/dev/null)"

if [ "$state" != "Login" ]; then
    echo "[$(date '+%Y-%m-%dT%H:%M:%S')] guard: no valid session (state='$state')."
    echo "[$(date '+%Y-%m-%dT%H:%M:%S')] guard: run a manual foreground login to scan the QR, then this will resume."
    # Sleep instead of exiting fast, so launchd KeepAlive doesn't hot-loop.
    sleep 600
    exit 0
fi

echo "[$(date '+%Y-%m-%dT%H:%M:%S')] guard: session present, starting corplink..."
exec "$BIN" "$CFG"
