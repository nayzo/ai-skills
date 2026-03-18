# git-worktree

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
git-worktree/
├── worktree-manager.sh      ← script Bash, moteur commun
├── install.sh               ← installateur interactif (recommandé)
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
| `create <branch> [from]` | Crée un worktree (copie .env, symlink vendor) + cd auto |
| `migrate <branch> [from]` | Déplace le code non commité dans un nouveau worktree + cd auto |
| `switch <branch\|main>` | Bascule vers un worktree (ou le repo principal) + cd auto |
| `list` | Liste tous les worktrees actifs |
| `copy-env [branch]` | Copie les .env vers un worktree existant |
| `cleanup` | Supprime interactivement les worktrees (sélection par numéro) |
| `update` | Met à jour le script depuis GitHub |

## Installation rapide

```bash
curl -sSL https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree/install.sh | bash
```

L'installateur configure automatiquement :
- Le script dans `~/.local/share/git-worktree/`
- La fonction shell `wt()` dans ton rc file (bash/zsh/fish)
- L'intégration IA au choix (Claude Code, Cursor, OpenCode)

> La fonction `wt()` est un thin wrapper : elle lit `~/.local/share/git-worktree/.cd_path`
> après chaque commande pour changer le répertoire dans le shell courant.
> `wt update` suffit pour mettre à jour toute la logique — la fonction dans le rc file ne change plus.

Voir [INSTALL.md](./INSTALL.md) pour l'installation manuelle par outil.
