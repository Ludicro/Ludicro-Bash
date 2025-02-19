#!/bin/bash

##
# Author: Ludicro
# Version: 2.0
# Description: Check to see if a service is running and will send the output to a discord webhook.
#               Also checks if the public IP address has changed and will send a notification if it has.
##

## User Changes
# Discord Webhook
# Change the 'discord_url' with your actual Discord Webhook

# Service
# Change the 'service_port' to the port your service is using
# Change the 'service_name' to the name of your service

# WebHook Avatar
# Change the 'webhook_avatar' with your actual avatar URL
##

## Usage
# May need to modify the awk statement to be `FNR == 6` or `== 7`

# add to linux cron:
# sudo crontab -e
# https://crontab.guru/
##

#discord url
discord_url=""

# Set service variables
ip=$(localhost)
service_port=""
service_name=""

# Get current public IP address
publicIP=$(curl https://ipinfo.io/ip)


## Compare public IPs

# Save current public IP to temporary file
echo "$publicIP" > /tmp/currentIP


# Check if previous IP exists and compare with current IP
if [ -f /tmp/previousIP ]; then
    changeInIP=$(diff /tmp/currentIP /tmp/previousIP)
else
    changeInIP="different" # Force update on first run
fi



# Scan specified port using nmap to check service status
scan=$(nmap -Pn -p $service_port $ip | awk 'FNR == 7 {print $2}')

# Save current scan result to temporary file
echo "$scan" > /tmp/${service_name}CurResult

# Compare current scan result with previous status
changeInStatus=$(diff ${service_name}CurResult /tmp/${service_name}Status)

# Check if service is running and set appropriate message
if [[ $scan == "open" ]]; then
	content="Service is running."
	echo "$scan" > /tmp/${service_name}Status
else
	content="Service is down."
	echo "$scan" > /tmp/${service_name}Status
fi

# Function to generate JSON payload for Discord webhook
generate_post_data() {
  cat <<EOF
{
  "username": "$service_name Status", 
  "avatar_url":"",
  "embeds": [{
    "title": "$service_name Status",
    "description": "$content\\nIP Address: $publicIP",
    "color": "45973"
  }]
}
EOF
}

# POST request to Discord Webhook
if [[ "$changeInStatus" != "" ]]; then
    curl -H "Content-Type: application/json" -X POST -d "$(generate_post_data)" $discord_url
fi

# Update the previous IP file
cp /tmp/currentIP /tmp/previousIP
