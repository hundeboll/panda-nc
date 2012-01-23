#!/bin/bash

USAGE="Usage: $0 {up|down} [CONFIG]"

if [ $# -lt 1 ]; then
  echo $USAGE
  exit 1
fi

source $(dirname $0)/nc.conf

set_hostname() {
  # Change hostname
  hostname n$N
  echo n$N > /etc/hostname
  #sed -i -r s/HOSTNAME=\"[a-zA-Z0-9]+\"/HOSTNAME=\"n${N}\"/ /etc/rc.conf
  sed -i -e "s/\(127\.0\.1\.1\s\)[a-zA-Z0-9]\+/\1n57/" /etc/hosts
}

iface_up() {
  ip link set dev $WIRE_IFACE address $WIRE_MAC
  ip link set dev $WIRE_IFACE up
  ip addr add $WIRE_IP dev $WIRE_IFACE label $WIRE_IFACE:0
  echo $WIRE_IFACE up
}

iface_down() {
  ip addr del $WIRE_IP dev $WIRE_IFACE:0
  ip link set dev $WIRE_IFACE down
  echo $WIRE_IFACE down
}

if [ $1 = "up" ]; then
  set_hostname
  iface_up

elif [ $1 = "down" ]; then
  iface_down

fi
