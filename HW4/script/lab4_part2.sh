#!/bin/bash

# setup container
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name h1 lab4
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name h2 lab4
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name GWr lab4
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name BRG1 lab4
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name BRG2 lab4
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name BRGr lab4
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name R1 lab4
docker run --privileged --cap-add NET_ADMIN --cap-add NET_BROADCAST --net=none -d -it --name R2 lab4

# create veth pairs
ip link add h1-eth0 type veth peer name BRG1-eth0
ip link add h2-eth0 type veth peer name BRG2-eth0
ip link add GWr-eth0 type veth peer name BRGr-eth0
ip link add BRG1-eth1 type veth peer name R1-eth0
ip link add BRG2-eth1 type veth peer name R1-eth1
ip link add BRGr-eth1 type veth peer name R2-eth0
ip link add R1-eth2 type veth peer name R2-eth1

# set veth pairs
ip link set h1-eth0 netns $(docker inspect --format='{{.State.Pid}}' h1)
ip link set BRG1-eth0 netns $(docker inspect --format='{{.State.Pid}}' BRG1)
ip link set h2-eth0 netns $(docker inspect --format='{{.State.Pid}}' h2)
ip link set BRG2-eth0 netns $(docker inspect --format='{{.State.Pid}}' BRG2)
ip link set GWr-eth0 netns $(docker inspect --format='{{.State.Pid}}' GWr)
ip link set BRGr-eth0 netns $(docker inspect --format='{{.State.Pid}}' BRGr)
ip link set BRG1-eth1 netns $(docker inspect --format='{{.State.Pid}}' BRG1)
ip link set R1-eth0 netns $(docker inspect --format='{{.State.Pid}}' R1)
ip link set BRG2-eth1 netns $(docker inspect --format='{{.State.Pid}}' BRG2)
ip link set R1-eth1 netns $(docker inspect --format='{{.State.Pid}}' R1)
ip link set BRGr-eth1 netns $(docker inspect --format='{{.State.Pid}}' BRGr)
ip link set R2-eth0 netns $(docker inspect --format='{{.State.Pid}}' R2)
ip link set R1-eth2 netns $(docker inspect --format='{{.State.Pid}}' R1)
ip link set R2-eth1 netns $(docker inspect --format='{{.State.Pid}}' R2)

# configue ip address
docker exec h1 ip addr add 10.0.1.1/24 dev h1-eth0
docker exec h2 ip addr add 10.0.1.2/24 dev h2-eth0
docker exec GWr ip addr add 10.0.1.254/24 dev GWr-eth0
docker exec BRG1 ip addr add 140.114.0.1/16 dev BRG1-eth1
docker exec BRG2 ip addr add 140.115.0.1/16 dev BRG2-eth1
docker exec BRGr ip addr add 140.113.0.1/16 dev BRGr-eth1
docker exec R1 ip addr add 140.114.0.2/16 dev R1-eth0
docker exec R1 ip addr add 140.115.0.2/16 dev R1-eth1
docker exec R1 ip addr add 140.116.0.1/16 dev R1-eth2
docker exec R2 ip addr add 140.113.0.2/16 dev R2-eth0
docker exec R2 ip addr add 140.116.0.2/16 dev R2-eth1

# turn up veth
docker exec h1 ip link set h1-eth0 up
docker exec h2 ip link set h2-eth0 up
docker exec GWr ip link set GWr-eth0 up
docker exec BRG1 ip link set BRG1-eth0 up
docker exec BRG1 ip link set BRG1-eth1 up
docker exec BRG2 ip link set BRG2-eth0 up
docker exec BRG2 ip link set BRG2-eth1 up
docker exec BRGr ip link set BRGr-eth0 up
docker exec BRGr ip link set BRGr-eth1 up
docker exec R1 ip link set R1-eth0 up
docker exec R1 ip link set R1-eth1 up
docker exec R1 ip link set R1-eth2 up
docker exec R2 ip link set R2-eth0 up
docker exec R2 ip link set R2-eth1 up

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

# configue static routing rules
docker exec h1 ip route add default via 10.0.1.254
docker exec h2 ip route add default via 10.0.1.254

docker exec BRG1 ip route add 140.113.0.0/16 via 140.114.0.2
docker exec BRG2 ip route add 140.113.0.0/16 via 140.115.0.2
docker exec BRGr ip route add 140.114.0.0/16 via 140.113.0.2
docker exec BRGr ip route add 140.115.0.0/16 via 140.113.0.2

docker exec R1 ip route add 140.114.0.0/16 via 140.114.0.1
docker exec R1 ip route add 140.115.0.0/16 via 140.115.0.1
docker exec R1 ip route add 140.113.0.0/16 via 140.116.0.2
docker exec R2 ip route add 140.114.0.0/16 via 140.116.0.1
docker exec R2 ip route add 140.115.0.0/16 via 140.116.0.1
docker exec R2 ip route add 140.113.0.0/16 via 140.113.0.1

# gretap
docker exec BRG1 ip link add GRETAP type gretap remote 140.113.0.1 local 140.114.0.1
docker exec BRG1 ip link set GRETAP up
docker exec BRG1 ip link add br0 type bridge
docker exec BRG1 ip link set BRG1-eth0 master br0
docker exec BRG1 ip link set GRETAP master br0
docker exec BRG1 ip link set br0 up

docker exec BRG2 ip link add GRETAP type gretap remote 140.113.0.1 local 140.115.0.1
docker exec BRG2 ip link set GRETAP up
docker exec BRG2 ip link add br0 type bridge
docker exec BRG2 ip link set BRG2-eth0 master br0
docker exec BRG2 ip link set GRETAP master br0
docker exec BRG2 ip link set br0 up