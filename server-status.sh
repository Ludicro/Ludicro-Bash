#!/bin/bash

##
# Author: Ludicro
# Version: 1.0
# Description: Check to see if a service is running and will send the output to a discord webhook.
##

##
# Discord Webhook
# Change the 'discord_url' with your actual Discord Webhook
##

##
# Service
# Change the 'ip' to the public IP of the device hosting your service
# Change the 'service_port' to the port your service is using
# Change the 'service_name' to the name of your service
##

##
# add to linux cron:
# sudo crontab -e
# https://crontab.guru/
##

#discord url
discord_url=""

ip=$(curl https://ipinfo.io/ip)
service_port=""
service_name=""


scan=$(nmap -Pn -p $service_port $ip | awk 'FNR == 6 {print $2}')


echo "$scan" > /tmp/${service_name}CurResult

changeInStatus=$(diff ${service_name}CurResult /tmp/${service_name}Status)

if [[ $scan == "open" ]]; then
	content="Service is running."
	echo "$scan" > /tmp/${service_name}Status
else
	content="Service is down."
	echo "$scan" > /tmp/${service_name}Status
fi

generate_post_data() {
  cat <<EOF
{
  "username": "Service Status",
  "avatar_url":"",
  "embeds": [{
    "title": "$service_name Status",
    "description": "$content\\nIP Address: $ip",
    "color": "45973"
  }]
}
EOF
}


# POST request to Discord Webhook
if [[ "$changeInStatus" != "" ]]; then
    curl -H "Content-Type: application/json" -X POST -d "$(generate_post_data)" $discord_url
fi


