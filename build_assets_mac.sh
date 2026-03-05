#!/bin/bash

# 1. Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo cp /Applications/Tailscale.app/Contents/MacOS/Tailscale /usr/local/bin/tailscale

# 2. Setup User
USER="Mac_Auditor"
PASS="kali"
sudo sysadminctl -addUser $USER -fullName "Mac Auditor" -password $PASS -admin

# 3. Enable VNC (Screen Sharing)
# This command tells macOS to allow VNC connections with a password
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart \
-activate -configure -access -on \
-clientopts -setvncpw -vncpw $PASS \
-restart -agent -privs -all

# 4. Connect Tailscale
sudo tailscale up --authkey=$TS_KEY --hostname="mac-visual-$(jot -r 1 1 500)"

echo "--------------------------------"
echo "MAC_VNC_READY"
echo "IP: Use your Tailscale IP"
echo "PORT: 5900"
echo "PASS: $PASS"
echo "--------------------------------"

# 5. Keep Alive
while true; do sleep 60; done

