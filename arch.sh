#!/usr/bin/env bash
# =============================================================================
# arch.sh / Setup completo de ambiente dev / Gustavo Ueti
# Alvo: Arch Linux
#
# Uso:
#   chmod +x arch.sh
#   ./arch.sh
#
# Alinhado 1:1 com o wsl2-ubuntu.sh no que diz respeito a shell, prompt, tmux
# e tooling (Starship + Tokyo Night Moon, ~/.tmux.conf, eza, bat, LunarVim,
# LazyGit, Rust, nvm + asdf 2.x). Mantém os extras específicos do Arch:
# Alacritty, Firefox, Google Cloud SDK, AWS CLI e Nerd Fonts via pacman.
#
# Idempotente: pode rodar de novo sem duplicar nada (checa antes de instalar).
# =============================================================================
set -e

echo "🏹 Iniciando setup do ambiente Arch Linux..."

# -----------------------------------------------------------------------------
# pacman update + dependências base
# -----------------------------------------------------------------------------
echo "==> Atualizando pacman"
sudo pacman -Syu --noconfirm

echo "==> Instalando dependências base"
sudo pacman -S --noconfirm --needed \
  base-devel git curl wget unzip gpg jq \
  xclip wl-clipboard dos2unix \
  python-pip npm

# -----------------------------------------------------------------------------
# Libs de build para compilar Python via asdf (python-build)
# Sem isso, extensões nativas (bz2, sqlite3, ctypes, lzma, readline, tkinter)
# ficam faltando e o binário compilado fica capado (ModuleNotFoundError).
# -----------------------------------------------------------------------------
echo "==> Instalando libs de build para compilação de Python (asdf)"
sudo pacman -S --noconfirm --needed \
  openssl zlib bzip2 readline sqlite \
  libffi ncurses xz tk

# -----------------------------------------------------------------------------
# yay (AUR helper)
# -----------------------------------------------------------------------------
echo "==> Instalando yay (AUR helper)"
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
  rm -rf /tmp/yay
fi

# -----------------------------------------------------------------------------
# zsh + Oh My Zsh (só pra plugins — tema é via Starship, não via OMZ theme)
# -----------------------------------------------------------------------------
echo "==> Instalando zsh + Oh My Zsh"
sudo pacman -S --noconfirm --needed zsh
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
sudo pacman -S --noconfirm --needed starship

# -----------------------------------------------------------------------------
# eza (ls moderno) + bat (cat moderno)
# -----------------------------------------------------------------------------
echo "==> Instalando eza e bat"
sudo pacman -S --noconfirm --needed eza bat

# -----------------------------------------------------------------------------
# tmux
# -----------------------------------------------------------------------------
echo "==> Instalando tmux"
sudo pacman -S --noconfirm --needed tmux

# -----------------------------------------------------------------------------
# Rust (rustup) — usado por plugins do LunarVim (telescope-fzf-native, etc)
# e por ferramentas de formatação/busca que rodam via cargo install.
# -----------------------------------------------------------------------------
echo "==> Instalando Rust via rustup"
sudo pacman -S --noconfirm --needed rustup
if ! rustup toolchain list 2>/dev/null | grep -q '^stable'; then
  rustup default stable
fi
source "$HOME/.cargo/env" 2>/dev/null || export PATH="$HOME/.cargo/bin:$PATH"

# fd + ripgrep: usados pelo Telescope (fuzzy finder) do LunarVim para busca de
# arquivos/texto. No Arch vêm dos repos oficiais (mais rápido que cargo install).
echo "==> Instalando fd e ripgrep"
sudo pacman -S --noconfirm --needed fd ripgrep

# -----------------------------------------------------------------------------
# Neovim + LunarVim
# -----------------------------------------------------------------------------
echo "==> Instalando Neovim"
sudo pacman -S --noconfirm --needed neovim

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
export ASDF_DATA_DIR="$HOME/.asdf"

echo "==> Instalando plugins e runtimes do asdf (python, nodejs)"
PYTHON_VERSION="3.14.0"
NODEJS_VERSION="26.3.0"
asdf plugin list 2>/dev/null | grep -qx python  || asdf plugin add python
asdf plugin list 2>/dev/null | grep -qx nodejs  || asdf plugin add nodejs
asdf install python "$PYTHON_VERSION"
asdf install nodejs "$NODEJS_VERSION"
asdf set -u python "$PYTHON_VERSION"
asdf set -u nodejs "$NODEJS_VERSION"

# -----------------------------------------------------------------------------
# nvm — coexiste com o asdf. Alguns projetos (SWA CLI / front) esperam um node
# gerenciado por nvm; o asdf continua sendo o default via ~/.tool-versions.
# O ~/.zshrc reafirma a prioridade do shim do asdf depois que o nvm carrega.
# -----------------------------------------------------------------------------
echo "==> Instalando nvm"
if [ ! -d "$HOME/.nvm" ]; then
  NVM_VERSION=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
  curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
fi

# -----------------------------------------------------------------------------
# Git Credential Manager (GCM)
# -----------------------------------------------------------------------------
echo "==> Instalando Git Credential Manager"
if ! command -v git-credential-manager &> /dev/null; then
  yay -S --noconfirm git-credential-manager
  git-credential-manager configure
fi
# 'plaintext' grava a credencial em ~/.git-credentials (protegido só por chmod).
# Num desktop Arch com keyring/GNOME você pode preferir 'secretservice'.
git config --global credential.credentialStore plaintext
# Azure DevOps: cada repo/org precisa da credencial casada com o path completo
git config --global credential."https://dev.azure.com".useHttpPath true

# -----------------------------------------------------------------------------
# Git — identidade global
# -----------------------------------------------------------------------------
echo "==> Configurando git user.name / user.email"
git config --global user.email "gustavo.ueti@yduqs.com.br"
git config --global user.name "gustavoueti"

# -----------------------------------------------------------------------------
# Java JDK
# -----------------------------------------------------------------------------
echo "==> Instalando JDK"
sudo pacman -S --noconfirm --needed jdk-openjdk

# -----------------------------------------------------------------------------
# Google Cloud SDK
# -----------------------------------------------------------------------------
echo "==> Instalando Google Cloud SDK"
command -v gcloud &>/dev/null || yay -S --noconfirm google-cloud-cli

# -----------------------------------------------------------------------------
# Azure CLI
# -----------------------------------------------------------------------------
echo "==> Instalando Azure CLI"
command -v az &>/dev/null || yay -S --noconfirm azure-cli

# -----------------------------------------------------------------------------
# AWS CLI
# -----------------------------------------------------------------------------
echo "==> Instalando AWS CLI"
sudo pacman -S --noconfirm --needed aws-cli-v2

# -----------------------------------------------------------------------------
# Databricks CLI
# -----------------------------------------------------------------------------
echo "==> Instalando Databricks CLI"
if ! command -v databricks &> /dev/null; then
  curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sudo sh
fi

# -----------------------------------------------------------------------------
# LazyGit — usado pelo atalho <leader>gg do LunarVim (precisa estar no PATH)
# -----------------------------------------------------------------------------
echo "==> Instalando LazyGit"
sudo pacman -S --noconfirm --needed lazygit

# -----------------------------------------------------------------------------
# Nerd Fonts
# -----------------------------------------------------------------------------
echo "==> Instalando Nerd Fonts"
sudo pacman -S --noconfirm --needed ttf-jetbrains-mono-nerd ttf-firacode-nerd
fc-cache -fv

# -----------------------------------------------------------------------------
# Alacritty terminal — fonte JetBrainsMono Nerd Font + cores Tokyo Night Moon
# -----------------------------------------------------------------------------
echo "==> Instalando Alacritty"
sudo pacman -S --noconfirm --needed alacritty
mkdir -p ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.toml << 'ALACRITTYEOF'
# =============================================================================
# Alacritty — Gustavo Ueti (Arch) — Tokyo Night Moon
# =============================================================================

[terminal.shell]
program = "/usr/bin/zsh"

[font]
size = 12.0

[font.normal]
family = "JetBrainsMono Nerd Font"
style  = "Regular"

[font.bold]
family = "JetBrainsMono Nerd Font"
style  = "Bold"

[font.italic]
family = "JetBrainsMono Nerd Font"
style  = "Italic"

[window]
padding = { x = 8, y = 8 }
opacity = 0.98

# --- Tokyo Night Moon --------------------------------------------------------
[colors.primary]
background = "#222436"
foreground = "#c8d3f5"

[colors.normal]
black   = "#1b1d2b"
red     = "#ff757f"
green   = "#c3e88d"
yellow  = "#ffc777"
blue    = "#82aaff"
magenta = "#c099ff"
cyan    = "#86e1fc"
white   = "#828bb8"

[colors.bright]
black   = "#444a73"
red     = "#ff757f"
green   = "#c3e88d"
yellow  = "#ffc777"
blue    = "#82aaff"
magenta = "#c099ff"
cyan    = "#86e1fc"
white   = "#c8d3f5"
ALACRITTYEOF

# -----------------------------------------------------------------------------
# Firefox
# -----------------------------------------------------------------------------
echo "==> Instalando Firefox"
sudo pacman -S --noconfirm --needed firefox

# -----------------------------------------------------------------------------
# ~/.zshrc — versão final, consolidada, sem PATH duplicado
# -----------------------------------------------------------------------------
echo "==> Escrevendo ~/.zshrc"
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null || true
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
alias cat='bat'

# =============================================================================
# Clipboard — Wayland (wl-clipboard) com fallback X11 (xclip)
# =============================================================================
alias clippaste='wl-paste 2>/dev/null || xclip -selection clipboard -o | sed "s/$//"'

# =============================================================================
# Aliases pessoais
# =============================================================================
alias cls="clear"
alias :q="exit"
alias gs="git status"
alias gl="git log --oneline --graph --decorate"
alias dal="databricks auth login"
alias dbdev="databricks bundle deploy -t dev"
alias swastart="swa start --api-location api"

# =============================================================================
# Google Cloud SDK
# =============================================================================
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# =============================================================================
# nvm
# =============================================================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # carrega o nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # completion do nvm

# nvm joga o próprio node no início do PATH ao carregar, escondendo o shim do
# asdf — reafirma a prioridade do asdf.
export PATH="$HOME/.asdf/shims:$PATH"
ZSHRC_EOF

# -----------------------------------------------------------------------------
# ~/.config/starship.toml — Tokyo Night Moon + Databricks (nf-fae-hexagon) + Azure
# -----------------------------------------------------------------------------
echo "==> Escrevendo ~/.config/starship.toml"
mkdir -p "$HOME/.config"
cat > "$HOME/.config/starship.toml" << 'STARSHIP_EOF'
# =============================================================================
# Starship — Tokyo Night Moon — Gustavo Ueti (Arch)
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
$python\
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
Arch = "󰣇"
Ubuntu = "󰕈"

[username]
show_always = true
style_user = "bg:bg_dark fg:fg"
style_root = "bg:bg_dark fg:red"
format = '[ $user ]($style)'

[directory]
style = "bg:bg_light fg:cyan"
format = "[ 󰉋 $path ]($style)"
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
format = "[ 󱎫 $duration ]($style)"
min_time = 2000

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold yellow)"

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
format = '[ 󰠅 $subscription ]($style)'
style = "bg:bg_darker fg:blue"

# ----------------------------------------------------------------------------
# Python — mostra o nome do venv ativo entre parênteses, em verde
# (precisa de $python referenciado no format principal lá em cima, senão
#  o módulo fica configurado mas nunca é chamado)
# ----------------------------------------------------------------------------
[python]
disabled = false
format = '[(\($virtualenv\) )]($style)'
style = "fg:green"
detect_extensions = []
detect_files = []
detect_folders = []
STARSHIP_EOF

# -----------------------------------------------------------------------------
# ~/.tmux.conf
# -----------------------------------------------------------------------------
echo "==> Escrevendo ~/.tmux.conf"
cat > "$HOME/.tmux.conf" << 'TMUX_EOF'
# =============================================================================
# tmux — Gustavo Ueti (Arch)
# =============================================================================

# --- prefixo: Ctrl+b -> Ctrl+a -----------------------------------------------
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# --- splits: | horizontal, - vertical (herdam o diretório atual) ------------
unbind '"'
unbind %
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
# nova janela também no diretório atual
bind c new-window -c "#{pane_current_path}"

# --- navegação entre panes com hjkl (estilo vim) ---------------------------
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# --- redimensionar panes com HJKL (repetível: segura sem reapertar prefixo) -
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# --- mouse: roda rola o histórico, clique seleciona/redimensiona pane -------
set -g mouse on

# --- scroll / copy-mode estilo vi -----------------------------------------
# prefix + [  entra no modo de scroll; hjkl / Ctrl-u / Ctrl-d / PageUp navegam;
# q sai. Com o mouse ligado, a roda já entra nesse modo sozinha.
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection
bind -T copy-mode-vi C-v send -X rectangle-toggle
# y copia pro clipboard (Wayland via wl-copy, fallback X11 via xclip)
bind -T copy-mode-vi y send -X copy-pipe-and-cancel 'wl-copy 2>/dev/null || xclip -selection clipboard'
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel 'wl-copy 2>/dev/null || xclip -selection clipboard'
bind -T copy-mode-vi Escape send -X cancel

# --- histórico de scrollback maior ---------------------------------------
set -g history-limit 50000

# --- índices de janela/pane começam em 1, renumera ao fechar ---------------
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# --- qualidade de vida ---------------------------------------------------
set -sg escape-time 0
set -g focus-events on
set -g display-time 2000

# --- true color --------------------------------------------------------
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"

# --- recarregar esta config: prefix + r --------------------------------
bind r source-file ~/.tmux.conf \; display "~/.tmux.conf recarregado"
TMUX_EOF

# -----------------------------------------------------------------------------
# ~/.config/lvim/config.lua — clipboard nativo (xclip/wl-clipboard auto) +
# workaround do illuminate (bug em paste grande + treesitter nessas versões).
# Só escreve se o LunarVim já tiver criado o diretório de config.
# -----------------------------------------------------------------------------
if [ -d "$HOME/.config/lvim" ]; then
  echo "==> Escrevendo ~/.config/lvim/config.lua"
  cat > "$HOME/.config/lvim/config.lua" << 'LVIM_EOF'
-- Read the docs: https://www.lunarvim.org/docs/configuration

vim.opt.clipboard = "unnamedplus"

lvim.builtin.illuminate.active = false
LVIM_EOF
fi

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
echo " Abra o Alacritty — a fonte JetBrainsMono Nerd Font já está configurada."
echo ""
echo " Versões default do asdf (ajuste com 'asdf set -u <tool> <versao>'):"
echo "    - python 3.14.0"
echo "    - nodejs 26.3.0"
echo ""
echo " Autenticações pendentes:"
echo "    - databricks auth login --host https://<workspace>.azuredatabricks.net"
echo "    - az login"
echo "    - gcloud auth login"
echo ""
echo " Reinicie o terminal antes de usar."
echo "==================================================================="
