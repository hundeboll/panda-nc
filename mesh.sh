#!/bin/sh

USAGE="Usage: ${0} {up|down} CONFIG"

if [ $# -ne 2 ]; then
  echo ${USAGE}
fi

source ${2}

if [ ${1} = "up" ]; then
  # Reload wl12xx_sdio wireless driver to avoid kernel oops'es
  if lsmod | grep -q wl12xx_sdio; then
    rmmod wl12xx_sdio
    modprobe wl12xx_sdio
  fi

  # Detect the physical device
  PHY_IFACE=`iw dev | sed -nE "s/phy#([0-9]+)/phy\1/p"`

  # Change hostname
  hostname n${N}
  sed -i -r s/HOSTNAME=\"[a-zA-Z0-9]+\"/HOSTNAME=\"n${N}\"/ /etc/rc.conf

  # Setup wireless interface to ad-hoc
  ip link set dev ${WIRELESS_IFACE} down
  ip link set dev ${WIRELESS_IFACE} address ${WIRELESS_MAC}
  iw ${WIRELESS_IFACE} set type ibss
  ip link set dev ${WIRELESS_IFACE} up
  iw ${WIRELESS_IFACE} ibss join ${WIRELESS_ESSID} ${WIRELESS_FREQ} ${WIRELESS_BSSID}
  iw phy ${PHY_IFACE} set rts 100
  ip addr add ${WIRELESS_IP} dev ${WIRELESS_IFACE}

  # Remove batman module if inserted
  if lsmod | grep -q batman; then
    rmmod batman_adv
  fi

  path=`pwd`
  cd ${BAT_MOD_PATH}

  # Update git repository
  git fetch origin
  git reset --hard origin

  # Make module and insert it
  #if ! make -j2 --quiet CONFIG_BATMAN_ADV_STATS=y CONFIG_BATMAN_ADV_NC=y CONFIG_BATMAN_ADV_DEBUG=y; then
  if ! make -j2 --quiet CONFIG_BATMAN_ADV_DEBUG=y; then
    echo "Compiling batman-adv module failed"
    exit 1
  fi 
  insmod ./batman-adv.ko
  cd ${path}

  # Configure
  ip link set ${BAT_HARD_IFACE} mtu 1600
  ip link set ${BAT_HARD_IFACE} promisc on
  ${BAT_BATCTL_PATH}/batctl -m ${BAT_SOFT_IFACE} if add ${BAT_HARD_IFACE}
  ip link set dev ${BAT_SOFT_IFACE} up
  ip addr add ${BAT_IP} dev ${BAT_SOFT_IFACE}

elif [ ${1} = "down" ]; then
  # Deconfigure batman-adv
  ip link set dev ${BAT_SOFT_IFACE} down
  ip addr del ${BAT_IP} dev ${BAT_SOFT_IFACE}
  ${BAT_BATCTL_PATH}/batctl -m ${BAT_SOFT_IFACE} if del ${BAT_HARD_IFACE}
  ip link set ${BAT_HARD_IFACE} mtu 1500
  ip link set ${BAT_HARD_IFACE} promisc off

  # Unload module
  if lsmod | grep -q batman; then
    rmmod batman_adv
  fi

  # Bring down wireless interface
  ip addr del ${WIRELESS_IP} dev ${WIRELESS_IFACE}
  iw ${WIRELESS_IFACE} ibss leave
  ip link set dev ${WIRELESS_IFACE} down
  iw ${WIRELESS_IFACE} set type managed

else
  # Wrong option
  echo ${USAGE}

fi
