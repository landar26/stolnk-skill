#!/usr/bin/env bash
set -euo pipefail

# stolnk-push.sh — Push a file from terminal or AI agent to a Stolnk iPhone inbox.
# Usage:
#   STOLNK_INBOX=ryan ./stolnk-push.sh ./report.html
#   ./stolnk-push.sh ./report.html ryan.stolnk.com

usage() {
  cat >&2 <<'EOF'
Usage: stolnk-push.sh <file> [inbox]

Arguments:
  file   Path to the file to send (max 95 MiB via terminal route)
  inbox  Optional Stolnk name or URL (e.g. "ryan" or "https://ryan.stolnk.com").
         Falls back to $STOLNK_INBOX if omitted.

Environment:
  STOLNK_INBOX     Default inbox name or full URL
  STOLNK_PASSWORD  Optional inbox password (if password-protected)
EOF
  exit 1
}

if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
fi

FILE_PATH="$1"
INBOX_RAW="${2:-${STOLNK_INBOX:-}}"

if [[ -z "$INBOX_RAW" ]]; then
  echo "Error: No inbox specified. Pass [inbox] or set STOLNK_INBOX." >&2
  exit 1
fi

if [[ ! -f "$FILE_PATH" ]]; then
  echo "Error: File not found: $FILE_PATH" >&2
  exit 1
fi

# Check 95 MiB limit (99,614,720 bytes)
MAX_BYTES=$((95 * 1024 * 1024))
FILE_SIZE=$(wc -c < "$FILE_PATH" | tr -d ' ')
if [[ "$FILE_SIZE" -gt "$MAX_BYTES" ]]; then
  echo "Error: File is $((FILE_SIZE / 1024 / 1024)) MiB, exceeding the 95 MiB terminal limit." >&2
  echo "Tip: Open the inbox URL in a browser to send larger files (up to 20 GB)." >&2
  exit 1
fi

# Normalize inbox URL
if [[ "$INBOX_RAW" == http://* || "$INBOX_RAW" == https://* ]]; then
  INBOX_URL="${INBOX_RAW%/}"
elif [[ "$INBOX_RAW" == *.* ]]; then
  INBOX_URL="https://${INBOX_RAW%/}"
else
  INBOX_URL="https://${INBOX_RAW}.stolnk.com"
fi

CURL_ARGS=(--fail-with-body -sS)
if [[ -n "${STOLNK_PASSWORD:-}" ]]; then
  CURL_ARGS+=(-F "password=${STOLNK_PASSWORD}")
fi
CURL_ARGS+=(-F "file=@${FILE_PATH}" "$INBOX_URL")

curl "${CURL_ARGS[@]}"
echo
