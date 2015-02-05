#!/bin/bash
set -o nounset
set -o errexit
shopt -s expand_aliases
############## Utilities ##############
source utils.sh
#######################################
log_msg "Installing SOAPlib Commandline Wrapper dependencies"
pkgupdate
pkginstall python-pip python-dev python-lxml
sudo pip install -r requirements.txt
#######################################
log_msg "Installing CellML Simulator"
take_dir ../vendors
download https://cellml-simulator.googlecode.com/files/CSim-0.4.3-Linux.tar.gz
extract CSim-0.4.3-Linux.tar.gz
cd ..
#######################################
log "Configure SOAPLib to autostart"
sudo cat initd.cellmlsimulator > /etc/init.d/cellmlsimulator
sudo chmod +x /etc/init.d/cellmlsimulator
sudo update-rc.d cellmlsimulator defaults
#######################################
log "Starting application"
sudo service cellmlsimulator start
#######################################
log "Cleaning up..."
pkgclean
pkgautoremove
history -c
#######################################
