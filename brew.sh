#!/usr/bin/env bash

echo "Installing Homebrew."

# Make sure we’re using the latest Homebrew.
brew update
brew upgrade

# Installs Brew
brew install node
brew install git

# Installs Casks
brew tap caskroom/cask

brew cask install 1password
brew cask install iterm2
brew cask install slack
brew cask install spotify
brew cask install visual-studio-code

# Remove outdated versions from the cellar.
brew cleanup

echo "Done with Homebrew"