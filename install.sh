#!/bin/bash
set -e

echo "=== LazyVim Custom Config Installer ==="

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# Check OS
OS="$(uname -s)"
echo -e "${GREEN}Detected OS: $OS${NC}"

# Install dependencies
install_deps() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y git curl unzip ripgrep fd-find nodejs npm python3 python3-pip python3-venv build-essential
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git curl unzip ripgrep fd-find nodejs npm python3 python3-pip gcc gcc-c++
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu --noconfirm git curl unzip ripgrep fd nodejs npm python python-pip base-devel
    elif command -v brew &> /dev/null; then
        brew install git curl unzip ripgrep fd node python
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
    
    echo ""
    
    # If all installed, configure and use defaults
    if $HAS_OPENCODE && $HAS_CLAUDE && $HAS_COPILOT; then
        echo -e "${GREEN}All AI CLI providers installed!${NC}"
        configure_opencode_agent
        echo -e "${GREEN}Default provider: OpenCode (switch with :NNClaude or :NNCopilot)${NC}"
        return
    fi
    
    # If at least one installed, configure what's available
    if $HAS_OPENCODE || $HAS_CLAUDE || $HAS_COPILOT; then
        if $HAS_OPENCODE; then
            configure_opencode_agent
            echo -e "${GREEN}Configured OpenCode as default provider${NC}"
        elif $HAS_CLAUDE; then
            echo -e "${GREEN}Claude Code available - use :NNClaude in neovim${NC}"
        elif $HAS_COPILOT; then
            echo -e "${GREEN}Copilot CLI available - use :NNCopilot in neovim${NC}"
        fi
    fi
    
    # Offer to install missing providers
    if ! $HAS_OPENCODE || ! $HAS_CLAUDE || ! $HAS_COPILOT; then
        echo ""
        echo -e "${YELLOW}Would you like to install missing AI CLI providers?${NC}"
        read -p "Install missing providers? [y/N] " -n 1 -r; echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_ai_providers "$HAS_OPENCODE" "$HAS_CLAUDE" "$HAS_COPILOT"
        else
            if ! $HAS_OPENCODE && ! $HAS_CLAUDE && ! $HAS_COPILOT; then
                echo -e "${YELLOW}Warning: No AI CLI providers installed. 99 plugin won't work without one.${NC}"
                echo -e "${YELLOW}You can install them later manually:${NC}"
                echo "  OpenCode:  curl -fsSL https://opencode.ai/install | bash"
                echo "  Claude:    npm install -g @anthropic-ai/claude-code"
                echo "  Copilot:   gh extension install github/gh-copilot"
            fi
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

# Sync plugins
sync_plugins() {
    echo -e "${YELLOW}Installing plugins (this may take a minute)...${NC}"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || nvim --headless -c "lua require('lazy').sync()" -c "qa" 2>/dev/null || true
    echo -e "${GREEN}Plugins installed!${NC}"
}

# Main
main() {
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
    echo "Debugging:"
    echo "  <leader>db  = Toggle breakpoint"
    echo "  <leader>dc  = Start/continue debug"
    echo ""
    echo "99 AI Agent (requires OpenCode/Claude/Copilot CLI):"
    echo "  <leader>9f  = Fill in function"
    echo "  <leader>9v  = Process visual selection"
    echo "  :NNOpenCode = Switch to OpenCode provider"
    echo "  :NNClaude   = Switch to Claude CLI"
    echo "  :NNCopilot  = Switch to Copilot CLI"
}

main "$@"
