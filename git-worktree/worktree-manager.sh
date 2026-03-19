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

# Get repo root — always the main worktree, even when called from a worktree
GIT_ROOT=$(git worktree list --porcelain | awk 'NR==1{print $2}')
WORKTREE_DIR="$GIT_ROOT/.worktrees"

# File used to pass the target cd path back to the parent shell's wt() wrapper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CD_PATH_FILE="$SCRIPT_DIR/.cd_path"

# Write the path the parent shell should cd into after this script exits
write_cd_path() {
  echo "$1" > "$CD_PATH_FILE"
}

# Ensure .worktrees is in .gitignore
ensure_gitignore() {
  if ! grep -q "worktrees" "$GIT_ROOT/.gitignore" 2>/dev/null; then
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
  write_cd_path "$worktree_path"
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
  while IFS= read -r git_file; do
    local worktree_path
    worktree_path=$(dirname "$git_file")
    count=$((count + 1))

    # Affiche le chemin relatif depuis .worktrees/ pour lisibilité
    local worktree_name
    worktree_name="${worktree_path#$WORKTREE_DIR/}"

    local branch
    branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    if [[ "$PWD" == "$worktree_path" ]]; then
      echo -e "${GREEN}✓ $worktree_name${NC} (current) → branch: $branch"
    else
      echo -e "  $worktree_name → branch: $branch"
    fi
  done < <(find "$WORKTREE_DIR" -name ".git" -not -path "*/.git/*" 2>/dev/null | sort)

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
    worktree_name="main"
  fi

  if [[ "$worktree_name" == "main" ]]; then
    echo -e "${GREEN}Switching to main repo: $GIT_ROOT${NC}"
    write_cd_path "$GIT_ROOT"
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
  write_cd_path "$worktree_path"
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

# Migrate uncommitted changes from current location to a new worktree
migrate_to_worktree() {
  local branch_name="$1"
  local from_branch="${2:-main}"

  if [[ -z "$branch_name" ]]; then
    echo -e "${RED}Error: Branch name required${NC}"
    echo ""
    show_help
    exit 1
  fi

  # Check there are uncommitted changes (staged, unstaged, or untracked)
  local has_staged has_unstaged has_untracked
  git diff --cached --quiet && has_staged=0 || has_staged=1
  git diff --quiet && has_unstaged=0 || has_unstaged=1
  [[ -z "$(git ls-files --others --exclude-standard)" ]] && has_untracked=0 || has_untracked=1

  if [[ $has_staged -eq 0 && $has_unstaged -eq 0 && $has_untracked -eq 0 ]]; then
    echo -e "${YELLOW}No uncommitted changes to migrate.${NC}"
    echo -e "Use '${BLUE}create${NC}' instead to just create the worktree."
    exit 0
  fi

  echo -e "${BLUE}Migrating uncommitted changes to new worktree: $branch_name${NC}"

  # Stash everything: staged + unstaged + untracked
  git stash push --include-untracked -m "wt-migrate: $branch_name"
  echo -e "  ${GREEN}✓ Changes stashed (stash@{0})${NC}"

  # Create the worktree (shares the same .git stash stack)
  create_worktree "$branch_name" "$from_branch"

  local worktree_path="$WORKTREE_DIR/$branch_name"

  # Restore stash inside the new worktree
  echo -e "${BLUE}Restoring stashed changes in worktree...${NC}"
  if git -C "$worktree_path" stash pop; then
    echo -e "  ${GREEN}✓ Changes restored${NC}"
  else
    echo -e "  ${YELLOW}⚠️  Stash pop had conflicts. Resolve manually in: $worktree_path${NC}"
    echo -e "  Stash is still available: run 'git stash list' to see it."
  fi

  echo ""
  echo -e "${GREEN}✓ Migration complete!${NC}"
  write_cd_path "$worktree_path"
}

# Clean up worktrees — interactive multi-select
cleanup_worktrees() {
  if [[ ! -d "$WORKTREE_DIR" ]]; then
    echo -e "${YELLOW}No worktrees to clean up${NC}"
    return
  fi

  echo -e "${BLUE}Inactive worktrees:${NC}"
  echo ""

  local names=()
  local paths=()
  local idx=0

  while IFS= read -r git_file; do
    local worktree_path
    worktree_path=$(dirname "$git_file")
    local worktree_name
    worktree_name="${worktree_path#$WORKTREE_DIR/}"

    if [[ "$PWD" == "$worktree_path" ]]; then
      echo -e "  ${YELLOW}(skip) $worktree_name — currently active${NC}"
      continue
    fi

    idx=$((idx + 1))
    names+=("$worktree_name")
    paths+=("$worktree_path")
    local branch
    branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo -e "  ${YELLOW}$idx)${NC} $worktree_name ${BLUE}(branch: $branch)${NC}"
  done < <(find "$WORKTREE_DIR" -name ".git" -not -path "*/.git/*" 2>/dev/null | sort)

  if [[ $idx -eq 0 ]]; then
    echo -e "${GREEN}No inactive worktrees to clean up${NC}"
    return
  fi

  echo ""
  echo -e "Remove which? (${YELLOW}1 3${NC} / ${YELLOW}all${NC} / ${YELLOW}q${NC} to quit)"
  printf "  > "
  read -r selection

  [[ "$selection" == "q" || -z "$selection" ]] && { echo -e "${YELLOW}Cancelled${NC}"; return; }

  local selected_paths=()
  if [[ "$selection" == "all" ]]; then
    selected_paths=("${paths[@]}")
  else
    for num in $selection; do
      if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= idx )); then
        selected_paths+=("${paths[$((num - 1))]}")
      else
        echo -e "  ${YELLOW}Ignored: $num${NC}"
      fi
    done
  fi

  if [[ ${#selected_paths[@]} -eq 0 ]]; then
    echo -e "${YELLOW}Nothing selected${NC}"
    return
  fi

  echo -e "${BLUE}Removing...${NC}"
  for worktree_path in "${selected_paths[@]}"; do
    local worktree_name
    worktree_name="${worktree_path#$WORKTREE_DIR/}"
    git worktree remove "$worktree_path" --force 2>/dev/null || rm -rf "$worktree_path"
    echo -e "  ${GREEN}✓ Removed: $worktree_name${NC}"
  done

  git worktree prune

  if [[ -z "$(ls -A "$WORKTREE_DIR" 2>/dev/null)" ]]; then
    rmdir "$WORKTREE_DIR" 2>/dev/null || true
    echo -e "${GREEN}✓ Removed empty .worktrees/ directory${NC}"
  fi

  echo -e "${GREEN}Done!${NC}"
}

SCRIPT_URL="https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree/worktree-manager.sh"
SCRIPT_SELF="${BASH_SOURCE[0]}"

# Self-update from GitHub
update_self() {
  echo -e "${BLUE}Updating worktree-manager.sh...${NC}"

  if ! command -v curl &>/dev/null; then
    echo -e "${RED}Error: curl is required for updates${NC}"
    exit 1
  fi

  local tmp_file
  tmp_file=$(mktemp)

  if curl -sSL "$SCRIPT_URL" -o "$tmp_file"; then
    chmod +x "$tmp_file"
    mv "$tmp_file" "$SCRIPT_SELF"
    echo -e "${GREEN}✓ Updated successfully${NC}"
    echo -e "  Source: ${BLUE}$SCRIPT_URL${NC}"
    echo -e "  Target: $SCRIPT_SELF"
  else
    rm -f "$tmp_file"
    echo -e "${RED}Error: failed to download update${NC}"
    exit 1
  fi
}

show_help() {
  cat << EOF
Git Worktree Manager

Usage: worktree-manager.sh <command> [options]

Commands:
  create <branch> [from]   Create new worktree (copies .env files automatically)
                           (from defaults to main)
  migrate <branch> [from]  Move uncommitted changes from current repo to a new worktree
                           (stash → create worktree → stash pop)
  list | ls                List all worktrees and current status
  switch | go [name]       Switch to a worktree (or 'main' to go back)
  copy-env | env [name]    Copy .env files from main repo to worktree
  cleanup | clean          Interactively remove inactive worktrees
  update                   Update this script to the latest version from GitHub
  help                     Show this help

Examples:
  worktree-manager.sh create feat/ALM-1234/my-feature
  worktree-manager.sh create fix/ALM-5678/my-fix main
  worktree-manager.sh migrate feat/ALM-1234/my-feature
  worktree-manager.sh list
  worktree-manager.sh switch feat/ALM-1234/my-feature
  worktree-manager.sh copy-env feat/ALM-1234/my-feature
  worktree-manager.sh cleanup
  worktree-manager.sh update

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
    create)        create_worktree "$2" "$3" ;;
    migrate|mv)    migrate_to_worktree "$2" "$3" ;;
    list|ls)       list_worktrees ;;
    switch|go)     switch_worktree "$2" ;;
    copy-env|env)  copy_env_to_worktree "$2" ;;
    cleanup|clean) cleanup_worktrees ;;
    update)        update_self ;;
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
