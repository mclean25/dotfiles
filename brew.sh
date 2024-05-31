#!/usr/bin/env bash

echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo "Finished installing Homebrew"

echo "Updating Homebrew..."
# Make sure we’re using the latest Homebrew.
brew update
brew upgrade
echo "Finshed updating Homebrew..."

echo "Installing Homebrew packages..."
# Installs Brew
brew install node
brew install git

echo "Homebrew casks..."
# Installs Casks
brew tap homebrew/cask

brew install --cask 1password
brew install --cask iterm2
brew install --cask slack
brew install --cask spotify
brew install --cask visual-studio-code
brew install --cask chrome
brew install --cask zoom
brew install --cask linear
brew install --cask notion
brew install --cask microsoft-excel

# Remove outdated versions from the cellar.
brew cleanup

echo "Done with Homebrew"
