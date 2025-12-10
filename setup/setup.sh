#!/usr/bin/env bash
sleep 1

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# --------------------------------------------------------------
# Library
# --------------------------------------------------------------

source $SCRIPT_DIR/_lib.sh

# ----------------------------------------------------------
# Detect operating system and run appropriate setup
# ----------------------------------------------------------

_detect_and_run_setup() {
    # Detect operating system
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo ":: Detected macOS"
        $SCRIPT_DIR/setup-macos.sh
    elif [[ $(_checkCommandExists "pacman") == 0 ]]; then
        echo ":: Detected Arch Linux"
        $SCRIPT_DIR/setup-arch.sh
    else
        echo ":: Operating system could not be auto detected."
        echo ":: Please select your base distribution."
        echo 
        echo "1: Arch (pacman + aur helper)"
        echo "2: macOS"
        echo "3: Show dependencies and install manually for your distribution"
        echo "4: Cancel"
        echo 
        while true; do
            read -p "Please select: " yn
            case $yn in
                1)
                    $SCRIPT_DIR/setup-arch.sh
                    break
                    ;;
                2)
                    $SCRIPT_DIR/setup-macos.sh
                    break
                    ;;
                3)
                    $SCRIPT_DIR/dependencies.sh
                    break
                    ;;
                4)
                    echo ":: Installation canceled"
                    exit
                    break
                    ;;
                *)
                    echo ":: Please select a valid option."
                    ;;
            esac
        done    
    fi
}

# ----------------------------------------------------------
# Header
# ----------------------------------------------------------

clear
echo -e "${GREEN}"
cat <<"EOF"
   ____    __          
  / __/__ / /___ _____ 
 _\ \/ -_) __/ // / _ \
/___/\__/\__/\_,_/ .__/
                /_/    
ML4W Dotfiles Setup

EOF
    echo -e "${NONE}"
    
    if gum confirm "DO YOU WANT TO START THE SETUP NOW?: "; then
        echo ":: Installation started."
        echo
        _detect_and_run_setup
    else
        echo ":: Installation canceled"
        exit
    fi
