#!/bin/bash

set -e

source .creds
# labname
labname=nfd33
# gnmic command with common global flags
gnmic_cmd="gnmic --tls-ca clab-$labname/.tls/ca/ca.pem -u $username -p $password"

function configure_interfaces
{
      ${gnmic_cmd} \
            --log \
            -a $1 \
            set \
            --request-file configs/1.interfaces/interfaces_template.gotmpl \
            --request-file configs/1.interfaces/subinterfaces_template.gotmpl \
            --request-vars configs/1.interfaces/interfaces_template_vars.yaml
}

function configure_routing_policy
{
      ${gnmic_cmd} \
            --log \
            -a $1 \
            set \
            --request-file configs/2.routing-policy/routing_policy_prefix_set_template.gotmpl \
            --request-file configs/2.routing-policy/routing_policy_policy_template.gotmpl \
            --request-vars configs/2.routing-policy/routing_policy_vars.yaml
}

function configure_ns_bgp
{
      ${gnmic_cmd} \
            --log \
            -a $1 \
            set \
            --request-file configs/3.network-instance/network_instance_template.gotmpl \
            --request-file configs/3.network-instance/network_instance_bgp_template.gotmpl \
            --request-vars configs/3.network-instance/network_instance_template_vars.yaml
}

node=$1

if [ -z "$node" ]; then
  # list SR Linux containers names belonging to lab $labname and join them with commma.
  node=$(docker ps -f label=containerlab=$labname -f label=clab-node-kind=srl --format {{.Names}} | paste -s -d, -)
fi

# configure network interfaces
configure_interfaces $node
# configure routing policy
configure_routing_policy $node
# configure network-instance and BGP peers
configure_ns_bgp $node
