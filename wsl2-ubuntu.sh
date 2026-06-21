#!/usr/bin/env bash
# =============================================================================
# ubuntu26.sh — Setup completo de ambiente dev — Gustavo Ueti
# Alvo: WSL2 / Ubuntu 26.04 (ou qualquer Ubuntu recente com glibc 2.34+)
#
# Uso:
#   chmod +x ubuntu26.sh
#   ./ubuntu26.sh
#
# Idempotente: pode rodar de novo sem duplicar nada (checa antes de instalar).
# =============================================================================
set -e
 
echo "==> Atualizando apt"
sudo apt update
sudo apt upgrade -y
 
# -----------------------------------------------------------------------------
# Dependências base
# -----------------------------------------------------------------------------
echo "==> Instalando dependências base"
sudo apt install -y \
  git curl wget unzip gpg xclip \
  build-essential gcc make \
  python3-pip python3-venv npm
 
# -----------------------------------------------------------------------------
# Libs de build para compilar Python via asdf (python-build)
# Sem isso, extensões nativas (bz2, sqlite3, ctypes, lzma, readline, tkinter)
# ficam faltando e o binário compilado fica capado (ModuleNotFoundError).
# -----------------------------------------------------------------------------
echo "==> Instalando libs de build para compilação de Python (asdf)"
sudo apt install -y \
  libssl-dev zlib1g-dev libbz2-dev \
  libreadline-dev libsqlite3-dev libncursesw5-dev libffi-dev \
  liblzma-dev tk-dev xz-utils
 
# -----------------------------------------------------------------------------
# zsh + Oh My Zsh (só pra plugins — tema é via Starship, não via OMZ theme)
# -----------------------------------------------------------------------------
echo "==> Instalando zsh + Oh My Zsh"
sudo apt install -y zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi
 
echo "==> Instalando plugins zsh-autosuggestions e zsh-syntax-highlighting"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
 
# -----------------------------------------------------------------------------
# Starship (tema Tokyo Night Moon + módulos Databricks/Azure)
# -----------------------------------------------------------------------------
echo "==> Instalando Starship"
if ! command -v starship &> /dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
 
# -----------------------------------------------------------------------------
# eza (ls moderno) + bat (cat moderno)
# -----------------------------------------------------------------------------
echo "==> Instalando eza"
if ! command -v eza &> /dev/null; then
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt update
  sudo apt install -y eza
fi
 
echo "==> Instalando bat"
sudo apt install -y bat
 
# -----------------------------------------------------------------------------
# tmux
# -----------------------------------------------------------------------------
echo "==> Instalando tmux"
sudo apt install -y tmux
 
# -----------------------------------------------------------------------------
# Rust (rustup) — usado por plugins do LunarVim (telescope-fzf-native, etc)
# e por ferramentas de formatação/busca que rodam via cargo install.
# -----------------------------------------------------------------------------
echo "==> Instalando Rust via rustup"
if ! command -v rustc &> /dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env"
 
echo "==> Instalando ferramentas cargo usadas pelo LunarVim"
# stylua: formatter de Lua (usado pelo conform/null-ls do lvim)
command -v stylua &> /dev/null || cargo install stylua
# fd-find e ripgrep: usados pelo Telescope (fuzzy finder) para busca de arquivos/texto
command -v fd &> /dev/null || cargo install fd-find
command -v rg &> /dev/null || cargo install ripgrep
# tree-sitter-cli: necessário para :TSInstall / parsers do treesitter
command -v tree-sitter &> /dev/null || cargo install tree-sitter-cli
 
# -----------------------------------------------------------------------------
# Neovim + LunarVim
# -----------------------------------------------------------------------------
echo "==> Instalando Neovim"
sudo apt install -y neovim
 
NVIM_VERSION=$(nvim --version | head -1 | grep -oP '\d+\.\d+' | head -1)
echo "    Neovim version: $NVIM_VERSION"
 
echo "==> Instalando LunarVim"
if ! command -v lvim &> /dev/null; then
  LV_BRANCH='release-1.4/neovim-0.9' bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/release-1.4/neovim-0.9/utils/installer/install.sh) --yes
fi
 
# -----------------------------------------------------------------------------
# asdf (version manager) — instalado como binário Go (formato atual, 2.x+)
# -----------------------------------------------------------------------------
echo "==> Instalando asdf"
if [ ! -f "$HOME/bin/asdf" ]; then
  mkdir -p "$HOME/bin"
  ASDF_VERSION=$(curl -s https://api.github.com/repos/asdf-vm/asdf/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  curl -L -o /tmp/asdf.tar.gz "https://github.com/asdf-vm/asdf/releases/latest/download/asdf-${ASDF_VERSION}-linux-amd64.tar.gz"
  tar -xzf /tmp/asdf.tar.gz -C "$HOME/bin"
  chmod +x "$HOME/bin/asdf"
fi
export PATH="$HOME/bin:$PATH"
 
# -----------------------------------------------------------------------------
# Git Credential Manager (GCM)
# -----------------------------------------------------------------------------
echo "==> Instalando Git Credential Manager"
if ! command -v git-credential-manager &> /dev/null; then
  GCM_VERSION=$(curl -s https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
  curl -L -o /tmp/gcm.deb "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION}.deb"
  sudo dpkg -i /tmp/gcm.deb
  git-credential-manager configure
fi
git config --global credential.credentialStore secretservice
 
# -----------------------------------------------------------------------------
# Azure CLI
# -----------------------------------------------------------------------------
echo "==> Instalando Azure CLI"
if ! command -v az &> /dev/null; then
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi
 
# -----------------------------------------------------------------------------
# Databricks CLI
# -----------------------------------------------------------------------------
echo "==> Instalando Databricks CLI"
if ! command -v databricks &> /dev/null; then
  curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sudo sh
fi
 
# -----------------------------------------------------------------------------
# ~/.zshrc — versão final, consolidada, sem PATH duplicado
# -----------------------------------------------------------------------------
echo "==> Escrevendo ~/.zshrc"
cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# =============================================================================
# Oh My Zsh
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
 
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
 
source $ZSH/oh-my-zsh.sh
 
# =============================================================================
# PATH (consolidado — uma única linha, ordem importa: primeiro tem prioridade)
# =============================================================================
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/.asdf/shims:$HOME/.cargo/bin:$PATH"
 
# =============================================================================
# asdf
# =============================================================================
export ASDF_DATA_DIR="$HOME/.asdf"
. <(asdf completion zsh)
 
# =============================================================================
# Starship
# =============================================================================
eval "$(starship init zsh)"
 
# =============================================================================
# Aliases — eza
# =============================================================================
alias ls='eza --icons'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias lt='eza --tree --icons --level=2'
 
# =============================================================================
# Aliases — bat
# =============================================================================
alias cat='batcat'
alias bat='batcat'
ZSHRC_EOF
 
# -----------------------------------------------------------------------------
# ~/.config/starship.toml — Tokyo Night Moon + Databricks (nf-fae-hexagon) + Azure
# -----------------------------------------------------------------------------
echo "==> Escrevendo ~/.config/starship.toml"
mkdir -p "$HOME/.config"
cat > "$HOME/.config/starship.toml" << 'STARSHIP_EOF'
# =============================================================================
# Starship — Tokyo Night Moon — Gustavo Ueti (WSL)
# =============================================================================
 
format = """
[](fg:bg_dark)\
$os\
$username\
[](bg:bg_light fg:bg_dark)\
$directory\
[](fg:bg_light bg:bg_dark)\
$git_branch\
$git_status\
[](fg:bg_dark bg:bg_darker)\
$custom\
$azure\
[](fg:bg_darker)\
$fill\
$cmd_duration\
$line_break\
$character"""
 
palette = "tokyo_night_moon"
 
[palettes.tokyo_night_moon]
bg_dark    = "#1b1d2b"
bg_light   = "#2f334d"
bg_darker  = "#222436"
fg         = "#c8d3f5"
red        = "#ff757f"
green      = "#c3e88d"
yellow     = "#ffc777"
blue       = "#82aaff"
magenta    = "#c099ff"
cyan       = "#86e1fc"
orange     = "#ff966c"
databricks = "#FF6B35"
 
[os]
style = "bg:bg_dark fg:fg"
disabled = false
 
[os.symbols]
Ubuntu = "??"
 
[username]
show_always = true
style_user = "bg:bg_dark fg:fg"
style_root = "bg:bg_dark fg:red"
format = '[ $user ]($style)'
 
[directory]
style = "bg:bg_light fg:cyan"
format = "[ ?? $path ]($style)"
truncation_length = 0
truncate_to_repo = false
 
[git_branch]
style = "bg:bg_dark fg:cyan"
format = '[ $symbol$branch ]($style)'
symbol = " "
 
[git_status]
style = "bg:bg_dark fg:yellow"
format = '[$all_status$ahead_behind ]($style)'
 
[fill]
symbol = " "
 
[cmd_duration]
style = "bg:bg_darker fg:yellow"
format = "[ ?? $duration ]($style)"
min_time = 2000
 
[character]
success_symbol = "[?](bold green)"
error_symbol = "[?](bold red)"
vimcmd_symbol = "[?](bold yellow)"
 
# ----------------------------------------------------------------------------
# Databricks — lê o(s) profile(s) configurados em ~/.databrickscfg
# Funciona com o formato novo do CLI (seções [profile_name], sem default_profile)
# ----------------------------------------------------------------------------
[custom.databricks]
command = "grep -oP '(?<=^\\[)[^\\]]+(?=\\]$)' ~/.databrickscfg 2>/dev/null | grep -v -E '^(DEFAULT|__settings__)$' | tail -1"
when = "test -f ~/.databrickscfg"
style = "bg:bg_darker fg:databricks"
format = '[  $output ]($style)'
shell = ["bash", "--norc"]
 
# ----------------------------------------------------------------------------
# Azure
# ----------------------------------------------------------------------------
[azure]
disabled = false
format = '[ ?? $subscription ]($style)'
style = "bg:bg_darker fg:blue"
STARSHIP_EOF
 
# -----------------------------------------------------------------------------
# Limpeza de resíduos conhecidos do asdf
# O repo asdf-plugins (plugin-index) traz um .tool-versions de CI interno que,
# se ficar lá, pode confundir a resolução de versão do asdf exec.
# -----------------------------------------------------------------------------
echo "==> Limpando .tool-versions órfão do asdf plugin-index (se existir)"
rm -f "$HOME/.asdf/plugin-index/.tool-versions"
 
# -----------------------------------------------------------------------------
# Trocar shell padrão para zsh
# -----------------------------------------------------------------------------
echo "==> Trocando shell padrão para zsh"
if [ "$SHELL" != "$(which zsh)" ]; then
  sudo chsh -s "$(which zsh)" "$USER"
fi
 
echo ""
echo "==================================================================="
echo " Instalação concluída!"
echo ""
echo " Passos manuais restantes (fora do WSL, lado Windows):"
echo " 1. Instalar uma Nerd Font (ex: JetBrainsMono Nerd Font) no Windows"
echo "    https://www.nerdfonts.com/font-downloads"
echo " 2. No Windows Terminal settings.json:"
echo "    - Adicionar o color scheme 'Tokyo Night Moon'"
echo "    - Setar 'colorScheme': 'Tokyo Night Moon' no perfil do WSL"
echo "    - Setar 'font.face': 'JetBrainsMono Nerd Font' no perfil do WSL"
echo "    - Setar 'defaultProfile' com o guid do perfil do WSL"
echo "    - (Opcional) keybindings ctrl+shift+c / ctrl+shift+v para copy/paste"
echo ""
echo " Autenticações pendentes:"
echo " 3. databricks auth login --host https://<workspace>.azuredatabricks.net"
echo " 4. az login"
echo ""
echo " Reinicie o terminal (feche e abra a aba) antes de usar."
echo "==================================================================="
