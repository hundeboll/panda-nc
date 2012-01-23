#!/bin/sh

# Check arguments
USAGE="Usage: ${0} {start|stop} CONFIG"
if [ $# -ne 2 ]; then
  echo ${USAGE}
fi

# Source config
source ${2}

if [ ${1} = "start" ]; then
  # Update git repository
  cd ${RD_PATH}
  git fetch origin
  git reset --hard origin

  if [ -e ${RD_PID} ]; then
    echo Killing running instance
    kill $(cat ${RD_PID}) &> /dev/null
    sleep 1
  fi

  # Start riddler node
  ./node.py --wifi_iface ${WIRELESS_IFACE} --mesh_host ${BAT_IP%/*} | tee ${RD_LOG} &
  if [ $? -eq 0 ]; then
    echo $! > ${RD_PID}
  fi

elif [ ${1} = "stop" ]; then
  if [ -e ${RD_PID} ]; then
    kill $(cat ${RD_PID}) &> /dev/null
    rm ${RD_PID}
  else
    echo Riddler node does not seem to be running.
  fi
fi
