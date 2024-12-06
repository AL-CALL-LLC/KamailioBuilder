#!/bin/bash

## Function to get colored text
color_red() { echo -e "\e[31m$1\e[0m"; }
color_green() { echo -e "\e[32m$1\e[0m"; }
color_yellow() { echo -e "\e[33m$1\e[0m"; }
color_blue() { echo -e "\e[34m$1\e[0m"; }

## welcome message
welcome_message() {
    color_yellow "## Welcome to the Kamailio 5.8 installation script."
}

## Check if the script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        color_red ":: XX This script must be run with root privileges. Please try again with 'sudo'."
        exit 1
    fi
}