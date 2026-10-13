#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing WhiteSur theme (dark + blue + Fedora + classic Big Sur) ==="

WORKDIR=/tmp/whitesur-build
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ---------------------------------------------------------------
# 1. GTK + GNOME Shell + GDM theme
# ---------------------------------------------------------------
echo "--> Cloning WhiteSur-gtk-theme..."
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme

echo "--> Installing system-wide GTK + Shell theme..."
# classic Big Sur look, dark, blue accent, Fedora Activities icon, Nautilus stable
./install.sh \
  -d /usr/share/themes \
  -c dark \
  -t blue \
  -o normal \
  -N stable \
  --shell -i fedora \
  --silent-mode

echo "--> Installing GDM theme..."
./tweaks.sh -g \
  -c dark \
  -t blue \
  --shell -i fedora \
  --silent-mode

echo "--> Setting up Flatpak theme integration..."

# Connect the theme itself
./tweaks.sh -F \
  -c dark \
  -t blue \
  -o normal \
  --silent-mode

# Make sure both system and user Flatpaks can see the themes
# System-wide Flatpaks
flatpak override --system --filesystem=xdg-config/gtk-3.0 || true
flatpak override --system --filesystem=xdg-config/gtk-4.0 || true
flatpak override --system --filesystem=/usr/share/themes || true
flatpak override --system --filesystem=/usr/share/icons || true

# User Flatpaks (Brave, etc.)
flatpak override --user --filesystem=xdg-config/gtk-3.0 || true
flatpak override --user --filesystem=xdg-config/gtk-4.0 || true
flatpak override --user --filesystem=/usr/share/themes || true
flatpak override --user --filesystem=/usr/share/icons || true

cd ..

# ---------------------------------------------------------------
# 2. Icon theme
# ---------------------------------------------------------------
echo "--> Cloning WhiteSur-icon-theme..."
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme

echo "--> Installing system-wide icon theme (blue)..."
./install.sh \
  -d /usr/share/icons \
  -t default \
  --silent-mode || ./install.sh -d /usr/share/icons -t default

cd ..

# ---------------------------------------------------------------
# 3. Make a small helper for the user (optional but useful)
# ---------------------------------------------------------------
cat > /usr/bin/whitesur-apply << 'EOF'
#!/usr/bin/env bash
# Quick helper to apply WhiteSur after first login

gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark-blue"
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur"
gsettings set org.gnome.desktop.interface cursor-theme "WhiteSur-cursors" 2>/dev/null || true
gsettings set org.gnome.shell.extensions.user-theme name "WhiteSur-Dark-blue" 2>/dev/null || true

# libadwaita (gtk4)
mkdir -p ~/.config/gtk-4.0
# The installer already put a system copy; this makes a user override if needed
echo "WhiteSur applied. Log out/in or restart GNOME Shell if needed."
EOF
chmod +x /usr/bin/whitesur-apply

echo "=== WhiteSur installation finished ==="
echo "Themes are in /usr/share/themes and /usr/share/icons"
echo "After first login you can run:  whitesur-apply"
echo "Or set them manually in GNOME Tweaks / Extension Manager (User Themes)."
