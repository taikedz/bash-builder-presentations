#!/bin/bash

mode="$1"

if [ "$mode" = on ]; then

ufw deny 80
ufw deny 8080
ufw deny 25

else

ufw delete deny 80
ufw delete deny 8080
ufw delete deny 25

fi

