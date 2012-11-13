#!/bin/sh

USAGE="Usage: $0 {up|down}"

if [ $# -lt 1 ]; then
  echo $USAGE
  exit 1
fi

source $(dirname $0)/nc.conf

setup_adhoc() {
  # Detect the physical device
  #PHY_IFACE=`iw dev | sed -nE "s/phy#([0-9]+)/phy\1/p"`
  PHY_IFACE=phy$(iw dev | pcregrep -M -o1 "phy\#([0-9])+\s+.+\s${WIRELESS_IFACE}")

  # Setup wireless interface to ad-hoc
  ip link set dev $WIRELESS_IFACE down
  #ip link set dev $WIRELESS_IFACE address $WIRELESS_MAC
  iw dev $WIRELESS_IFACE set type ibss
  ip link set dev $WIRELESS_IFACE up
  ip link set dev $WIRELESS_IFACE txqlen $WIRELESS_QLEN
  iw $WIRELESS_IFACE ibss join $WIRELESS_ESSID $WIRELESS_FREQ $WIRELESS_BSSID
  ip addr add $WIRELESS_IP dev $WIRELESS_IFACE
  #iw phy $PHY_IFACE set rts $WIRELESS_RTS
  #iw dev $WIRELESS_IFACE set bitrates legacy-2.4 $WIRELESS_RATE
  #iwconfig $WIRELESS_IFACE rate ${WIRELESS_RATE}M fixed
}

update_batman() {
  # Remove batman module if inserted
  if lsmod | grep -q batman; then
    rmmod batman_adv
  fi

  path=`pwd`
  cd $BAT_MOD_PATH

  # Update git repository
  git fetch origin
  git reset --hard origin

  # Make module and insert it
  if ! make -j2 --quiet \
      CONFIG_BATMAN_ADV_STATS=y \
      CONFIG_BATMAN_ADV_NC=y \
      CONFIG_BATMAN_ADV_DEBUG=y \
      CONFIG_BATMAN_ADV_DAT=n
  then
    echo "Compiling batman-adv module failed"
    exit 1
  fi 
  insmod ./batman-adv.ko
  cd $path
}

setup_batman() {
  # Configure
  ip link set $BAT_HARD_IFACE mtu 1600
  ip link set $BAT_HARD_IFACE promisc on
  $BAT_BATCTL_PATH/batctl -m $BAT_SOFT_IFACE if add $BAT_HARD_IFACE
  ip link set dev $BAT_SOFT_IFACE up
  ip addr add $BAT_IP dev $BAT_SOFT_IFACE

  # Insert bat-hosts
  rm -f /etc/bat-hosts
  ln -s $(dirname $0)/bat-hosts /etc/bat-hosts

  # Update /etc/hosts
  sed -i -e "/start/,/stop/d" /etc/hosts
  cat $(dirname $0)/hosts >> /etc/hosts
  if [ "$N" == "55" ]; then
      echo 1c:7e:e5:5c:94:7d allow > /sys/kernel/debug/batman_adv/bat0/block_ogm
  elif [ "$N" == "57" ]; then
      echo 1c:7e:e5:5c:94:7d allow > /sys/kernel/debug/batman_adv/bat0/block_ogm
  fi
}

reset_adhoc() {
  # Bring down wireless interface
  ip addr del $WIRELESS_IP dev $WIRELESS_IFACE
  iw $WIRELESS_IFACE ibss leave
  ip link set dev $WIRELESS_IFACE down
  iw $WIRELESS_IFACE set type managed
}

reset_batman() {
  # Deconfigure batman-adv
  ip link set dev $BAT_SOFT_IFACE down
  ip addr del $BAT_IP dev $BAT_SOFT_IFACE
  $BAT_BATCTL_PATH/batctl -m $BAT_SOFT_IFACE if del $BAT_HARD_IFACE
  ip link set $BAT_HARD_IFACE mtu 1500
  ip link set $BAT_HARD_IFACE promisc off

  # Unload module
  if lsmod | grep -q batman; then
    rmmod batman_adv
  fi
}

if [ $1 = "up" ]; then
  setup_adhoc
  update_batman
  setup_batman

elif [ $1 = "down" ]; then
  reset_batman
  reset_adhoc

else
  echo $USAGE
  exit 1

fi
