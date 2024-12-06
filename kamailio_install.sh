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

## Check the distribution
check_distribution() {
    if [[ -f /etc/os-release ]]; then
        distribution=$(grep ^ID= /etc/os-release | cut -d= -f2 | tr -d '"')
        codename=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
        color_green ":: System details: $distribution ($codename)"
    else
        color_red ":: XX Unable to determine the distribution. Ensure your system uses /etc/os-release. XX"
        exit 1
    fi
}

## Check if Kamailio is already installed
check_kamailio_installed() {
    sleep 0.5
    color_yellow "## Checking if Kamailio is already installed"
    sleep 1
    if [[ -x /usr/local/sbin/kamailio ]] || command -v kamailio >/dev/null 2>&1; then
        color_green ":: Kamailio is already installed on this system."
        sleep 0.5
        if command -v kamailio >/dev/null 2>&1; then
            color_green ":: Using 'kamailio' via PATH to display the version."
            kamailio -V
        else
            color_green ":: 'kamailio' is not in PATH, using /usr/local/sbin/kamailio."
            /usr/local/sbin/kamailio -V
        fi
        sleep 0.5
        color_yellow "## Kamailio installation program ended."
        exit 0
    fi
}