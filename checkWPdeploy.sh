#!/bin/bash
# FIle should be added here to the below location
# /var/zoneinit/includes/30-checkWPdeploy.sh

if [[ $(mdata-get WPinstall) == "yes" ]]; then
	cd /root/
	curl -s -o 'wpDeploy.sh' 'https://raw.githubusercontent.com/mnxnick2/installWPnick/master/wpDeploy.sh'
	chmod './wpDeploy.sh'
	bash -x './wpDeploy.sh'
fi