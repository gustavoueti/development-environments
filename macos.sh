#!/bin/zsh
# =============================================================================
# macOS Dev Environment Setup — Gustavo Ueti
# =============================================================================

set -e

echo "🍎 Iniciando setup do ambiente macOS..."

# =============================================================================
# 1. HOMEBREW
# =============================================================================
echo "\n📦 Instalando/atualizando Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
brew update && brew upgrade

# =============================================================================
# 2. PACOTES BASE
# =============================================================================
echo "\n🔧 Instalando pacotes base..."
brew install git neovim zsh jq curl wget

# =============================================================================
# 3. NODE LTS via NVM
# =============================================================================
echo "\n🟢 Instalando NVM + Node LTS..."
if ! command -v nvm &>/dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# =============================================================================
# 4. PYTHON LTS via asdf
# =============================================================================
echo "\n🐍 Instalando asdf + Python LTS..."
if ! command -v asdf &>/dev/null; then
  brew install asdf
fi
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
asdf plugin add python 2>/dev/null || true
asdf install python latest
asdf global python latest

# =============================================================================
# 5. JAVA JDK
# =============================================================================
echo "\n☕ Instalando JDK..."
brew install --cask temurin

# =============================================================================
# 6. CLIs DE CLOUD
# =============================================================================
echo "\n☁️  Instalando CLIs de cloud..."

# Google Cloud SDK
brew install --cask google-cloud-sdk

# Azure CLI
brew install azure-cli

# AWS CLI
brew install awscli

# Databricks CLI
brew tap databricks/tap
brew install databricks

# =============================================================================
# 7. GIT CREDENTIAL MANAGER
# =============================================================================
echo "\n🔑 Instalando Git Credential Manager..."
brew install --cask git-credential-manager
git config --global credential.helper manager

# =============================================================================
# 8. NERD FONTS
# =============================================================================
echo "\n🔤 Instalando Nerd Fonts..."
brew install --cask font-jetbrains-mono-nerd-font
brew install --cask font-fira-code-nerd-font

# =============================================================================
# 9. TERMINAL — iTerm2
# =============================================================================
echo "\n💻 Instalando iTerm2..."
brew install --cask iterm2

# =============================================================================
# 10. FIREFOX
# =============================================================================
echo "\n🦊 Instalando Firefox..."
brew install --cask firefox

# =============================================================================
# 11. ZSH + OH MY ZSH
# =============================================================================
echo "\n🚀 Instalando Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Spaceship theme
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt" ]; then
  git clone https://github.com/spaceship-prompt/spaceship-prompt "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt"
  ln -sf "$HOME/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
fi

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone https://github.com/SlavaYakovenko/zsh-databricks "$HOME/.oh-my-zsh/custom/plugins/databricks" 2>/dev/null || true

# =============================================================================
# 12. ZSHRC
# =============================================================================
echo "\n📝 Configurando .zshrc..."
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null || true

cat > ~/.zshrc << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="spaceship"

plugins=(git battery azure databricks zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

SPACESHIP_GCLOUD_SYMBOL="󰊭 "
SPACESHIP_AZURE_SYMBOL="󰠅 "

# Aliases
alias cls="clear"
alias gs="git status"
alias gl="git log --oneline --graph --decorate"
alias dal="databricks auth login"
alias swastart="swa start --api-location api"
alias dbdev="databricks bundle deploy -t dev"
alias mousemv="python ~/Documents/projects/testes/mouse/mouse.py"

# Export homebrew to $PATH
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/opt/homebrew/share/zsh-syntax-highlighting/highlighters

# asdf
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Google Cloud SDK
if [ -f '/Users/gustavoueti/google-cloud-sdk/path.zsh.inc' ]; then
  source '/Users/gustavoueti/google-cloud-sdk/path.zsh.inc'
fi
if [ -f '/Users/gustavoueti/google-cloud-sdk/completion.zsh.inc' ]; then
  source '/Users/gustavoueti/google-cloud-sdk/completion.zsh.inc'
fi

# Segmento customizado do Databricks
spaceship_databricks() {
  local profile
  profile=$(grep "default_profile" ~/.databrickscfg 2>/dev/null | awk -F'= ' '{print $2}' | tr -d ' ')
  [[ -z "$profile" ]] && profile="DEFAULT"
  spaceship::section --color "#FF6B35" --prefix "using " "⬡ $profile "
}

# Ordem do prompt
SPACESHIP_PROMPT_ORDER=(
  dir
  git
  databricks
  azure
  line_sep
  char
)
EOF

# =============================================================================
# DEFINIR ZSH COMO SHELL PADRÃO
# =============================================================================
echo "\n🐚 Definindo zsh como shell padrão..."
chsh -s $(which zsh)

echo "\n✅ Setup macOS concluído!"
echo "👉 Abra o iTerm2, configure a fonte para 'JetBrainsMono Nerd Font' em Preferences > Profiles > Text > Font"
echo "👉 Rode: source ~/.zshrc"