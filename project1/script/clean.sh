#!/bin/bash

docker stop h1 h2 R1 R2 BRG1 BRG2 BRGr
docker rm h1 h2 R1 R2 BRG1 BRG2 BRGr
ip link delete br0
sysctl net.ipv4.ip_forward=0
sysctl -p
iptables -t nat -D POSTROUTING -o ens33 --source 20.0.1.0/24 -j MASQUERADE
iptables -D FORWARD -i br0 -o br0 -j ACCEPT 
iptables -D FORWARD -i GWrBRGr -o ens33 -j ACCEPT
iptables -D FORWARD -i ens33 -o GWrBRGr -j ACCEPT
kill -9 `ps aux | grep GWrBRGr | grep dhcpd | awk '{print $2}'`