---
name: export
description: Save current conversation to disk — use mid-session before token limit
---

# /claude-autosave:export — Save Current Conversation

You are exporting the current conversation to a persistent file for future reference.

## Steps

1. **Determine save directory**: Use `$CLAUDE_PROJECT_DIR/.claude/conversations/` if in a project, else `~/.claude/conversations/`

2. **Create a summary file** with filename `{YYYY-MM-DD}_{HHMMSS}_manual_export.md`

3. **Content must include:**
   ```markdown
   # Conversation Export (Manual)

   - **Date**: {current datetime}
   - **Export type**: Manual (/export command)

   ## Session Context
   {What module/task was being worked on}

   ## Key Decisions Made
   {Bullet list of important decisions from this conversation}

   ## Work Completed
   {What was accomplished so far}

   ## Work Remaining
   {What still needs to be done — critical for session resume}

   ## Current State
   {Any state info: current phase, branch, open files, blockers}

   ## Important Code References
   {Files modified, key file paths, line numbers}

   ---
   *Exported manually via /claude-autosave:export*
   ```

4. **Confirm** to user with the file path and a brief summary of what was saved.

## Important
- Be thorough — this export might be the ONLY record if the session dies
- Include ALL relevant context needed to resume work in a new session
- The "Work Remaining" section is the most critical part
