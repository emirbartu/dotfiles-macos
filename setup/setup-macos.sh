#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES_DIR="$REPO_ROOT/dotfiles"

# --------------------------------------------------------------
# Header
# --------------------------------------------------------------

echo -e "${BLUE}:: macOS Kurulum Scripti Başlatılıyor...${NC}"
echo -e "${BLUE}:: Repo dizini: $REPO_ROOT${NC}"
echo -e "${BLUE}:: Dotfiles dizini: $DOTFILES_DIR${NC}"

# --------------------------------------------------------------
# Verify dotfiles directory exists
# --------------------------------------------------------------

if [ ! -d "$DOTFILES_DIR" ]; then
    echo -e "${RED}:: Hata: Dotfiles dizini bulunamadı: $DOTFILES_DIR${NC}"
    exit 1
fi

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

formulae_file="$DOTFILES_DIR/homebrew/formulae.txt"
casks_file="$DOTFILES_DIR/homebrew/casks.txt"

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
# Backup existing dotfiles
# --------------------------------------------------------------

echo -e "${BLUE}:: Mevcut dotfiles yedekleniyor...${NC}"

backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"

# Scan dotfiles directory to find ALL files that need backup
echo -e "${BLUE}:: Yedeklenecek dosyalar taranıyor...${NC}"
cd "$DOTFILES_DIR" || exit 1

# Find all files and directories that would conflict
dotfiles_to_backup=()

# Root level files
while IFS= read -r file; do
    filename=$(basename "$file")
    if [ -e "$HOME/$filename" ] && [ ! -L "$HOME/$filename" ]; then
        dotfiles_to_backup+=("$filename")
    fi
done < <(find . -maxdepth 1 -type f -name ".*" ! -name ".DS_Store" ! -name ".git*")

# .config subdirectories
if [ -d ".config" ]; then
    while IFS= read -r dir; do
        dirname=$(basename "$dir")
        if [ -e "$HOME/.config/$dirname" ] && [ ! -L "$HOME/.config/$dirname" ]; then
            dotfiles_to_backup+=(".config/$dirname")
        fi
    done < <(find .config -mindepth 1 -maxdepth 1 -type d)
fi

cd - > /dev/null || exit 1

# Backup all found files
if [ ${#dotfiles_to_backup[@]} -gt 0 ]; then
    for item in "${dotfiles_to_backup[@]}"; do
        if [ -e "$HOME/$item" ] && [ ! -L "$HOME/$item" ]; then
            echo -e "${YELLOW}:: Yedekleniyor: $item${NC}"
            mkdir -p "$backup_dir/$(dirname "$item")"
            mv "$HOME/$item" "$backup_dir/$item"
        fi
    done
    echo -e "${GREEN}:: ${#dotfiles_to_backup[@]} dosya/klasör yedeklendi.${NC}"
else
    echo -e "${GREEN}:: Yedeklenecek dosya bulunamadı.${NC}"
fi

# --------------------------------------------------------------
# Install dotfiles using GNU Stow
# --------------------------------------------------------------

echo -e "${BLUE}:: Dotfiles GNU Stow ile linkleniyor...${NC}"
echo -e "${BLUE}:: Kaynak: $DOTFILES_DIR${NC}"
echo -e "${BLUE}:: Hedef: $HOME${NC}"

cd "$DOTFILES_DIR" || exit 1

# Remove any existing stow links first
echo -e "${YELLOW}:: Mevcut stow linkleri kaldırılıyor...${NC}"
stow -D . -t "$HOME" 2>/dev/null || true

# Create symlinks with stow
echo -e "${BLUE}:: Yeni symlink'ler oluşturuluyor...${NC}"

# First try a dry run to see if there are any conflicts
echo -e "${BLUE}:: Önce test ediliyor (dry-run)...${NC}"
if ! stow -n -v -t "$HOME" --ignore='homebrew' --ignore='assets' --ignore='.DS_Store' . 2>&1; then
    echo -e "${RED}:: HATA: Hala conflict'ler var!${NC}"
    echo -e "${YELLOW}:: Lütfen manuel olarak çakışan dosyaları kontrol edin:${NC}"
    stow -n -t "$HOME" --ignore='homebrew' --ignore='assets' --ignore='.DS_Store' . 2>&1 | grep "existing target"
    echo -e ""
    echo -e "${YELLOW}:: Bu dosyaları manuel olarak yedekleyin veya silin, sonra script'i tekrar çalıştırın.${NC}"
    exit 1
fi

# If dry run passes, do the actual stow
echo -e "${GREEN}:: Test başarılı, linkler oluşturuluyor...${NC}"
stow -v -t "$HOME" --ignore='homebrew' --ignore='assets' --ignore='.DS_Store' .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}:: Dotfiles başarıyla linklendi!${NC}"
    echo -e "${GREEN}:: Artık $DOTFILES_DIR içinde yaptığınız değişiklikler anında aktif olacak.${NC}"
else
    echo -e "${RED}:: Dotfiles linkleme başarısız!${NC}"
    echo -e "${YELLOW}:: Yukarıdaki hata mesajlarını kontrol edin.${NC}"
    exit 1
fi

# --------------------------------------------------------------
# Install Fonts
# --------------------------------------------------------------

echo -e "${BLUE}:: Fontlar kuruluyor...${NC}"
FONTS_DIR="$REPO_ROOT/setup/fonts"

if [ -d "$FONTS_DIR" ]; then
    # Create fonts directory if it doesn't exist
    mkdir -p "$HOME/Library/Fonts"
    
    # Copy all font files
    find "$FONTS_DIR" -name "*.ttf" -o -name "*.otf" | while read -r font; do
        font_name=$(basename "$font")
        if [ ! -f "$HOME/Library/Fonts/$font_name" ]; then
            echo -e "${YELLOW}:: $font_name kuruluyor...${NC}"
            cp "$font" "$HOME/Library/Fonts/"
        else
            echo -e "${GREEN}:: $font_name zaten yüklü.${NC}"
        fi
    done
else
    echo -e "${YELLOW}:: Font dizini bulunamadı: $FONTS_DIR${NC}"
fi

# --------------------------------------------------------------
# Oh My Zsh & Plugins
# --------------------------------------------------------------

echo -e "${BLUE}:: Oh My Zsh kuruluyor...${NC}"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${GREEN}:: Oh My Zsh zaten yüklü.${NC}"
fi

echo -e "${BLUE}:: Oh My Zsh eklentileri kuruluyor...${NC}"
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
echo -e "${BLUE}:: Oh My Posh kuruluyor...${NC}"
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin

# --------------------------------------------------------------
# UV
# --------------------------------------------------------------

echo -e "${BLUE}:: UV kuruluyor...${NC}"
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

# Install fonts required for Sketchybar
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
mkdir -p "$HOME/Library/Fonts"

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

# --------------------------------------------------------------
# Install SbarLua
# --------------------------------------------------------------

echo -e "${BLUE}:: SbarLua kuruluyor...${NC}"
if [ ! -d "/usr/local/share/lua/5.4/sketchybar" ]; then
    git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua
    cd /tmp/SbarLua || exit 1
    make install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: SbarLua başarıyla kuruldu.${NC}"
    else
        echo -e "${RED}:: SbarLua kurulumu başarısız.${NC}"
    fi
    cd - > /dev/null || exit 1
    rm -rf /tmp/SbarLua
else
    echo -e "${GREEN}:: SbarLua zaten yüklü.${NC}"
fi

# --------------------------------------------------------------
# Install sketchybar-app-font-bg
# --------------------------------------------------------------

echo -e "${BLUE}:: sketchybar-app-font-bg kuruluyor...${NC}"
SKETCHYBAR_APP_FONT_BG_DIR="$HOME/.config/sketchybar/helpers/sketchybar-app-font-bg"
if [ ! -d "$SKETCHYBAR_APP_FONT_BG_DIR" ]; then
    mkdir -p "$HOME/.config/sketchybar/helpers"
    git clone https://github.com/SoichiroYamane/sketchybar-app-font-bg.git "$SKETCHYBAR_APP_FONT_BG_DIR"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}:: sketchybar-app-font-bg başarıyla klonlandı.${NC}"
        cd "$SKETCHYBAR_APP_FONT_BG_DIR" || exit 1
        if [ -f "install.sh" ]; then
            bash install.sh
        elif [ -f "Makefile" ]; then
            make install
        fi
        cd - > /dev/null || exit 1
    else
        echo -e "${RED}:: sketchybar-app-font-bg klonlanamadı.${NC}"
    fi
else
    echo -e "${GREEN}:: sketchybar-app-font-bg zaten yüklü.${NC}"
fi

# --------------------------------------------------------------
# Build Sketchybar Helpers
# --------------------------------------------------------------

SKETCHYBAR_CONFIG_DIR="$HOME/.config/sketchybar"
if [ -d "$SKETCHYBAR_CONFIG_DIR/helpers" ]; then
    echo -e "${BLUE}:: Sketchybar helper binary'leri derleniyor...${NC}"
    
    cd "$SKETCHYBAR_CONFIG_DIR/helpers" || exit 1
    
    # Run install.sh if it exists
    if [ -f "install.sh" ]; then
        echo -e "${BLUE}:: install.sh çalıştırılıyor...${NC}"
        bash install.sh
    fi
    
    # Build with make
    if [ -f "Makefile" ]; then
        echo -e "${BLUE}:: Make ile derleniyor...${NC}"
        make clean 2>/dev/null
        make
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}:: Sketchybar helper binary'leri başarıyla derlendi.${NC}"
        else
            echo -e "${RED}:: Sketchybar helper binary'leri derlenemedi.${NC}"
        fi
    else
        echo -e "${YELLOW}:: Makefile bulunamadı.${NC}"
    fi
    
    # Make all binaries executable
    if [ -d "bin" ]; then
        chmod +x bin/*
        echo -e "${GREEN}:: Helper binary'leri çalıştırılabilir yapıldı.${NC}"
    fi
    
    cd - > /dev/null || exit 1
    
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
fi

# --------------------------------------------------------------
# Git Configuration
# --------------------------------------------------------------

echo -e "${BLUE}:: Git yapılandırması...${NC}"
git config --global user.name "emirbartu"
git config --global user.email "bartuekinci42@gmail.com"

# --------------------------------------------------------------
# Verify symlinks
# --------------------------------------------------------------

echo -e "${BLUE}:: Symlink'ler kontrol ediliyor...${NC}"

# Check some key files
key_files=(
    ".zshrc"
    ".tmux.conf"
    ".config/kitty"
    ".config/sketchybar"
    ".config/aerospace"
)

all_good=true
for item in "${key_files[@]}"; do
    if [ -L "$HOME/$item" ]; then
        target=$(readlink "$HOME/$item")
        # Get full path
        full_target=$(cd "$HOME" && cd "$(dirname "$item")" 2>/dev/null && cd "$(dirname "$target")" && pwd)/$(basename "$target")
        echo -e "${GREEN}:: ✓ ~/$item${NC}"
        echo -e "     -> $full_target"
    elif [ -e "$HOME/$item" ]; then
        echo -e "${YELLOW}:: ✗ ~/$item (var ama symlink değil)${NC}"
        all_good=false
    else
        echo -e "${RED}:: ✗ ~/$item (bulunamadı)${NC}"
        all_good=false
    fi
done

echo ""
if [ "$all_good" = true ]; then
    echo -e "${GREEN}:: Tüm symlink'ler başarıyla oluşturuldu! ✓${NC}"
else
    echo -e "${YELLOW}:: Bazı dosyalar doğru linklenemedi. Yukarıya bakın.${NC}"
fi

# --------------------------------------------------------------
# Finish
# --------------------------------------------------------------

echo -e "${GREEN}--------------------------------------------------------------${NC}"
echo -e "${GREEN}:: Kurulum Tamamlandı!${NC}"
echo -e "${GREEN}--------------------------------------------------------------${NC}"
echo -e "${YELLOW}:: Yapılması gerekenler:${NC}"
echo -e "  1. Terminal'i yeniden başlatın veya 'source ~/.zshrc' çalıştırın"
echo -e "  2. Sketchybar'ın düzgün çalıştığını kontrol edin"
echo -e "  3. Eski dotfiles yedeği: $backup_dir"
echo -e ""
echo -e "${GREEN}:: Artık $DOTFILES_DIR içinde yaptığınız değişiklikler${NC}"
echo -e "${GREEN}:: otomatik olarak sisteminize yansıyacak!${NC}"
echo -e "${GREEN}--------------------------------------------------------------${NC}"