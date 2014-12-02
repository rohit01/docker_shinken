#!/usr/bin/env bash
#
# Program to initialize the shinken docker container with default configuration
# and keep running in foreground for supervisord
# Author: Rohit Gupta - @rohit01
#

CUSTOM_CONFIGS_DIR="/etc/shinken/custom_configs"


default_htpasswd_content() {
    cat << EOF
## Apache/Nginx htpasswd file for Basic Authentication ##
#
# The passwords can be managed in this file using the apache utililty: htpasswd
# Installation:
#     sudo apt-get install apache2-utils
# Use: 
#     htpasswd -c htpasswd.users <username>
# Default:
#    Username: admin
#    Password: admin
#
admin:$apr1$j/CRE/fJ$5p4u5PnvwQehBuulY8x0n1

EOF
}

initialize_configs() {
    mkdir -p /var/log/supervisord /var/log/nginx "${CUSTOM_CONFIGS_DIR}"

    ls_count="$(ls ${CUSTOM_CONFIGS_DIR} | wc -l)"
    if [ ${ls_count} -eq 0 ]; then
        echo "Blank custom_configs directory. Creating default files"
        cd "${CUSTOM_CONFIGS_DIR}"
        for dir_name in commands timeperiods escalations templates notificationways servicegroups hostgroups contactgroups contacts hosts services contacts realms resources
        do
            mkdir -p "${dir_name}"
            echo "Logical directory to keep Shinken ${dir_name} .cfg files here" > "${dir_name}/README.md"
            echo "=====" >> "${dir_name}/README.md"
        done
        cd -
    fi

    if [ ! -r "${CUSTOM_CONFIGS_DIR}/htpasswd.users" ]; then
        echo "No htpasswd.users file found. Creating default htpasswd file"
        default_htpasswd_content > "${CUSTOM_CONFIGS_DIR}/htpasswd.users"
    fi
}


initialize_configs
sleep 10

while true; do
    initialize_configs
    sleep 3600
done
