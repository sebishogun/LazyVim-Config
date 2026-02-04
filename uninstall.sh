#!/bin/bash
echo "Removing Neovim config..."
rm -rf "$HOME/.config/nvim" "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"
echo "Done. Neovim config removed."
