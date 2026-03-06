#!/bin/bash

# Git Worktree Manager
# Handles creating, listing, switching, and cleaning up Git worktrees
# KISS principle: Simple, interactive, opinionated

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get repo root
GIT_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_DIR="$GIT_ROOT/.worktrees"

# Ensure .worktrees is in .gitignore
ensure_gitignore() {
  if ! grep -q "^\.worktrees$" "$GIT_ROOT/.gitignore" 2>/dev/null; then
    echo ".worktrees" >> "$GIT_ROOT/.gitignore"
    echo -e "  ${GREEN}✓ Added .worktrees to .gitignore${NC}"
  fi
}

# Copy .env files from main repo to worktree
copy_env_files() {
  local worktree_path="$1"

  echo -e "${BLUE}Copying environment files...${NC}"

  # Find all .env* files in root (excluding .env.example which should be in git)
  local env_files=()
  for f in "$GIT_ROOT"/.env*; do
    if [[ -f "$f" ]]; then
      local basename=$(basename "$f")
      # Skip .env.example (that's typically committed to git)
      if [[ "$basename" != ".env.example" ]]; then
        env_files+=("$basename")
      fi
    fi
  done

  if [[ ${#env_files[@]} -eq 0 ]]; then
    echo -e "  ${YELLOW}ℹ️  No .env files found in main repository${NC}"
    return
  fi

  local copied=0
  for env_file in "${env_files[@]}"; do
    local source="$GIT_ROOT/$env_file"
    local dest="$worktree_path/$env_file"

    if [[ -f "$dest" ]]; then
      echo -e "  ${YELLOW}⚠️  $env_file already exists, backing up to ${env_file}.backup${NC}"
      cp "$dest" "${dest}.backup"
    fi

    cp "$source" "$dest"
    echo -e "  ${GREEN}✓ Copied $env_file${NC}"
    copied=$((copied + 1))
  done

  echo -e "  ${GREEN}✓ Copied $copied environment file(s)${NC}"
}

# Create a new worktree
create_worktree() {
  local branch_name="$1"
  local from_branch="${2:-main}"

  if [[ -z "$branch_name" ]]; then
    echo -e "${RED}Error: Branch name required${NC}"
    echo ""
    show_help
    exit 1
  fi

  local worktree_path="$WORKTREE_DIR/$branch_name"

  # Check if worktree already exists
  if [[ -d "$worktree_path" ]]; then
    echo -e "${YELLOW}Worktree already exists at: $worktree_path${NC}"
    echo -e "Switch to it instead? (y/n)"
    read -r response
    if [[ "$response" == "y" ]]; then
      switch_worktree "$branch_name"
    fi
    return
  fi

  echo -e "${BLUE}Creating worktree: $branch_name${NC}"
  echo "  From: $from_branch"
  echo "  Path: $worktree_path"

  # Update base branch
  echo -e "${BLUE}Updating $from_branch...${NC}"
  git fetch origin "$from_branch" 2>/dev/null || true

  # Create worktree directory and ensure .gitignore
  mkdir -p "$WORKTREE_DIR"
  ensure_gitignore

  # Check if branch already exists (local or remote)
  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    echo -e "${BLUE}Branch $branch_name already exists locally, using it...${NC}"
    git worktree add "$worktree_path" "$branch_name"
  elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
    echo -e "${BLUE}Branch $branch_name exists on remote, checking out...${NC}"
    git worktree add "$worktree_path" --track "origin/$branch_name"
  else
    echo -e "${BLUE}Creating new branch $branch_name from $from_branch...${NC}"
    git worktree add -b "$branch_name" "$worktree_path" "origin/$from_branch" 2>/dev/null \
      || git worktree add -b "$branch_name" "$worktree_path" "$from_branch"
  fi

  # Symlink vendor if it exists in main repo (avoids duplicating heavy dependencies)
  if [[ -d "$GIT_ROOT/vendor" ]]; then
    local depth
    depth=$(echo ".worktrees/$branch_name" | tr '/' '\n' | wc -l | tr -d ' ')
    local dots
    dots=$(printf '../%.0s' $(seq 1 $depth))
    ln -sf "${dots}vendor" "$worktree_path/vendor"
    echo -e "  ${GREEN}✓ vendor → ${dots}vendor (symlink)${NC}"
  fi

  # Symlink docker/compose/docker-compose.override.yml if it exists in main repo (required for Docker/Makefile commands)
  # The Makefile reads DOCKER_COMPOSE_OVERRIDE_FILE=${WORKSPACE}/docker/compose/docker-compose.override.yml
  local override_src="$GIT_ROOT/docker/compose/docker-compose.override.yml"
  local override_dest="$worktree_path/docker/compose/docker-compose.override.yml"
  if [[ -f "$override_src" ]] && [[ -d "$worktree_path/docker/compose" ]]; then
    local depth
    depth=$(echo ".worktrees/$branch_name" | tr '/' '\n' | wc -l | tr -d ' ')
    local dots
    dots=$(printf '../%.0s' $(seq 1 $depth))
    ln -sf "${dots}docker/compose/docker-compose.override.yml" "$override_dest"
    echo -e "  ${GREEN}✓ docker/compose/docker-compose.override.yml → symlink${NC}"
  fi

  # Copy environment files
  copy_env_files "$worktree_path"

  echo ""
  echo -e "${GREEN}✓ Worktree created successfully!${NC}"
  echo ""
  echo "To switch to this worktree:"
  echo -e "${BLUE}cd $worktree_path${NC}"
}

# List all worktrees
list_worktrees() {
  echo -e "${BLUE}Git worktrees:${NC}"
  echo ""

  # Show main repo
  local main_branch
  main_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  if [[ "$PWD" == "$GIT_ROOT" ]]; then
    echo -e "${GREEN}✓ [main]${NC} → branch: $main_branch  (${GIT_ROOT})"
  else
    echo -e "  [main] → branch: $main_branch  (${GIT_ROOT})"
  fi

  if [[ ! -d "$WORKTREE_DIR" ]]; then
    echo ""
    echo -e "${YELLOW}No additional worktrees found (.worktrees/ does not exist)${NC}"
    return
  fi

  local count=0
  for worktree_path in "$WORKTREE_DIR"/*; do
    if [[ -d "$worktree_path" && -e "$worktree_path/.git" ]]; then
      count=$((count + 1))
      local worktree_name
      worktree_name=$(basename "$worktree_path")
      local branch
      branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

      if [[ "$PWD" == "$worktree_path" ]]; then
        echo -e "${GREEN}✓ $worktree_name${NC} (current) → branch: $branch"
      else
        echo -e "  $worktree_name → branch: $branch"
      fi
    fi
  done

  echo ""
  if [[ $count -eq 0 ]]; then
    echo -e "${YELLOW}No additional worktrees found${NC}"
  else
    echo -e "${BLUE}Total worktrees: $count${NC}"
  fi
}

# Switch to a worktree
switch_worktree() {
  local worktree_name="$1"

  if [[ -z "$worktree_name" ]]; then
    list_worktrees
    echo ""
    echo -e "${BLUE}Switch to which worktree? (enter name, or 'main' for main repo)${NC}"
    read -r worktree_name
  fi

  if [[ "$worktree_name" == "main" ]]; then
    echo -e "${GREEN}Switching to main repo: $GIT_ROOT${NC}"
    cd "$GIT_ROOT"
    echo -e "${BLUE}Now in: $(pwd)${NC}"
    return
  fi

  local worktree_path="$WORKTREE_DIR/$worktree_name"

  if [[ ! -d "$worktree_path" ]]; then
    echo -e "${RED}Error: Worktree not found: $worktree_name${NC}"
    echo ""
    list_worktrees
    exit 1
  fi

  echo -e "${GREEN}Switching to worktree: $worktree_name${NC}"
  cd "$worktree_path"
  echo -e "${BLUE}Now in: $(pwd)${NC}"
}

# Copy env files to an existing worktree
copy_env_to_worktree() {
  local worktree_name="$1"
  local worktree_path

  if [[ -z "$worktree_name" ]]; then
    local current_dir
    current_dir=$(pwd)
    if [[ "$current_dir" == "$WORKTREE_DIR"/* ]]; then
      worktree_path="$current_dir"
      worktree_name=$(basename "$worktree_path")
      echo -e "${BLUE}Detected current worktree: $worktree_name${NC}"
    else
      echo -e "${YELLOW}Usage: worktree-manager.sh copy-env [worktree-name]${NC}"
      echo "Or run from within a worktree to copy to current directory"
      list_worktrees
      return 1
    fi
  else
    worktree_path="$WORKTREE_DIR/$worktree_name"
    if [[ ! -d "$worktree_path" ]]; then
      echo -e "${RED}Error: Worktree not found: $worktree_name${NC}"
      list_worktrees
      return 1
    fi
  fi

  copy_env_files "$worktree_path"
}

# Clean up completed worktrees
cleanup_worktrees() {
  if [[ ! -d "$WORKTREE_DIR" ]]; then
    echo -e "${YELLOW}No worktrees to clean up${NC}"
    return
  fi

  echo -e "${BLUE}Checking for worktrees to remove...${NC}"
  echo ""

  local found=0
  local to_remove=()

  for worktree_path in "$WORKTREE_DIR"/*; do
    if [[ -d "$worktree_path" && -e "$worktree_path/.git" ]]; then
      local worktree_name
      worktree_name=$(basename "$worktree_path")

      if [[ "$PWD" == "$worktree_path" ]]; then
        echo -e "${YELLOW}(skip) $worktree_name — currently active${NC}"
        continue
      fi

      found=$((found + 1))
      to_remove+=("$worktree_path")
      local branch
      branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
      echo -e "${YELLOW}• $worktree_name${NC} (branch: $branch)"
    fi
  done

  if [[ $found -eq 0 ]]; then
    echo -e "${GREEN}No inactive worktrees to clean up${NC}"
    return
  fi

  echo ""
  echo -e "Remove $found worktree(s)? (y/n)"
  read -r response

  if [[ "$response" != "y" ]]; then
    echo -e "${YELLOW}Cleanup cancelled${NC}"
    return
  fi

  echo -e "${BLUE}Cleaning up...${NC}"
  for worktree_path in "${to_remove[@]}"; do
    local worktree_name
    worktree_name=$(basename "$worktree_path")
    git worktree remove "$worktree_path" --force 2>/dev/null || rm -rf "$worktree_path"
    echo -e "${GREEN}✓ Removed: $worktree_name${NC}"
  done

  git worktree prune

  # Remove empty .worktrees dir
  if [[ -z "$(ls -A "$WORKTREE_DIR" 2>/dev/null)" ]]; then
    rmdir "$WORKTREE_DIR" 2>/dev/null || true
    echo -e "${GREEN}✓ Removed empty .worktrees/ directory${NC}"
  fi

  echo -e "${GREEN}Cleanup complete!${NC}"
}

show_help() {
  cat << EOF
Git Worktree Manager

Usage: worktree-manager.sh <command> [options]

Commands:
  create <branch> [from]   Create new worktree (copies .env files automatically)
                           (from defaults to main)
  list | ls                List all worktrees and current status
  switch | go [name]       Switch to a worktree (or 'main' to go back)
  copy-env | env [name]    Copy .env files from main repo to worktree
  cleanup | clean          Interactively remove inactive worktrees
  help                     Show this help

Examples:
  worktree-manager.sh create feat/ALM-1234/my-feature
  worktree-manager.sh create fix/ALM-5678/my-fix main
  worktree-manager.sh list
  worktree-manager.sh switch feat/ALM-1234/my-feature
  worktree-manager.sh copy-env feat/ALM-1234/my-feature
  worktree-manager.sh cleanup

Notes:
  - Worktrees are stored in .worktrees/ (auto-added to .gitignore)
  - .env files are copied automatically on create
  - Each worktree has its own isolated working directory
  - You can push/commit from any worktree independently
EOF
}

# Main
main() {
  local command="${1:-list}"

  case "$command" in
    create)       create_worktree "$2" "$3" ;;
    list|ls)      list_worktrees ;;
    switch|go)    switch_worktree "$2" ;;
    copy-env|env) copy_env_to_worktree "$2" ;;
    cleanup|clean) cleanup_worktrees ;;
    help|-h|--help) show_help ;;
    *)
      echo -e "${RED}Unknown command: $command${NC}"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

main "$@"
