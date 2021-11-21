#!/usr/bin/env bash

echo "::group::Setup Rclone"
curl https://rclone.org/install.sh | sudo bash
mkdir -p ~/.config/rclone
echo "$RCLONE" > ~/.config/rclone/rclone.conf
echo "::endgroup::"
