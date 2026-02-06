#!/bin/bash
set -e

echo "=== LazyVim Custom Config Installer ==="

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Check OS
OS="$(uname -s)"
echo -e "${GREEN}Detected OS: $OS${NC}"

# Check and install Nerd Font (required for icons)
check_nerd_font() {
    echo -e "${YELLOW}Checking for Nerd Font...${NC}"
    
    # Check if any Nerd Font is installed
    if fc-list 2>/dev/null | grep -qi "nerd"; then
        NERD_FONT=$(fc-list 2>/dev/null | grep -i "nerd" | head -1 | cut -d: -f2 | xargs)
        echo -e "${GREEN}Nerd Font found: $NERD_FONT${NC}"
        return 0
    fi
    
    echo -e "${RED}No Nerd Font detected!${NC}"
    echo -e "${YELLOW}Nerd Fonts are required for icons in neo-tree, statusline, etc.${NC}"
    
    read -p "Install JetBrainsMono Nerd Font? [Y/n] " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        install_nerd_font
    else
        echo -e "${YELLOW}Warning: Icons may not display correctly without a Nerd Font.${NC}"
        echo -e "${YELLOW}Install manually: https://www.nerdfonts.com/${NC}"
        echo -e "${YELLOW}Then configure your terminal to use the Nerd Font.${NC}"
    fi
}

install_nerd_font() {
    echo -e "${YELLOW}Installing JetBrainsMono Nerd Font...${NC}"
    
    FONT_DIR=""
    if [[ "$OS" == "Linux" ]]; then
        FONT_DIR="$HOME/.local/share/fonts"
    elif [[ "$OS" == "Darwin" ]]; then
        FONT_DIR="$HOME/Library/Fonts"
    fi
    
    mkdir -p "$FONT_DIR"
    
    # Download and install JetBrainsMono Nerd Font
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    TEMP_DIR=$(mktemp -d)
    
    if curl -fsSL "$FONT_URL" -o "$TEMP_DIR/JetBrainsMono.zip"; then
        unzip -q "$TEMP_DIR/JetBrainsMono.zip" -d "$TEMP_DIR/fonts"
        cp "$TEMP_DIR/fonts"/*.ttf "$FONT_DIR/" 2>/dev/null || true
        rm -rf "$TEMP_DIR"
        
        # Refresh font cache on Linux
        if [[ "$OS" == "Linux" ]] && command -v fc-cache &> /dev/null; then
            fc-cache -f
        fi
        
        echo -e "${GREEN}JetBrainsMono Nerd Font installed!${NC}"
        echo -e "${YELLOW}IMPORTANT: Configure your terminal to use 'JetBrainsMono Nerd Font'${NC}"
        echo -e "${YELLOW}Terminal settings > Font > JetBrainsMono Nerd Font${NC}"
    else
        echo -e "${RED}Failed to download Nerd Font${NC}"
        echo -e "${YELLOW}Install manually: https://www.nerdfonts.com/${NC}"
    fi
}

# Install dependencies
install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y git curl unzip ripgrep fd-find nodejs npm python3 python3-pip python3-venv build-essential jq
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git curl unzip ripgrep fd-find nodejs npm python3 python3-pip gcc gcc-c++ jq
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm git curl unzip ripgrep fd nodejs npm python python-pip base-devel jq
    elif command -v brew &> /dev/null; then
        brew install git curl unzip ripgrep fd node python jq
    else
        echo -e "${RED}Unknown package manager. Install git, ripgrep, fd, node, python manually.${NC}"
    fi
}

# Install Neovim
install_neovim() {
    echo -e "${YELLOW}Installing Neovim...${NC}"
    if command -v nvim &> /dev/null; then
        NVIM_VER=$(nvim --version | head -1 | grep -oP '\d+\.\d+')
        if (( $(echo "$NVIM_VER >= 0.10" | bc -l) )); then
            echo -e "${GREEN}Neovim $NVIM_VER already installed${NC}"
            return
        fi
    fi
    
    if [[ "$OS" == "Linux" ]]; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
        sudo rm -rf /opt/nvim && sudo tar -C /opt -xzf nvim-linux64.tar.gz
        sudo ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
        rm nvim-linux64.tar.gz
    elif [[ "$OS" == "Darwin" ]]; then
        brew install neovim
    fi
    echo -e "${GREEN}Neovim installed: $(nvim --version | head -1)${NC}"
}

# Backup existing config
backup_config() {
    if [[ -d "$HOME/.config/nvim" ]]; then
        BACKUP="$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
        echo -e "${YELLOW}Backing up existing config to $BACKUP${NC}"
        mv "$HOME/.config/nvim" "$BACKUP"
    fi
    rm -rf "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim" 2>/dev/null || true
}

# Install config
install_config() {
    echo -e "${YELLOW}Installing config...${NC}"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    mkdir -p "$HOME/.config"
    cp -r "$SCRIPT_DIR" "$HOME/.config/nvim"
    rm -f "$HOME/.config/nvim/install.sh" "$HOME/.config/nvim/uninstall.sh" "$HOME/.config/nvim/README.md" "$HOME/.config/nvim/.git" 2>/dev/null || true
}

# Install 99 AI agent plugin (fork with CopilotCLI support)
install_99_plugin() {
    echo -e "${YELLOW}Installing 99 AI agent plugin...${NC}"
    PLUGIN_DIR="$HOME/neovim-configs/99"
    
    if [[ -d "$PLUGIN_DIR" ]]; then
        echo -e "${GREEN}99 plugin already exists, pulling latest...${NC}"
        cd "$PLUGIN_DIR" && git pull origin master
    else
        echo -e "${YELLOW}Cloning 99 plugin fork...${NC}"
        mkdir -p "$HOME/neovim-configs"
        git clone https://github.com/sebishogun/99.git "$PLUGIN_DIR"
    fi
    
    # Setup AI CLI providers
    setup_ai_providers
}

# Detect and setup AI CLI providers for 99 plugin
setup_ai_providers() {
    echo ""
    echo -e "${YELLOW}=== AI CLI Provider Setup ===${NC}"
    
    # Detect installed providers
    HAS_OPENCODE=false
    HAS_CLAUDE=false
    HAS_COPILOT=false
    HAS_GEMINI=false
    HAS_CODEX=false
    
    if command -v opencode &> /dev/null; then
        HAS_OPENCODE=true
        echo -e "${GREEN}✓ OpenCode CLI found${NC}"
    else
        echo -e "${RED}✗ OpenCode CLI not found${NC}"
    fi
    
    if command -v claude &> /dev/null; then
        HAS_CLAUDE=true
        echo -e "${GREEN}✓ Claude Code CLI found${NC}"
    else
        echo -e "${RED}✗ Claude Code CLI not found${NC}"
    fi
    
    if command -v gh &> /dev/null && gh copilot --help &> /dev/null; then
        HAS_COPILOT=true
        echo -e "${GREEN}✓ GitHub Copilot CLI found${NC}"
    else
        echo -e "${RED}✗ GitHub Copilot CLI not found${NC}"
    fi
    
    if command -v gemini &> /dev/null; then
        HAS_GEMINI=true
        echo -e "${GREEN}✓ Gemini CLI found${NC}"
    else
        echo -e "${RED}✗ Gemini CLI not found${NC}"
    fi
    
    if command -v codex &> /dev/null; then
        HAS_CODEX=true
        echo -e "${GREEN}✓ Codex CLI found${NC}"
    else
        echo -e "${RED}✗ Codex CLI not found${NC}"
    fi
    
    echo ""
    
    # If OpenCode is installed, configure it
    if $HAS_OPENCODE; then
        configure_opencode_agent
        echo -e "${GREEN}Configured OpenCode as default provider${NC}"
    fi
    
    # Show available provider switch commands
    echo -e "${YELLOW}Available provider commands in neovim:${NC}"
    $HAS_OPENCODE && echo "  :NNOpenCode  - Anthropic Claude via OpenCode"
    $HAS_OPENCODE && echo "  :NNOpenAI    - OpenAI models via OpenCode"
    $HAS_CLAUDE && echo "  :NNClaude    - Claude Code CLI"
    $HAS_COPILOT && echo "  :NNCopilot   - GitHub Copilot CLI"
    $HAS_GEMINI && echo "  :NNGemini    - Google Gemini CLI"
    $HAS_CODEX && echo "  :NNCodex     - OpenAI Codex CLI"
    echo "  :NNModel     - Change model (with Tab completion)"
    echo "  :NNStatus    - Show current provider status"
    
    # Offer to install missing providers
    if ! $HAS_OPENCODE || ! $HAS_CLAUDE || ! $HAS_COPILOT; then
        echo ""
        read -p "Would you like to install missing AI CLI providers? [Y/n] " -n 1 -r; echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_ai_providers "$HAS_OPENCODE" "$HAS_CLAUDE" "$HAS_COPILOT"
        fi
    fi
    
    # Warn if still no providers installed
    if ! $HAS_OPENCODE && ! $HAS_CLAUDE && ! $HAS_COPILOT && ! $HAS_GEMINI && ! $HAS_CODEX; then
        # Re-check after potential installation
        command -v opencode &> /dev/null && HAS_OPENCODE=true
        command -v claude &> /dev/null && HAS_CLAUDE=true
        (command -v gh &> /dev/null && gh copilot --help &> /dev/null) && HAS_COPILOT=true
        
        if ! $HAS_OPENCODE && ! $HAS_CLAUDE && ! $HAS_COPILOT && ! $HAS_GEMINI && ! $HAS_CODEX; then
            echo ""
            echo -e "${YELLOW}Warning: No AI CLI providers installed. 99 plugin won't work without one.${NC}"
            echo -e "${YELLOW}Install options:${NC}"
            echo "  OpenCode:  curl -fsSL https://opencode.ai/install | bash"
            echo "  Claude:    npm install -g @anthropic-ai/claude-code"
            echo "  Copilot:   gh extension install github/gh-copilot"
            echo "  Gemini:    npm install -g @google/gemini-cli"
            echo "  Codex:     npm install -g @openai/codex"
        fi
    fi
}

# Install AI CLI providers
install_ai_providers() {
    local has_opencode=$1
    local has_claude=$2
    local has_copilot=$3
    
    echo ""
    
    # Install OpenCode
    if [[ "$has_opencode" == "false" ]]; then
        echo ""
        read -p "Install OpenCode CLI? (recommended) [Y/n] " -n 1 -r; echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}Installing OpenCode CLI...${NC}"
            if curl -fsSL https://opencode.ai/install | bash; then
                echo -e "${GREEN}OpenCode CLI installed!${NC}"
                # Refresh PATH
                export PATH="$HOME/.opencode/bin:$PATH"
                if command -v opencode &> /dev/null; then
                    configure_opencode_agent
                    echo -e "${GREEN}OpenCode configured as default provider${NC}"
                fi
            else
                echo -e "${RED}Failed to install OpenCode CLI${NC}"
            fi
        fi
    fi
    
    # Install Claude Code
    if [[ "$has_claude" == "false" ]]; then
        echo ""
        read -p "Install Claude Code CLI? [Y/n] " -n 1 -r; echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}Installing Claude Code CLI...${NC}"
            if command -v npm &> /dev/null; then
                if npm install -g @anthropic-ai/claude-code; then
                    echo -e "${GREEN}Claude Code CLI installed!${NC}"
                    echo -e "${YELLOW}Note: Run 'claude' once to authenticate with Anthropic${NC}"
                else
                    echo -e "${RED}Failed to install Claude Code CLI${NC}"
                fi
            else
                echo -e "${RED}npm not found. Install Node.js first.${NC}"
            fi
        fi
    fi
    
    # Install GitHub Copilot CLI
    if [[ "$has_copilot" == "false" ]]; then
        echo ""
        read -p "Install GitHub Copilot CLI? [Y/n] " -n 1 -r; echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}Installing GitHub Copilot CLI...${NC}"
            if command -v gh &> /dev/null; then
                # Check if authenticated
                if ! gh auth status &> /dev/null; then
                    echo -e "${YELLOW}GitHub CLI not authenticated. Running 'gh auth login'...${NC}"
                    gh auth login
                fi
                
                if gh extension install github/gh-copilot; then
                    echo -e "${GREEN}GitHub Copilot CLI installed!${NC}"
                    echo -e "${YELLOW}Note: Requires GitHub Copilot subscription${NC}"
                else
                    echo -e "${RED}Failed to install GitHub Copilot CLI${NC}"
                fi
            else
                echo -e "${RED}GitHub CLI (gh) not found. Install it first:${NC}"
                echo "  https://cli.github.com/"
            fi
        fi
    fi
}

# Configure OpenCode with neovim agent for 99 plugin
configure_opencode_agent() {
    OPENCODE_CONFIG="$HOME/.config/opencode/config.json"
    mkdir -p "$HOME/.config/opencode"
    
    # Neovim agent config - allows external file writes for 99 plugin temp files
    NEOVIM_AGENT='{
  "neovim": {
    "description": "Agent for neovim 99 plugin - allows all file writes",
    "mode": "all",
    "permission": {
      "external_directory": "allow",
      "read": "allow",
      "edit": "allow",
      "bash": "allow",
      "glob": "allow",
      "grep": "allow",
      "list": "allow",
      "question": "deny",
      "doom_loop": "deny"
    }
  }
}'

    if [[ -f "$OPENCODE_CONFIG" ]]; then
        # Check if neovim agent already configured
        if grep -q '"neovim"' "$OPENCODE_CONFIG" 2>/dev/null; then
            echo -e "${GREEN}OpenCode neovim agent already configured${NC}"
            return
        fi
        
        # Add neovim agent to existing config using jq if available
        if command -v jq &> /dev/null; then
            # Merge agent config into existing config
            jq --argjson agent "$NEOVIM_AGENT" '.agent = (.agent // {}) + $agent' "$OPENCODE_CONFIG" > "$OPENCODE_CONFIG.tmp" && mv "$OPENCODE_CONFIG.tmp" "$OPENCODE_CONFIG"
            echo -e "${GREEN}Added neovim agent to OpenCode config${NC}"
        else
            echo -e "${YELLOW}jq not found - please manually add neovim agent to $OPENCODE_CONFIG${NC}"
            echo -e "${YELLOW}See: https://github.com/sebishogun/99#opencode-setup${NC}"
        fi
    else
        # Create new config with neovim agent
        cat > "$OPENCODE_CONFIG" << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "neovim": {
      "description": "Agent for neovim 99 plugin - allows all file writes",
      "mode": "all",
      "permission": {
        "external_directory": "allow",
        "read": "allow",
        "edit": "allow",
        "bash": "allow",
        "glob": "allow",
        "grep": "allow",
        "list": "allow",
        "question": "deny",
        "doom_loop": "deny"
      }
    }
  }
}
EOF
        echo -e "${GREEN}Created OpenCode config with neovim agent${NC}"
    fi
}

# Install treesitter parsers required by 99 plugin
install_treesitter_parsers() {
    echo -e "${YELLOW}Installing treesitter parsers for 99 plugin...${NC}"
    
    # Parsers needed for 99 plugin language support
    # These are required for the 99 AI plugin to find functions via treesitter
    PARSERS="rust go zig java elixir cpp ruby"
    
    # Install parsers with TSInstall! (the ! makes it synchronous)
    # Use sleep to ensure async compilation completes before quitting
    echo -e "${YELLOW}This may take 1-2 minutes...${NC}"
    nvim --headless -c "TSInstall! $PARSERS" -c "sleep 45" -c "qa" 2>&1 | grep -E "(Installing|Compiling|Language installed|Installed)" || true
    
    # Verify installation
    INSTALLED=$(ls ~/.local/share/nvim/site/parser/*.so 2>/dev/null | wc -l)
    echo -e "${GREEN}Treesitter parsers installed! ($INSTALLED parsers available)${NC}"
}

# Sync plugins
sync_plugins() {
    echo -e "${YELLOW}Installing plugins (this may take a minute)...${NC}"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || nvim --headless -c "lua require('lazy').sync()" -c "qa" 2>/dev/null || true
    echo -e "${GREEN}Plugins installed!${NC}"
    
    # Install treesitter parsers after plugins are synced
    install_treesitter_parsers
}

# Main
main() {
    echo ""
    
    # Check Nerd Font first (required for icons)
    check_nerd_font
    echo ""
    
    read -p "Install system dependencies? [y/N] " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && install_deps
    
    read -p "Install/Update Neovim? [y/N] " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] && install_neovim
    
    backup_config
    install_config
    install_99_plugin
    sync_plugins
    
    echo ""
    echo -e "${GREEN}=== Installation Complete! ===${NC}"
    echo "Run 'nvim' to start. First launch will install remaining plugins."
    echo ""
    echo "Quick tips:"
    echo "  Space       = Leader key"
    echo "  <leader>e   = File explorer"
    echo "  <leader>ff  = Find files"
    echo "  <leader>fg  = Live grep"
    echo ""
    echo "Debugging (all languages):"
    echo "  <leader>db  = Toggle breakpoint"
    echo "  <leader>dc  = Start/continue debug"
    echo "  <leader>di  = Step into"
    echo "  <leader>do  = Step over"
    echo "  <leader>dt  = Terminate"
    echo ""
    echo "Rust (rustaceanvim - in .rs files):"
    echo "  <leader>rr  = Run at cursor"
    echo "  <leader>rd  = Debug at cursor"
    echo "  <leader>rt  = Test at cursor"
    echo "  <leader>rm  = Expand macro"
    echo "  <leader>re  = Explain error"
    echo "  <leader>rc  = Open Cargo.toml"
    echo ""
    echo "99 AI Agent (supports OpenCode/Claude/Copilot/Gemini/Codex CLI):"
    echo "  <leader>9f  = Fill in function"
    echo "  <leader>9v  = Process visual selection"
    echo "  :NNOpenCode = Switch to OpenCode provider"
    echo "  :NNClaude   = Switch to Claude CLI"
    echo "  :NNCopilot  = Switch to Copilot CLI"
}

main "$@"
