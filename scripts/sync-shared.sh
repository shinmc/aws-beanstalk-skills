#!/bin/bash
# Sync shared files to individual skills
# Run after editing files in _shared/
# Creates symlinks instead of copies to reduce duplication

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/plugins/aws-beanstalk/skills"
SHARED_DIR="$SKILLS_DIR/_shared"

echo "Syncing shared files..."

# Get list of skills (directories excluding _shared)
skills=$(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -not -name "_shared" -exec basename {} \;)

# Sync scripts only to skills that reference eb-api.sh in allowed-tools
for skill in $skills; do
  skill_dir="$SKILLS_DIR/$skill"
  skill_md="$skill_dir/SKILL.md"

  if [ -f "$skill_md" ]; then
    # Check if skill references eb-api.sh
    if grep -q "eb-api.sh" "$skill_md" 2>/dev/null; then
      mkdir -p "$skill_dir/scripts"
      # Create symlink if not already one
      if [ ! -L "$skill_dir/scripts/eb-api.sh" ]; then
        rm -f "$skill_dir/scripts/eb-api.sh"
        ln -s "../../_shared/scripts/eb-api.sh" "$skill_dir/scripts/eb-api.sh"
        echo "  Linked eb-api.sh to $skill"
      else
        echo "  Symlink already exists for $skill"
      fi
    fi
  fi
done

echo "Done!"
