#!/bin/bash
# conversation-autosave.sh — Periodic auto-save of conversation transcript (every 10s)
# Portable: works in any project with Claude Code
# Triggered by: SessionStart hook

# Determine save directory (project-local or fallback to home)
if [[ -n "$CLAUDE_PROJECT_DIR" ]]; then
  CONV_DIR="$CLAUDE_PROJECT_DIR/.claude/conversations"
else
  CONV_DIR="$HOME/.claude/conversations"
fi

PID_FILE="$CONV_DIR/.autosave.pid"
mkdir -p "$CONV_DIR"

# Kill any existing autosave process from previous session
if [[ -f "$PID_FILE" ]]; then
  OLD_PID=$(cat "$PID_FILE" 2>/dev/null)
  if [[ -n "$OLD_PID" ]]; then
    kill "$OLD_PID" 2>/dev/null
  fi
  rm -f "$PID_FILE"
fi

# Parse stdin JSON — try node first, fall back to python, then grep
INPUT=$(cat)

parse_field() {
  local field="$1"
  local input="$2"

  # Try node
  if command -v node &>/dev/null; then
    echo "$input" | node -e "
      let d='';
      process.stdin.on('data',c=>d+=c);
      process.stdin.on('end',()=>{
        try { console.log(JSON.parse(d).$field||''); }
        catch(e) { console.log(''); }
      });
    "
    return
  fi

  # Try python
  if command -v python3 &>/dev/null || command -v python &>/dev/null; then
    local py=$(command -v python3 || command -v python)
    echo "$input" | "$py" -c "
import sys,json
try:
    d=json.load(sys.stdin)
    print(d.get('$field',''))
except:
    print('')
"
    return
  fi

  # Fallback: grep
  echo "$input" | grep -oP '"'"$field"'"\s*:\s*"[^"]*"' | head -1 | sed 's/.*:\s*"//' | sed 's/"$//'
}

TRANSCRIPT_PATH=$(parse_field "transcript_path" "$INPUT")
SESSION_ID=$(parse_field "session_id" "$INPUT")

# If no transcript path, nothing to do
if [[ -z "$TRANSCRIPT_PATH" ]]; then
  exit 0
fi

SHORT_ID="${SESSION_ID:0:8}"
DATE_PREFIX=$(date +%Y-%m-%d)
SAVE_FILE="$CONV_DIR/${DATE_PREFIX}_${SHORT_ID}_live.jsonl"

# Launch background autosave loop
(
  while true; do
    if [[ -f "$TRANSCRIPT_PATH" ]]; then
      cp "$TRANSCRIPT_PATH" "$SAVE_FILE" 2>/dev/null
    fi
    sleep 10
  done
) &

# Save PID for cleanup
echo $! > "$PID_FILE"

exit 0
