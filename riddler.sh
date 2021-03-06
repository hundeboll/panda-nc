#!/bin/sh

# Check arguments
USAGE="Usage: $0 {start|stop} [CONFIG]"
if [ $# -lt 1 ]; then
  echo $USAGE
fi

if [ $# -gt 1 ]; then
  CONFIG=$2
else
  CONFIG=$(dirname $0)/nc.conf
fi

# Source config
source $CONFIG

start_riddler() {
  # Update git repository
  path=$(pwd)
  cd $RD_PATH
  git fetch origin
  git reset --hard origin

  # Make sure output from node.py is written immediately
  export PYTHONUNBUFFERED=1

  # Start riddler node
  ./node.py --wifi_iface $WIRELESS_IFACE --mesh_host ${BAT_IP%/*} &> $RD_LOG &
  if [ $? -eq 0 ]; then
    echo $! > $RD_PID
  fi

  cd $path
}

stop_riddler() {
  if [ -e $RD_PID ]; then
    kill $(cat $RD_PID) &> /dev/null
    rm $RD_PID
  fi
}

if [ $1 = "start" ]; then
  stop_riddler
  start_riddler

elif [ $1 = "stop" ]; then
  stop_riddler
fi
