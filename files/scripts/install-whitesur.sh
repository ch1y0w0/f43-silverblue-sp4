#!/usr/bin/env bash
set -euo pipefail
set -x

echo "=== Installing WhiteSur theme (dark + blue + Fedora + classic Big Sur) ==="

# Make sure the tools we need are present
command -v sassc >/dev/null || { echo "sassc missing"; exit 1; }
command -v glib-compile-resources >/dev/null || { echo "glib2-devel missing"; exit 1; }

WORKDIR=/tmp/whitesur-build
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# ---------------------------------------------------------------
# 1. GTK + GNOME Shell theme
# ---------------------------------------------------------------
echo "--> Cloning WhiteSur-gtk-theme..."
git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme

echo "--> Installing system-wide GTK + Shell theme..."

# Important: we install as root so it goes to /usr/share/themes
# We also disable the installer's own dependency installation
# because we already layered the packages in the recipe.

./install.sh \
  --dest /usr/share/themes \
  --color dark \
  --theme blue \
  --opacity normal \
  --nautilus stable \
  --shell \
  --icon fedora \
  --silent-mode || {
    echo "install.sh failed. Trying alternative syntax..."
    ./install.sh -d /usr/share/themes -c dark -t blue -o normal -N stable --shell -i fedora --silent-mode
  }

echo "--> Installing GDM theme..."
./tweaks.sh -g \
  -c dark \
  -t blue \
  --shell -i fedora \
  --silent-mode || true   # GDM is nice-to-have, don't fail the whole build

echo "--> Setting up Flatpak theme integration..."
./tweaks.sh -F \
  -c dark \
  -t blue \
  -o normal \
  --silent-mode || true

# Flatpak filesystem overrides
flatpak override --system --filesystem=xdg-config/gtk-3.0 || true
flatpak override --system --filesystem=xdg-config/gtk-4.0 || true
flatpak override --system --filesystem=/usr/share/themes || true
flatpak override --system --filesystem=/usr/share/icons || true

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

echo "--> Installing system-wide icon theme..."
./install.sh -d /usr/share/icons -t default || ./install.sh -d /usr/share/icons

cd ..

# ---------------------------------------------------------------
# 3. Helper command
# ---------------------------------------------------------------
cat > /usr/bin/whitesur-apply << 'EOF'
#!/usr/bin/env bash
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark-blue" || true
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur" || true
gsettings set org.gnome.shell.extensions.user-theme name "WhiteSur-Dark-blue" 2>/dev/null || true
echo "WhiteSur theme applied. You may need to log out/in."
EOF
chmod +x /usr/bin/whitesur-apply

echo "=== WhiteSur installation finished ==="
ls /usr/share/themes | grep -i whitesur || echo "WARNING: no WhiteSur themes found in /usr/share/themes"
ls /usr/share/icons | grep -i whitesur || echo "WARNING: no WhiteSur icons found"
