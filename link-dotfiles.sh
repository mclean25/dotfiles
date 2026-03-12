#!/bin/bash

echo "Creating symlinks for dotfiles to $HOME"

for f in dotfiles/\.[^.]*; do
    FILE="$(basename ${f})"
    ln -sf "$PWD/dotfiles/${FILE}" "$HOME"
done

mkdir -p "$HOME/.config/yabai/bin" "$HOME/.config/skhd"

for f in dotfiles/.config/yabai/yabairc dotfiles/.config/yabai/bin/center-window.sh; do
    FILE="${f#dotfiles/.config/yabai/}"
    ln -sf "$PWD/${f}" "$HOME/.config/yabai/${FILE}"
done

ln -sf "$PWD/dotfiles/.config/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"

echo "Linked dotfiles. Please restart your shell. "
