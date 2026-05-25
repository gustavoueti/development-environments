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
brew install git neovim zsh jq curl wget starship

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
# 9. TERMINAL — Kitty
# =============================================================================
echo "\n💻 Instalando Kitty..."
brew install --cask kitty

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

# Plugins
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone https://github.com/SlavaYakovenko/zsh-databricks "$HOME/.oh-my-zsh/custom/plugins/databricks" 2>/dev/null || true

# =============================================================================
# 12. ZSHRC
# =============================================================================
echo "\n📝 Configurando .zshrc..."
cp ~/.zshrc ~/.zshrc.backup 2>/dev/null || true

cat > ~/.zshrc << 'EOF'
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

plugins=(git battery azure databricks zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

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

# Starship
eval "$(starship init zsh)"
EOF

# =============================================================================
# 13. STARSHIP CONFIG
# =============================================================================
echo "\n⭐ Configurando Starship..."
mkdir -p ~/.config

cat > ~/.config/starship.toml << 'EOF'
# =============================================================================
# Starship — Tokyo Night theme — Gustavo Ueti
# =============================================================================

format = """
$time\
$directory\
$git_branch\
$git_status\
$custom\
$azure\
$line_break\
$character"""

[time]
disabled = false
format = '[$time]($style) '
time_format = "%H:%M"
style = "fg:#565f89"

[directory]
format = '[ $path]($style)[$read_only]($read_only_style) '
style = "fg:#7aa2f7 bold"
read_only = " 󰌾"
read_only_style = "fg:#f7768e"
truncation_length = 3
truncate_to_repo = true

[git_branch]
format = '[on](fg:#565f89) [ $branch]($style) '
style = "fg:#bb9af7 bold"
symbol = ""

[git_status]
format = '([$all_status$ahead_behind]($style) )'
style = "fg:#e0af68"
conflicted = "󰩌 "
ahead = "⇡${count} "
behind = "⇣${count} "
diverged = "⇕⇡${ahead_count}⇣${behind_count} "
untracked = "? "
stashed = " "
modified = "! "
staged = "+ "
renamed = "» "
deleted = "✘ "
up_to_date = "[✓](fg:#9ece6a) "

[custom.databricks]
command = "grep 'default_profile' /Users/gustavoueti/.databrickscfg | awk -F' = ' '{print $2}'"
when = "test -f /Users/gustavoueti/.databrickscfg"
format = '[via](fg:#565f89) [⬡ $output]($style) '
style = "fg:#FF6B35 bold"
shell = ["zsh", "-c"]
use_stdin = false

[azure]
disabled = false
format = '[on](fg:#565f89) [󰠅 $subscription]($style) '
style = "fg:#7dcfff bold"
symbol = "󰠅 "

[character]
success_symbol = "[❯](bold fg:#9ece6a)"
error_symbol = "[❯](bold fg:#f7768e)"
vimcmd_symbol = "[❮](bold fg:#bb9af7)"

[package]
disabled = true

[nodejs]
disabled = true

[python]
disabled = true

[java]
disabled = true

[aws]
disabled = true

[gcloud]
disabled = true
EOF

# =============================================================================
# 14. KITTY CONFIG
# =============================================================================
echo "\n🐱 Configurando Kitty..."
mkdir -p ~/.config/kitty

# Tokyo Night Moon theme
git clone https://github.com/kovidgoyal/kitty-themes.git /tmp/kitty-themes 2>/dev/null || true
cp /tmp/kitty-themes/themes/tokyo_night_moon.conf ~/.config/kitty/tokyo-night.conf

cat > ~/.config/kitty/kitty.conf << 'EOF'
font_family JetBrainsMono Nerd Font
font_size 12.0
shell zsh
include tokyo-night.conf

hide_window_decorations titlebar-only
background_opacity 0.97

enabled_layouts splits

# splits
map cmd+enter launch --location=vsplit
map shift+cmd+enter launch --location=hsplit

# navegação entre painéis
map cmd+left neighboring_window left
map cmd+right neighboring_window right
map cmd+up neighboring_window up
map cmd+down neighboring_window down
EOF

# =============================================================================
# DEFINIR ZSH COMO SHELL PADRÃO
# =============================================================================
echo "\n🐚 Definindo zsh como shell padrão..."
chsh -s $(which zsh)

echo "\n✅ Setup macOS concluído!"
echo "👉 Abra o Kitty — fonte e tema já configurados"
echo "👉 Rode: source ~/.zshrc"