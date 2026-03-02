#!/bin/bash
# archive-md.sh — Auto-copy .md files to artifacts directory
# Portable: works in any project with Claude Code
# Triggered by: PostToolUse (Write|Edit)

# Determine artifacts directory
if [[ -n "$CLAUDE_PROJECT_DIR" ]]; then
  ARTIFACTS_DIR="$CLAUDE_PROJECT_DIR/.claude/artifacts"
else
  ARTIFACTS_DIR="$HOME/.claude/artifacts"
fi

# Parse stdin JSON
INPUT=$(cat)

parse_field() {
  local field="$1"
  local input="$2"

  if command -v node &>/dev/null; then
    echo "$input" | node -e "
      let d='';
      process.stdin.on('data',c=>d+=c);
      process.stdin.on('end',()=>{
        try {
          const j=JSON.parse(d);
          const v=field.split('.').reduce((o,k)=>o&&o[k],j);
          console.log(v||'');
        } catch(e) { console.log(''); }
      });
    " 2>/dev/null
    return
  fi

  if command -v python3 &>/dev/null || command -v python &>/dev/null; then
    local py=$(command -v python3 || command -v python)
    echo "$input" | "$py" -c "
import sys,json
try:
    d=json.load(sys.stdin)
    keys='$field'.split('.')
    v=d
    for k in keys: v=v.get(k,'')
    print(v or '')
except:
    print('')
" 2>/dev/null
    return
  fi

  echo "$input" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*:\s*"//' | sed 's/"$//'
}

FILE_PATH=$(parse_field "tool_input.file_path" "$INPUT")

# Skip if empty or not .md
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

# Skip files already in artifacts/ or conversations/
if [[ "$FILE_PATH" == *"/artifacts/"* ]] || [[ "$FILE_PATH" == *"/conversations/"* ]]; then
  exit 0
fi

# Skip node_modules, .git, dist
if [[ "$FILE_PATH" == *"node_modules"* ]] || [[ "$FILE_PATH" == *".git/"* ]] || [[ "$FILE_PATH" == *"/dist/"* ]]; then
  exit 0
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME=$(basename "$FILE_PATH")

mkdir -p "$ARTIFACTS_DIR"

# Copy with timestamp prefix
if [[ -f "$FILE_PATH" ]]; then
  cp "$FILE_PATH" "$ARTIFACTS_DIR/${TIMESTAMP}__${FILENAME}" 2>/dev/null
fi

exit 0
