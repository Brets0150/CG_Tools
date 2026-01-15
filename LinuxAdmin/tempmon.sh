#!/bin/bash

X :0 &
export DISPLAY=:0
nvidia-xconfig --cool-bits=4
nvidia-settings -a "[gpu:0]/GPUFanControlState=1" -a "[fan:0]/GPUTargetFanSpeed=85"
nvidia-settings -a "[gpu:1]/GPUFanControlState=1" -a "[fan:1]/GPUTargetFanSpeed=85"


#    GPUFanControlState=0: auto fan speed setting turns the fans off at 41°C or below.
#    GPUFanControlState=1: fixed percentage fan speed setting keeps fans speed fixed regardless of GPU temperature.


#
s=0
while [ "${s}" = 0 ];do
        clear
        s=0
        # /home/seawolf/amd_drivers/amdgpu-pro-fans/amdgpu-pro-fans.sh -s 90 2> /dev/null
		sensors coretemp-isa-0000
		data="$(nvidia-smi)"
		echo "${data}"
        w=$(echo "${data}" | grep 'C'| grep '%'| awk -F' ' '{print $5}' | tr -d 'W' | awk '{s+=$1} END {print s}');
        a=$(calc $w/110);
        echo "${w} Watts";
        echo "GPU Amps ${a}"
        # Ask the user if they want to stop the loop by inputing 'Q' for 10 seconds before repeating.
        read -t 10 -n 1 -s -p "Press 'Q' to quit." input
        if [[ $input = "Q" ]] || [[ $input = "q" ]]; then
                s=1
        fi
done
# Return the fan control to auto on the GPUs.
nvidia-settings -a "[gpu:0]/GPUFanControlState=0"
nvidia-settings -a "[gpu:1]/GPUFanControlState=0"