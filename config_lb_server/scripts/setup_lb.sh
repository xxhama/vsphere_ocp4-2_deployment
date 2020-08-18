#!/bin/bash

# Install the HAProxy, depending upon the platform
function install_haproxy() {
    echo "Installing HAProxy"
    yum -y install haproxy
    setsebool -P haproxy_connect_any=1
    cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
	systemctl start haproxy
}

# Restart the HAProxy
function start_lb_server() {
    echo "Starting HAProxy"
    systemctl restart haproxy
}

install_haproxy
cp /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg 
start_lb_server