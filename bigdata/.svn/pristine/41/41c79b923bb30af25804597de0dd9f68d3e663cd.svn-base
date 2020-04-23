#!/bin/bash
echo "pssh : '$@'"

HOST_DIR=/home/hadoop/dev/parm

if [ "$USER" == "root" ];then
    mkdir -p /var/log/pssh/pssh
    chmod -R 777 /var/log/pssh
fi
pssh -e /var/log/pssh/pssh -t 0 -h ${HOST_DIR}/host_all.list -i $@
