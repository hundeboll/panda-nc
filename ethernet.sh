#!/bin/bash

USAGE="Usage: $0 {up|down} [CONFIG]"

if [ $# -lt 1 ]; then
  echo $USAGE
  exit 1
fi

if [ $# -gt 1 ]; then
  CONFIG=$2
else
  CONFIG=$(dirname $0)/nc.conf
fi

source $CONFIG

set_hostname() {
  # Change hostname
  hostname n$N

  if [ -a /etc/ubuntu-release ]; then
    echo $hostname > /etc/hostname
    sed -i -e "s/\(127\.0\.1\.1\s\)[a-zA-Z0-9]\+/\1 ${hostname}\/" /etc/hosts

  elif [ -a /etc/arch-release ]; then
    sed -i -r s/HOSTNAME=\"[a-zA-Z0-9]+\"/HOSTNAME=\"${hostname}\"/ /etc/rc.conf
    sed -i -e "s/\(127\.0\.0\.1.\+\)$/\1 ${hostname}/" /etc/hosts

  else
      echo "Unknown distribution; unable to set hostname"
  fi
}

iface_up() {
  ip link set dev $WIRE_IFACE address $WIRE_MAC
  ip link set dev $WIRE_IFACE up
  dhcpcd $WIRE_IFACE
  ip addr add $WIRE_IP dev $WIRE_IFACE label $WIRE_IFACE:0
  echo $WIRE_IFACE up
}

iface_down() {
  # Update git configuration repo
  path=$(pwd)
  cd $(dirname $0)
  git fetch origin
  git reset --hard origin
  cd $path

  ip addr del $WIRE_IP dev $WIRE_IFACE:0
  dhcpcd -k $WIRE_IFACE
  ip link set dev $WIRE_IFACE down
  echo $WIRE_IFACE down
}

if [ $1 = "up" ]; then
  set_hostname
  iface_up

elif [ $1 = "down" ]; then
  iface_down
fi
