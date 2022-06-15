#!/bin/sh

while :
do
        Out=`sh wifistatus.sh`
        echo "[Sending packet...]"
        echo -n -e "\x04\x02\x00\x34\x00\x00\x00\x00$Out" | nc 192.168.2.254 6653
        echo "[Done]"
        sleep 20
done