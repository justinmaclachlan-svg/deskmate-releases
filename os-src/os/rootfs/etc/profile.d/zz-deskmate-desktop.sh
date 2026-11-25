# Logging in on the first screen starts the desktop (when no login manager did).
# Only for a real person: system accounts (like the login screen's) never get a desktop.
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty 2>/dev/null)" = /dev/tty1 ] && [ "$(id -u)" -ge 1000 ] && id "$(id -un)-bots" >/dev/null 2>&1 && [ -z "$DESKMATE_NO_DESKTOP" ]; then
  exec deskmate-session
fi
