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

brew cask install 1password
brew cask install iterm2
brew cask install slack
brew cask install spotify
brew cask install visual-studio-code

# Remove outdated versions from the cellar.
brew cleanup

echo "Done with Homebrew"
