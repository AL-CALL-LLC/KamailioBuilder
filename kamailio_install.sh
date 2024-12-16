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
            color_green ":: 'kamailio' is not in PATH, using /usr/local/sbin/kamailio to display version."
            /usr/local/sbin/kamailio -V
        fi
        sleep 0.5
        ask_kamailio_module_installation
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
        color_orange ":: X Failed to update APT repositories. X"
        color_orange "..."
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
        color_orange "..."
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
        color_orange ":: X Failed to configure Kamailio with systemd. X"
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
        color_orange ":: X 'kamailio' was not added to the PATH. Using /usr/local/sbin/kamailio to display version.X "
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

## Configure kamailio database & create test user
create_database_and_user() {
    sleep 0.5
    color_green ":: Configuration updated."
    kamdbctl create

    sleep 0.5
    # User and password
    user1="test"
    password1=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12)

    sleep 0.5
    color_yellow "## Creating a test user : $user1"
    sleep 1

    color_green ":: Adding user $user1 with the generated password..."
    kamctl add "$user1" "$password1"

    if [ $? -eq 0 ]; then
        color_green ":: User $user1 successfully added. Password: $password1"
    else
        color_orange ":: X Failed to add user $user1. X"
    fi
}

# install kamailio other modules
install_kamailio_modules() {
    # Return to source directory
    cd /usr/local/src/kamailio-5.8/kamailio

    # Array of Kamailio modules with descriptions
    modules=(
        "app_lua"      # Lua scripting support
        "app_python3"  # Python scripting support
        "http_client"  # HTTP client for external requests
        "presence"     # Presence management
        "uuid"         # Unique identifier generation
        "xmlrpc"       # XML-RPC support
        "websocket"    # WebSocket protocol support
    )

    # Associative array of dependencies with explanatory comments
    declare -A dependencies
    dependencies["app_lua"]="liblua5.1-0-dev"            # Lua dev libraries
    dependencies["app_python3"]="python3-dev"             # Python dev libraries
    dependencies["http_client"]="libcurl4-openssl-dev"    # Curl for HTTP
    dependencies["presence"]="libxml2-dev"                # XML for presence
    dependencies["uuid"]="uuid-dev"                       # UUID dev libraries
    dependencies["xmlrpc"]="libxml2-dev"                  # XML for XMLRPC
    dependencies["websocket"]="libssl-dev"                # SSL for websocket

    # Display list of available modules with descriptions
    color_yellow "## List of available modules:"
    for i in "${!modules[@]}"; do
        echo "$((i+1))) ${modules[$i]}"
    done

    # Ask user to select modules
    color_yellow ":: Enter the numbers of modules to install (separated by spaces): "
    read -a selected_indices

    # Vérifier si des modules ont été sélectionnés
    if [ ${#selected_indices[@]} -eq 0 ]; then
        color_red ":: XX No module selected. Installation canceled. XX"
        return 1
    fi

    # Verification and processing of selected modules
    for index in "${selected_indices[@]}"; do
        adjusted_index=$((index-1))
        if [[ $index =~ ^[0-9]+$ ]] && [ "$index" -gt 0 ] && [ "$adjusted_index" -lt "${#modules[@]}" ]; then
            module_name="${modules[$adjusted_index]}"
            module_deps="${dependencies[$module_name]}"
            color_yellow ":: Module $module_name will need dependencies: $module_deps"
        else
            color_orange ":: X Invalid index ignored: $index X"
        fi
    done

    # Installing dependencies for selected modules
    color_yellow "## Installing dependencies..."
    for index in "${selected_indices[@]}"; do
        adjusted_index=$((index-1))
        if [[ $index =~ ^[0-9]+$ ]] && [ "$index" -gt 0 ] && [ "$adjusted_index" -lt "${#modules[@]}" ]; then
            module_name="${modules[$adjusted_index]}"
            module_deps="${dependencies[$module_name]}"
            
            if [ ! -z "$module_deps" ]; then
                color_orange ":: Installing dependencies for $module_name..."
                # Using apt-get with -y for non-interactive installation
                sudo apt-get install -y $module_deps
                if [ $? -eq 0 ]; then
                    color_green ":: Dependencies installed for $module_name"
                else
                    color_red ":: XX Error installing dependencies for $module_name XX"
                    return 1
                fi
            fi
        fi
    done

    # Module compilation phase
    color_yellow ":: Compiling modules..."

    # Building module list for include_modules
    # Expected format: module1 module2 module3
    module_list=""
    for index in "${selected_indices[@]}"; do
        if [[ $index =~ ^[0-9]+$ ]] && [ "$index" -gt 0 ] && [ "$index" -lt "${#modules[@]}" ]; then
            module_name="${modules[$index]}"
            if [ -z "$module_list" ]; then
                module_list="$module_name"
            else
                module_list="$module_list $module_name"
            fi
        fi
    done

    # Cleanup and compilation
    color_yellow "## Running make clean..."
    make clean

    color_yellow ":: Compiling with modules: $module_list"
    make include_modules="$module_list" cfg
    make all
    make install
    if [ $? -eq 0 ]; then
        color_green ":: Compilation successful"
        return 0
    else
        color_red ":: XX Compilation error XX"
        return 1
    fi
}

# Function to ask user if they want to install modules
ask_kamailio_module_installation() {
    while true; do
        color_yellow "## Do you want to install additional modules? (yes/no): "
        read response
        case $response in
            [Yy]* )
                color_yellow ":: Starting module installation..."
                install_kamailio_modules
                break
                ;;
            [Nn]* )
                color_orange ":: X Installation cancelled. X"
                break
                ;;
            * )
                color_orange ":: Please answer yes or no"
                ;;
        esac
    done
}

## Main execution
welcome_message
check_root
check_distribution
check_kamailio_installed
update_apt_repositories
install_dependencies
prepare_kamailio_storage_and_install
install_mysql_server
configure_systemd_services
configure_config_files
create_database_and_user
ask_kamailio_module_installation
color_yellow "## End of the script"