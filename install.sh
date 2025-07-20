#!/bin/bash
set -e

REPO_URL="https://github.com/Rad-nerd/HomeLAB-Radio.git"
REPO_DIR="HomeLAB-Radio"

# CORRECTED PATH: This is the actual path for OpenWebRX+ htdocs.
OPENWEBRX_HTDOCS_PATH="/usr/lib/python3/dist-packages/htdocs" 

# This is the path to your custom htdocs directory *within* your cloned HomeLAB-Radio repository.
CUSTOM_HTDOCS_LOCAL_NAME="htdocs" 

echo "========================================="
echo "  Welcome to the HomeLAB-Radio Installer!"
echo "========================================="
echo ""
echo "This script will install OpenWebRX+ and then apply the HomeLAB-Radio UI modifications."
echo "It requires an internet connection and sudo privileges."
echo ""

# Ask for sudo password upfront and keep it cached for the duration of the script
sudo -v || { echo "Sudo access required. Exiting."; exit 1; }

# Set DEBIAN_FRONTEND to noninteractive to prevent apt from asking questions
# This is crucial for one-liner execution.
export DEBIAN_FRONTEND=noninteractive

# 1. Update package lists and install basic tools
echo "1/6: Updating package lists and installing essential tools (git, curl, gpg, etc.)..."
sudo apt update -y
sudo apt install -y git curl gnupg software-properties-common dirmngr ca-certificates 

# 2. Detect OS and Version for OpenWebRX+ repository setup
echo "2/6: Detecting Operating System and setting up OpenWebRX+ repositories..."

# Get OS ID and VERSION_CODENAME
OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
VERSION_CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

OPENWEBRX_REPO_ADDED=false

case "$OS_ID" in
    ubuntu)
        case "$VERSION_CODENAME" in
            jammy) # Ubuntu 22.04
                echo "    Detected Ubuntu 22.04 (Jammy). Adding OpenWebRX+ and OpenWebRX repositories."
                curl -s https://luarvique.github.io/ppa/openwebrx-plus.gpg | sudo gpg --yes --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
                sudo tee /etc/apt/sources.list.d/openwebrx-plus.list <<<"deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/ubuntu ./"
                curl -s https://repo.openwebrx.de/debian/key.gpg.txt | sudo gpg --yes --dearmor -o /usr/share/keyrings/openwebrx.gpg
                sudo tee /etc/apt/sources.list.d/openwebrx.list <<<"deb [signed-by=/usr/share/keyrings/openwebrx.gpg] https://repo.openwebrx.de/ubuntu/ jammy main"
                OPENWEBRX_REPO_ADDED=true
                ;;
            noble) # Ubuntu 24.04
                echo "    Detected Ubuntu 24.04 (Noble). Adding OpenWebRX+ repository."
                curl -s https://luarvique.github.io/ppa/openwebrx-plus.gpg | sudo gpg --yes --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
                sudo tee /etc/apt/sources.list.d/openwebrx-plus.list <<<"deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/noble ./"
                OPENWEBRX_REPO_ADDED=true
                ;;
            *)
                echo "    Unsupported Ubuntu version ($VERSION_CODENAME). Cannot proceed with package install."
                echo "    Please install OpenWebRX+ manually or use a supported OS version."
                exit 1
                ;;
        esac
        ;;
    debian)
        case "$VERSION_CODENAME" in
            bullseye) # Debian Bullseye
                echo "    Detected Debian Bullseye. Adding OpenWebRX+ and OpenWebRX repositories."
                curl -s https://luarvique.github.io/ppa/openwebrx-plus.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
                sudo tee /etc/apt/sources.list.d/openwebrx-plus.list <<<"deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/debian ./"
                curl -s https://repo.openwebrx.de/debian/key.gpg.txt | sudo gpg --yes --dearmor -o /usr/share/keyrings/openwebrx.gpg
                sudo tee /etc/apt/sources.list.d/openwebrx.list <<<"deb [signed-by=/usr/share/keyrings/openwebrx.gpg] https://repo.openwebrx.de/debian/ bullseye main"
                OPENWEBRX_REPO_ADDED=true
                ;;
            bookworm) # Debian Bookworm
                echo "    Detected Debian Bookworm. Adding OpenWebRX+ repository."
                curl -s https://luarvique.github.io/ppa/openwebrx-plus.gpg | sudo gpg --yes --dearmor -o /etc/apt/trusted.gpg.d/openwebrx-plus.gpg
                sudo tee /etc/apt/sources.list.d/openwebrx-plus.list <<<"deb [signed-by=/etc/apt/trusted.gpg.d/openwebrx-plus.gpg] https://luarvique.github.io/ppa/bookworm ./"
                OPENWEBRX_REPO_ADDED=true
                ;;
            *)
                echo "    Unsupported Debian version ($VERSION_CODENAME). Cannot proceed with package install."
                echo "    Please install OpenWebRX+ manually or use a supported OS version."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "    Unsupported OS: $OS_ID. This script only supports Ubuntu (22.04/24.04) and Debian (Bullseye/Bookworm)."
        echo "    Please install OpenWebRX+ manually or use a supported OS version."
        exit 1
        ;;
esac

if [ "$OPENWEBRX_REPO_ADDED" = false ]; then
    echo "    Failed to add OpenWebRX+ repositories. Please ensure your OS is supported and try again."
    exit 1
fi

# 3. Clone or update the HomeLAB-Radio repository
echo "3/6: Cloning or updating HomeLAB-Radio repository..."
if [ -d "$REPO_DIR" ]; then
    echo "    Repository directory '$REPO_DIR' found. Pulling latest changes..."
    # Ensure we are in the cloned repo directory for git pull
    (cd "$REPO_DIR" && git pull)
else
    echo "    Cloning HomeLAB-Radio repository from $REPO_URL..."
    git clone "$REPO_URL"
fi

# Get the full path to the cloned repo AFTER cloning/pulling
CURRENT_REPO_PATH=$(pwd)/$REPO_DIR

# 4. Install OpenWebRX+ from packages
echo "4/6: Updating package cache and installing OpenWebRX+..."
# DEBIAN_FRONTEND=noninteractive ensures apt doesn't ask questions
sudo apt update -y
sudo apt install -y openwebrx # This should now pull from the added repositories

# 5. Replace OpenWebRX+ htdocs with HomeLAB-Radio htdocs
echo "5/6: Applying HomeLAB-Radio UI modifications by replacing htdocs..."
# Corrected path for OPENWEBRX_HTDOCS_PATH
if [ -d "$OPENWEBRX_HTDOCS_PATH" ]; then
    echo "    Backing up original OpenWebRX+ htdocs to ${OPENWEBRX_HTDOCS_PATH}.bak"
    sudo mv "$OPENWEBRX_HTDOCS_PATH" "${OPENWEBRX_HTDOCS_PATH}.bak" || true # Use || true to prevent error if .bak already exists
    
    echo "    Copying custom htdocs from $CURRENT_REPO_PATH/$CUSTOM_HTDOCS_LOCAL_NAME to $OPENWEBRX_HTDOCS_PATH"
    # Important: Copy contents of the folder, not the folder itself
    sudo cp -r "$CURRENT_REPO_PATH/$CUSTOM_HTDOCS_LOCAL_NAME/." "$OPENWEBRX_HTDOCS_PATH/"
    echo "    HomeLAB-Radio htdocs applied."
else
    echo "    WARNING: OpenWebRX+ htdocs directory not found at '$OPENWEBRX_HTDOCS_PATH'."
    echo "    The UI modifications may not be applied correctly."
    echo "    Please verify the OpenWebRX+ htdocs path on your system."
fi

# 6. Start/Restart OpenWebRX+ service
echo "6/6: Starting/Restarting OpenWebRX+ service..."
sudo systemctl daemon-reload || true # Reload systemd units in case new service file was added/changed
sudo systemctl enable openwebrx || true # Enable at boot
sudo systemctl restart openwebrx || true # Restart the service

echo ""
echo "========================================="
echo "  HomeLAB-Radio Installation Complete!"
echo "========================================="
echo "You should now be able to access HomeLAB-Radio in your web browser."
echo "Access it at: http://localhost:8073 (or whatever port OpenWebRX+ is configured for, usually 8073 by default)"
echo "If you have issues, check the OpenWebRX+ logs with: journalctl -u openwebrx -f"
echo "Thank you for using HomeLAB-Radio by Rad-nerd!"
echo ""
