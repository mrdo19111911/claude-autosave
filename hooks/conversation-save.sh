#!/bin/bash
# conversation-save.sh — Save conversation transcript on session end
# Portable: works in any project with Claude Code
# Triggered by: Stop, SessionEnd

# Determine save directory
if [[ -n "$CLAUDE_PROJECT_DIR" ]]; then
  CONV_DIR="$CLAUDE_PROJECT_DIR/.claude/conversations"
else
  CONV_DIR="$HOME/.claude/conversations"
fi
mkdir -p "$CONV_DIR"

# Parse stdin JSON
INPUT=$(cat)

parse_json() {
  local input="$1"

  if command -v node &>/dev/null; then
    echo "$input" | node -e "
      let d='';
      process.stdin.on('data',c=>d+=c);
      process.stdin.on('end',()=>{
        try {
          const j=JSON.parse(d);
          console.log(JSON.stringify({
            transcript: j.transcript_path||'',
            session: j.session_id||'unknown',
            message: (j.last_assistant_message||'').substring(0, 5000),
            event: j.hook_event_name||'Stop'
          }));
        } catch(e) {
          console.log(JSON.stringify({transcript:'',session:'unknown',message:'',event:'Stop'}));
        }
      });
    "
    return
  fi

  if command -v python3 &>/dev/null || command -v python &>/dev/null; then
    local py=$(command -v python3 || command -v python)
    echo "$input" | "$py" -c "
import sys,json
try:
    j=json.load(sys.stdin)
    print(json.dumps({
        'transcript':j.get('transcript_path',''),
        'session':j.get('session_id','unknown'),
        'message':(j.get('last_assistant_message','') or '')[:5000],
        'event':j.get('hook_event_name','Stop')
    }))
except:
    print(json.dumps({'transcript':'','session':'unknown','message':'','event':'Stop'}))
"
    return
  fi

  echo '{"transcript":"","session":"unknown","message":"","event":"Stop"}'
}

extract() {
  local json="$1" field="$2"
  if command -v node &>/dev/null; then
    echo "$json" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{console.log(JSON.parse(d).$field||'')})"
  elif command -v python3 &>/dev/null || command -v python &>/dev/null; then
    local py=$(command -v python3 || command -v python)
    echo "$json" | "$py" -c "import sys,json;print(json.load(sys.stdin).get('$field',''))"
  fi
}

PARSED=$(parse_json "$INPUT")
TRANSCRIPT_PATH=$(extract "$PARSED" "transcript")
SESSION_ID=$(extract "$PARSED" "session")
LAST_MSG=$(extract "$PARSED" "message")
EVENT=$(extract "$PARSED" "event")

TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
SHORT_ID="${SESSION_ID:0:8}"

# Kill autosave background process
PID_FILE="$CONV_DIR/.autosave.pid"
if [[ -f "$PID_FILE" ]]; then
  AUTOSAVE_PID=$(cat "$PID_FILE" 2>/dev/null)
  if [[ -n "$AUTOSAVE_PID" ]]; then
    kill "$AUTOSAVE_PID" 2>/dev/null
  fi
  rm -f "$PID_FILE"
  rm -f "$CONV_DIR"/*_${SHORT_ID}_live.jsonl 2>/dev/null
fi

# Copy full transcript JSONL
if [[ -n "$TRANSCRIPT_PATH" ]] && [[ -f "$TRANSCRIPT_PATH" ]]; then
  cp "$TRANSCRIPT_PATH" "$CONV_DIR/${TIMESTAMP}_${SHORT_ID}_transcript.jsonl" 2>/dev/null
fi

# Create human-readable summary
SUMMARY_FILE="$CONV_DIR/${TIMESTAMP}_${SHORT_ID}_summary.md"
cat > "$SUMMARY_FILE" << HEREDOC
# Conversation Summary

- **Session**: ${SESSION_ID}
- **Date**: $(date '+%Y-%m-%d %H:%M:%S %Z')
- **Event**: ${EVENT}
- **Transcript**: ${TIMESTAMP}_${SHORT_ID}_transcript.jsonl

## Last Response

${LAST_MSG}

---
*Auto-saved by claude-autosave plugin*
HEREDOC

exit 0
