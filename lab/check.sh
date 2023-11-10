#!/bin/bash

set -e

labname=nfd33
source .creds

gnmic_cmd="gnmic --tls-ca clab-$labname/.tls/ca/ca.pem -u $username -p $password"

function check_bgp_status
{
      node=$1
      bgp_state=$(${gnmic_cmd} \
                  -a $1 \
                  -e ascii \
                  --format flat \
                  get \
                  --path /network-instance[name=default]/protocols/bgp/oper-state | awk '{print $NF}')
      printf "$1: BGP state is ${bgp_state^^} \n"
      # cowsay -T U -e XX "$1: BGP state is ${bgp_state^^}"
}

function check_bgp_neighbors
{
      node=$1
      neighbors=$(
            gnmic -a $node \
            --tls-ca clab-$labname/.tls/ca/ca.pem \
            -u $username \
            -p $password \
            -e ascii \
            --format flat \
            get \
            --path /network-instance[name=default]/protocols/bgp/neighbor/afi-safi[afi-safi-name=ipv4-unicast]/oper-state
            )

      num_neighbors=$(echo "$neighbors" | grep neighbor | wc -l)
      printf "$node: has $num_neighbors BGP neighbor(s) \n"
      echo "$neighbors" | while IFS= read -r neighbor
      do
            state=$(echo $neighbor | awk '{print $NF}')
            ip_address=$(echo "$neighbor" | grep -oP '\bpeer-address=([0-9]{1,3}\.){3}[0-9]{1,3}\b')
            ip_address="${ip_address#peer-address=}"
            printf "$node: BGP neighbor $ip_address state $state \n"
            # cowsay -T U -e @@ $node has BGP neighbor $ip_address with state $state
      done
      # printf "\\U1F44D $node has $num_neighbors BGP neighbors \n"
}

node=$1

if [ -z "$node" ]; then
  nodes=$(docker ps -f label=clab-node-kind=srl -f label=containerlab=$labname --format {{.Names}})
  for node in $nodes
    do
        check_bgp_status $node
        check_bgp_neighbors $node
        echo ""
    done
else
    check_bgp_status $node
    check_bgp_neighbors $node
fi
