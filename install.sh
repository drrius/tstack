#!/usr/bin/env bash
# Symlinks skills/ into the folders Claude Code and Codex read, so edits here take effect without reinstalling.
set -euo pipefail

root="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude_skills="${TSTACK_CLAUDE_SKILLS:-$HOME/.claude/skills}"
codex_skills="${TSTACK_CODEX_SKILLS:-$HOME/.codex/skills}"
backup="$HOME/.local/state/tstack/backup/$(date +%Y%m%d-%H%M%S)"

force=false
dry_run=false
for arg in "$@"; do
  case "$arg" in
    --force) force=true ;;
    --dry-run) dry_run=true ;;
    *) echo "usage: ./install.sh [--force] [--dry-run]" >&2; exit 2 ;;
  esac
done

run() { if $dry_run; then echo "would: $*"; else "$@"; fi; }

# ours: absent, or a symlink into this repo.
ours() {
  local path="$1"
  [ ! -e "$path" ] && [ ! -L "$path" ] && return 0
  [ -L "$path" ] && [[ "$(readlink "$path")" == "$root"/* ]]
}

# make_room: removes our old link at path, or moves someone else's entry to the backup.
make_room() {
  local path="$1"
  if [ -e "$path" ] || [ -L "$path" ]; then
    if ours "$path"; then
      run rm "$path"
    else
      run mkdir -p "$backup/$(dirname "${path#"$HOME"/}")"
      run mv "$path" "$backup/${path#"$HOME"/}"
    fi
  fi
  run mkdir -p "$(dirname "$path")"
}

place() { make_room "$1"; run ln -s "$2" "$1"; }

# stale: a link an earlier install made whose target no longer exists (a renamed or removed skill).
stale() { [ -L "$1" ] && [ ! -e "$1" ] && [[ "$(readlink "$1")" == "$root"/* ]]; }

chmod +x "$root"/skills/*/scripts/* 2>/dev/null || true

for dir in "$claude_skills" "$codex_skills"; do
  [ -d "$dir" ] || continue
  for link in "$dir"/*; do
    if stale "$link"; then run rm "$link"; fi
  done
done

linked=0
skipped=()
for dir in "$root"/skills/*/; do
  name="$(basename "$dir")"
  target="$root/skills/$name"
  c="$claude_skills/$name"
  x="$codex_skills/$name"
  if { ! ours "$c" || ! ours "$x"; } && ! $force; then
    skipped+=("$name")
    continue
  fi
  place "$c" "$target"
  place "$x" "$target"
  linked=$((linked + 1))
done

echo "linked $linked skills into $claude_skills and $codex_skills"
if [ ${#skipped[@]} -gt 0 ]; then
  echo "skipped, a different skill already uses the name: ${skipped[*]}"
  echo "rerun with --force to take them over (the old ones move to $backup)"
fi
if [ -d "$backup" ]; then echo "backed up replaced entries to $backup"; fi
