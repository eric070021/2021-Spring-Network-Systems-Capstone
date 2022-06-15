#!/bin/bash

/usr/share/openvswitch/scripts/ovs-ctl start
ovs-vsctl add-br br0
ovs-vsctl set bridge br0 protocols=OpenFlow13
ovs-vsctl -- set bridge br0 fail-mode=secure # delete default flow control
ovs-vsctl add-port br0 BRG1h1 -- set Interface BRG1h1 ofport_request=1
ovs-vsctl add-port br0 GRETAP -- set Interface GRETAP ofport_request=2
ovs-ofctl -O OpenFlow13 add-meter br0 meter=1,kbps,band=type=drop,rate=1000
ovs-ofctl -O OpenFlow13 add-flow br0 in_port=1,actions=meter:1,output:2
ovs-ofctl -O OpenFlow13 add-flow br0 in_port=2,actions=output:1
#ovs-ofctl -O OpenFlow13 dump-meters br0
#ovs-ofctl -O OpenFlow13 dump-flows br0

iperf3 -s -B 20.0.1.1
iperf3 -u -b 100M -c 20.0.1.1 --length 1200