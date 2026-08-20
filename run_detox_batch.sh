#!/usr/bin/env bash
# run_detox_batch.sh — generate one video per topic in detox_topics.txt.
#
# MoneyPrinterTurbo's cli.py only takes a single --video-subject per run
# (verified against cli.py: no batch/topics-file flag exists upstream), so
# this wrapper loops over detox_topics.txt and invokes cli.py once per topic.
#
# Usage:
#   ./run_detox_batch.sh                # generate all topics
#   ./run_detox_batch.sh --stop-at script  # extra flags are passed through to cli.py

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

TOPICS_FILE="detox_topics.txt"

if [ ! -f "$TOPICS_FILE" ]; then
  echo "Fant ikke $TOPICS_FILE" >&2
  exit 1
fi

while IFS= read -r line || [ -n "$line" ]; do
  # skip blank lines and comment lines (starting with #)
  [ -z "$line" ] && continue
  [[ "$line" =~ ^# ]] && continue

  echo "=== Genererer video for tema: $line ==="
  uv run python cli.py \
    --video-subject "$line" \
    --video-language nb-NO \
    --voice-name nb-NO-PernilleNeural-Female \
    --video-aspect 9:16 \
    "$@"
done < "$TOPICS_FILE"
