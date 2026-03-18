#!/bin/bash
# Git Worktree Manager — Installer
# Usage: curl -sSL https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree-generic/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

BASE_URL="https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree-generic"
INSTALL_DIR="$HOME/.local/share/git-worktree"
SCRIPT_PATH="$INSTALL_DIR/worktree-manager.sh"

echo ""
echo -e "${BOLD}${BLUE}Git Worktree Manager — Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check curl
if ! command -v curl &>/dev/null; then
  echo -e "${RED}Error: curl is required. Install it and retry.${NC}"
  exit 1
fi

# --- 1. Install script ---
echo -e "${BLUE}[1/3] Installing worktree-manager.sh...${NC}"
mkdir -p "$INSTALL_DIR"
curl -sSL "$BASE_URL/worktree-manager.sh" -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"
echo -e "  ${GREEN}✓ Installed at $SCRIPT_PATH${NC}"

# --- 2. Shell alias ---
echo ""
echo -e "${BLUE}[2/3] Setting up shell alias...${NC}"

add_alias() {
  local rc_file="$1"
  local alias_line='alias wt="bash $HOME/.local/share/git-worktree/worktree-manager.sh"'

  if [[ -f "$rc_file" ]] && grep -q "worktree-manager" "$rc_file" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠  Alias already present in $rc_file, skipping${NC}"
  else
    echo "" >> "$rc_file"
    echo "# Git Worktree Manager" >> "$rc_file"
    echo "$alias_line" >> "$rc_file"
    echo -e "  ${GREEN}✓ Alias added to $rc_file${NC}"
  fi
}

if [[ "$SHELL" == *"zsh"* ]]; then
  add_alias "$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
  add_alias "$HOME/.bashrc"
else
  add_alias "$HOME/.profile"
fi

# --- 3. AI tool integration ---
echo ""
echo -e "${BLUE}[3/3] AI tool integration${NC}"
echo ""
echo -e "  Quel outil IA utilises-tu ? (plusieurs choix possibles, ex: ${BOLD}1 3${NC})"
echo -e "    ${BOLD}1)${NC} Claude Code"
echo -e "    ${BOLD}2)${NC} Cursor"
echo -e "    ${BOLD}3)${NC} OpenCode"
echo -e "    ${BOLD}4)${NC} Aucun (standalone uniquement)"
echo ""
printf "  Ton choix : "
read -r ai_choices

for choice in $ai_choices; do
  case "$choice" in
    1)
      echo ""
      echo -e "  ${BLUE}Claude Code...${NC}"
      mkdir -p "$HOME/.claude/commands"
      mkdir -p "$HOME/.claude/scripts/git-worktree"
      curl -sSL "$BASE_URL/claude-code/SKILL.md" -o "$HOME/.claude/commands/git-worktree.md"
      cp "$SCRIPT_PATH" "$HOME/.claude/scripts/git-worktree/worktree-manager.sh"
      echo -e "  ${GREEN}✓ SKILL.md → ~/.claude/commands/git-worktree.md${NC}"
      echo -e "  ${GREEN}✓ Script  → ~/.claude/scripts/git-worktree/worktree-manager.sh${NC}"
      echo -e "  ${YELLOW}  Usage dans Claude Code : /git-worktree create feat/xxx${NC}"
      ;;
    2)
      echo ""
      echo -e "  ${BLUE}Cursor...${NC}"
      printf "  Chemin vers ton projet (ex: ~/www/monrepo) : "
      read -r project_path
      project_path="${project_path/#\~/$HOME}"
      if [[ ! -d "$project_path" ]]; then
        echo -e "  ${RED}Dossier introuvable : $project_path${NC}"
      else
        mkdir -p "$project_path/.cursor/rules"
        curl -sSL "$BASE_URL/cursor/git-worktree.mdc" -o "$project_path/.cursor/rules/git-worktree.mdc"
        echo -e "  ${GREEN}✓ Rule → $project_path/.cursor/rules/git-worktree.mdc${NC}"
        echo -e "  ${YELLOW}  Cursor charge automatiquement les rules au démarrage${NC}"
      fi
      ;;
    3)
      echo ""
      echo -e "  ${BLUE}OpenCode...${NC}"
      mkdir -p "$HOME/.config/opencode/plugins/git-worktree"
      curl -sSL "$BASE_URL/opencode/plugin.ts" -o "$HOME/.config/opencode/plugins/git-worktree/plugin.ts"
      echo -e "  ${GREEN}✓ Plugin → ~/.config/opencode/plugins/git-worktree/plugin.ts${NC}"
      echo -e "  ${YELLOW}  Ajoute dans ~/.config/opencode/config.json :${NC}"
      echo -e '  { "plugins": ["~/.config/opencode/plugins/git-worktree/plugin.ts"] }'
      ;;
    4)
      echo -e "  ${GREEN}✓ Standalone uniquement${NC}"
      ;;
    *)
      echo -e "  ${YELLOW}Choix ignoré : $choice${NC}"
      ;;
  esac
done

# --- Done ---
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}Installation terminée !${NC}"
echo ""
echo -e "  Recharge ton shell : ${BOLD}source ~/.zshrc${NC}  (ou ouvre un nouveau terminal)"
echo ""
echo -e "  Commandes disponibles :"
echo -e "    ${BOLD}wt create feat/ALM-1234/ma-feature${NC}"
echo -e "    ${BOLD}wt list${NC}"
echo -e "    ${BOLD}wt migrate feat/ALM-1234/ma-feature${NC}"
echo -e "    ${BOLD}wt cleanup${NC}"
echo -e "    ${BOLD}wt update${NC}   ← mise à jour depuis GitHub"
echo ""
