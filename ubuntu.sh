#!/bin/bash
# =============================================================================
# Ubuntu Dev Environment Setup — Gustavo Ueti
# =============================================================================

set -e

echo "🐧 Iniciando setup do ambiente Ubuntu..."

# =============================================================================
# 1. APT UPDATE
# =============================================================================
echo "\n📦 Atualizando apt..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git zsh jq build-essential software-properties-common \
  apt-transport-https ca-certificates gnupg unzip

# =============================================================================
# 2. NEOVIM (versão recente via PPA)
# =============================================================================
echo "\n📝 Instalando Neovim..."
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install -y neovim

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
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
  echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc
  . "$HOME/.asdf/asdf.sh"
fi
sudo apt install -y libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
asdf plugin add python 2>/dev/null || true
asdf install python latest
asdf global python latest

# =============================================================================
# 5. JAVA JDK
# =============================================================================
echo "\n☕ Instalando JDK..."
sudo apt install -y default-jdk

# =============================================================================
# 6. GOOGLE CLOUD SDK
# =============================================================================
echo "\n☁️  Instalando Google Cloud SDK..."
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
  sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt update && sudo apt install -y google-cloud-cli

# =============================================================================
# 7. AZURE CLI
# =============================================================================
echo "\n🔷 Instalando Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# =============================================================================
# 8. AWS CLI
# =============================================================================
echo "\n🟡 Instalando AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# =============================================================================
# 9. DATABRICKS CLI
# =============================================================================
echo "\n🟠 Instalando Databricks CLI..."
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sudo sh

# =============================================================================
# 10. GIT CREDENTIAL MANAGER
# =============================================================================
echo "\n🔑 Instalando Git Credential Manager..."
GCM_VERSION=$(curl -s https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest | grep tag_name | cut -d'"' -f4 | tr -d 'v')
curl -fsSL "https://github.com/git-ecosystem/git-credential-manager/releases/latest/download/gcm-linux_amd64.${GCM_VERSION}.deb" -o /tmp/gcm.deb
sudo dpkg -i /tmp/gcm.deb
rm /tmp/gcm.deb
git-credential-manager configure

# =============================================================================
# 11. NERD FONTS
# =============================================================================
echo "\n🔤 Instalando Nerd Fonts..."
mkdir -p ~/.local/share/fonts
cd /tmp
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip -o JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
unzip -o FiraCode.zip -d ~/.local/share/fonts/FiraCode
fc-cache -fv
rm -f JetBrainsMono.zip FiraCode.zip
cd -

# =============================================================================
# 12. KITTY TERMINAL
# =============================================================================
echo "\n💻 Instalando Kitty..."
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin

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
# 13. FIREFOX
# =============================================================================
echo "\n🦊 Instalando Firefox..."
sudo apt install -y firefox

# =============================================================================
# 14. ZSH + OH MY ZSH
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
# 15. ZSHRC
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

echo "\n✅ Setup Ubuntu concluído!"
echo "👉 Abra o Kitty — a fonte JetBrainsMono Nerd Font já está configurada"
echo "👉 Rode: source ~/.zshrc"
