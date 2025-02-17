# DenOS - Debian Linux build from scratch with Debootstrap#
# Bernardino Lopez [ bernardino.lopez@gmail.com ]
# 11.27.18

# 03_denos_chroot.sh - Customize your Distro
# As root in chroot. Execute the script in a Terminal 
# ./03_denos_chroot_lxde.sh

# export LIVE_BOOT=LIVE_BOOT64
source ./denos_config.txt

# Set Hostname
echo $DISTRO_HOSTNAME > /etc/hostname 

apt-cache search linux-image

apt-get update && \
apt-get install -y --no-install-recommends \
    linux-image-6.1.0-29-amd64 \
    live-boot \
    systemd-sysv \
    plymouth \
    plymouth-themes \
    figlet neofetch

apt-get install -y --no-install-recommends \
    network-manager net-tools wireless-tools wpagui \
    curl openssh-server openssh-client \
    blackbox xserver-xorg-core xserver-xorg xinit xterm \
    screenfetch screen vim iputils-ping \
    psmisc htop nmap firefox-esr wget git ca-certificates \
    nano fdisk kde-full sddm sddm-theme-debian-breeze \
    calamares calamares-settings-debian && \
apt-get clean

echo -e "127.0.0.1\tlocalhost" > /etc/hosts
echo -e "127.0.0.1\t$DISTRO_HOSTNAME" >> /etc/hosts

# Create live user for the installer
useradd -m live -s /bin/bash
echo 'live:live' | chpasswd

# Don't set root password for live system
# passwd root  # commenting this out for live system

# Set up Plymouth boot splash
mkdir -p /usr/share/plymouth/themes/custom-splash
wget -O /usr/share/plymouth/themes/custom-splash/boot-logo.png https://raw.githubusercontent.com/Parkourer10/extras/main/output.png

cat > /usr/share/plymouth/themes/custom-splash/custom-splash.plymouth << EOF
[Plymouth Theme]
Name=Custom Splash
Description=Custom boot splash theme
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/custom-splash
ScriptFile=/usr/share/plymouth/themes/custom-splash/custom-splash.script
EOF

cat > /usr/share/plymouth/themes/custom-splash/custom-splash.script << EOF
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);
logo.image = Image("boot-logo.png");
logo.sprite = Sprite(logo.image);
logo.sprite.SetPosition(Window.GetWidth() / 2 - logo.image.GetWidth() / 2, Window.GetHeight() / 2 - logo.image.GetHeight() / 2, 10000);
EOF

plymouth-set-default-theme custom-splash
update-initramfs -u

# Set up custom neofetch configuration
mkdir -p /etc/skel/.config/neofetch
cat > /etc/skel/.config/neofetch/config.conf << 'EOF'
print_info() {
    info title
    info "OS" distro
    info "Host" model
    info "Kernel" kernel
    info "Uptime" uptime
    info "Packages" packages
    info "Shell" shell
    info "Resolution" resolution
    info "DE" de
    info "WM" wm
    info "Memory" memory
    info "CPU" cpu
    info "GPU" gpu
}

# Set custom logo using FIGLET
ascii_distro="auto"
ascii_colors=(4 6 1 8 8 6)
ascii_bold="on"
image_source="$(figlet FonderOS)"

# Override OS name
distro="FonderOS 0.0.2"
EOF

# Also set it for root user and live user
mkdir -p /root/.config/neofetch
cp /etc/skel/.config/neofetch/config.conf /root/.config/neofetch/
mkdir -p /home/live/.config/neofetch
cp /etc/skel/.config/neofetch/config.conf /home/live/.config/neofetch/
chown -R live:live /home/live/.config

# Create a custom ASCII art file for the logo
figlet "FonderOS" > /etc/neofetch-logo

# Configure automatic installer launch for live session
mkdir -p /etc/skel/.config/autostart
cat > /etc/skel/.config/autostart/calamares.desktop << EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Install FonderOS
GenericName=System Installer
Keywords=calamares;system;installer;
TryExec=calamares
Exec=pkexec calamares
Comment=Install FonderOS on your system
Icon=calamares
Terminal=false
StartupNotify=true
Categories=Qt;System;
EOF

# Configure SDDM for automatic login in live session
cat > /etc/sddm.conf << EOF
[Theme]
Current=debian-breeze

[Users]
RememberLastUser=true
RememberLastSession=true

[General]
InputMethod=
Numlock=on

[Autologin]
Relogin=false
Session=plasma
User=live
EOF

# Create a live-session specific script
cat > /usr/local/bin/live-session-setup << EOF
#!/bin/bash
if [ ! -f /etc/live-session-setup-done ]; then
    # Start Calamares installer
    pkexec calamares &
    touch /etc/live-session-setup-done
fi
EOF

chmod +x /usr/local/bin/live-session-setup

# Add the script to autostart
cat > /etc/skel/.config/autostart/live-setup.desktop << EOF
[Desktop Entry]
Type=Application
Name=Live Session Setup
Exec=/usr/local/bin/live-session-setup
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

# Configure Calamares installer with custom branding
mkdir -p /etc/calamares/modules
mkdir -p /etc/calamares/branding/fonderos

# Create branding configuration
cat > /etc/calamares/branding/fonderos/branding.desc << EOF
---
componentName: fonderos
welcomeStyleCalamares: true
welcomeExpandingLogo: true
windowExpanding: normal

strings:
    productName:         FonderOS
    shortProductName:    FonderOS
    version:            0.0.2
    shortVersion:       0.0.2
    versionedName:      FonderOS 0.0.2
    shortVersionedName: FonderOS 0.0.2
    bootloaderEntryName: FonderOS
    productUrl:         https://github.com/Parkourer10
    supportUrl:         https://github.com/Parkourer10
    releaseNotesUrl:    https://github.com/Parkourer10

images:
    productLogo:         "logo.png"
    productIcon:         "logo.png"
    productWelcome:      "welcome.png"

slideshow: "show.qml"

style:
   sidebarBackground:    "#231F20"
   sidebarText:          "#FFFFFF"
   sidebarTextSelect:    "#0068C8"
EOF

# Download and set your logo for the installer
wget -O /etc/calamares/branding/fonderos/logo.png https://raw.githubusercontent.com/Parkourer10/extras/main/output.png
cp /etc/calamares/branding/fonderos/logo.png /etc/calamares/branding/fonderos/welcome.png

# Create a simple slideshow
cat > /etc/calamares/branding/fonderos/show.qml << EOF
import QtQuick 2.0;
import calamares.slideshow 1.0;

Presentation
{
    id: presentation

    Timer {
        interval: 20000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }
    
    Slide {
        Image {
            id: background
            source: "logo.png"
            width: 200
            height: 200
            fillMode: Image.PreserveAspectFit
            anchors.centerIn: parent
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: background.bottom
            text: "Welcome to FonderOS<br/>"+
                  "A modern, user-friendly Linux distribution"
            wrapMode: Text.WordWrap
            width: parent.width
            horizontalAlignment: Text.Center
        }
    }
}
EOF

# Update Calamares settings to use our branding
cat > /etc/calamares/settings.conf << EOF
modules-search: [ local ]

sequence:
- show:
  - welcome
  - locale
  - keyboard
  - partition
  - users
  - summary
- exec:
  - partition
  - mount
  - unpackfs
  - networkcfg
  - users
  - displaymanager
  - grubcfg
  - bootloader
  - packages
  - umount

branding: fonderos
prompt-install: true

dont-chroot: false

oem-setup: false

disable-cancel: false

disable-cancel-during-exec: false
EOF

# Create desktop shortcut for installer
mkdir -p /etc/skel/Desktop /home/live/Desktop
cat > /etc/skel/Desktop/install-fonder.desktop << EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=Install FonderOS
GenericName=System Installer
Keywords=calamares;system;installer;
TryExec=calamares
Exec=pkexec calamares
Comment=Install FonderOS on your system
Icon=calamares
Terminal=false
StartupNotify=true
Categories=Qt;System;
EOF

chmod +x /etc/skel/Desktop/install-fonder.desktop
cp /etc/skel/Desktop/install-fonder.desktop /home/live/Desktop/
chown -R live:live /home/live/Desktop

# Set up autostart for Calamares
mkdir -p /home/live/.config/autostart
cat > /home/live/.config/autostart/calamares.desktop << EOF
[Desktop Entry]
Type=Application
Name=Install FonderOS
Exec=pkexec calamares
Hidden=false
X-GNOME-Autostart-enabled=true
EOF

chmod +x /home/live/.config/autostart/calamares.desktop
chown -R live:live /home/live/.config

exit
