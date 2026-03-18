# git-worktree-generic

Skill Git Worktree générique — compatible **Claude Code**, **OpenCode**, **Cursor**, et usage standalone.

## Pourquoi les worktrees ?

Git worktrees permettent de travailler sur plusieurs branches **simultanément** sans stash ni checkout. Chaque worktree est un répertoire isolé qui partage le même `.git` (objets, historique, stash).

```
monrepo/
├── .git/                              ← partagé
├── src/                               ← main
└── .worktrees/
    ├── feat/ALM-1234/ma-feature       ← branche indépendante
    └── fix/ALM-5678/hotfix            ← autre branche indépendante
```

## Structure

```
git-worktree-generic/
├── worktree-manager.sh      ← script Bash, moteur commun
├── claude-code/
│   └── SKILL.md             ← slash command /git-worktree pour Claude Code CLI
├── opencode/
│   └── plugin.ts            ← plugin TypeScript pour OpenCode
├── cursor/
│   └── git-worktree.mdc     ← Cursor Rules (.cursor/rules/)
├── INSTALL.md               ← guide d'installation par outil
└── README.md                ← ce fichier
```

## Commandes

| Commande | Description |
|---|---|
| `create <branch> [from]` | Crée un worktree (copie .env, symlink vendor) |
| `migrate <branch> [from]` | Déplace le code non commité dans un nouveau worktree |
| `list` | Liste tous les worktrees actifs |
| `copy-env [branch]` | Copie les .env vers un worktree existant |
| `cleanup` | Supprime interactivement les worktrees inactifs |

## Installation rapide

Voir [INSTALL.md](./INSTALL.md).

```bash
# Script seul
mkdir -p ~/.local/share/git-worktree
cp worktree-manager.sh ~/.local/share/git-worktree/
chmod +x ~/.local/share/git-worktree/worktree-manager.sh
alias wt="bash ~/.local/share/git-worktree/worktree-manager.sh"
```
