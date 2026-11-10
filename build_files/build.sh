#!/bin/bash
set -ouex pipefail

# Copy CN-PLAY files into the image
cp -a /ctx/cn-play/system_files/. /
chmod +x /usr/bin/cn-play-session

# Branding
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="CN-PLAY OS (Bazzite-based)"/' /usr/lib/os-release

# First boot installer for Pegasus
systemctl enable cn-play-firstboot.service
