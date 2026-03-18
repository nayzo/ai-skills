# Git Worktree Generic — Installation

## Prérequis

- Git ≥ 2.5
- Bash
- Pour OpenCode : `@opencode-ai/plugin` (inclus dans OpenCode)

---

## 1. Installer le script (commun à tous les outils)

```bash
mkdir -p ~/.local/share/git-worktree
cp worktree-manager.sh ~/.local/share/git-worktree/
chmod +x ~/.local/share/git-worktree/worktree-manager.sh

# Alias pratique (optionnel)
echo 'alias wt="bash ~/.local/share/git-worktree/worktree-manager.sh"' >> ~/.zshrc
source ~/.zshrc
```

Test :
```bash
wt list
# ou
bash ~/.local/share/git-worktree/worktree-manager.sh list
```

---

## 2a. Claude Code CLI

```bash
mkdir -p ~/.claude/commands
mkdir -p ~/.claude/scripts/git-worktree
cp claude-code/SKILL.md ~/.claude/commands/git-worktree.md
cp worktree-manager.sh ~/.claude/scripts/git-worktree/worktree-manager.sh
chmod +x ~/.claude/scripts/git-worktree/worktree-manager.sh
```

Utilisation dans Claude Code :
```
/git-worktree create feat/ALM-1234/ma-feature
/git-worktree list
/git-worktree migrate feat/ALM-1234/ma-feature
```

---

## 2b. OpenCode

```bash
mkdir -p ~/.config/opencode/plugins/git-worktree
cp opencode/plugin.ts ~/.config/opencode/plugins/git-worktree/plugin.ts
```

Ajouter dans `~/.config/opencode/config.json` :
```json
{
  "plugins": ["~/.config/opencode/plugins/git-worktree/plugin.ts"]
}
```

Utilisation dans OpenCode — en langage naturel :
```
crée un worktree pour feat/ALM-1234/ma-feature
liste mes worktrees
j'ai du code non commité, migre-le vers feat/ALM-1234/ma-feature
```

---

## 2c. Cursor

Dans le projet (une fois) :
```bash
mkdir -p .cursor/rules
cp cursor/git-worktree.mdc .cursor/rules/
```

Cursor charge automatiquement les règles `.cursor/rules/*.mdc`.
Mentionner `@git-worktree` ou demander de créer un worktree dans Composer.

---

## 2d. Usage standalone (sans IA)

```bash
# Alias court
wt create feat/ALM-1234/ma-feature
wt list
wt migrate feat/ALM-1234/ma-feature
wt cleanup

# Ou via Makefile (ajouter dans le projet) :
# make worktree BRANCH=feat/ALM-1234/ma-feature
```

---

## Structure créée

```
monrepo/
├── .git/
├── src/
└── .worktrees/               ← gitignored automatiquement
    ├── feat/ALM-1234/desc    ← worktree isolé
    │   ├── vendor -> ../../../../vendor  (symlink)
    │   ├── .env              (copié)
    │   └── src/              (branch checkout)
    └── fix/hotfix/           ← autre worktree
```
