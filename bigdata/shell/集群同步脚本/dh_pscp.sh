#!/bin/bash

echo "pscp : '$1' '$2'"

HOST_DIR=/home/hadoop/dev/parm

if [ "$USER" == "root" ];then
    mkdir -p /var/log/pssh/pscp
    chmod -R 777 /var/log/pssh
fi
pscp -x "-C -p" -r -e /var/log/pssh/pscp -p 8 -h ${HOST_DIR}/hosts_all.list $1 $2
