#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --------------------------------------------------------------
# Header
# --------------------------------------------------------------

echo -e "${BLUE}:: macOS Kurulum Scripti Başlatılıyor...${NC}"

# --------------------------------------------------------------
# Install Homebrew
# --------------------------------------------------------------

if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}:: Homebrew bulunamadı. Kuruluyor...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}:: Homebrew zaten yüklü.${NC}"
fi

# --------------------------------------------------------------
# Update Homebrew
# --------------------------------------------------------------

echo -e "${BLUE}:: Homebrew güncelleniyor...${NC}"
brew update

# --------------------------------------------------------------
# Install GNU Stow
# --------------------------------------------------------------

echo -e "${BLUE}:: GNU Stow kuruluyor...${NC}"
if brew list --formula | grep -q "^stow$"; then
    echo -e "${GREEN}:: GNU Stow zaten yüklü.${NC}"
else
    echo -e "${YELLOW}:: GNU Stow kuruluyor...${NC}"
    brew install stow
fi

# --------------------------------------------------------------
# Install CLI Tools
# --------------------------------------------------------------

# Read formulae from file
formulae_file="$SCRIPT_DIR/../macos/dotfiles/homebrew/formulae.txt"
casks_file="$SCRIPT_DIR/../macos/dotfiles/homebrew/casks.txt"

echo -e "${BLUE}:: CLI Araçları Kuruluyor...${NC}"
if [ -f "$formulae_file" ]; then
    while IFS= read -r formula; do
        if [ -n "$formula" ]; then
            if brew list --formula | grep -q "^${formula}$"; then
                echo -e "${GREEN}:: $formula zaten yüklü.${NC}"
            else
                echo -e "${YELLOW}:: $formula kuruluyor...${NC}"
                brew install "$formula"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}:: $formula başarıyla kuruldu.${NC}"
                else
                    echo -e "${RED}:: $formula kurulumu başarısız.${NC}"
                fi
            fi
        fi
    done < "$formulae_file"
else
    echo -e "${YELLOW}:: Formula dosyası bulunamadı: $formulae_file${NC}"
fi

# --------------------------------------------------------------
# Install GUI Applications
# --------------------------------------------------------------

echo -e "${BLUE}:: GUI Uygulamaları (Cask) Kuruluyor...${NC}"
if [ -f "$casks_file" ]; then
    while IFS= read -r cask; do
        if [ -n "$cask" ]; then
            if brew list --cask | grep -q "^${cask}$"; then
                echo -e "${GREEN}:: $cask zaten yüklü.${NC}"
            else
                echo -e "${YELLOW}:: $cask kuruluyor...${NC}"
                brew install --cask "$cask"
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}:: $cask başarıyla kuruldu.${NC}"
                else
                    echo -e "${RED}:: $cask kurulumu başarısız.${NC}"
                fi
            fi
        fi
    done < "$casks_file"
else
    echo -e "${YELLOW}:: Cask dosyası bulunamadı: $casks_file${NC}"
fi
# --------------------------------------------------------------
# Install dotfiles using GNU Stow
# --------------------------------------------------------------

echo -e "${BLUE}:: Dotfiles kurulumu başlatılıyor...${NC}"

SOURCE_DOTFILES_DIR="$SCRIPT_DIR/../dotfiles"
DEST_DOTFILES_DIR="$HOME/.dotfiles"

# 1. Eski yedekleri temizle ve mevcut klasörü yedekle
if [ -d "$DEST_DOTFILES_DIR" ]; then
    echo -e "${YELLOW}:: Mevcut .dotfiles klasörü yedekleniyor...${NC}"
    mv "$DEST_DOTFILES_DIR" "$DEST_DOTFILES_DIR.bak.$(date +%Y%m%d-%H%M%S)"
fi

# 2. Güncel dotfiles'ı home dizinine kopyala
echo -e "${BLUE}:: Dotfiles $DEST_DOTFILES_DIR adresine kopyalanıyor...${NC}"
cp -r "$SOURCE_DOTFILES_DIR" "$DEST_DOTFILES_DIR"

# 3. Stow işlemleri için hedef klasöre gir
cd "$DEST_DOTFILES_DIR"

# 4. .config altındaki klasörleri linkle
# Bu işlem ~/.config/kitty gibi klasör yapısını korur.
if [ -d ".config" ]; then
    echo -e "${BLUE}:: .config içerisindeki uygulamalar linkleniyor...${NC}"
    # --target=$HOME diyerek ana dizini hedefliyoruz, 
    # Stow içindeki .config klasörünü görünce otomatik olarak ~/.config ile eşleştirir.
    stow -v -R -t "$HOME" .config
fi

# 5. Ana dizindeki (root) dosyaları linkle (.zshrc, .tmux.conf vb.)
echo -e "${BLUE}:: Root seviyesindeki dosyalar linkleniyor (.zshrc, .tmux.conf)...${NC}"
# Bu komut .dotfiles/ içindeki .zshrc gibi dosyaları ~/ .zshrc olarak linkler.
# --ignore ile .config klasörünü ve diğer gereksizleri atlıyoruz ki tekrar uğraşmasın.
stow -v -R -t "$HOME" --ignore=".config" --ignore="homebrew" --ignore="assets" .

echo -e "${GREEN}:: Dotfiles kurulumu başarıyla tamamlandı.${NC}"

# --------------------------------------------------------------
# Oh My Zsh & Plugins
# --------------------------------------------------------------

echo ":: Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo ":: Oh My Zsh already installed"
fi

echo ":: Installing Oh My Zsh plugins..."
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# zsh-autocomplete
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autocomplete" ]; then
    git clone https://github.com/marlonrichert/zsh-autocomplete "$ZSH_CUSTOM/plugins/zsh-autocomplete"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# fast-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/fast-syntax-highlighting" ]; then
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
fi

# --------------------------------------------------------------
# Oh My Posh
# --------------------------------------------------------------
echo ":: Installing Oh My Posh..."
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# --------------------------------------------------------------
# UV
# --------------------------------------------------------------

curl -LsSf https://astral.sh/uv/install.sh | sh

# --------------------------------------------------------------
# Install Sketchybar
# --------------------------------------------------------------

echo -e "${BLUE}:: Sketchybar kuruluyor...${NC}"

# Add custom tap for sketchybar
echo -e "${BLUE}:: FelixKratz/formulae tap ekleniyor...${NC}"
brew tap FelixKratz/formulae

# Install sketchybar dependencies
echo -e "${YELLOW}:: Sketchybar bağımlılıkları kuruluyor...${NC}"
sketchybar_deps=("lua" "switchaudio-osx" "nowplaying-cli" "jq" "gh")
for dep in "${sketchybar_deps[@]}"; do
    if brew list --formula | grep -q "^${dep}$"; then
        echo -e "${GREEN}:: $dep zaten yüklü.${NC}"
    else
        echo -e "${YELLOW}:: $dep kuruluyor...${NC}"
        brew install "$dep"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}:: $dep başarıyla kuruldu.${NC}"
        else
            echo -e "${RED}:: $dep kurulumu başarısız.${NC}"
        fi
    fi
done

# Install sketchybar
if brew list --formula | grep -q "^sketchybar$"; then
    echo -e "${GREEN}:: Sketchybar zaten yüklü.${NC}"
else
    echo -e "${YELLOW}:: Sketchybar kuruluyor...${NC}"
    brew install sketchybar
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: Sketchybar başarıyla kuruldu.${NC}"
    else
        echo -e "${RED}:: Sketchybar kurulumu başarısız.${NC}"
    fi
fi

# Install fonts
echo -e "${BLUE}:: Sketchybar fontları kuruluyor...${NC}"
font_casks=("sf-symbols" "font-sf-mono" "font-sf-pro")
for font in "${font_casks[@]}"; do
    if brew list --cask | grep -q "^${font}$"; then
        echo -e "${GREEN}:: $font zaten yüklü.${NC}"
    else
        echo -e "${YELLOW}:: $font kuruluyor...${NC}"
        brew install --cask "$font"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}:: $font başarıyla kuruldu.${NC}"
        else
            echo -e "${RED}:: $font kurulumu başarısız.${NC}"
        fi
    fi
done

# Download sketchybar-app-font
echo -e "${BLUE}:: sketchybar-app-font.ttf indiriliyor...${NC}"
if [ ! -d "$HOME/Library/Fonts" ]; then
    mkdir -p "$HOME/Library/Fonts"
fi

if [ ! -f "$HOME/Library/Fonts/sketchybar-app-font.ttf" ]; then
    curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.5/sketchybar-app-font.ttf -o "$HOME/Library/Fonts/sketchybar-app-font.ttf"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: sketchybar-app-font.ttf başarıyla indirildi.${NC}"
    else
        echo -e "${RED}:: sketchybar-app-font.ttf indirilemedi.${NC}"
    fi
else
    echo -e "${GREEN}:: sketchybar-app-font.ttf zaten yüklü.${NC}"
fi

# Install sketchybar-app-font-bg (required for custom app icons)
echo -e "${BLUE}:: sketchybar-app-font-bg kuruluyor...${NC}"
SKETCHYBAR_APP_FONT_BG_DIR="$HOME/.config/sketchybar/helpers/sketchybar-app-font-bg"
if [ ! -d "$SKETCHYBAR_APP_FONT_BG_DIR" ]; then
    mkdir -p "$HOME/.config/sketchybar/helpers"
    git clone https://github.com/SoichiroYamane/sketchybar-app-font-bg.git "$SKETCHYBAR_APP_FONT_BG_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: sketchybar-app-font-bg başarıyla klonlandı.${NC}"
        # Follow the installation instructions from the repo
        cd "$SKETCHYBAR_APP_FONT_BG_DIR"
        # Check if there's an install script or readme
        if [ -f "install.sh" ]; then
            bash install.sh
        elif [ -f "Makefile" ]; then
            make install
        fi
        cd - > /dev/null
    else
        echo -e "${RED}:: sketchybar-app-font-bg klonlanamadı.${NC}"
    fi
else
    echo -e "${GREEN}:: sketchybar-app-font-bg zaten yüklü.${NC}"
fi

# Install SbarLua
echo -e "${BLUE}:: SbarLua kuruluyor...${NC}"
if [ ! -d "/usr/local/share/lua/5.4/sketchybar" ]; then
    git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua
    cd /tmp/SbarLua
    make install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: SbarLua başarıyla kuruldu.${NC}"
    else
        echo -e "${RED}:: SbarLua kurulumu başarısız.${NC}"
    fi
    cd - > /dev/null
    rm -rf /tmp/SbarLua
else
    echo -e "${GREEN}:: SbarLua zaten yüklü.${NC}"
fi

# --------------------------------------------------------------
# Build Sketchybar Helpers
# --------------------------------------------------------------

# Build sketchybar helper binaries if configuration exists
SKETCHYBAR_CONFIG_DIR="$HOME/.config/sketchybar"
if [ -d "$SKETCHYBAR_CONFIG_DIR/helpers" ]; then
    echo -e "${BLUE}:: Sketchybar helper binary'leri derleniyor...${NC}"
    
    # Save current directory
    CURRENT_DIR=$(pwd)
    
    # Build helpers
    cd "$SKETCHYBAR_CONFIG_DIR/helpers"
    if [ -f "Makefile" ]; then
        make clean 2>/dev/null
        make
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}:: Sketchybar helper binary'leri başarıyla derlendi.${NC}"
        else
            echo -e "${RED}:: Sketchybar helper binary'leri derlenemedi.${NC}"
        fi
    else
        echo -e "${YELLOW}:: Makefile bulunamadı, helper binary'leri derlenemedi.${NC}"
    fi
    
    # Make all binaries executable
    if [ -d "bin" ]; then
        chmod +x bin/*
        echo -e "${GREEN}:: Helper binary'leri çalıştırılabilir yapıldı.${NC}"
    fi
    
    # Return to original directory
    cd "$CURRENT_DIR"
    
    # Start sketchybar service
    echo -e "${BLUE}:: Sketchybar servisi başlatılıyor...${NC}"
    brew services restart sketchybar
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: Sketchybar servisi başarıyla başlatıldı.${NC}"
    else
        echo -e "${RED}:: Sketchybar servisi başlatılamadı.${NC}"
        echo -e "${YELLOW}:: Logları kontrol etmek için: log stream --predicate 'process == \"sketchybar\"' --level info${NC}"
    fi
else
    echo -e "${YELLOW}:: Sketchybar konfigürasyonu bulunamadı: $SKETCHYBAR_CONFIG_DIR/helpers${NC}"
    echo -e "${YELLOW}:: Dotfiles'ın doğru şekilde stow edildiğinden emin olun.${NC}"
fi

# --------------------------------------------------------------
# Git Configuration
# --------------------------------------------------------------

git config --global user.name "emirbartu"
git config --global user.email "bartuekinci42@gmail.com"

echo ":: Configuration complete! Please run 'source ~/.zshrc' or restart your terminal."

# --------------------------------------------------------------
# Finish
# --------------------------------------------------------------

echo -e "${GREEN}--------------------------------------------------------------${NC}"
echo -e "${GREEN}:: Kurulum Tamamlandı!${NC}"
echo -e "${GREEN}--------------------------------------------------------------${NC}"