#!/usr/bin/env bash
# Removes only the symlinks install.sh made. Skills installed by hand or by another repo stay.
set -euo pipefail

root="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_skills="${TSTACK_CLAUDE_SKILLS:-$HOME/.claude/skills}"
codex_skills="${TSTACK_CODEX_SKILLS:-$HOME/.codex/skills}"

removed=0
for dir in "$claude_skills" "$codex_skills"; do
  [ -d "$dir" ] || continue
  for link in "$dir"/*; do
    if [ -L "$link" ] && [[ "$(readlink "$link")" == "$root"/* ]]; then
      rm "$link"
      removed=$((removed + 1))
    fi
  done
done
echo "removed $removed links from $claude_skills and $codex_skills"
