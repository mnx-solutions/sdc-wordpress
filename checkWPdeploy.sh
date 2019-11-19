#!/bin/bash
# FIle should be added here to the below location
# /var/zoneinit/includes/30-checkWPdeploy.sh

if [[ $(mdata-get MWPinstall) == "yes" ]]; then
	mkdir -p /root/sdc-wordpress
	cd /root/sdc-wordpress
	curl -s -o 'wpDeploy.sh' 'https://raw.githubusercontent.com/mnx-solutions/sdc-wordpress/master/wpDeploy.sh'
	chmod +x './wpDeploy.sh'
	bash -x './wpDeploy.sh'
else
	echo "mdata to MWPinstall not set to yes"
fi
