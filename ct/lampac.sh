#!/usr/bin/env bash
_cs_boot="${COMMUNITY_SCRIPTS_CORE_DIR:-$(dirname "${BASH_SOURCE[0]}")/../../core}/core/build.func"
source "$_cs_boot" 2>/dev/null || source <(curl -fsSL "${COMMUNITY_SCRIPTS_CORE_URL:-https://raw.githubusercontent.com/community-scripts/core/main}/core/build.func")
# Copyright (c) 2021-2026 community-scripts ORG
# Author: LayerTM
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/lampac-nextgen/lampac

APP="Lampac"
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
      /opt/lampac/.claude \
      /opt/lampac/.config \
      /opt/lampac/.playwright \
      /opt/lampac/users.json \
      /opt/lampac/passwd \
      /opt/lampac/current.conf \
      /opt/lampac/database \
      /opt/lampac/plugins/override \
      /opt/lampac/module/NextHUB/override \
      /opt/lampac/module/Catalog/override \
      /opt/lampac/module/AdminPanel/manifest.json \
      /opt/lampac/notifications_date.txt \
      /opt/lampac/excludes.conf \
      /opt/lampac/install.sh \
      /opt/lampac/version.txt

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "lampac" "lampac-nextgen/lampac" "prebuild" "latest" "/opt/lampac" "lampac-nextgen.zip"

    restore_backup

    if [[ ! -f /opt/lampac/init.conf && ! -f /opt/lampac/init.yaml ]]; then
      cp /opt/lampac/example.init.conf /opt/lampac/init.conf
      jq '.chromium.Args = ["--no-sandbox"] | .BaseModule.SkipModules |= map(select(. != "JacRed" and . != "Sync" and . != "TimeCode" and . != "TorrServer")) | .LampaWeb.initPlugins.torrserver = true | .LampaWeb.initPlugins.jacred = true | .LampaWeb.initPlugins.sync = true | .LampaWeb.initPlugins.bookmark = false | .LampaWeb.initPlugins.timecode = false' /opt/lampac/init.conf >/opt/lampac/init.conf.tmp
      mv /opt/lampac/init.conf.tmp /opt/lampac/init.conf
    fi
    [[ -f /opt/lampac/passwd ]] && chmod 600 /opt/lampac/passwd

    msg_info "Starting Lampac NextGen"
    systemctl start lampac
    msg_ok "Started Lampac NextGen"
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
