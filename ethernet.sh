#!/bin/bash

USAGE="Usage: $0 {up|down} [CONFIG]"

if [ $# -lt 1 ]; then
  echo $USAGE
  exit 1
fi

source $(dirname $0)/nc.conf




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
  iface_up

elif [ $1 = "down" ]; then
  iface_down

fi
