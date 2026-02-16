#!/bin/bash
# linux-install-rr.sh — Install rr record & replay debugger on Linux
# Supports: Arch (pacman/yay), Debian/Ubuntu (apt), Fedora (dnf)
# Can be run standalone or called from install.sh
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [[ "$(uname -s)" != "Linux" ]]; then
    echo -e "${RED}rr is Linux-only. macOS and Windows (native) are not supported.${NC}"
    exit 1
fi

# WSL2 detection
IS_WSL=false
if grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
    echo -e "${YELLOW}WSL2 detected. rr requires Windows 11+ for WSL2 support.${NC}"
    echo -e "${YELLOW}If rr fails, ensure your Windows build is 22000+ (Settings > System > About).${NC}"
    echo ""
fi

# Detect package manager
PKG_MGR="unknown"
if command -v pacman &>/dev/null; then
    PKG_MGR="pacman"
elif command -v apt-get &>/dev/null; then
    PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
fi

echo -e "${YELLOW}=== rr Record & Replay Debugger Installer ===${NC}"
echo -e "${GREEN}Package manager: $PKG_MGR${NC}"
echo ""

# Install gdb if missing
if ! command -v gdb &>/dev/null; then
    echo -e "${YELLOW}Installing gdb...${NC}"
    case "$PKG_MGR" in
        pacman) sudo pacman -S --noconfirm gdb ;;
        apt)    sudo apt-get update && sudo apt-get install -y gdb ;;
        dnf)    sudo dnf install -y gdb ;;
        *)      echo -e "${RED}Unknown package manager. Install gdb manually.${NC}"; exit 1 ;;
    esac
else
    echo -e "${GREEN}gdb already installed: $(gdb --version | head -1)${NC}"
fi

# Install rr
if ! command -v rr &>/dev/null; then
    echo -e "${YELLOW}Installing rr...${NC}"
    case "$PKG_MGR" in
        pacman)
            if command -v yay &>/dev/null; then
                yay -S --noconfirm rr
            elif command -v paru &>/dev/null; then
                paru -S --noconfirm rr
            else
                echo -e "${RED}rr is in the AUR. Install yay or paru first:${NC}"
                echo "  sudo pacman -S --needed git base-devel"
                echo "  git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
                exit 1
            fi
            ;;
        apt)
            # Try the rr PPA first, fall back to building from source
            if sudo apt-get install -y rr 2>/dev/null; then
                echo -e "${GREEN}rr installed from apt repos${NC}"
            else
                echo -e "${YELLOW}rr not in repos, trying Mozilla PPA...${NC}"
                sudo apt-get install -y software-properties-common
                if sudo add-apt-repository -y ppa:rr-debugger/rr && sudo apt-get update && sudo apt-get install -y rr; then
                    echo -e "${GREEN}rr installed from PPA${NC}"
                else
                    echo -e "${RED}Failed to install rr from PPA.${NC}"
                    echo -e "${YELLOW}Try building from source: https://github.com/rr-debugger/rr/wiki/Building-And-Installing${NC}"
                    exit 1
                fi
            fi
            ;;
        dnf)
            sudo dnf install -y rr
            ;;
        *)
            echo -e "${RED}Unknown package manager. Install rr manually: https://rr-project.org/${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${GREEN}rr already installed: $(rr --version 2>&1 | head -1)${NC}"
fi

# Set perf_event_paranoid (required for rr)
echo ""
PARANOID=$(cat /proc/sys/kernel/perf_event_paranoid 2>/dev/null || echo "unknown")
echo -e "${YELLOW}Current perf_event_paranoid: $PARANOID${NC}"

if [[ "$PARANOID" != "1" && "$PARANOID" != "0" && "$PARANOID" != "-1" ]]; then
    echo -e "${YELLOW}Setting kernel.perf_event_paranoid=1 (required for rr)...${NC}"

    # Set immediately
    sudo sysctl -w kernel.perf_event_paranoid=1

    # Persist across reboots
    SYSCTL_CONF="/etc/sysctl.d/10-rr.conf"
    if [[ ! -f "$SYSCTL_CONF" ]] || ! grep -q "perf_event_paranoid" "$SYSCTL_CONF" 2>/dev/null; then
        echo "kernel.perf_event_paranoid=1" | sudo tee "$SYSCTL_CONF" >/dev/null
        echo -e "${GREEN}Persisted to $SYSCTL_CONF${NC}"
    fi
else
    echo -e "${GREEN}perf_event_paranoid already permissive ($PARANOID)${NC}"
fi

# Verify rr works
echo ""
echo -e "${YELLOW}Verifying rr...${NC}"
if rr record /bin/true 2>/dev/null && echo -e "${GREEN}rr works!${NC}"; then
    # Clean up the test trace
    rm -rf "$HOME/.local/share/rr/true-"* 2>/dev/null || true
else
    echo -e "${RED}rr verification failed.${NC}"
    if $IS_WSL; then
        echo -e "${YELLOW}On WSL2, ensure you have Windows 11 build 22000+.${NC}"
        echo -e "${YELLOW}Also check: https://github.com/rr-debugger/rr/wiki/Usage#wsl2${NC}"
    else
        echo -e "${YELLOW}Check: https://github.com/rr-debugger/rr/wiki/Building-And-Installing${NC}"
    fi
    exit 1
fi

echo ""
echo -e "${GREEN}=== rr installation complete ===${NC}"
echo "Usage in Neovim:"
echo "  :RRRecord ./target/debug/myapp   Record a binary"
echo "  :RRReplay                        Start replay server"
echo "  <leader>dc                       Connect DAP, pick 'rr: Replay Binary'"
echo "  <leader>dRc                      Reverse continue"
echo "  <leader>dRi                      Reverse step into"
echo "  <leader>dRo                      Reverse step over"
echo "  <leader>dRO                      Reverse step out"
