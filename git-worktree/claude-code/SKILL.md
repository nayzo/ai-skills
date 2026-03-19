# Git Worktree Manager — Claude Code

Manage Git worktrees using the `worktree-manager.sh` script.

## Script location

The script must be installed at: `~/.local/share/git-worktree/worktree-manager.sh`

Run it via Bash: `bash ~/.local/share/git-worktree/worktree-manager.sh <command> [args]`

## Commands

- **create** `<branch> [from-branch]` — Create a new worktree. Copies `.env*` files and symlinks `vendor/` automatically. Defaults to branching from `main`.
- **migrate** `<branch> [from-branch]` — Move uncommitted changes from current directory to a new worktree (stash → create → stash pop).
- **list** — List all worktrees with their branch and status.
- **copy-env** `[branch]` — Copy `.env*` files from main repo to an existing worktree.
- **switch** `[branch]` — Switch to a worktree. Without argument, switches to the main repo.
- **cleanup** — Interactively remove inactive worktrees and run `git worktree prune`.

## Behavior rules

- Always run the script via Bash: `bash ~/.local/share/git-worktree/worktree-manager.sh`
- For `create` and `migrate`: show the full output, including the path where the worktree was created
- After `create` or `migrate`: automatically `cd` into the worktree path via a Bash `cd` call (the cwd persists between Bash tool calls)
- For `cleanup`: run the script and let the user respond to the interactive prompt
- If the script is not found at `~/.local/share/git-worktree/worktree-manager.sh`, tell the user to install it first (see README.md)

## Examples

User: "crée un worktree pour feat/ALM-1234/ma-feature"
→ `bash ~/.local/share/git-worktree/worktree-manager.sh create feat/ALM-1234/ma-feature`
→ then: `cd "$(git worktree list | head -1 | awk '{print $1}')/.worktrees/feat/ALM-1234/ma-feature"`

User: "j'ai du code non commité sur main, migre-le vers feat/ALM-1234/ma-feature"
→ `bash ~/.local/share/git-worktree/worktree-manager.sh migrate feat/ALM-1234/ma-feature`
→ then: `cd "$(git worktree list | head -1 | awk '{print $1}')/.worktrees/feat/ALM-1234/ma-feature"`

User: "liste mes worktrees"
→ `bash ~/.local/share/git-worktree/worktree-manager.sh list`

User: "nettoie les worktrees"
→ `bash ~/.local/share/git-worktree/worktree-manager.sh cleanup`

User: "reviens sur main" / "switch sur main"
→ `cd "$(git worktree list | head -1 | awk '{print $1}')"`

User: "switch sur feat/ALM-1234/ma-feature"
→ `cd "$(git worktree list | head -1 | awk '{print $1}')/.worktrees/feat/ALM-1234/ma-feature"`

## Arguments

$ARGUMENTS
