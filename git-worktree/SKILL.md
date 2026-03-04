# Git Worktree Skill for Claude Code

This skill adds a `/git-worktree` slash command to Claude Code for managing Git worktrees.

## Installation

```bash
# 1. Copy the script
mkdir -p ~/.claude/scripts/git-worktree
cp worktree-manager.sh ~/.claude/scripts/git-worktree/worktree-manager.sh
chmod +x ~/.claude/scripts/git-worktree/worktree-manager.sh

# 2. Install the Claude Code command
mkdir -p ~/.claude/commands
cp SKILL.md ~/.claude/commands/git-worktree.md
```

## Usage in Claude Code

Once installed, describe what you want in natural language or use the slash command:

```
/git-worktree create feat/ALM-1234/my-feature
/git-worktree list
/git-worktree cleanup
```

## How Claude uses this skill

When invoked, Claude runs the script via Bash:

```bash
bash ~/.claude/scripts/git-worktree/worktree-manager.sh <command> [args]
```

## Workflow

For every new feature or fix:

1. Create a Jira ticket
2. Create a worktree: `/git-worktree create feat/ALM-XXXX/my-feature`
3. `cd` into the worktree path shown by the command
4. Work on the feature in isolation
5. When done: `/git-worktree cleanup`

## Commands

- **create** `<branch> [from-branch]` — Create worktree + vendor symlink + copy `.env` files. Defaults to branching from `main`.
- **list** — List all worktrees with branch and status.
- **switch** `<name>` — Show path to switch to (use `main` to go back).
- **copy-env** `[name]` — Copy `.env*` files from main repo to worktree.
- **cleanup** — Interactively remove inactive worktrees.

## Notes

- Worktrees are stored in `.worktrees/` at repo root (auto-added to `.gitignore`)
- `vendor/` is symlinked (not copied) to avoid duplicating dependencies
- `cd` into the worktree must be done by the user — Claude shows the path
- Each worktree is fully independent: separate working directory, can push/commit independently

## Arguments

$ARGUMENTS
