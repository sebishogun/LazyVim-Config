# LazyVim Custom Config

Full-featured Neovim config based on LazyVim with debugging, LSP, themes, AI code generation, and more.

## Features

- **Framework**: LazyVim (batteries included)
- **AI Code Generation**: 99 plugin with multi-provider support (OpenCode, Claude, Copilot, Gemini, Codex)
- **LSP**: Go, Rust, Zig, C/C++, Python, TypeScript, Lua, and more
- **Debugging**: Full DAP support for Go, Rust, C/C++, Zig, Python, JavaScript, Java
- **14 Themes**: tokyonight, catppuccin, gruvbox, kanagawa, rose-pine, nord, etc.
- **Navigation**: Harpoon, Telescope, neo-tree
- **Editor**: Treesitter, autopairs, surround, comments, todo-comments

## Quick Install

```bash
./install.sh
```

The installer will:
- Install system dependencies
- Install/update Neovim
- Install the 99 AI plugin fork
- Install treesitter parsers for all supported languages
- Optionally install AI CLI providers (OpenCode, Claude, Copilot, etc.)

## New Machine Bootstrap

Run this on a fresh Linux/macOS machine:

```bash
mkdir -p ~/neovim-configs
cd ~/neovim-configs
git clone https://github.com/sebishogun/LazyVim-Config.git LazyvimCustomConfig
git clone https://github.com/sebishogun/nn-ai.git 99
cd ~/neovim-configs/LazyvimCustomConfig
./install.sh --dry-run
./install.sh
```

Optional AI CLI installs (if missing):

```bash
curl -fsSL https://opencode.ai/install | bash
npm install -g @anthropic-ai/claude-code @google/gemini-cli @openai/codex
curl -fsSL https://gh.io/copilot-install | bash
```

Verify in Neovim:

```vim
:NNStatus
:lua require("99").doctor()
:NNProvider <Tab>
:NNModel <Tab>
```

## Key Bindings

**Leader: Space**

### 99 AI Code Generation

The 99 plugin allows AI-powered code generation directly in Neovim. It supports multiple AI providers and can fill in functions, process visual selections, and more.

| Key | Mode | Action |
|-----|------|--------|
| `<leader>9f` | Normal | Fill in function body (AI generates implementation) |
| `<leader>9F` | Normal | Fill in function with custom prompt |
| `<leader>9v` | Visual | Process visual selection (AI replaces/improves code) |
| `<leader>9V` | Visual | Process selection with custom prompt |
| `<leader>9s` | Normal | Stop all active AI requests |
| `<leader>9l` | Normal | View logs from last request |
| `<leader>9i` | Normal | Show plugin info |
| `<leader>9q` | Normal | Previous requests to quickfix |
| `<leader>9c` | Normal | Clear previous requests |

### 99 Provider Commands

Switch between AI providers on the fly:

| Command | Description |
|---------|-------------|
| `:NNOpenCode` | Switch to OpenCode (claude-opus-4-6) |
| `:NNOpenAI` | Switch to OpenCode with OpenAI (gpt-codex-5.3) |
| `:NNClaude` | Switch to Claude Code CLI (claude-opus-4-6) |
| `:NNCopilot` | Switch to GitHub Copilot CLI (claude-opus-4.6) |
| `:NNGemini` | Switch to Gemini CLI (gemini-3-pro-preview) |
| `:NNCodex` | Switch to Codex CLI (gpt-codex-5.3) |
| `:NNModel <model>` | Set custom model (Tab completion available) |
| `:NNStatus` | Show current provider and available CLIs |

### How to Use 99

1. **Fill in a function**: Place cursor inside a function with a signature but empty/partial body, press `<leader>9f`. The AI will generate the implementation.

2. **Process visual selection**: Select code in visual mode, press `<leader>9v`. The AI will replace/improve the selected code. Add a prompt with `<leader>9V`.

3. **Add context**: Create `AGENT.md` files in your project directories to provide context to the AI about coding standards, patterns, etc.

4. **Switch providers**: Use `:NNStatus` to see available providers, then switch with `:NNClaude`, `:NNCopilot`, etc.

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

## Supported Languages (99 AI + Treesitter)

lua, go, java, rust, python, zig, typescript, javascript, tsx, ruby, cpp, elixir

## LSP Servers (auto-installed)

gopls, rust-analyzer, zls, clangd, pyright, lua_ls, ts_ls, eslint, html, cssls, tailwindcss, jsonls, yamlls, bashls, dockerls, marksman, sqlls

## Debug Adapters (auto-installed)

delve (Go), codelldb (Rust/C/C++/Zig), debugpy (Python), js-debug (JavaScript), jdtls (Java)

## AI CLI Providers

The 99 plugin supports multiple AI CLI providers. Install at least one:

| Provider | Install Command |
|----------|-----------------|
| OpenCode | `curl -fsSL https://opencode.ai/install \| bash` |
| Claude Code | `npm install -g @anthropic-ai/claude-code` |
| Copilot CLI | `curl -fsSL https://gh.io/copilot-install \| bash` |
| Gemini CLI | `npm install -g @google/gemini-cli` |
| Codex CLI | `npm install -g @openai/codex` |

## Uninstall

```bash
./uninstall.sh
```
