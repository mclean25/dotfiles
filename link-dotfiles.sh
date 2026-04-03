#!/bin/bash

echo "Creating symlinks for dotfiles to $HOME"

for f in dotfiles/\.[^.]*; do
    FILE="$(basename ${f})"
    ln -sf "$PWD/dotfiles/${FILE}" "$HOME"
done

mkdir -p "$HOME/.config/yabai/bin" "$HOME/.config/skhd"
mkdir -p "$HOME/.config/zed"

mkdir -p "$HOME/bin"

for f in dotfiles/.config/yabai/yabairc dotfiles/.config/yabai/bin/center-window.sh; do
    FILE="${f#dotfiles/.config/yabai/}"
    ln -sf "$PWD/${f}" "$HOME/.config/yabai/${FILE}"
done

ln -sf "$PWD/dotfiles/.config/skhd/skhdrc" "$HOME/.config/skhd/skhdrc"
ln -sf "$PWD/dotfiles/.config/zed/keymap.json" "$HOME/.config/zed/keymap.json"
ln -sf "$PWD/dotfiles/.config/zed/settings.json" "$HOME/.config/zed/settings.json"

for f in dotfiles/bin/*; do
    [ -e "$f" ] || continue
    FILE="$(basename ${f})"
    ln -sf "$PWD/${f}" "$HOME/bin/${FILE}"
done

echo "Linked dotfiles. Please restart your shell. "
