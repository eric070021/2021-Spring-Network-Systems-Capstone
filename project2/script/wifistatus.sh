#!/bin/sh

mac=`iw dev wlan0 station dump | grep -i station | awk '{printf $2","}'`
signal=`iw dev wlan0 station dump | grep -i signal: | awk '{printf $2","}'`
echo "$mac$signal"