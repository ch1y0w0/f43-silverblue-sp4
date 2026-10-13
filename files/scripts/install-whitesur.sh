#!/usr/bin/env bash
set -euo pipefail

# WhiteSur's lib-core.sh dies silently when $USER is empty (no login session in a build)
export USER=root
export SUDO_USER=root
export HOME=/root

command -v sassc >/dev/null || { echo "sassc missing (add to dnf list)"; exit 1; }
command -v glib-compile-resources >/dev/null || { echo "glib2-devel missing (add to dnf list)"; exit 1; }

WORKDIR=/tmp/whitesur-build
rm -rf "$WORKDIR"; mkdir -p "$WORKDIR"; cd "$WORKDIR"

# --- GTK + GNOME Shell theme ---
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme
# --shell MUST be last: it consumes the options after it
./install.sh -d /usr/share/themes -c dark -t blue -o normal -N stable --shell -i fedora

# GDM login theme (non-fatal; can fail on newer GNOME)
./tweaks.sh -g -c dark -t blue --shell -i fedora || echo "GDM tweak failed, skipping"
cd "$WORKDIR"

# --- Icons ---
git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme
./install.sh -d /usr/share/icons

# --- Helper to apply the theme per user ---
cat > /usr/bin/whitesur-apply <<'EOF'
#!/usr/bin/env bash
gsettings set org.gnome.desktop.interface gtk-theme "WhiteSur-Dark-blue"
gsettings set org.gnome.desktop.interface icon-theme "WhiteSur"
gsettings set org.gnome.shell.extensions.user-theme name "WhiteSur-Dark-blue" 2>/dev/null || true
EOF
chmod +x /usr/bin/whitesur-apply

rm -rf "$WORKDIR"
ls /usr/share/themes | grep -i whitesur
ls /usr/share/icons | grep -i whitesur