#!/bin/bash
docker exec -d h1 python -m SimpleHTTPServer 8080
docker exec -d h2 python -m SimpleHTTPServer 9090
docker exec R1 iptables -t nat -A PREROUTING --protocol tcp --destination 140.113.2.1 --dport 8080 -j DNAT --to 192.168.1.2:8080
docker exec R1 iptables -t nat -A PREROUTING --protocol tcp --destination 140.113.2.1 --dport 9090 -j DNAT --to 192.168.2.2:9090