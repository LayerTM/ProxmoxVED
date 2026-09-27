#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: LayerTM
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/lampac-nextgen/lampac

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Lampac NextGen Dependencies"
$STD apt install -y \
  chromium \
  fontconfig \
  gstreamer1.0-libav \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-base-apps \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-tools \
  libgstreamer-plugins-base1.0-0 \
  libgstreamer1.0-0 \
  libjpeg-dev \
  libnspr4 \
  libpng-dev \
  libwebp-dev \
  ocl-icd-libopencl1 \
  xvfb
msg_ok "Installed Lampac NextGen Dependencies"

setup_ffmpeg
setup_imagemagick
DOTNET_VERSION="10" DOTNET_TYPE="aspnetcore" setup_dotnet

fetch_and_deploy_gh_release "lampac" "lampac-nextgen/lampac" "prebuild" "latest" "/opt/lampac" "lampac-nextgen.zip"

msg_info "Configuring Lampac NextGen"
if [[ ! -f /opt/lampac/init.conf ]]; then
  cp /opt/lampac/example.init.conf /opt/lampac/init.conf
  jq '.chromium.Args = ["--no-sandbox"]' /opt/lampac/init.conf >/opt/lampac/init.conf.tmp
  mv /opt/lampac/init.conf.tmp /opt/lampac/init.conf
fi
if [[ ! -f /opt/lampac/passwd ]]; then
  openssl rand -hex 24 >/opt/lampac/passwd
fi
chmod 600 /opt/lampac/passwd
msg_ok "Configured Lampac NextGen"

msg_info "Creating Lampac NextGen Service"
cat <<'UNIT_EOF' >/etc/systemd/system/lampac.service
[Unit]
Description=Lampac NextGen
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lampac
Environment=HOME=/opt/lampac
Environment=DOTNET_ROOT=/usr/share/dotnet
Environment=DOTNET_RUNNING_IN_CONTAINER=false
Environment=DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
Environment=DOTNET_CLI_TELEMETRY_OPTOUT=1
ExecStart=/usr/bin/dotnet /opt/lampac/Core.dll
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT_EOF
systemctl enable -q --now lampac
msg_ok "Created Lampac NextGen Service"
msg_info "Checking Lampac NextGen"
for attempt in {1..30}; do
  if systemctl is-active --quiet lampac && curl -fsS --max-time 3 'http://127.0.0.1:9118/version?type=hash' 2>/dev/null | grep -Eq '^[[:xdigit:]]{32}$'; then
    msg_ok "Lampac NextGen is responding"
    break
  fi
  if ((attempt == 30)); then
    msg_error "Lampac NextGen did not respond at http://127.0.0.1:9118/version?type=hash"
    exit 1
  fi
  sleep 2
done

motd_ssh
customize
cleanup_lxc
