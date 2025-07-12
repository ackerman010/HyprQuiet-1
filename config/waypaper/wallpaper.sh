#!/bin/bash

# Give swww a moment to set the wallpaper before querying
sleep 1

# Get the current wallpaper path from swww
WALLPAPER=$(swww query | sed -n 's/.*image: \(.*\)$/\1/p')

# --- Existing Matugen and Wallust commands ---
matugen image "$WALLPAPER"
wallust run "$WALLPAPER"
~/.config/matugen/papirus-folders/change-icons.sh
# ---------------------------------------------

# --- Logic to create symbolic link for Rofi and Hyprlock ---

# Define the target path for Rofi's and Hyprlock's wallpaper
ROFI_WALLPAPER_PATH="$HOME/.config/hypr/current_wallpaper"

# Check if a wallpaper path was successfully obtained from swww
if [ -z "$WALLPAPER" ]; then
    echo "Error: Could not determine current wallpaper from swww. Is swww running and has it set a wallpaper?"
    # Optional: Set a fallback image if no wallpaper is found
    # Uncomment the line below and replace with a path to a default image
    # ln -sf "$HOME/Pictures/default_wallpaper.jpg" "$ROFI_WALLPAPER_PATH"
    exit 1 # Exit if no wallpaper path is found, as subsequent commands would fail
fi

# Check if the current wallpaper file actually exists
if [ ! -f "$WALLPAPER" ]; then
    echo "Error: Current wallpaper file not found at $WALLPAPER"
    exit 1 # Exit if the wallpaper file doesn't exist
fi

# Remove any existing symbolic link or file at the target path
if [ -e "$ROFI_WALLPAPER_PATH" ]; then
    rm "$ROFI_WALLPAPER_PATH"
    echo "Removed old link/file at $ROFI_WALLPAPER_PATH"
fi

# Create a new symbolic link from the actual wallpaper path to the Rofi/Hyprlock target path
ln -s "$WALLPAPER" "$ROFI_WALLPAPER_PATH"
echo "Successfully linked $WALLPAPER to $ROFI_WALLPAPER_PATH for Rofi and Hyprlock."

# --- REMOVED: Hyprlock auto-restart. Hyprlock will now update its wallpaper
#              only when you manually launch it (e.g., via a keybinding).
# pkill hyprlock
# hyprlock & disown

# Optional: Reload Rofi theme if it's already open (might not be necessary if Rofi re-reads on launch)
# pkill -USR1 rofi

