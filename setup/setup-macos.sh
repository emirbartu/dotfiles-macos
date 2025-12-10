#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BLUE}:: macOS Kurulum Scripti Başlatılıyor...${NC}"

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

echo -e "${BLUE}:: Homebrew güncelleniyor...${NC}"
brew update

echo -e "${BLUE}:: GNU Stow kuruluyor...${NC}"
if brew list --formula | grep -q "^stow$"; then
    echo -e "${GREEN}:: GNU Stow zaten yüklü.${NC}"
else
    echo -e "${YELLOW}:: GNU Stow kuruluyor...${NC}"
    brew install stow
fi

echo -e "${BLUE}:: Oh My Zsh kuruluyor...${NC}"
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}:: Oh My Zsh zaten yüklü.${NC}"
else
    echo -e "${YELLOW}:: Oh My Zsh kuruluyor...${NC}"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: Oh My Zsh başarıyla kuruldu.${NC}"
    else
        echo -e "${RED}:: Oh My Zsh kurulumu başarısız.${NC}"
    fi
fi

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

DOTFILES_DIR="$SCRIPT_DIR/../macos/dotfiles"

echo -e "${BLUE}:: GNU Stow ile dotfiles kuruluyor...${NC}"

if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"
    echo -e "${BLUE}:: Dotfiles kuruluyor: $DOTFILES_DIR${NC}"
    
    # Install each directory in macos/dotfiles
    for dir in */; do
        if [ -d "$dir" ]; then
            echo -e "${YELLOW}:: $dir kuruluyor...${NC}"
            stow -t ~ "$dir"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}:: $dir başarıyla kuruldu.${NC}"
            else
                echo -e "${RED}:: $dir kurulumu başarısız.${NC}"
            fi
        fi
    done
    echo -e "${GREEN}:: Dotfiles kurulumu tamamlandı.${NC}"
else
    echo -e "${YELLOW}:: macos/dotfiles klasörü bulunamadı: $DOTFILES_DIR${NC}"
fi

echo -e "${BLUE}:: Sketchybar kuruluyor...${NC}"
if brew list --formula | grep -q "^sketchybar$"; then
    echo -e "${GREEN}:: Sketchybar zaten yüklü.${NC}"
else
    echo -e "${YELLOW}:: Sketchybar bağımlılıkları kuruluyor...${NC}"
    
    # Install sketchybar dependencies
    sketchybar_deps=("lua" "switchaudio-osx" "nowplaying-cli")
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
    
    # Add custom tap for sketchybar
    echo -e "${BLUE}:: FelixKratz/formulae tap ekleniyor...${NC}"
    brew tap FelixKratz/formulae
    
    # Install sketchybar
    echo -e "${YELLOW}:: Sketchybar kuruluyor...${NC}"
    brew install sketchybar
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: Sketchybar başarıyla kuruldu.${NC}"
    else
        echo -e "${RED}:: Sketchybar kurulumu başarısız.${NC}"
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
fi

# Build sketchybar helper binaries if configuration exists
SKETCHYBAR_CONFIG_DIR="$HOME/.config/sketchybar"
if [ -d "$SKETCHYBAR_CONFIG_DIR" ]; then
    echo -e "${BLUE}:: Sketchybar helper binary'leri derleniyor...${NC}"
    cd "$SKETCHYBAR_CONFIG_DIR/helpers"
    make
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: Sketchybar helper binary'leri başarıyla derlendi.${NC}"
    else
        echo -e "${RED}:: Sketchybar helper binary'leri derlenemedi.${NC}"
    fi
    
    # Start sketchybar service
    echo -e "${BLUE}:: Sketchybar servisi başlatılıyor...${NC}"
    brew services start sketchybar
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: Sketchybar servisi başarıyla başlatıldı.${NC}"
    else
        echo -e "${RED}:: Sketchybar servisi başlatılamadı.${NC}"
    fi
else
    echo -e "${YELLOW}:: Sketchybar konfigürasyonu bulunamadı, helper binary'leri derlenemedi.${NC}"
fi

echo -e "${GREEN}--------------------------------------------------------------${NC}"
echo -e "${GREEN}:: Kurulum Tamamlandı!${NC}"
echo -e "${GREEN}--------------------------------------------------------------${NC}"
