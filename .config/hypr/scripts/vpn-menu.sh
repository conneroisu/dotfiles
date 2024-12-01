#!/usr/bin/env bash

notify-send "NordVPN Connection Type Selector"

# Check if NordVPN is installed
if ! command -v nordvpn &> /dev/null; then
    notify-send "NordVPN is not installed. Please install it first."
    exit 1
fi

# Define connection types
connection_types="Country\nServer\nCountry Code\nCity\nGroup"

# Use rofi to select connection type
chosen_type=$(echo -e "$connection_types" | rofi -dmenu -i -p "Select Connection Type: ")

case $chosen_type in
    "Country")
        # Get a list of countries
        country_list=$(nordvpn countries | tr '\n' '\0' | xargs -0 -n1 | sort | uniq -u)
        chosen_country=$(echo -e "$country_list" | rofi -dmenu -i -p "Select Country: ")
        if [[ -n "$chosen_country" ]]; then
            nordvpn connect "$chosen_country"
            notify-send "NordVPN" "Connecting to $chosen_country..."
        fi
        ;;
    "Server")
        chosen_server=$(rofi -dmenu -i -p "Enter Server: ")
        if [[ -n "$chosen_server" ]]; then
            nordvpn connect "$chosen_server"
            notify-send "NordVPN" "Connecting to server $chosen_server..."
        fi
        ;;
    "Country Code")
        chosen_code=$(rofi -dmenu -i -p "Enter Country Code: ")
        if [[ -n "$chosen_code" ]]; then
            nordvpn connect "$chosen_code"
            notify-send "NordVPN" "Connecting to country code $chosen_code..."
        fi
        ;;
    "City")
        # This is a simplified approach since listing all cities is not directly supported
        chosen_city=$(rofi -dmenu -i -p "Enter 'Country City': ")
        if [[ -n "$chosen_city" ]]; then
            nordvpn connect "$chosen_city"
            notify-send "NordVPN" "Connecting to $chosen_city..."
        fi
        ;;
    "Group")
        # Get a list of groups
        group_list=$(nordvpn groups | tr '\n' '\0' | xargs -0 -n1 | sort | uniq -u)
        chosen_group=$(echo -e "$group_list" | rofi -dmenu -i -p "Select Group: ")
        if [[ -n "$chosen_group" ]]; then
            nordvpn connect --group "$chosen_group"
            notify-send "NordVPN" "Connecting to group $chosen_group..."
        fi
        ;;
    *)
        notify-send "Invalid selection. Please try again."
        ;;
esac