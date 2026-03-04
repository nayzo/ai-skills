# git-worktree skill

A Git worktree manager for parallel branch development — designed for use with Claude Code but usable standalone.

## Why worktrees?

Git worktrees let you work on multiple branches simultaneously without stashing or switching. Each worktree is an isolated working directory sharing the same `.git` object store — no re-cloning, no re-installing dependencies.

```
repo/
├── .git/                        ← shared git objects
├── src/                         ← main branch (e.g. main)
└── .worktrees/
    ├── feat/ALM-1234/my-feature ← independent working dir
    └── fix/ALM-5678/hotfix      ← another independent working dir
```

## Features

- Creates worktrees under `.worktrees/<branch>` (auto-added to `.gitignore`)
- **Vendor symlink** — symlinks `vendor/` from main repo to avoid duplicating heavy dependencies
- **`.env` copy** — copies local `.env*` files to the new worktree automatically
- Handles existing local and remote branches
- `list`, `switch`, `copy-env`, `cleanup` commands

## Installation

```bash
# Clone or copy worktree-manager.sh somewhere on your PATH, or run directly:
bash /path/to/worktree-manager.sh <command>
```

For Claude Code, copy `SKILL.md` to `~/.claude/commands/git-worktree.md` and the script to `~/.claude/scripts/git-worktree/worktree-manager.sh`.

## Usage

```bash
bash worktree-manager.sh create feat/ALM-1234/my-feature
bash worktree-manager.sh create fix/ALM-5678/hotfix main   # branch from main explicitly
bash worktree-manager.sh list
bash worktree-manager.sh copy-env feat/ALM-1234/my-feature
bash worktree-manager.sh cleanup
```

### create

Creates a new worktree for the given branch name. If the branch doesn't exist, it is created from `main` (or from the optional second argument).

- Fetches remote before branching
- Handles existing local/remote branches
- Symlinks `vendor/` (relative path, works at any nesting depth)
- Copies `.env*` files from the main repo

```bash
bash worktree-manager.sh create feat/ALM-1234/my-feature
# → worktree at .worktrees/feat/ALM-1234/my-feature
# → .worktrees/feat/ALM-1234/my-feature/vendor → ../../../../vendor
```

### list

Lists all worktrees with their branch and current status.

### copy-env

Copies `.env*` files from the main repo to an existing worktree. Useful when env changes after worktree creation.

```bash
bash worktree-manager.sh copy-env feat/ALM-1234/my-feature
# or run from within the worktree (auto-detected):
bash worktree-manager.sh copy-env
```

### cleanup

Interactively removes inactive worktrees and runs `git worktree prune`.

## Makefile integration

Add this target to your `Makefile` for a quick team-friendly command:

```makefile
worktree: ## Create a git worktree. Usage: make worktree BRANCH=feat/ALM-XXXX/my-feature
	@[ -n "$(BRANCH)" ] || (echo "Usage: make worktree BRANCH=feat/ALM-XXXX/my-feature"; exit 1)
	bash .claude/scripts/git-worktree/worktree-manager.sh create $(BRANCH)
```

## Claude Code integration

See `SKILL.md` for the Claude Code slash command (`/git-worktree`).
