#!/bin/bash

## Function to get colored text
color_red() { echo -e "\e[31m$1\e[0m"; }
color_green() { echo -e "\e[32m$1\e[0m"; }
color_orange() { echo -e "\e[33m$1\e[0m"; }
color_yellow() { echo -e "\e[38;5;214m$1\e[0m"; }

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

## Update APT repositories
update_apt_repositories() {
    sleep 0.5
    color_yellow "## Updating APT repositories..."
    sleep 1
    if ! apt update -y; then
        color_yellow ":: X Failed to update APT repositories. X"
        color_yellow "..."
    fi
}

## Install dependencies
install_dependencies() {
    color_yellow "## Installing required dependencies..."
    sleep 1
    deps=(make autoconf pkg-config git gcc g++ flex bison libssl-dev default-libmysqlclient-dev)

    for dep in "${deps[@]}"; do
        color_yellow ":: Installing $dep..."
        if ! apt install -y "$dep"; then
            color_red ":: XX Failed to install $dep. XX"
            exit 1
        fi
        sleep 0.5
    done
}

## Prepare and install Kamailio
prepare_kamailio_storage_and_install() {
    ## Create the storage folder
    color_yellow "## Preparing the folder for Kamailio..."
    sleep 1
    kamailio_src="/usr/local/src/kamailio-5.8"
    if [[ ! -d $kamailio_src ]]; then
        mkdir -p "$kamailio_src"
        color_green ":: Folder created: $kamailio_src"
    else
        color_green ":: Folder already exists: $kamailio_src"
    fi

    ## Clone the Git repository
    color_yellow "## Checking for the Kamailio repository in $kamailio_src..."
    sleep 1
    if [[ -d "$kamailio_src/kamailio/.git" ]]; then
        color_green ":: The Kamailio repository is already cloned in $kamailio_src/kamailio."
        color_green ":: Updating the existing repository..."
        cd "$kamailio_src/kamailio" || exit
        if git pull origin 5.8; then
            color_green ":: The Kamailio repository was successfully updated."
        else
            color_red ":: XX Failed to update the Git repository. XX"
            exit 1
        fi
    else
        color_green ":: Cloning the Kamailio repository into $kamailio_src..."
        cd "$kamailio_src" || exit
        if git clone --depth 1 --branch 5.8 https://github.com/kamailio/kamailio kamailio; then
            color_green ":: The Kamailio repository was successfully cloned."
            cd "kamailio"
        else
            color_red ":: XX Failed to clone the Git repository. Check your network connection. XX"
            exit 1
        fi
    fi

    ## Compile and install
    color_yellow "## Compiling and installing Kamailio with db_mysql and tls modules..."
    sleep 1
    make clean
    if ! make include_modules="db_mysql tls" cfg || ! make all || ! make install; then
        color_red ":: XX Failed to compile or install Kamailio. XX"
        exit 1
    fi
}

## Install MySQL server
install_mysql_server() {
    ## Install MySQL server
    sleep 0.5
    color_yellow "## Installing the default MySQL server"
    sleep 1
    if ! apt -y install default-mysql-server; then
        color_orange ":: X Failed to install the default MySQL server. X"
        color_orange ":: X To use Kamailio with MySQL, you must install an SQL server later. X"
        color_yellow "..."
    fi
}

## Configure systemd service
configure_systemd_services() {
    ## Configure systemd services
    sleep 0.5
    color_yellow "## Configuring systemd services for Kamailio..."
    sleep 1

    # Save 'adduser' default permission
    original_permissions=$(stat -c "%a" /usr/sbin/adduser)
    original_owner=$(stat -c "%U:%G" /usr/sbin/adduser)

    # Edit permission to set adduser available
    sudo chmod 755 /usr/sbin/adduser
    sudo chown root:root /usr/sbin/adduser
    export PATH=$PATH:/usr/sbin

    if ! make install-systemd-debian || ! systemctl enable kamailio; then
        color_yellow ":: X Failed to configure Kamailio with systemd. X"
    fi
    systemctl enable kamailio
    systemctl daemon-reload

    # Reset adduser permission to default
    sudo chmod "$original_permissions" /usr/sbin/adduser
    sudo chown "$original_owner" /usr/sbin/adduser

    sleep 0.5
    color_yellow "## Adding Kamailio to the PATH"
    sleep 1
    echo 'PATH=$PATH:/usr/local/sbin' >> ~/.bashrc
    echo 'export PATH' >> ~/.bashrc
    source ~/.bashrc

    sleep 0.5
    color_yellow "## Kamailio installation and configuration completed."
    sleep 1
    if command -v kamailio >/dev/null 2>&1; then
        color_green ":: Using 'kamailio' via PATH to display the version."
        kamailio -V
    else
        color_yellow ":: X 'kamailio' was not added to the PATH. Using /usr/local/sbin/kamailio to display version.X "
        /usr/local/sbin/kamailio -V
    fi
    color_yellow "## Kamailio installation program ended."
    color_green ":: Starting Kamailio."
    systemctl start kamailio
    kamailio
}

## Configure config file
configure_config_files() {
    sleep 0.5
    color_yellow "## Proceeding to configure your configuration files"
    sleep 1
    color_yellow ">> Please enter your SIP domain:"
    read sip_domain

    while [ -z "$sip_domain" ]; do
        color_yellow "No SIP domain entered. Please try again:"
        read sip_domain
    done

    config_file="/usr/local/etc/kamailio"

    sed -i 's/^# DBENGINE=MYSQL/DBENGINE=MYSQL/' "$config_file/kamctlrc"
    sed -i "s/^# SIP_DOMAIN=kamailio.org/SIP_DOMAIN=$sip_domain/" "$config_file/kamctlrc"
    sed -i 's/^# DBRWPW="kamailiorw"/DBRWPW="kamailiorw"/' "$config_file/kamctlrc"
    sed -i '/#!KAMAILIO/a \#!define WITH_MYSQL\n#!define WITH_AUTH\n#!define WITH_USRLOCDB' "$config_file/kamailio.cfg"
}