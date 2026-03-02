# claude-autosave

A Claude Code plugin that automatically saves conversations and archives .md artifacts.

## What it does

| Feature | How | Trigger |
|---------|-----|---------|
| **Live autosave** | Copies transcript every 10 seconds | Automatic (SessionStart) |
| **Archive .md files** | Copies every .md written/edited to artifacts/ | Automatic (PostToolUse) |
| **Final save** | Full transcript + summary on session end | Automatic (Stop/SessionEnd) |
| **Manual export** | `/claude-autosave:export` — structured context dump | Manual |

## Install

### Option 1: Local plugin (test)
```bash
claude --plugin-dir ./claude-autosave
```

### Option 2: Install to user scope
```bash
claude plugin install ./claude-autosave --scope user
```

### Option 3: Git-tracked (per-project)

Copy the hooks into your project's `.claude/` directory:
```bash
cp -r claude-autosave/hooks/ your-project/.claude/hooks/
```

Then add to your project's `.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/conversation-autosave.sh\"", "timeout": 5 }] }],
    "PostToolUse": [{ "matcher": "Write|Edit", "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/archive-md.sh\"", "timeout": 10 }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/conversation-save.sh\"", "timeout": 15 }] }],
    "SessionEnd": [{ "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/conversation-save.sh\"", "timeout": 15 }] }]
  }
}
```

## Where files are saved

| Type | Location |
|------|----------|
| Live transcript | `{project}/.claude/conversations/{date}_live.jsonl` |
| Final transcript | `{project}/.claude/conversations/{date}_transcript.jsonl` |
| Summary | `{project}/.claude/conversations/{date}_summary.md` |
| Archived .md | `{project}/.claude/artifacts/{timestamp}__{filename}.md` |

## Requirements

- Claude Code CLI
- One of: `node`, `python3`, or `python` (for JSON parsing)
- `bash` shell

## How it works

```
Session Start ──► Background process starts (copies transcript every 10s)
     │
     ▼
  You chat ────► PostToolUse hook copies any .md to artifacts/
     │
     ▼
Session End ───► Kill background process
               ► Copy final transcript
               ► Generate human-readable summary
```

If session crashes mid-conversation, the `_live.jsonl` file has your transcript from at most 10 seconds ago.

## License

MIT
