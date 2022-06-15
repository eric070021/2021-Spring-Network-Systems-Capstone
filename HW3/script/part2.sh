#!/bin/bash
docker exec R1 iptables -t nat -A POSTROUTING --source 192.168.1.0/24 -j SNAT --to 140.113.2.30
docker exec R1 iptables -t nat -A POSTROUTING --source 192.168.2.0/24 -j SNAT --to 140.113.2.40