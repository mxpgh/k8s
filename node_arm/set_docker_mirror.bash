#!/usr/bin/env bash
set -e
MIRROR_URL="http://a58c8480.m.daocloud.io"

set_daemon_json_file(){
    DOCKER_DAEMON_JSON_FILE="/etc/docker/daemon.json"
    if sudo test -f ${DOCKER_DAEMON_JSON_FILE}
    then
        sudo cp  ${DOCKER_DAEMON_JSON_FILE} "${DOCKER_DAEMON_JSON_FILE}.bak"
        if sudo grep -q registry-mirrors "${DOCKER_DAEMON_JSON_FILE}.bak";then
            sudo cat "${DOCKER_DAEMON_JSON_FILE}.bak" | sed -n "1h;1"'!'"H;\${g;s|\"registry-mirrors\":\s*\[[^]]*\]|\"registry-mirrors\": [\"${MIRROR_URL}\"]|g;p;}" | sudo tee ${DOCKER_DAEMON_JSON_FILE}
        else
            sudo cat "${DOCKER_DAEMON_JSON_FILE}.bak" | sed -n "s|{|{\"registry-mirrors\": [\"${MIRROR_URL}\"],|g;p;" | sudo tee ${DOCKER_DAEMON_JSON_FILE}
        fi
    else
        sudo mkdir -p "/etc/docker"
        sudo echo "{\"registry-mirrors\": [\"${MIRROR_URL}\"]}" | sudo tee ${DOCKER_DAEMON_JSON_FILE}
    fi
}

set_daemon_json_file
sudo systemctl restart docker
