#!/bin/bash
# AWS Elastic Beanstalk Skills Installer
# Supports Claude Code, OpenAI Codex, OpenCode, and Cursor

set -e

REPO_URL="https://github.com/shinmc/aws-beanstalk-skills"
REPO_RAW="https://raw.githubusercontent.com/shinmc/aws-beanstalk-skills/main"
SKILLS_DIR="plugins/aws-beanstalk/skills"

# Detect agent
detect_agent() {
  if command -v claude &>/dev/null; then
    echo "claude"
  elif command -v codex &>/dev/null; then
    echo "codex"
  elif command -v opencode &>/dev/null; then
    echo "opencode"
  elif [ -d "$HOME/.cursor" ]; then
    echo "cursor"
  else
    echo "unknown"
  fi
}

# Get skills directory for agent
get_skills_dir() {
  case "$1" in
    claude)
      echo "$HOME/.claude/skills"
      ;;
    codex)
      echo "$HOME/.codex/skills"
      ;;
    opencode)
      echo "$HOME/.config/opencode/skill"
      ;;
    cursor)
      echo "$HOME/.cursor/skills"
      ;;
    *)
      echo "$HOME/.claude/skills"
      ;;
  esac
}

# Download skills
download_skills() {
  local dest="$1"
  local skills=(
    "eb"
    "deploy"
    "status"
    "logs"
    "config"
    "troubleshoot"
    "environment"
    "app"
    "maintenance"
    "eb-infra"
    "eb-docs"
  )

  echo "Downloading skills to $dest..."

  # Create directories
  mkdir -p "$dest/aws-beanstalk"

  # Download each skill
  for skill in "${skills[@]}"; do
    echo "  - $skill"
    mkdir -p "$dest/aws-beanstalk/$skill"
    curl -fsSL "$REPO_RAW/$SKILLS_DIR/$skill/SKILL.md" -o "$dest/aws-beanstalk/$skill/SKILL.md"
  done

  # Download shared references
  echo "  - shared references"
  mkdir -p "$dest/aws-beanstalk/_shared/references"

  curl -fsSL "$REPO_RAW/$SKILLS_DIR/_shared/references/config-options.md" -o "$dest/aws-beanstalk/_shared/references/config-options.md"
  curl -fsSL "$REPO_RAW/$SKILLS_DIR/_shared/references/health-states.md" -o "$dest/aws-beanstalk/_shared/references/health-states.md"
  curl -fsSL "$REPO_RAW/$SKILLS_DIR/_shared/references/platforms.md" -o "$dest/aws-beanstalk/_shared/references/platforms.md"
  curl -fsSL "$REPO_RAW/$SKILLS_DIR/_shared/references/cost-optimization.md" -o "$dest/aws-beanstalk/_shared/references/cost-optimization.md"

  echo "Done!"
}

# Main
main() {
  echo "AWS Elastic Beanstalk Skills Installer"
  echo "======================================"
  echo ""

  # Check prerequisites
  if ! command -v curl &>/dev/null; then
    echo "Error: curl is required but not installed."
    exit 1
  fi

  # Detect agent
  agent=$(detect_agent)
  echo "Detected agent: $agent"

  # Get destination directory
  dest=$(get_skills_dir "$agent")
  echo "Skills directory: $dest"
  echo ""

  # Confirm
  read -p "Install AWS Elastic Beanstalk skills? [Y/n] " -n 1 -r
  echo ""

  if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Installation cancelled."
    exit 0
  fi

  # Download
  download_skills "$dest"

  echo ""
  echo "Installation complete!"
  echo ""
  echo "Available skills:"
  echo "  - eb          : General entry point"
  echo "  - deploy      : Deploy application versions"
  echo "  - status      : Check status & health"
  echo "  - logs        : View logs & events"
  echo "  - config      : Manage configuration"
  echo "  - troubleshoot: Diagnose issues"
  echo "  - environment : Manage environments"
  echo "  - app         : Manage applications"
  echo "  - maintenance : Platform updates"
  echo "  - eb-infra    : AWS infrastructure (SSL, domains, secrets, DB, security, costs)"
  echo "  - eb-docs     : Documentation & best practices"
  echo ""
  echo "Make sure AWS CLI is configured: aws configure"
}

main "$@"
