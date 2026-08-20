#!/usr/bin/env bash
# add_pexels_key.sh — paste a Pexels API key into config.toml without it ever
# appearing on screen, in shell history, or in a Claude Code conversation.
#
# Same pattern as used for the LiteLLM key: silent prompt (read -s), value
# piped over stdin (not argv, so it doesn't show in `ps aux`), and the script
# only ever prints a length/confirmation — never the value itself.
#
# Run this yourself, directly in your own terminal — not by asking Claude to
# run it — so the key never touches this chat at all.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

CONFIG_FILE="config.toml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Fant ikke $CONFIG_FILE — kjør scriptet fra MoneyPrinterTurbo-mappen." >&2
  exit 1
fi

read -r -s -p "Lim inn Pexels API-nøkkel (skjules mens du skriver, trykk Enter): " PEXELS_KEY
echo

if [ -z "$PEXELS_KEY" ]; then
  echo "Ingen nøkkel oppgitt, avbryter." >&2
  exit 1
fi

printf '%s' "$PEXELS_KEY" | python3 - "$CONFIG_FILE" <<'PYEOF'
import re
import sys

path = sys.argv[1]
key = sys.stdin.read().strip()

with open(path) as f:
    content = f.read()

pattern = re.compile(r'^pexels_api_keys\s*=\s*\[.*\]$', re.MULTILINE)
if not pattern.search(content):
    print("Fant ikke pexels_api_keys-linjen i config.toml", file=sys.stderr)
    sys.exit(1)

new_line = f'pexels_api_keys = ["{key}"]'
content = pattern.sub(new_line, content, count=1)

with open(path, "w") as f:
    f.write(content)

print(f"pexels_api_keys satt i {path} (nøkkel-lengde: {len(key)})")
PYEOF

unset PEXELS_KEY
echo "Ferdig. Nøkkelen ble aldri vist eller skrevet til shell-historikk."
