#!/bin/bash
# Builds Deskmate OS: Debian 13 with Deskmate as the desktop, as a disk image
# for a Hyper-V generation 2 VM (UEFI). Run as root on a Debian or Ubuntu
# machine:   sudo os/build.sh <folder with deskmate, dm, deskctl> <output folder>
set -euo pipefail
BIN=$(realpath "$1"); OUT=$(realpath -m "$2"); HERE=$(cd "$(dirname "$0")" && pwd)
SUITE=trixie; SIZE=${DESKMATE_OS_SIZE:-9G}
ROOT=/mnt/deskmate-os; IMG="$OUT/deskmate-os.raw"
mkdir -p "$OUT" "$ROOT"

# What must be there, and what's nice to have (skipped if Debian doesn't carry it).
BASE="linux-image-amd64 grub-efi-amd64 grub-efi-amd64-signed shim-signed systemd systemd-sysv systemd-resolved systemd-timesyncd dbus dbus-user-session libpam-systemd udev kmod iproute2 iputils-ping netbase ca-certificates curl wget sudo acl locales tzdata less nano bash-completion openssh-server procps psmisc file zip unzip xz-utils git whiptail cloud-guest-utils e2fsprogs dosfstools nftables unattended-upgrades initramfs-tools zstd"
DESKTOP="labwc foot waybar fuzzel swaybg grim slurp wtype wlrctl wl-clipboard xwayland pcmanfm-qt featherpad xdg-utils xdg-user-dirs fonts-noto-core fonts-dejavu-core fonts-noto-mono adwaita-icon-theme libgl1-mesa-dri libegl1 libgles2 libwayland-egl1 libxkbcommon0 libxkbcommon-x11-0 libfontconfig1 chromium libnotify-bin"
DEV="build-essential python3 python3-venv python3-pip pipx nodejs npm bubblewrap binutils gdb strace ltrace jq ripgrep tmux"
SECURITY="clamav clamav-freshclam shellcheck debsecan"
OPTIONAL="hyperv-daemons greetd tuigreet mako-notifier cliphist swaylock swayidle btop neovim lazygit fzf fd-find bat gh bandit python3-bandit gitleaks yara lynis radare2 rizin"

truncate -s "$SIZE" "$IMG"
sgdisk -Z "$IMG" >/dev/null
sgdisk -n1:1M:+300M -t1:ef00 -c1:EFI -n2:0:0 -t2:8300 -c2:root "$IMG" >/dev/null
LOOP=$(losetup -Pf --show "$IMG")
unmount_all() {
  for m in dev/pts dev proc sys run boot/efi ""; do mountpoint -q "$ROOT/$m" && umount "$ROOT/$m" || true; done
}
cleanup() {
  set +e
  unmount_all
  losetup -d "$LOOP" 2>/dev/null
}
trap cleanup EXIT
mkfs.vfat -F32 -n EFI "${LOOP}p1" >/dev/null
mkfs.ext4 -q -L deskmate-os "${LOOP}p2"
mount "${LOOP}p2" "$ROOT"; rmdir "$ROOT/lost+found" 2>/dev/null || true

# Debian's current signing keys, straight from Debian (the build machine's own copy may be old).
KEYRING=/tmp/deskmate-debian-keys.gpg; : >"$KEYRING"
for k in archive-key-13 archive-key-13-security release-13 archive-key-12 archive-key-12-security release-12; do
  curl -fsSL "https://ftp-master.debian.org/keys/$k.asc" | gpg --dearmor >>"$KEYRING" 2>/dev/null || echo "key not fetched: $k"
done
[ -s "$KEYRING" ] || { echo "Couldn't fetch Debian's signing keys."; exit 1; }

mmdebstrap --variant=minbase --components=main,contrib,non-free-firmware --keyring="$KEYRING" \
  --include="$(echo $BASE $DESKTOP $DEV $SECURITY | tr ' ' ',')" \
  "$SUITE" "$ROOT" \
  "deb http://deb.debian.org/debian $SUITE main contrib non-free-firmware" \
  "deb http://deb.debian.org/debian $SUITE-updates main contrib non-free-firmware" \
  "deb http://security.debian.org/debian-security $SUITE-security main contrib non-free-firmware"

mkdir -p "$ROOT/boot/efi"; mount "${LOOP}p1" "$ROOT/boot/efi"
for m in dev dev/pts proc sys run; do mount --bind "/$m" "$ROOT/$m"; done
cp /etc/resolv.conf "$ROOT/etc/resolv.conf.build"
in_root() { chroot "$ROOT" /usr/bin/env DEBIAN_FRONTEND=noninteractive LC_ALL=C PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"; }
# Name lookups inside the chroot while building.
rm -f "$ROOT/etc/resolv.conf"; cp /etc/resolv.conf "$ROOT/etc/resolv.conf"

in_root apt-get update -q
for p in $OPTIONAL; do
  in_root apt-get install -y -q --no-install-recommends "$p" >/dev/null 2>&1 && echo "optional: $p" || echo "optional (not available): $p"
done

# Deskmate itself.
install -d "$ROOT/opt/deskmate"
install -m755 "$BIN/deskmate" "$BIN/dm" "$BIN/deskctl" "$ROOT/opt/deskmate/"
cp "$HERE/../README.md" "$ROOT/opt/deskmate/README.md"
ln -sf /opt/deskmate/deskmate /opt/deskmate/dm /opt/deskmate/deskctl "$ROOT/usr/local/bin/"
cp -R --preserve=mode "$HERE/rootfs/." "$ROOT/"
install -d "$ROOT/etc/chromium.d"
echo 'export CHROMIUM_FLAGS="$CHROMIUM_FLAGS --ozone-platform-hint=auto"' >"$ROOT/etc/chromium.d/deskmate"
chmod 755 "$ROOT"/usr/local/bin/deskmate-* "$ROOT"/usr/local/sbin/deskmate-*
cat >"$ROOT/usr/share/applications/deskmate.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Deskmate
Comment=Your AI teammates
Exec=deskmate-desktop deskmate
Icon=applications-system
Categories=Utility;
DESK

# Security scanners that aren't Debian packages. Each is optional: Deskmate
# uses the ones that are there and says which are missing.
install -d "$ROOT/opt/deskmate-security/bin"
in_root env PIPX_HOME=/opt/deskmate-security/pipx PIPX_BIN_DIR=/opt/deskmate-security/bin pipx install "git+https://github.com/NVIDIA/skillspector.git" >/dev/null 2>&1 && echo "scanner: skillspector" || echo "scanner (not installed): skillspector"
in_root env PIPX_HOME=/opt/deskmate-security/pipx PIPX_BIN_DIR=/opt/deskmate-security/bin pipx install cisco-ai-skill-scanner >/dev/null 2>&1 && echo "scanner: skill-scanner" || echo "scanner (not installed): skill-scanner"
in_root sh -c 'command -v bandit >/dev/null || PIPX_HOME=/opt/deskmate-security/pipx PIPX_BIN_DIR=/opt/deskmate-security/bin pipx install bandit' >/dev/null 2>&1 || true
curl -fsSL -o "$ROOT/opt/deskmate-security/bin/osv-scanner" https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_linux_amd64 && chmod 755 "$ROOT/opt/deskmate-security/bin/osv-scanner" && echo "scanner: osv-scanner" || echo "scanner (not installed): osv-scanner"
for b in "$ROOT"/opt/deskmate-security/bin/*; do { [ -L "$b" ] || [ -e "$b" ]; } && ln -sf "/opt/deskmate-security/bin/$(basename "$b")" "$ROOT/usr/local/bin/$(basename "$b")"; done
chmod -R a+rX "$ROOT/opt/deskmate-security"

# The AI coding tools, installed but not signed in. They run only in a Bots'
# account; each person signs in with `deskmate-os login <tool>`.
for pkg in @anthropic-ai/claude-code @openai/codex @google/gemini-cli; do
  in_root npm install -g --no-fund --no-audit "$pkg" >/dev/null 2>&1 && echo "ai tool: $pkg" || echo "ai tool (not installed): $pkg"
done

# System setup.
echo deskmate-os >"$ROOT/etc/hostname"
printf '127.0.0.1 localhost\n127.0.1.1 deskmate-os\n::1 localhost ip6-localhost ip6-loopback\n' >"$ROOT/etc/hosts"
echo 'en_US.UTF-8 UTF-8' >"$ROOT/etc/locale.gen"; in_root locale-gen >/dev/null; echo 'LANG=en_US.UTF-8' >"$ROOT/etc/default/locale"
UUID_ROOT=$(blkid -s UUID -o value "${LOOP}p2"); UUID_EFI=$(blkid -s UUID -o value "${LOOP}p1")
printf 'UUID=%s / ext4 errors=remount-ro,noatime 0 1\nUUID=%s /boot/efi vfat umask=0077 0 2\n' "$UUID_ROOT" "$UUID_EFI" >"$ROOT/etc/fstab"
install -d "$ROOT/etc/systemd/network"
printf '[Match]\nName=en* eth*\n\n[Network]\nDHCP=yes\n' >"$ROOT/etc/systemd/network/20-wired.network"
printf 'Deskmate OS \\n \\l\n\nLog in as yourself for Deskmate. Root gets a terminal only.\n\n' >"$ROOT/etc/issue"
echo 'kernel.dmesg_restrict=1' >"$ROOT/etc/sysctl.d/50-deskmate.conf"
passwd_lock() { in_root passwd -l root >/dev/null; }; passwd_lock
rm -f "$ROOT"/etc/ssh/ssh_host_*
in_root systemctl enable systemd-networkd systemd-resolved systemd-timesyncd ssh nftables deskmate-firstboot unattended-upgrades >/dev/null 2>&1
in_root systemctl enable clamav-freshclam >/dev/null 2>&1 || true
if [ -x "$ROOT/usr/bin/tuigreet" ] && [ -x "$ROOT/usr/sbin/greetd" ]; then
  in_root systemctl enable greetd >/dev/null 2>&1
  in_root systemctl disable getty@tty1 >/dev/null 2>&1 || true
  echo "login: greetd + tuigreet"
else
  rm -rf "$ROOT/etc/greetd"
  echo "login: console (the desktop starts after logging in on the first screen)"
fi
if [ -d "$ROOT/etc/greetd" ]; then in_root systemctl set-default graphical.target >/dev/null 2>&1; else in_root systemctl set-default multi-user.target >/dev/null 2>&1; fi
in_root systemctl enable deskmate-debug >/dev/null 2>&1

# A few web apps in the launcher for every new user, Omarchy style.
install -d "$ROOT/etc/skel/.local/share/applications"
for app in "Grok|https://grok.com" "Claude|https://claude.ai" "ChatGPT|https://chatgpt.com" "GitHub|https://github.com"; do
  n=${app%%|*}; u=${app##*|}; s=$(echo "$n" | tr '[:upper:]' '[:lower:]')
  printf '[Desktop Entry]\nType=Application\nName=%s\nComment=Web app\nExec=chromium --app=%s --class=webapp-%s\nIcon=applications-internet\nCategories=Network;\n' "$n" "$u" "$s" >"$ROOT/etc/skel/.local/share/applications/webapp-$s.desktop"
done

# Boot: UEFI, at the removable path so a new VM starts it with no setup.
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet video=Virtual-1:1920x1080 video=hyperv_fb:1920x1080"/; s/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' "$ROOT/etc/default/grub"
echo 'GRUB_DISABLE_OS_PROBER=true' >>"$ROOT/etc/default/grub"
in_root grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --removable --no-nvram --uefi-secure-boot >/dev/null 2>&1 \
  || in_root grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable --no-nvram
in_root update-initramfs -u -k all >/dev/null
in_root update-grub >/dev/null 2>&1
sed -i "s#root=/dev/loop[0-9]*p2#root=UUID=$UUID_ROOT#g" "$ROOT/boot/grub/grub.cfg"
# The signed GRUB reads its first config from EFI/debian; keep a copy there too.
if [ -f "$ROOT/boot/efi/EFI/BOOT/grub.cfg" ]; then install -d "$ROOT/boot/efi/EFI/debian"; cp "$ROOT/boot/efi/EFI/BOOT/grub.cfg" "$ROOT/boot/efi/EFI/debian/grub.cfg"; fi
ls -R "$ROOT/boot/efi/EFI" | head -20
grep -q "root=UUID=$UUID_ROOT" "$ROOT/boot/grub/grub.cfg" || { echo "grub.cfg has no root UUID"; exit 1; }

# Tidy up and report.
echo "--- scanner sizes: $(du -sh "$ROOT"/opt/deskmate-security/pipx/venvs/* 2>/dev/null | tr '\n\t' '; ')"
echo "--- ai tool sizes: $(du -sh "$ROOT"/usr/local/lib/node_modules/@*/* "$ROOT"/usr/lib/node_modules/@*/* 2>/dev/null | tr '\n\t' '; ')"
find "$ROOT/opt/deskmate-security" "$ROOT/usr/lib/python3" -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null || true
rm -rf "$ROOT"/usr/share/doc/* "$ROOT"/usr/share/man/* "$ROOT"/usr/share/info/* "$ROOT"/root/.npm "$ROOT"/root/.local
find "$ROOT/usr/share/locale" -mindepth 1 -maxdepth 1 ! -name 'en*' ! -name locale.alias -exec rm -rf {} + 2>/dev/null || true
in_root apt-get clean; rm -rf "$ROOT"/var/lib/apt/lists/* "$ROOT"/var/cache/apt/*.bin "$ROOT"/root/.cache "$ROOT"/tmp/*
rm -f "$ROOT/etc/resolv.conf" "$ROOT/etc/resolv.conf.build"; ln -sf /run/systemd/resolve/stub-resolv.conf "$ROOT/etc/resolv.conf"
: >"$ROOT/etc/machine-id"
echo "--- installed size: $(du -sh --exclude=proc --exclude=sys --exclude=dev "$ROOT" 2>/dev/null | cut -f1)"
in_root sh -c 'for t in labwc foot waybar fuzzel grim wtype wlrctl chromium bwrap clamscan shellcheck debsecan skillspector skill-scanner osv-scanner bandit gitleaks tuigreet btop; do command -v $t >/dev/null && echo "have: $t" || echo "MISSING: $t"; done'
sync; fstrim "$ROOT" 2>/dev/null || true
unmount_all
losetup -d "$LOOP"; trap - EXIT
qemu-img convert -f raw -O vhdx -o subformat=dynamic "$IMG" "$OUT/DeskmateOS.vhdx"
ls -lh "$OUT"
