#!/usr/bin/env bash
#
# Watch shinken configuiration and restart shinken-arbiter if any modifications
# happen.
#

while true
do
    inotifywait -r -e modify,attrib,close_write,move,create,delete /etc/shinken/custom_configs/
    supervisorctl restart shinken-arbiter
    sleep 2
done
