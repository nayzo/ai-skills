# Git Worktree Manager — Installation

## Installation recommandée (one-liner)

```bash
curl -sSL https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree/install.sh | bash
```

L'installateur interactif configure :
1. Le script dans `~/.local/share/git-worktree/worktree-manager.sh`
2. La fonction shell `wt()` dans ton rc file (bash/zsh/fish)
3. L'intégration IA au choix (Claude Code, Cursor, OpenCode)

Test après installation :
```bash
source ~/.zshrc   # ou ~/.bashrc
wt list
```

---

## Prérequis

- Git ≥ 2.5
- Bash
- curl (pour l'installateur et `wt update`)

---

## Installation manuelle

### 1. Script

```bash
mkdir -p ~/.local/share/git-worktree
curl -sSL https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree/worktree-manager.sh \
  -o ~/.local/share/git-worktree/worktree-manager.sh
chmod +x ~/.local/share/git-worktree/worktree-manager.sh
```

### 2. Fonction shell (bash/zsh)

Ajouter dans `~/.zshrc` ou `~/.bashrc` :

```bash
# Git Worktree Manager
wt() {
  local cd_path_file="$HOME/.local/share/git-worktree/.cd_path"
  rm -f "$cd_path_file"
  bash "$HOME/.local/share/git-worktree/worktree-manager.sh" "$@"
  local exit_code=$?
  [[ $exit_code -ne 0 ]] && return $exit_code
  local cd_path
  cd_path=$(cat "$cd_path_file" 2>/dev/null)
  if [[ -n "$cd_path" ]]; then
    rm -f "$cd_path_file"
    cd "$cd_path"
  fi
}
```

> **Pourquoi une fonction et pas un alias ?**
> Un alias lance un sous-processus — son `cd` ne peut pas affecter le shell parent.
> La fonction `wt()` lit le chemin cible dans `.cd_path` (écrit par le script) et fait le `cd` dans le shell courant.
> La logique est entièrement dans le script : `wt update` suffit pour tout mettre à jour.

### 2b. Fonction shell (fish)

Ajouter dans `~/.config/fish/config.fish` :

```fish
# Git Worktree Manager
function wt
  set cd_path_file $HOME/.local/share/git-worktree/.cd_path
  rm -f $cd_path_file
  bash $HOME/.local/share/git-worktree/worktree-manager.sh $argv
  set exit_code $status
  test $exit_code -ne 0; and return $exit_code
  if test -f $cd_path_file
    set cd_path (cat $cd_path_file)
    rm -f $cd_path_file
    test -n "$cd_path"; and cd $cd_path
  end
end
```

---

## Intégration IA

### Claude Code CLI

```bash
mkdir -p ~/.claude/commands ~/.claude/scripts/git-worktree
curl -sSL https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree/claude-code/SKILL.md \
  -o ~/.claude/commands/git-worktree.md
cp ~/.local/share/git-worktree/worktree-manager.sh ~/.claude/scripts/git-worktree/worktree-manager.sh
```

Utilisation dans Claude Code :
```
/git-worktree create feat/ALM-1234/ma-feature
/git-worktree list
/git-worktree migrate feat/ALM-1234/ma-feature
```

### OpenCode

```bash
mkdir -p ~/.config/opencode/plugins/git-worktree
curl -sSL https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree/opencode/plugin.ts \
  -o ~/.config/opencode/plugins/git-worktree/plugin.ts
```

Ajouter dans `~/.config/opencode/config.json` :
```json
{
  "plugins": ["~/.config/opencode/plugins/git-worktree/plugin.ts"]
}
```

### Cursor

Dans le projet (une fois) :
```bash
mkdir -p .cursor/rules
curl -sSL https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree/cursor/git-worktree.mdc \
  -o .cursor/rules/git-worktree.mdc
```

---

## Structure créée dans le projet

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

## Mise à jour

```bash
wt update
```

Met à jour `worktree-manager.sh` depuis GitHub. La fonction `wt()` dans ton rc file n'a pas besoin d'être modifiée.
