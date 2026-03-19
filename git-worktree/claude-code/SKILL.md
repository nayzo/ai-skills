# Git Worktree Manager — Claude Code

Manage Git worktrees using the `worktree-manager.sh` script.

## Script location

Installed at: `~/.local/share/git-worktree/worktree-manager.sh`

Run via: `bash ~/.local/share/git-worktree/worktree-manager.sh <command> [args]`

If missing, tell the user to install it first (see README.md).

## Navigation (critical)

The script writes a `.cd_path` file for the shell wrapper `wt` — **the agent must `cd` explicitly**.
The Bash tool's cwd persists between calls; shell variables do not.

Main repo path: `$(git worktree list | head -1 | awk '{print $1}')`
Worktree path pattern: `<main_repo>/.worktrees/<branch-name>`

**For `switch` (to main or another worktree): just `cd` — do not call the script.**

## Commands

- **create** `<branch> [from-branch]` — Create a new worktree. Copies `.env*` files, symlinks `vendor/`. Defaults to branching from `main`.
- **migrate** `<branch> [from-branch]` — Move uncommitted changes to a new worktree (stash → create → stash pop).
- **list** — List all worktrees with branch and current status.
- **copy-env** `[branch]` — Copy `.env*` files from main repo to an existing worktree.
- **cleanup** — Interactively remove worktrees. **Terminal only** (requires user input — do not run autonomously, tell the user to run `wt cleanup` instead).

## Behavior rules

- After `create` or `migrate`: always `cd` into the new worktree immediately.
- Before `create`: if unsure whether the worktree already exists, run `list` first. If it exists, `cd` directly without calling `create` (calling `create` on an existing worktree prompts for input and blocks).
- For `switch`: `cd` directly, no script call needed.
- Show the full script output for `create` and `migrate`.

## Examples

**Create a new worktree and switch into it:**
```bash
bash ~/.local/share/git-worktree/worktree-manager.sh create feat/ALM-1234/ma-feature
cd "$(git worktree list | head -1 | awk '{print $1}')/.worktrees/feat/ALM-1234/ma-feature"
```

**Migrate uncommitted changes to a new worktree:**
```bash
bash ~/.local/share/git-worktree/worktree-manager.sh migrate feat/ALM-1234/ma-feature
cd "$(git worktree list | head -1 | awk '{print $1}')/.worktrees/feat/ALM-1234/ma-feature"
```

**List worktrees:**
```bash
bash ~/.local/share/git-worktree/worktree-manager.sh list
```

**Switch to a worktree:**
```bash
cd "$(git worktree list | head -1 | awk '{print $1}')/.worktrees/feat/ALM-1234/ma-feature"
```

**Switch back to main:**
```bash
cd "$(git worktree list | head -1 | awk '{print $1}')"
```

**Copy env files to an existing worktree:**
```bash
bash ~/.local/share/git-worktree/worktree-manager.sh copy-env feat/ALM-1234/ma-feature
```

## Arguments

$ARGUMENTS
