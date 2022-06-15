FROM ubuntu:16.04

MAINTAINER eric

RUN apt update

RUN apt-get install net-tools -y
RUN apt-get install iproute2 -y
RUN apt-get install nano -y
RUN apt-get install iptables -y
RUN apt-get install iputils-ping -y
RUN apt-get install tcpdump -y
RUN apt-get install python3 -y
RUN apt-get install curl -y
RUN apt-get install isc-dhcp-server -y
RUN apt-get install isc-dhcp-client -y
RUN apt-get install arping -y
RUN apt-get install build-essential -y
RUN apt-get install libpcap-dev -y
RUN apt-get install iperf3 -y
RUN apt-get install python3-pip -y
RUN apt-get install wget -y
RUN apt-get install tar -y
RUN apt-get install -y --no-install-recommends gcc make && rm -rf /var/lib/apt/lists/*
RUN pip3 install six # install python package 
RUN wget https://www.openvswitch.org/releases/openvswitch-2.11.4.tar.gz
RUN tar zxf openvswitch-2.11.4.tar.gz
RUN cd openvswitch-2.11.4 && \
./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc && \
make && \
make install
