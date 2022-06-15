#!/bin/bash
sudo docker run --detach --interactive --privileged  \
--network none --cap-add NET_ADMIN --cap-add NET_BROADCAST \
--name R1 lab3

sudo docker run --detach --interactive --privileged  \
--network none --cap-add NET_ADMIN --cap-add NET_BROADCAST \
--name R2 lab3

sudo docker run --detach --interactive --privileged  \
--network none --cap-add NET_ADMIN --cap-add NET_BROADCAST \
--name h1 lab3


sudo docker run --detach --interactive --privileged  \
--network none --cap-add NET_ADMIN --cap-add NET_BROADCAST \
--name h2 lab3


sudo docker run --detach --interactive --privileged  \
--network none --cap-add NET_ADMIN --cap-add NET_BROADCAST \
--name hR lab3


ip link add R1R2veth type veth peer name R2R1veth
ip link add R1h1veth type veth peer name h1R1veth
ip link add R1h2veth type veth peer name h2R1veth
ip link add R2hRveth type veth peer name hRR2veth

ip link set R1R2veth netns $(docker inspect --format='{{.State.Pid}}' R1)
ip link set R1h1veth netns $(docker inspect --format='{{.State.Pid}}' R1)
ip link set R1h2veth netns $(docker inspect --format='{{.State.Pid}}' R1)
ip link set R2R1veth netns $(docker inspect --format='{{.State.Pid}}' R2)
ip link set R2hRveth netns $(docker inspect --format='{{.State.Pid}}' R2)
ip link set h1R1veth netns $(docker inspect --format='{{.State.Pid}}' h1)
ip link set h2R1veth netns $(docker inspect --format='{{.State.Pid}}' h2)
ip link set hRR2veth netns $(docker inspect --format='{{.State.Pid}}' hR)

docker exec R1 ip addr add 140.113.2.1/24 dev R1R2veth
docker exec R1 ip addr add 192.168.1.1/24 dev R1h1veth
docker exec R1 ip addr add 192.168.2.1/24 dev R1h2veth
docker exec R2 ip addr add 140.113.2.2/24 dev R2R1veth
docker exec R2 ip addr add 140.113.1.1/24 dev R2hRveth
docker exec h1 ip addr add 192.168.1.2/24 dev h1R1veth
docker exec h2 ip addr add 192.168.2.2/24 dev h2R1veth
docker exec hR ip addr add 140.113.1.2/24 dev hRR2veth

docker exec R1 ip link set R1R2veth up
docker exec R1 ip link set R1h1veth up
docker exec R1 ip link set R1h2veth up
docker exec R2 ip link set R2R1veth up
docker exec R2 ip link set R2hRveth up
docker exec h1 ip link set h1R1veth up
docker exec h2 ip link set h2R1veth up
docker exec hR ip link set hRR2veth up

docker exec h1 ip route add default via 192.168.1.1
docker exec h2 ip route add default via 192.168.2.1
docker exec hR ip route add default via 140.113.1.1

docker exec R1 sysctl net.ipv4.ip_forward=1
docker exec R1 sysctl -p
docker cp daemons R1:/etc/quagga/daemons
docker cp zebra.conf R1:/etc/quagga/zebra.conf
docker cp bgp_R1.conf R1:/etc/quagga/bgpd.conf
docker exec R1 /etc/init.d/quagga restart
docker exec R2 sysctl net.ipv4.ip_forward=1
docker exec R2 sysctl -p
docker cp daemons R2:/etc/quagga/daemons
docker cp zebra.conf R2:/etc/quagga/zebra.conf
docker cp bgp_R2.conf R2:/etc/quagga/bgpd.conf
docker exec R2 /etc/init.d/quagga restart