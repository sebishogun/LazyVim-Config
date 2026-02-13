#!/bin/bash
# brew-install-tools.sh — Install all LSP servers, formatters, linters, and debug adapters
# For macOS corporate laptops where Mason can't download through the firewall
# Zero npm required — everything via brew + pip3
# Run this once after cloning the LazyVim-Config repo

set -e

echo "=== Installing LSP Servers ==="

# Go
brew install gopls

# Lua
brew install lua-language-server

# Python
brew install pyright

# Zig (includes zls)
brew install zig

# C/C++ (clangd from llvm)
brew install llvm

# Rust
brew install rust-analyzer

# Bash
brew install bash-language-server

# Markdown
brew install marksman

# TypeScript/JavaScript
brew install typescript-language-server

# HTML, CSS, JSON, ESLint
brew install vscode-langservers-extracted

# YAML
brew install yaml-language-server

# Dockerfile
brew install dockerfile-language-server

# SQL
brew install sql-language-server

# Tailwind CSS
brew install tailwindcss-language-server

echo ""
echo "=== Installing Formatters & Linters ==="
brew install stylua
brew install shfmt
brew install prettier
brew install black

echo ""
echo "=== Installing Debug Adapters ==="

# Go debugger
brew install delve

# Rust/C/C++/Zig debugger
brew install codelldb

# Python debugger
pip3 install debugpy

echo ""
echo "=== Done ==="
echo "Open neovim and run :LspInfo to verify servers are detected."
echo "Run :checkhealth for a full diagnostic."
