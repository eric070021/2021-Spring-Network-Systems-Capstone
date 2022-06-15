#include <iostream>
#include <vector>
#include <string>
#include <cstring>
#include <pcap.h>
#include <arpa/inet.h>
#include <net/ethernet.h>
#include <netinet/ip.h>
#include <stdlib.h>
#include <unordered_map>

using std::cout;
using std::cin;
using std::string;
using std::getline;

#define ETHERTYPE_IP        0x0800    /* IP protocol */
#define ETHERTYPE_ARP       0x0806    /* Addr. resolution protocol */
#define ETHERTYPE_REVARP    0x8035    /* reverse Addr. resolution protocol */
#define ETHERTYPE_IPV6      0x86dd    /* IPv6 */
#define ETHERTYPE_LOOPBACK  0x9000    /* used to test interfaces */
#define MAC_ADDRSTRLEN 2*6+5+1

string BRGr_IP =  "140.113.0.1";

struct gre_base_hdr {
	__be16 flags;
	__be16 protocol;
} __packed;

char *mac_ntoa(u_char *d);
char *ip_ntoa(void *i);

char *mac_ntoa(u_char *d) {
    static char str[MAC_ADDRSTRLEN];

    snprintf(str, sizeof(str), "%02x:%02x:%02x:%02x:%02x:%02x", d[0], d[1], d[2], d[3], d[4], d[5]);

    return str;
}

char *ip_ntoa(void *i) {
    static char str[INET_ADDRSTRLEN];

    inet_ntop(AF_INET, i, str, sizeof(str));

    return str;
}

int main(){
    std::unordered_map<string, bool> blacklist;
    pcap_if_t *devices = NULL;
    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle = NULL;
    struct pcap_pkthdr *header = NULL;
    const u_char *content = NULL;
    bpf_u_int32 net, mask;
    struct bpf_program fcode;
    int tunnelId = 1;

    //get all devices
    if(-1 == pcap_findalldevs(&devices, errbuf)) {
        fprintf(stderr, "pcap_findalldevs: %s\n", errbuf);
        exit(1);
    }

    //list all device
    int i = 0;
    std::vector<string> interface;
    for(pcap_if_t *d = devices; d ; d = d->next) {
        cout << i++ << " Name: " << d->name << '\n';
        interface.push_back(d->name);
    }

    string input;
    string expression;
    cout << "Insert a number to select interface:" << '\n';
    getline(cin, input);
    cout << "Start listening at $" << interface[stoi(input)] << '\n';

    //open interface
    handle = pcap_open_live(interface[stoi(input)].c_str(), 65535, 1, 1000, errbuf);
    if(!handle) {
        fprintf(stderr, "pcap_open_live: %s\n", errbuf);
        exit(1);
    }

    cout << "Insert BPF filter expression: " << '\n';
    getline(cin, expression);
    expression += " and dst host 140.113.0.1"; // add default filtering rule
    cout << "filter: " << expression << "\n\n";
    
    //get network and mask
    if(-1 == pcap_lookupnet(interface[stoi(input)].c_str(), &net, &mask, errbuf)) {
        fprintf(stderr, "pcap_lookupnet: %s\n", errbuf);
        pcap_close(handle);
        exit(1);
    }

    //compile filter
    if(-1 == pcap_compile(handle, &fcode, expression.c_str(), 1, mask)) {
        fprintf(stderr, "pcap_compile: %s\n", pcap_geterr(handle));
        pcap_close(handle);
        exit(1);
    }

    //set filter
    if(-1 == pcap_setfilter(handle, &fcode)) {
        fprintf(stderr, "pcap_pcap_setfilter: %s\n", pcap_geterr(handle));
        pcap_freecode(&fcode);
        pcap_close(handle);
        exit(1);
    }

    //free code
    pcap_freecode(&fcode);

    // set the bridge
    system("ip link add br0 type bridge");
    system("ip link set BRGr-eth0 master br0");

    //start capture
    for(int i = 1;; ){
        int ret = pcap_next_ex(handle, &header, &content);
        if(ret == 1) { // if success
            printf("Packet Num [%d]\n", i++);
            
            //dump outer ethernet
            struct ether_header *ethernet = (struct ether_header *)content;
            char dst_mac_addr[MAC_ADDRSTRLEN] = {};
            char src_mac_addr[MAC_ADDRSTRLEN] = {};
            u_int16_t type;

            std::memcpy(dst_mac_addr, mac_ntoa(ethernet->ether_dhost), sizeof(dst_mac_addr));
            std::memcpy(src_mac_addr, mac_ntoa(ethernet->ether_shost), sizeof(src_mac_addr));
            type = ntohs(ethernet->ether_type);

            printf("Outer Source MAC: %17s\n", src_mac_addr);
            printf("Outer Destination MAC: %17s\n", dst_mac_addr);
            printf("Outer Ethernet type: %04x\n", type);

            //dump outer ip
            struct ip *ip = (struct ip *)(content + ETHER_HDR_LEN);
            u_int ip_header_len = ip->ip_hl << 2;
            u_char ip_protocol = ip->ip_p;

            printf("Outer Source IP: %s\n", ip_ntoa(&ip->ip_src));
            printf("Outer Destination IP: %s\n", ip_ntoa(&ip->ip_dst));
            //printf("IP protocol: %x\n", ip_protocol);
            printf("Next Layer Protocol: GRE\n");

            //dump gre
            struct gre_base_hdr *gre = (struct gre_base_hdr *)(content + ETHER_HDR_LEN + ip_header_len);
            u_int16_t protocol = ntohs(gre->protocol);
            printf("Protocol: %x\n", protocol);

            //dump inner ethernet
            struct ether_header *ethernet_i = (struct ether_header *)(content + ETHER_HDR_LEN + ip_header_len + 4);
            char dst_mac_addr_i[MAC_ADDRSTRLEN] = {};
            char src_mac_addr_i[MAC_ADDRSTRLEN] = {};
            u_int16_t type_i;

            std::memcpy(dst_mac_addr_i, mac_ntoa(ethernet_i->ether_dhost), sizeof(dst_mac_addr_i));
            std::memcpy(src_mac_addr_i, mac_ntoa(ethernet_i->ether_shost), sizeof(src_mac_addr_i));
            type_i = ntohs(ethernet_i->ether_type);

            printf("Inner Source MAC: %17s\n", src_mac_addr_i);
            printf("Inner Destination MAC: %17s\n", dst_mac_addr_i);
            printf("Inner Ethernet type: %04x\n", type_i);

            //print packet in hex dump
            for(int j = 0 ; j < header->caplen ; j++) {
                printf("%02x ", content[j]);
            }
            printf("\n\n");

            //check if tunnel exist
            string src_ip (ip_ntoa(&ip->ip_src)); // convert char* to string
            if(blacklist.find(src_ip) == blacklist.end()){
                blacklist[src_ip] = true;
                struct bpf_program command;
                for(auto &it : blacklist){
                    expression += (" and not host " + it.first);
                }
                
                //compile filter
                if(-1 == pcap_compile(handle, &command, expression.c_str(), 1, mask)) {
                    fprintf(stderr, "pcap_compile: %s\n", pcap_geterr(handle));
                    pcap_close(handle);
                    exit(1);
                }

                //set filter
                if(-1 == pcap_setfilter(handle, &command)) {
                    fprintf(stderr, "pcap_pcap_setfilter: %s\n", pcap_geterr(handle));
                    pcap_freecode(&fcode);
                    pcap_close(handle);
                    exit(1);
                }

                //free code
                pcap_freecode(&command);

                //setup gre tunnel
                string gretap = "GRETAP-BRG" + std::to_string(tunnelId);
                string c1 = "ip link add " + gretap  + " type gretap remote " + src_ip + " local 140.113.0.1";
                string c2 = "ip link set " + gretap + " up";
                string c3 = "ip link set " + gretap +  " master br0";
                system("ip link set br0 down");
                system(c1.c_str());
                system(c2.c_str());
                system(c3.c_str());
                system("ip link set br0 up");
                tunnelId++;
            }
        }
    }

    //free handler
    pcap_close(handle);

    return 0;
}