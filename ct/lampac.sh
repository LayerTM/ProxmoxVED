#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: LayerTM
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/lampac-nextgen/lampac

APP="Lampac NextGen"
var_tags="${var_tags:-media;streaming;lampa}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_arm64="${var_arm64:-yes}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/lampac/Core.dll ]]; then
    msg_error "No Lampac NextGen Installation Found!"
    exit
  fi

  if check_for_gh_release "lampac" "lampac-nextgen/lampac"; then
    msg_info "Stopping Lampac NextGen"
    systemctl stop lampac
    msg_ok "Stopped Lampac NextGen"

    create_backup \
      /opt/lampac/init.conf \
      /opt/lampac/init.yaml \
      /opt/lampac/mods \
      /opt/lampac/data/kinoukr.json \
      /opt/lampac/data/PizdatoeDb.json \
      /opt/lampac/*.db \
      /opt/lampac/*.db-shm \
      /opt/lampac/*.db-wal \
      /opt/lampac/logs \
      /opt/lampac/cache \
      /opt/lampac/TorrServer \
      /opt/lampac/torrserver \
      /opt/lampac/data/ts \
      /opt/lampac/.local \
      /opt/lampac/.aspnet \
      /opt/lampac/.config \
      /opt/lampac/.playwright \
      /opt/lampac/users.json \
      /opt/lampac/passwd \
      /opt/lampac/current.conf \
      /opt/lampac/database \
      /opt/lampac/wwwroot \
      /opt/lampac/plugins/override \
      /opt/lampac/module/NextHUB/override \
      /opt/lampac/module/Catalog/override \
      /opt/lampac/notifications_date.txt \
      /opt/lampac/excludes.conf

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "lampac" "lampac-nextgen/lampac" "prebuild" "latest" "/opt/lampac" "lampac-nextgen.zip"

    restore_backup

    if [[ ! -f /opt/lampac/init.conf && -f /opt/lampac/config/example.init.conf ]]; then
      cp /opt/lampac/config/example.init.conf /opt/lampac/init.conf
    fi
    [[ -f /opt/lampac/passwd ]] && chmod 600 /opt/lampac/passwd

    msg_info "Starting Lampac NextGen"
    systemctl start lampac
    msg_ok "Started Lampac NextGen"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW}Access it using the following URL:${CL}"
echo -e "${GATEWAY}${BGN}http://${IP}:9118${CL}"
echo -e "${INFO}${YW}Lampa plugin:${CL} ${BGN}http://${IP}:9118/online.js${CL}"
