# Combined .zshrc file for macOS (without archlinux plugin)
# This file merges configurations from dotfiles/.config/zshrc/* files

# -----------------------------------------------------
# INIT
# -----------------------------------------------------

# -----------------------------------------------------
# Exports
# -----------------------------------------------------
export EDITOR=nvim
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:~/.cargo/bin/
export PATH=$PATH:~/.local/bin/

# -----------------------------------------------------
# CUSTOMIZATION
# -----------------------------------------------------
POSH=agnoster

# -----------------------------------------------------
# oh-myzsh themes: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# -----------------------------------------------------
ZSH_THEME="avit"
# -----------------------------------------------------
# oh-my-zsh plugins (without archlinux for macOS)
# -----------------------------------------------------
plugins=(
    git
    sudo
    web-search
    zsh-autosuggestions
    zsh-syntax-highlighting
    fast-syntax-highlighting
    copyfile
    copybuffer
    dirhistory
)

# Set-up oh-my-zsh and zsh-autocomplete
source $ZSH/oh-my-zsh.sh
source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# -----------------------------------------------------
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
# -----------------------------------------------------
source <(fzf --zsh)

# zsh history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# -----------------------------------------------------
# Prompt
# -----------------------------------------------------
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"
# eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/EDM115-newline.omp.json)"

# Shipped Theme
# eval "$(oh-my-posh init zsh --config /usr/share/oh-my-posh/themes/agnoster.omp.json)"

# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

# -----------------------------------------------------
# General
# -----------------------------------------------------
alias c='clear'
alias nf='fastfetch'
alias pf='fastfetch'
alias ff='fastfetch'
alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'
alias shutdown='systemctl poweroff'
alias v='$EDITOR'
alias vim='$EDITOR'
alias ts='~/.config/ml4w/scripts/arch/snapshot.sh'
alias wifi='nmtui'
alias cleanup='~/.config/ml4w/scripts/arch/cleanup.sh'
alias fuzzy='fzf --preview="cat {}" | xargs -r nvim'
# -----------------------------------------------------
# ML4W Apps
# -----------------------------------------------------
alias ml4w='flatpak run com.ml4w.welcome'
alias ml4w-settings='flatpak run com.ml4w.settings'
alias ml4w-calendar='flatpak run com.ml4w.calendar'
alias ml4w-hyprland='flatpak run com.ml4w.hyprlandsettings'
alias ml4w-sidebar='flatpak run com.ml4w.sidebar'
alias ml4w-options='ml4w-hyprland-setup -m options'
alias ml4w-diagnosis='~/.config/hypr/scripts/diagnosis.sh'
alias ml4w-hyprland-diagnosis='~/.config/hypr/scripts/diagnosis.sh'
alias ml4w-qtile-diagnosis='~/.config/ml4w/qtile/scripts/diagnosis.sh'
alias ml4w-update='~/.config/ml4w/scripts/installupdates.sh'

# -----------------------------------------------------
# Window Managers
# -----------------------------------------------------

alias Qtile='startx'
# Hyprland with Hyprland

# -----------------------------------------------------
# Scripts
# -----------------------------------------------------
alias ascii='~/.config/ml4w/scripts/figlet.sh'

# -----------------------------------------------------
# System
# -----------------------------------------------------
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'

# -----------------------------------------------------
# Qtile
# -----------------------------------------------------
alias res1='xrandr --output DisplayPort-0 --mode 2560x1440 --rate 120'
alias res2='xrandr --output DisplayPort-0 --mode 1920x1080 --rate 120'
alias setkb='setxkbmap de;echo "Keyboard set back to de."'

# -----------------------------------------------------
# AUTOSTART
# -----------------------------------------------------

# -----------------------------------------------------
# Fastfetch
# -----------------------------------------------------
if [[ $(tty) == *"pts"* ]]; then
    fastfetch
fi
