#!/bin/bash


# Installs Oh my ZSH with Homebrew (Mac)
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


# Assumes default ZSH installation
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Installs plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Install powerlevel10k fonts
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

# Make sure to set the theme in ~/.zshrc
# ZSH_THEME="powerlevel10k/powerlevel10k"

# Fix permissions
chmod 700 ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
