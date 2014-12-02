#!/usr/bin/env bash
#
# Program to initialize the shinken docker container with default configuration
# and keep running in foreground for supervisord
# Author: Rohit Gupta - @rohit01
#

custom_configs_dir="/etc/shinken/custom_configs"

mkdir -p /var/log/supervisord /var/log/nginx "${custom_configs_dir}"

ls_count="$(ls ${custom_configs_dir} | wc -l)"
if [ ${ls_count} -eq 0 ]; then
    cd "${custom_configs_dir}"
    for dir_name in commands timeperiods escalations templates notificationways servicegroups hostgroups contactgroups contacts hosts services contacts realms resources
    do
        mkdir -p "${dir_name}"
        echo "Logical directory to keep Shinken ${dir_name} .cfg files here" > "${dir_name}/README.md"
        echo "=====" >> "${dir_name}/README.md"
    done
fi

if [ ! -r "${custom_configs_dir}/htpasswd.users" ]; then
    cat > "${custom_configs_dir}/htpasswd.users" << EOF
## Apache/Nginx htpasswd file for Basic Authentication ##
#
# The passwords can be managed in this file using the apache utililty: htpasswd
# Installation:
#     sudo apt-get install apache2-utils
# Use: 
#     htpasswd -c htpasswd.users <username>
#
admin:$apr1$j/CRE/fJ$5p4u5PnvwQehBuulY8x0n1

EOF
fi

## Sleep Forever
while true; do
    sleep 86400
done
