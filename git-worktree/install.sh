#!/bin/bash
# Git Worktree Manager — Installer
# Usage: curl -sSL https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree/install.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

BASE_URL="https://raw.githubusercontent.com/nayzo/ai-skills/main/git-worktree"
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

# --- 2. Shell function ---
echo ""
echo -e "${BLUE}[2/3] Setting up shell function...${NC}"

OS="$(uname -s)"

add_alias_to_file() {
  local rc_file="$1"

  if [[ ! -f "$rc_file" ]]; then
    return 1  # fichier absent, on essaie le suivant
  fi

  if grep -q "worktree-manager" "$rc_file" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠  Already present in $rc_file, skipping${NC}"
    echo -e "  ${YELLOW}   (to upgrade: remove the wt block from $rc_file and re-run)${NC}"
  else
    # Write a shell function so wt switch/create/migrate can cd in the current shell.
    # A plain alias (bash subshell) can't change the parent's CWD.
    cat >> "$rc_file" << 'ENDOFWT'

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
ENDOFWT
    echo -e "  ${GREEN}✓ Function added to $rc_file${NC}"
  fi
  return 0
}

# Essaie les fichiers dans l'ordre, prend le premier qui existe
resolve_rc_file() {
  local candidates=("$@")
  for f in "${candidates[@]}"; do
    if [[ -f "$f" ]]; then
      echo "$f"
      return
    fi
  done
  # Aucun trouvé : fallback sur .profile (standard POSIX, toujours présent)
  echo "$HOME/.profile"
}

add_alias_fish() {
  local fish_config="$HOME/.config/fish/config.fish"

  if grep -q "worktree-manager" "$fish_config" 2>/dev/null; then
    echo -e "  ${YELLOW}⚠  Already present in $fish_config, skipping${NC}"
    echo -e "  ${YELLOW}   (to upgrade: remove the wt block from $fish_config and re-run)${NC}"
  else
    mkdir -p "$(dirname "$fish_config")"
    cat >> "$fish_config" << 'ENDOFWT'

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
ENDOFWT
    echo -e "  ${GREEN}✓ Function added to $fish_config${NC}"
  fi
}

SOURCED_FILE=""
case "$SHELL" in
  */zsh)
    if [[ "$OS" == "Darwin" ]]; then
      SOURCED_FILE=$(resolve_rc_file "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile")
    else
      SOURCED_FILE=$(resolve_rc_file "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile")
    fi
    add_alias_to_file "$SOURCED_FILE"
    ;;
  */bash)
    if [[ "$OS" == "Darwin" ]]; then
      SOURCED_FILE=$(resolve_rc_file "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile")
    else
      SOURCED_FILE=$(resolve_rc_file "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile")
    fi
    add_alias_to_file "$SOURCED_FILE"
    ;;
  */fish)
    add_alias_fish
    SOURCED_FILE="$HOME/.config/fish/config.fish"
    ;;
  *)
    SOURCED_FILE=$(resolve_rc_file "$HOME/.profile" "$HOME/.bashrc")
    add_alias_to_file "$SOURCED_FILE"
    ;;
esac

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

      # Auto-update config.json
      local oc_config="$HOME/.config/opencode/config.json"
      local plugin_entry="$HOME/.config/opencode/plugins/git-worktree/plugin.ts"
      if command -v python3 &>/dev/null; then
        python3 - "$oc_config" "$plugin_entry" << 'PYEOF'
import json, sys, os
config_file, plugin_path = sys.argv[1], sys.argv[2]
try:
    with open(config_file) as f:
        config = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    config = {}
plugins = config.get("plugins", [])
if plugin_path not in plugins:
    plugins.append(plugin_path)
config["plugins"] = plugins
os.makedirs(os.path.dirname(config_file), exist_ok=True)
with open(config_file, "w") as f:
    json.dump(config, f, indent=2)
PYEOF
        echo -e "  ${GREEN}✓ Plugin enregistré dans $oc_config${NC}"
      elif command -v jq &>/dev/null; then
        if [[ -f "$oc_config" ]]; then
          local tmp; tmp=$(mktemp)
          jq --arg p "$plugin_entry" '.plugins = ((.plugins // []) + [$p] | unique)' "$oc_config" > "$tmp" && mv "$tmp" "$oc_config"
        else
          mkdir -p "$(dirname "$oc_config")"
          echo "{\"plugins\": [\"$plugin_entry\"]}" > "$oc_config"
        fi
        echo -e "  ${GREEN}✓ Plugin enregistré dans $oc_config${NC}"
      else
        echo -e "  ${YELLOW}  python3/jq introuvable — ajoute manuellement dans $oc_config :${NC}"
        echo -e "  { \"plugins\": [\"$plugin_entry\"] }"
      fi
      echo -e "  ${YELLOW}  Usage : demande à OpenCode 'wt create feat/ALM-xxx/desc' ou utilise directement : wt create feat/ALM-xxx/desc${NC}"
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
echo -e "  Recharge ton shell : ${BOLD}source $SOURCED_FILE${NC}  (ou ouvre un nouveau terminal)"
echo ""
echo -e "  Commandes disponibles :"
echo -e "    ${BOLD}wt create feat/ALM-1234/ma-feature${NC}"
echo -e "    ${BOLD}wt list${NC}"
echo -e "    ${BOLD}wt migrate feat/ALM-1234/ma-feature${NC}"
echo -e "    ${BOLD}wt cleanup${NC}"
echo -e "    ${BOLD}wt update${NC}   ← mise à jour depuis GitHub"
echo ""
