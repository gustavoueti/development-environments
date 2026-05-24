#!/bin/bash
# =============================================================================
# Arch Linux Dev Environment Setup — Gustavo Ueti
# =============================================================================

set -e

echo "🏹 Iniciando setup do ambiente Arch Linux..."

# =============================================================================
# 1. PACMAN UPDATE
# =============================================================================
echo "\n📦 Atualizando pacman..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed base-devel curl wget git zsh jq unzip

# =============================================================================
# 2. YAY (AUR helper)
# =============================================================================
echo "\n🔧 Instalando yay (AUR helper)..."
if ! command -v yay &>/dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd -
  rm -rf /tmp/yay
fi

# =============================================================================
# 3. NEOVIM
# =============================================================================
echo "\n📝 Instalando Neovim..."
sudo pacman -S --noconfirm neovim

# =============================================================================
# 4. NODE LTS via NVM
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
# 5. PYTHON LTS via asdf
# =============================================================================
echo "\n🐍 Instalando asdf + Python LTS..."
sudo pacman -S --noconfirm openssl zlib xz tk
if ! command -v asdf &>/dev/null; then
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
  echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
  . "$HOME/.asdf/asdf.sh"
fi
asdf plugin add python 2>/dev/null || true
asdf install python latest
asdf global python latest

# =============================================================================
# 6. JAVA JDK
# =============================================================================
echo "\n☕ Instalando JDK..."
sudo pacman -S --noconfirm jdk-openjdk

# =============================================================================
# 7. GOOGLE CLOUD SDK
# =============================================================================
echo "\n☁️  Instalando Google Cloud SDK..."
yay -S --noconfirm google-cloud-cli

# =============================================================================
# 8. AZURE CLI
# =============================================================================
echo "\n🔷 Instalando Azure CLI..."
yay -S --noconfirm azure-cli

# =============================================================================
# 9. AWS CLI
# =============================================================================
echo "\n🟡 Instalando AWS CLI..."
sudo pacman -S --noconfirm aws-cli-v2

# =============================================================================
# 10. DATABRICKS CLI
# =============================================================================
echo "\n🟠 Instalando Databricks CLI..."
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sudo sh

# =============================================================================
# 11. GIT CREDENTIAL MANAGER
# =============================================================================
echo "\n🔑 Instalando Git Credential Manager..."
yay -S --noconfirm git-credential-manager
git-credential-manager configure

# =============================================================================
# 12. NERD FONTS
# =============================================================================
echo "\n🔤 Instalando Nerd Fonts..."
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd ttf-firacode-nerd
fc-cache -fv

# =============================================================================
# 13. KITTY TERMINAL
# =============================================================================
echo "\n💻 Instalando Kitty..."
sudo pacman -S --noconfirm kitty

# Configurar fonte no kitty
mkdir -p ~/.config/kitty
cat > ~/.config/kitty/kitty.conf << 'KITTYEOF'
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
font_size        12.0
shell            zsh
KITTYEOF

# =============================================================================
# 14. FIREFOX
# =============================================================================
echo "\n🦊 Instalando Firefox..."
sudo pacman -S --noconfirm firefox

# =============================================================================
# 15. ZSH + OH MY ZSH
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
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" 2>/dev/null || true
git clone https://github.com/SlavaYakovenko/zsh-databricks "$HOME/.oh-my-zsh/custom/plugins/databricks" 2>/dev/null || true

# =============================================================================
# 16. ZSHRC
# =============================================================================
echo "\n📝 Configurando .zshrc..."
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null || true

cat > ~/.zshrc << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="spaceship"

plugins=(git battery azure databricks zsh-autosuggestions fast-syntax-highlighting)

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

# PATH
export PATH="$HOME/.local/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# asdf
. "$HOME/.asdf/asdf.sh"
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Google Cloud SDK
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
fi
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
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
  time
  dir
  git
  databricks
  azure
  battery
  line_sep
  char
)
SPACESHIP_BATTERY_THRESHOLD=100
EOF

# =============================================================================
# DEFINIR ZSH COMO SHELL PADRÃO
# =============================================================================
echo "\n🐚 Definindo zsh como shell padrão..."
chsh -s $(which zsh)

echo "\n✅ Setup Arch Linux concluído!"
echo "👉 Abra o Kitty — a fonte JetBrainsMono Nerd Font já está configurada"
echo "👉 Rode: source ~/.zshrc"
