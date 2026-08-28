#!/usr/bin/env bash
# =============================================================================
# wsl2-ubuntu.sh / Setup completo de ambiente dev / Gustavo Ueti
# Alvo: WSL2 / Ubuntu 26.04 LTS (glibc 2.43; funciona em qualquer Ubuntu
#       recente com glibc 2.34+)
#
# Uso:
#   chmod +x wsl2-ubuntu.sh
#   ./wsl2-ubuntu.sh
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
  git curl wget unzip gpg xclip wl-clipboard dos2unix \
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
# fd-find e ripgrep: usados pelo Telescope (fuzzy finder) para busca de arquivos/texto
command -v fd &> /dev/null || cargo install fd-find
command -v rg &> /dev/null || cargo install ripgrep

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
# OBS: 'secretservice' e 'dpapi' NÃO funcionam dentro do WSL (exigem interface
# gráfica Linux ou Windows nativo, respectivamente). Usamos 'plaintext' — grava
# a credencial em ~/.git-credentials (sem criptografia, protegido só por chmod),
# sem reautenticar depois do primeiro login.
# -----------------------------------------------------------------------------
echo "==> Instalando Git Credential Manager"
if ! command -v git-credential-manager &> /dev/null; then
  GCM_VERSION=$(curl -s https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')
  curl -L -o /tmp/gcm.deb "https://github.com/git-ecosystem/git-credential-manager/releases/download/v${GCM_VERSION}/gcm-linux_amd64.${GCM_VERSION}.deb"
  sudo dpkg -i /tmp/gcm.deb
  git-credential-manager configure
fi
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
# LazyGit — usado pelo atalho <leader>gg do LunarVim (precisa estar no PATH)
# -----------------------------------------------------------------------------
echo "==> Instalando LazyGit"
if ! command -v lazygit &> /dev/null; then
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin
  rm /tmp/lazygit.tar.gz /tmp/lazygit
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

# =============================================================================
# Clipboard — pega o clipboard do Windows via WSLg (Wayland) com fallback X11
# =============================================================================
alias clippaste='wl-paste 2>/dev/null || xclip -selection clipboard -o | sed "s/$//"'

# =============================================================================
# Aliases pessoais
# =============================================================================
alias :q="exit"
alias dal="databricks auth login"
alias dbdev="databricks bundle deploy -t dev"
alias swastart="swa start --api-location api"

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
# tmux — Gustavo Ueti (WSL2)
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
# y copia pro clipboard do Windows (WSLg entrega como STRING)
bind -T copy-mode-vi y send -X copy-pipe-and-cancel 'wl-copy --type STRING'
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel 'wl-copy --type STRING'
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
# ~/.config/lvim/config.lua — clipboard via wl-clipboard (WSLg entrega o
# clipboard do Windows como STRING, não text/plain) + workaround do illuminate
# (bug em paste grande + treesitter nessa combinação de versões).
# Só escreve se o LunarVim já tiver criado o diretório de config.
# -----------------------------------------------------------------------------
if [ -d "$HOME/.config/lvim" ]; then
  echo "==> Escrevendo ~/.config/lvim/config.lua"
  cat > "$HOME/.config/lvim/config.lua" << 'LVIM_EOF'
-- Read the docs: https://www.lunarvim.org/docs/configuration

vim.g.clipboard = {
  name = "wl-clipboard",
  copy = {
    ["+"] = "wl-copy --type STRING",
    ["*"] = "wl-copy --type STRING --primary",
  },
  paste = {
    ["+"] = "wl-paste --no-newline --type STRING",
    ["*"] = "wl-paste --no-newline --primary --type STRING",
  },
  cache_enabled = 0,
}

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
echo " Versões default do asdf (ajuste com 'asdf set -u <tool> <versao>'):"
echo "    - python 3.14.0"
echo "    - nodejs 26.3.0"
echo ""
echo " Autenticações pendentes:"
echo " 3. databricks auth login --host https://<workspace>.azuredatabricks.net"
echo " 4. az login"
echo ""
echo " Reinicie o terminal (feche e abra a aba) antes de usar."
echo "==================================================================="
