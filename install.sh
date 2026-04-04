#!/usr/bin/env bash
set -euo pipefail

main() {
  local SKILL_DIR="${HOME}/.claude/skills/x-commit"
  local GLOBAL_SETTINGS="${HOME}/.claude/settings.json"

  # Clone if not already installed
  if [ -d "$SKILL_DIR" ]; then
    echo "x-commit already installed at $SKILL_DIR"
  else
    echo "Installing x-commit skill..."
    mkdir -p "${HOME}/.claude/skills"
    git clone https://github.com/ThatXliner/x-commit.git "$SKILL_DIR"
    echo "Installed to $SKILL_DIR"
  fi

  # Ask about hook guard
  echo ""
  read -rp "Install global hook guard? (validates commit format) [y/N] " install_hook
  if [[ ! "$install_hook" =~ ^[Yy]$ ]]; then
    echo ""
    echo "To install the hook guard later, either re-run this script or"
    echo "add the following to your ~/.claude/settings.json manually:"
    echo ""
    echo '  "hooks": {'
    echo '    "PreToolUse": [{'
    echo '      "matcher": "Bash",'
    echo '      "hooks": [{'
    echo '        "type": "prompt",'
    echo '        "if": "Bash(git commit:*)",'
    echo '        "prompt": "Check if this git commit command follows the x-commit skill conventions...",'
    echo '        "statusMessage": "Validating commit format..."'
    echo '      }]'
    echo '    }]'
    echo '  }'
    echo ""
    echo "See the README for the full hook JSON."
    echo ""
    echo "Done! The skill will activate on next conversation start."
    return 0
  fi

  local HOOK_JSON='{
    "matcher": "Bash",
    "hooks": [
      {
        "type": "prompt",
        "if": "Bash(git commit:*)",
        "prompt": "Check if this git commit command follows the x-commit skill conventions. The commit message MUST use the format `:gitmoji: type(scope): imperative description` (e.g. `:bug: fix(auth): prevent crash when session expires`). If the message does NOT match this format, block it and tell the model to invoke the x-commit skill first with /x-commit. If it DOES match, allow it. Here is the command: $ARGUMENTS",
        "statusMessage": "Validating commit format..."
      }
    ]
  }'

  # Check for jq
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required to modify settings.json. Install it with:"
    echo "  brew install jq    # macOS"
    echo "  apt install jq     # Debian/Ubuntu"
    echo ""
    echo "Then re-run: bash $SKILL_DIR/install.sh"
    return 1
  fi

  # Create settings file if it doesn't exist
  if [ ! -f "$GLOBAL_SETTINGS" ]; then
    echo '{}' > "$GLOBAL_SETTINGS"
  fi

  # Check if hook is already installed
  if jq -e '.hooks.PreToolUse[]? | select(.matcher == "Bash") | .hooks[]? | select(.if == "Bash(git commit:*)")' "$GLOBAL_SETTINGS" &>/dev/null; then
    echo "Hook guard already installed in $GLOBAL_SETTINGS"
  else
    # Add the hook to settings
    jq --argjson hook "$HOOK_JSON" '
      .hooks //= {} |
      .hooks.PreToolUse //= [] |
      .hooks.PreToolUse += [$hook]
    ' "$GLOBAL_SETTINGS" > "${GLOBAL_SETTINGS}.tmp" && mv "${GLOBAL_SETTINGS}.tmp" "$GLOBAL_SETTINGS"
    echo "Hook guard added to $GLOBAL_SETTINGS"
  fi

  echo "Done! The skill will activate on next conversation start."
}

main "$@"
