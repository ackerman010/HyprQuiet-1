#!/usr/bin/env bash
set -euo pipefail

# This script automates the installation of Hyprland and its core dependencies
# on Arch Linux. It handles both official repository packages and AUR packages,
# and includes a section for future dotfiles management.
#
# This script is designed to be run with bash (as indicated by the shebang).
# Its operations and outcomes are compatible whether the user's default
# interactive shell is bash, zsh, or fish.

echo "Starting Hyprland and dependency installation..."

# -----------------------------------------------------------------------------
# 0) Refresh pacman databases only (no full upgrade, so no extra package pulls)
echo "--> Refreshing pacman databases..."
sudo pacman -Sy --noconfirm

# -----------------------------------------------------------------------------
# 0.1) Add Chaotic-AUR repository conditionally
echo "--> Checking Chaotic-AUR repository status..."
if grep -q "\[chaotic-aur\]" /etc/pacman.conf && sudo pacman-key --list-keys 3056513887B78AEB &>/dev/null; then
  echo "    Chaotic-AUR appears to be already added and its key imported. Skipping setup."
  sudo pacman -Sy # Ensure databases are synced even if already added
else
  echo "    Chaotic-AUR not fully set up. Adding repository..."
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com && \
  sudo pacman-key --lsign-key 3056513887B78AEB && \
  sudo pacman -U \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && \
  echo -e "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" \
    | sudo tee -a /etc/pacman.conf && \
  sudo pacman -Sy # Resync after adding Chaotic-AUR
  echo "--> Chaotic-AUR added and synced."
fi

# -----------------------------------------------------------------------------
# 1) Define your exact desired list of packages
# Note: 'xdg-dekstop-portal' has been corrected to 'xdg-desktop-portal'
pkgs=(
  hyprland
  hyprlock
  hyprpicker
  hyprshot
  kitty
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-wlr
  xdg-desktop-portal # Corrected from xdg-dekstop-portal
  waybar
  pulsemixer
  swaync
  xwaylandvideobridge
  rofi-wayland
  rofi-emoji
  cliphist
  wl-clip-persist
  swww
  waypaper
  swappy
  yazi
  fish
  fastfetch
  eza
  ffmpeg
  expac
  fisher
  qt6ct
  bibata-cursor-theme-bin
  matugen
  wallust
  nemo
  nemo-fileroller
  mission-center
  sddm
  nwg-look
  loupe
  mpv-full
  gnome-polkit
  alsa-utils
  gvfs
  gvfs-smb
  gvfs-mtp
  gvfs-goa
  gvfs-afc
  file-roller
  p7zip
  unzip
  zip
  tar
  tumbler
  poppler
  ffmpegthumbnailer
  libgsf
  webp-pixbuf-loader
  gst-libav
  nemo-preview
  gnome-text-editor
)

echo "--> Analyzing package list: ${pkgs[*]}"

# -----------------------------------------------------------------------------
# 2) Partition into official repository vs. AUR packages
repo_pkgs=()
aur_pkgs=()
for pkg in "${pkgs[@]}"; do
  if pacman -Si "$pkg" &>/dev/null; then
    repo_pkgs+=("$pkg")
  else
    aur_pkgs+=("$pkg")
  fi
done

# -----------------------------------------------------------------------------
# 3) Install official-repo packages (if any)
if [ ${#repo_pkgs[@]} -gt 0 ]; then
  echo "--> Installing/updating official repository packages: ${repo_pkgs[*]}"
  # pacman is smart enough to skip already installed packages.
  # Use --overwrite '*' to automatically handle file conflicts.
  sudo pacman -S --noconfirm --overwrite '*' "${repo_pkgs[@]}"
else
  echo "--> No official repository packages to install/update."
fi

# -----------------------------------------------------------------------------
# 4) Bootstrap yay (AUR helper) if needed
if ! command -v yay &>/dev/null; then
  echo "--> yay (AUR helper) not found. Cloning and building yay..."
  # Clean up /tmp/yay if it exists from a previous failed attempt
  if [ -d "/tmp/yay" ]; then
    echo "    Cleaning up existing /tmp/yay directory..."
    sudo rm -rf /tmp/yay
  fi
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  pushd /tmp/yay >/dev/null
    makepkg -si --noconfirm
  popd >/dev/null
  sudo rm -rf /tmp/yay # Clean up after successful installation
  echo "--> yay installed successfully."
else
  echo "--> yay (AUR helper) is already installed. Skipping bootstrap."
fi

# -----------------------------------------------------------------------------
# 5) Install AUR packages (if any)
if [ ${#aur_pkgs[@]} -gt 0 ]; then
  echo "--> Installing/updating AUR packages: ${aur_pkgs[*]}"
  # yay is smart enough to skip already installed packages.
  # Use --overwrite '*' to automatically handle file conflicts.
  yay -S --noconfirm --overwrite '*' "${aur_pkgs[@]}"
else
  echo "--> No AUR packages to install/update."
fi

# -----------------------------------------------------------------------------
# 6) Install Fisher (Fish plugin manager), if not already present
echo "--> Checking for Fisher (Fish plugin manager)..."
if ! fish -c 'type -q fisher'; then
  echo "--> Fisher not found. Installing Fisher..."
  fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher'
  echo "--> Fisher installed successfully."
else
  echo "--> Fisher is already installed. Skipping installation."
fi

# -----------------------------------------------------------------------------
# 6.1) Install Catppuccin GTK Theme
echo "--> Installing Catppuccin GTK Theme..."
CATPPUCCIN_GTK_DIR="/tmp/Catppuccin-GTK-Theme"
# Always remove temporary directory to ensure a fresh clone and install
if [ -d "$CATPPUCCIN_GTK_DIR" ]; then
  echo "    Removing existing $CATPPUCCIN_GTK_DIR to ensure clean clone..."
  sudo rm -rf "$CATPPUCCIN_GTK_DIR"
fi
git clone https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git "$CATPPUCCIN_GTK_DIR"
pushd "$CATPPUCCIN_GTK_DIR/themes" >/dev/null
  echo "    Running Catppuccin GTK Theme install script..."
  sudo chmod +x install.sh
  sudo ./install.sh
popd >/dev/null
sudo rm -rf "$CATPPUCCIN_GTK_DIR" # Clean up after installation
echo "--> Catppuccin GTK Theme installation complete."

# -----------------------------------------------------------------------------
# 6.2) Set Default Applications and Enable User Services
echo "--> Setting default applications and enabling user services..."

# Set Loupe as default for images/gifs
echo "    Setting Loupe as default for images and GIFs..."
xdg-mime default org.gnome.Loupe.desktop image/jpeg
xdg-mime default org.gnome.Loupe.desktop image/png
xdg-mime default org.gnome.Loupe.desktop image/gif
xdg-mime default org.gnome.Loupe.desktop image/bmp
xdg-mime default org.gnome.Loupe.desktop image/tiff
xdg-mime default org.gnome.Loupe.desktop image/webp
xdg-mime default org.gnome.Loupe.desktop image/x-icon
xdg-mime default org.gnome.Loupe.desktop image/x-bmp
xdg-mime default org.gnome.Loupe.desktop image/x-portable-pixmap
xdg-mime default org.gnome.Loupe.desktop image/x-portable-graymap
xdg-mime default org.gnome.Loupe.desktop image/x-portable-bitmap
xdg-mime default org.gnome.Loupe.desktop image/x-xbitmap
xdg-mime default org.gnome.Loupe.desktop image/x-xpixmap
xdg-mime default org.gnome.Loupe.desktop image/svg+xml

# Set MPV as default for videos
echo "    Setting MPV as default for videos..."
xdg-mime default mpv.desktop video/mp4
xdg-mime default mpv.desktop video/x-matroska # .mkv
xdg-mime default mpv.desktop video/webm
xdg-mime default mpv.desktop video/avi
xdg-mime default mpv.desktop video/quicktime # .mov
xdg-mime default mpv.desktop video/x-flv
xdg-mime default mpv.desktop video/3gpp
xdg-mime default mpv.desktop video/ogg
xdg-mime default mpv.desktop video/x-msvideo
xdg-mime default mpv.desktop video/mpeg
xdg-mime default mpv.desktop application/x-extension-mp4
xdg-mime default mpv.desktop application/x-matroska

# Enable and start user-level xdg-desktop-portal
echo "    Enabling and starting xdg-desktop-portal --user service..."
systemctl --user enable --now xdg-desktop-portal

echo "--> Default applications and user services setup complete."

# -----------------------------------------------------------------------------
# 7) Dotfiles Integration
echo "--> Starting dotfiles integration..."

DOTFILES_REPO="https://github.com/ackerman010/HyprQuiet-1.git"
DOTFILES_DIR="$HOME/.dotfiles_hyprquiet" # Use a specific directory for this repo
CONFIG_DIR="$HOME/.config"
BACKUP_CONFIG_DIR="$HOME/.config_backup_$(date +%Y%m%d%H%M%S)"

# Ensure the dotfiles repository is cloned/updated first, as both .config and icons depend on it
echo "--> Cloning/Updating dotfiles repository from $DOTFILES_REPO to $DOTFILES_DIR..."
if [ -d "$DOTFILES_DIR" ]; then
  echo "    $DOTFILES_DIR already exists. Pulling latest changes..."
  git -C "$DOTFILES_DIR" pull
else
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# 7.1) Handle ~/.config directory
echo "--> Processing $CONFIG_DIR..."
# Create .config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Backup existing ~/.config
if [ -d "$CONFIG_DIR" ] && [ "$(ls -A "$CONFIG_DIR")" ]; then # Check if directory exists and is not empty
  echo "--> Backing up existing $CONFIG_DIR to $BACKUP_CONFIG_DIR..."
  mv "$CONFIG_DIR" "$BACKUP_CONFIG_DIR"
  echo "    Backup complete. Original config moved to $BACKUP_CONFIG_DIR"
  mkdir -p "$CONFIG_DIR" # Recreate empty .config after moving
else
  echo "--> $CONFIG_DIR is empty or does not exist. No backup needed."
  mkdir -p "$CONFIG_DIR" # Ensure it exists if it didn't
fi

# Copy dotfiles into ~/.config
echo "--> Copying dotfiles from $DOTFILES_DIR/config/ to $CONFIG_DIR/..."
# Ensure source directory exists before copying
if [ -d "$DOTFILES_DIR/config" ]; then
  cp -r "$DOTFILES_DIR/config/." "$CONFIG_DIR/"
  echo "    Dotfiles copied successfully."
  echo "    Any previous files in $CONFIG_DIR (before backup) have been replaced."
else
  echo "    Warning: Source directory $DOTFILES_DIR/config does not exist. Skipping dotfiles copy."
fi

# -----------------------------------------------------------------------------
# 8) Icon Theme Integration
echo "--> Starting icon theme integration..."

ICONS_SOURCE_DIR="$DOTFILES_DIR/local/share/icons"
ICONS_DEST_DIR="$HOME/.local/share/icons"
BACKUP_ICONS_DIR="$HOME/.local/share/icons_backup_$(date +%Y%m%d%H%M%S)"

# Create destination directory if it doesn't exist
mkdir -p "$ICONS_DEST_DIR"

# 8.1) Backup existing ~/.local/share/icons
if [ -d "$ICONS_DEST_DIR" ] && [ "$(ls -A "$ICONS_DEST_DIR")" ]; then # Check if directory exists and is not empty
  echo "--> Backing up existing $ICONS_DEST_DIR to $BACKUP_ICONS_DIR..."
  mv "$ICONS_DEST_DIR" "$BACKUP_ICONS_DIR"
  echo "    Backup complete. Original icons moved to $BACKUP_ICONS_DIR"
  mkdir -p "$ICONS_DEST_DIR" # Recreate empty icons dir after moving
else
  echo "--> $ICONS_DEST_DIR is empty or does not exist. No backup needed."
  mkdir -p "$ICONS_DEST_DIR" # Ensure it exists if it didn't
fi

# 8.2) Copy icon theme into ~/.local/share/icons
echo "--> Copying icon theme from $ICONS_SOURCE_DIR to $ICONS_DEST_DIR/..."
# Ensure source directory exists before copying
if [ -d "$ICONS_SOURCE_DIR" ]; then
  cp -r "$ICONS_SOURCE_DIR/." "$ICONS_DEST_DIR/"
  echo "    Icon theme copied successfully."
  echo "    Any previous files in $ICONS_DEST_DIR (before backup) have been replaced."
else
  echo "    Warning: Source directory $ICONS_SOURCE_DIR does not exist. Skipping icon theme copy."
fi

echo "--> Icon theme integration complete."

# -----------------------------------------------------------------------------
# 9) SDDM Theme Installation (User Choice)
echo "--> SDDM Theme Installation (Optional)"
read -rp "Do you want to install the SDDM Astronaut theme? (y/N): " install_sddm_theme_choice
if [[ "$install_sddm_theme_choice" =~ ^[Yy]$ ]]; then
  echo "--> Installing SDDM Astronaut theme..."
  sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)"
  echo "--> SDDM Astronaut theme installation complete."
  SDDM_THEME_INSTALLED="true"
else
  echo "--> Skipping SDDM Astronaut theme installation."
  SDDM_THEME_INSTALLED="false"
fi


# -----------------------------------------------------------------------------
# 10) SDDM Service Setup
echo "--> Setting up SDDM Display Manager service..."

# Enable SDDM service
echo "    Enabling sddm.service..."
sudo systemctl enable sddm.service

# Start SDDM service (optional, for immediate effect without reboot)
echo "    Starting sddm.service..."
sudo systemctl start sddm.service

echo "--> SDDM service setup complete."

echo
echo "✔️ Installation complete!"
echo "    • Attempted to install: ${pkgs[*]}"
echo "    • Official Repo packages installed/checked: ${repo_pkgs[*]}"
echo "    • AUR packages installed/checked:          ${aur_pkgs[*]}"
echo "    • Catppuccin GTK Theme installed."
echo "    • Your dotfiles from $DOTFILES_REPO have been applied to $HOME/.config"
echo "      (A backup of your previous ~/.config is available at $BACKUP_CONFIG_DIR)"
echo "    • Your icon theme from $DOTFILES_REPO has been applied to $HOME/.local/share/icons"
echo "      (A backup of your previous ~/.local/share/icons is available at $BACKUP_ICONS_DIR)"
if [ "$SDDM_THEME_INSTALLED" = "true" ]; then
  echo "    • SDDM has been installed and the Astronaut theme applied."
else
  echo "    • SDDM has been installed (theme installation skipped by user)."
fi
echo "    • SDDM service has been enabled and started."
echo
echo "You should now be presented with the SDDM login screen. If not, please reboot."
echo "Remember to select Hyprland as your session from the SDDM login screen."
