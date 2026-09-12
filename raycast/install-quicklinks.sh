#!/bin/bash
# Opens Raycast's "Create Quicklink" form pre-filled for each quicklink below.
# Raycast stores quicklinks in its own local database (not a plain config
# file), so there's nothing to symlink -- this script just re-creates them
# via Raycast's deeplink API. Confirm "Create" in the Raycast window that pops
# up for each one.
#
# Usage: ./raycast/install-quicklinks.sh

set -euo pipefail

open_quicklink() {
  local name="$1" link="$2"
  local context
  context=$(python3 -c "
import json, sys, urllib.parse
print(urllib.parse.quote(json.dumps({'name': sys.argv[1], 'link': sys.argv[2]})))
" "$name" "$link")
  open "raycast://extensions/raycast/raycast/create-quicklink?context=$context"
}

# Jira VX tickets: paste/type "VX-1234" -> browse/VX-1234
open_quicklink "Open Jira VX Ticket" "https://sironamedical.atlassian.net/browse/{argument}"

cat <<'EOF'

After creating the quicklink(s) above, enable "VX-#### pasted into root search
opens Jira" by adding the quicklink to Raycast's fallback order:
  Raycast Settings > Extensions > Quicklinks > (select the quicklink) > Fallback

With it in the fallback order, typing/pasting "VX-4836" into Raycast's root
search and hitting Enter (when nothing else matches) opens
https://sironamedical.atlassian.net/browse/VX-4836 directly.
EOF
