#!/bin/bash

# Install the HAProxy, depending upon the platform
function install_haproxy() {
    echo "Installing HAProxy"
    if [[ $PLATFORM == *"ubuntu"* ]]; then
        wait_apt_lock
        sudo apt-get update -y
        wait_apt_lock
        sudo apt-get install -y haproxy
    elif [[ $PLATFORM == *"rhel"* ]]; then
        sudo yum -y install haproxy
    fi
    setsebool -P haproxy_connect_any=1
    sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
	systemctl start haproxy
}

# Restart the HAProxy
function start_lb_server() {
    echo "Starting HAProxy"
    systemctl restart haproxy
}

# Identify the platform and version using Python
PLATFORM="unknown"
if command_exists python; then
    PLATFORM=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
    PLATFORM_VERSION=`python -c "import platform;print(platform.platform())" | rev | cut -d '-' -f2 | rev`
else
    if command_exists python3; then
        PLATFORM=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f3 | rev | tr -d '".' | tr '[:upper:]' '[:lower:]'`
        PLATFORM_VERSION=`python3 -c "import platform;print(platform.platform())" | rev | cut -d '-' -f2 | rev`
    fi
fi
if [[ $PLATFORM == *"redhat"* ]]; then
    PLATFORM="rhel"
fi
install_haproxy
cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg 
start_lb_server