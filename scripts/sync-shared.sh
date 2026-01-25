#!/bin/bash
# Sync shared files to individual skills
# Run after editing files in _shared/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/plugins/aws-beanstalk/skills"
SHARED_DIR="$SKILLS_DIR/_shared"

echo "Syncing shared files..."

# Get list of skills (directories excluding _shared)
skills=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -not -name "_shared" -exec basename {} \;)

# Sync references to all skills
for skill in $skills; do
  skill_dir="$SKILLS_DIR/$skill"

  # Create references directory if needed
  if [ -d "$SHARED_DIR/references" ]; then
    mkdir -p "$skill_dir/references"
    cp -r "$SHARED_DIR/references/"* "$skill_dir/references/" 2>/dev/null || true
    echo "  Synced references to $skill"
  fi
done

# Sync scripts only to skills that reference them
for skill in $skills; do
  skill_dir="$SKILLS_DIR/$skill"
  skill_md="$skill_dir/SKILL.md"

  if [ -f "$skill_md" ]; then
    # Check if skill references eb-api.sh
    if grep -q "eb-api.sh" "$skill_md" 2>/dev/null; then
      mkdir -p "$skill_dir/scripts"
      cp "$SHARED_DIR/scripts/eb-api.sh" "$skill_dir/scripts/"
      chmod +x "$skill_dir/scripts/eb-api.sh"
      echo "  Synced eb-api.sh to $skill"
    fi
  fi
done

echo "Done!"
