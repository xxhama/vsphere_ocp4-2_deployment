#!/bin/bash
bootstrapIP=$1

IFS=',' read -a masterIParr <<< $2
echo masterIParr

IFS=',' read -a workerIParr <<< $3
echo workerIParr


function create_bootstrap_lb_endpoints() {
	API="    server bootstrap ${bootstrapIP}:6443 check"
	MCS="    server bootstrap ${bootstrapIP}:22623 check"
		sudo sed -i -e "s/@boot_6443@/${API}/" /etc/haproxy/haproxy.cfg
		sudo sed -i -e "s/@boot_22623@/${MCS}/" /etc/haproxy/haproxy.cfg
}

#Control Plane IP's
function create_control_lb_endpoints(){
    NUM_IPS=3
    for ((i=0; i < ${NUM_IPS}; i++)); do
        API="\ \ \ \ server control-plane-${i} ${masterIParr[i]}:6443 check"
        MCS="\ \ \ \ server control-plane-${i} ${masterIParr[i]}:22623 check"
        line="${masterIParr[i]}:6443 check"
        if grep -q "$line" /etc/haproxy/haproxy.cfg
        then 
        	echo "${API} and ${MCS} already added" 
        else 
        	echo "${API} and ${MCS} not found. Add ${API} and ${MCS}"        
        	LN=`sudo awk /^"backend api"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        	LN=$((LN + 2))
        	sudo sed -i -e "${LN} a ${API}" /etc/haproxy/haproxy.cfg
        	LN1=`sudo awk /^"backend machine-config"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        	LN1=$((LN1 + 2))
        	sudo sed -i -e "${LN1} a ${MCS}" /etc/haproxy/haproxy.cfg
    	fi
    done
}

#Compute IP's
function create_compute_lb_endpoints(){
    NUM_IPS=3
    for ((i=0; i < ${NUM_IPS}; i++)); do
        API="\ \ \ \ server compute-${i} ${workerIParr[i]}:80 check"
        MCS="\ \ \ \ server compute-${i} ${workerIParr[i]}:443 check"
        line="${workerIParr[i]}:80 check"
        if grep -q "$line" /etc/haproxy/haproxy.cfg
        then 
        	echo "${API} and ${MCS} already added"
        else
        	echo "${API} and ${MCS} not found. Add ${API} and ${MCS}"        
        	LN=`sudo awk /^"backend http"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        	LN=$((LN + 2))
        	sudo sed -i -e "${LN} a ${API}" /etc/haproxy/haproxy.cfg
        	LN1=`sudo awk /^"backend https"$/'{ print NR;exit }' /etc/haproxy/haproxy.cfg`
        	LN1=$((LN1 + 2))
        	sudo sed -i -e "${LN1} a ${MCS}" /etc/haproxy/haproxy.cfg
    	fi
    done
}

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
create_bootstrap_lb_endpoints
create_control_lb_endpoints
create_compute_lb_endpoints
cat /etc/haproxy/haproxy.cfg 
start_lb_server