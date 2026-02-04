# LazyVim Custom Config

Full-featured Neovim config based on LazyVim with debugging, LSP, themes, and more.

## Features

- **Framework**: LazyVim (batteries included)
- **LSP**: Go, Rust, Zig, C/C++, Python, TypeScript, Lua, and more
- **Debugging**: Full DAP support for Go, Rust, C/C++, Zig, Python, JavaScript, Java
- **14 Themes**: tokyonight, catppuccin, gruvbox, kanagawa, rose-pine, nord, etc.
- **Navigation**: Harpoon, Telescope, neo-tree
- **Editor**: Treesitter, autopairs, surround, comments, todo-comments

## Quick Install

```bash
./install.sh
```

## Key Bindings

**Leader: Space**

### Debugging
| Key | Action |
|-----|--------|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Continue/Start |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Restart |
| `<leader>dt` | Terminate |
| `<leader>du` | Toggle UI |
| `<leader>de` | Evaluate |

### Navigation
| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>e` | File explorer |
| `<leader>1-0` | Harpoon files |
| `<leader>a` | Add to Harpoon |
| `<leader>h` | Harpoon menu |

### LSP
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover docs |
| `<leader>ca` | Code actions |
| `<leader>cr` | Rename |

## LSP Servers (auto-installed)

gopls, rust-analyzer, zls, clangd, pyright, lua_ls, tsserver, eslint, html, cssls, tailwindcss, jsonls, yamlls, bashls, dockerls, marksman, sqlls

## Debug Adapters (auto-installed)

delve (Go), codelldb (Rust/C/C++/Zig), debugpy (Python), js-debug (JavaScript), jdtls (Java)

## Uninstall

```bash
./uninstall.sh
```
