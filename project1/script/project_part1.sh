#!/bin/bash

# setup container
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name h1 project1
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name h2 project1
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name BRG1 project1
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name BRG2 project1
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name BRGr project1
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name R1 project1
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name R2 project1

# create veth pairs
ip link add h1BRG1 type veth peer name BRG1h1
ip link add h2BRG2 type veth peer name BRG2h2
ip link add BRG1br0 type veth peer name br0BRG1
ip link add BRG2br0 type veth peer name br0BRG2
ip link add R1br0 type veth peer name br0R1
ip link add R1R2 type veth peer name R2R1
ip link add R2BRGr type veth peer name BRGrR2
ip link add BRGrGWr type veth peer name GWrBRGr

# set veth pairs
ip link set h1BRG1 netns $(docker inspect --format='{{.State.Pid}}' h1)
ip link set BRG1h1 netns $(docker inspect --format='{{.State.Pid}}' BRG1)
ip link set h2BRG2 netns $(docker inspect --format='{{.State.Pid}}' h2)
ip link set BRG2h2 netns $(docker inspect --format='{{.State.Pid}}' BRG2)
ip link set BRG1br0 netns $(docker inspect --format='{{.State.Pid}}' BRG1)
ip link set BRG2br0 netns $(docker inspect --format='{{.State.Pid}}' BRG2)
ip link set R1R2 netns $(docker inspect --format='{{.State.Pid}}' R1)
ip link set R2R1 netns $(docker inspect --format='{{.State.Pid}}' R2)
ip link set R1br0 netns $(docker inspect --format='{{.State.Pid}}' R1)
ip link set R2BRGr netns $(docker inspect --format='{{.State.Pid}}' R2)
ip link set BRGrR2 netns $(docker inspect --format='{{.State.Pid}}' BRGr)
ip link set BRGrGWr netns $(docker inspect --format='{{.State.Pid}}' BRGr)

# create bridge
ip link add br0 type bridge
ip link set br0BRG1 master br0
ip link set br0BRG2 master br0
ip link set br0R1 master br0
ip link set br0 up

# configue ip address
docker exec R1 ip addr add 172.27.0.1/24 dev R1br0
docker exec R1 ip addr add 140.114.0.1/24 dev R1R2
docker exec R2 ip addr add 140.114.0.2/24 dev R2R1
docker exec R2 ip addr add 140.113.0.1/24 dev R2BRGr
docker exec BRGr ip addr add 140.113.0.2/24 dev BRGrR2
docker exec BRGr ip addr add 20.0.1.2/24 dev BRGrGWr
ip addr add 20.0.1.1/24 dev GWrBRGr

# turn up veth
docker exec h1 ip link set h1BRG1 up
docker exec h2 ip link set h2BRG2 up
docker exec BRG1 ip link set BRG1h1 up
docker exec BRG1 ip link set BRG1br0 up
docker exec BRG2 ip link set BRG2h2 up
docker exec BRG2 ip link set BRG2br0 up
ip link set br0BRG1 up
ip link set br0BRG2 up
ip link set br0R1 up
docker exec R1 ip link set R1br0 up
docker exec R1 ip link set R1R2 up
docker exec R2 ip link set R2R1 up
docker exec R2 ip link set R2BRGr up
docker exec BRGr ip link set BRGrR2 up
docker exec BRGr ip link set BRGrGWr up
ip link set GWrBRGr up

# enable ip forwaring in routers
docker exec R1 sysctl net.ipv4.ip_forward=1
docker exec R1 sysctl -p
docker exec R2 sysctl net.ipv4.ip_forward=1
docker exec R2 sysctl -p
docker exec BRG1 sysctl net.ipv4.ip_forward=1
docker exec BRG1 sysctl -p
docker exec BRG2 sysctl net.ipv4.ip_forward=1
docker exec BRG2 sysctl -p
docker exec BRGr sysctl net.ipv4.ip_forward=1
docker exec BRGr sysctl -p
sysctl net.ipv4.ip_forward=1
sysctl -p

# configue static routing rules
docker exec R1 ip route add 140.113.0.0/24 via 140.114.0.2
docker exec BRGr ip route add 140.114.0.0/24 via 140.113.0.1
ip route add 140.114.0.0/24 via 20.0.1.2 dev GWrBRGr
ip route add 140.113.0.0/24 via 20.0.1.2 dev GWrBRGr

# IPTABLES rules
docker exec R1 iptables -t nat -A POSTROUTING -o R1R2 --source 172.27.0.0/24 -j SNAT --to 140.114.0.1
iptables -t nat -A POSTROUTING -o ens33 --source 20.0.1.0/24 -j MASQUERADE
iptables -A FORWARD -i br0 -o br0 -j ACCEPT # to prevent iptable drop br0 packets
iptables -A FORWARD -i GWrBRGr -o ens33 -j ACCEPT # since default rule of FORWARD is all DROP
iptables -A FORWARD -i ens33 -o GWrBRGr -j ACCEPT 

# DHCP for BRG1, BRG2
docker cp /var/lib/dhcp/dhcpd.leases R1:/var/lib/dhcp/dhcpd.leases
docker cp dhcpd_R1.conf R1:/dhcpd.conf
docker exec R1 /usr/sbin/dhcpd -4 -pf /run/dhcp-server-dhcpd.pid -cf /dhcpd.conf R1br0
docker exec BRG1 dhclient BRG1br0
docker exec BRG2 dhclient BRG2br0
/usr/sbin/dhcpd -4 -pf /run/dhcp-server-dhcpd.pid -cf ./dhcpd.conf GWrBRGr

# send dynamic tunnel creation program to BRGr
docker cp 0716234.cpp BRGr:/
docker exec BRGr g++ 0716234.cpp -std=c++11 -o 0716234 -lpcap

# gretap
modprobe fou
docker exec BRG1 ip link add GRETAP type gretap remote 140.113.0.2 local `docker exec BRG1 ifconfig BRG1br0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'` key 1 encap fou encap-sport 22222 encap-dport 44444
docker exec BRG1 ip link set GRETAP up
docker exec BRG1 ip link add br0 type bridge
docker exec BRG1 ip link set BRG1h1 master br0
docker exec BRG1 ip link set GRETAP master br0
docker exec BRG1 ip link set br0 up
docker exec BRG1 ip fou add port 22222 ipproto 47

docker exec BRG2 ip link add GRETAP type gretap remote 140.113.0.2 local `docker exec BRG2 ifconfig BRG2br0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'` key 2 encap fou encap-sport 33333 encap-dport 55555
docker exec BRG2 ip link set GRETAP up
docker exec BRG2 ip link add br0 type bridge
docker exec BRG2 ip link set BRG2h2 master br0
docker exec BRG2 ip link set GRETAP master br0
docker exec BRG2 ip link set br0 up
docker exec BRG2 ip fou add port 33333 ipproto 47