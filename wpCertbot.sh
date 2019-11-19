#!/bin/bash
# Nick Leffler
# Deploy certbot v1

changeSSL () {
# replace data in nginx conf for certbot
sed -i 's#ssl_certificate /opt/local/etc/nginx/ssl/${siteURL}/crt;#ssl_certificate /opt/local/etc/acme/fullchain.pem;#g' "/opt/local/etc/nginx/vhosts/${siteURL}.conf"
sed -i 's#ssl_certificate_key /opt/local/etc/nginx/ssl/${siteURL}/key;#ssl_certificate_key /opt/local/etc/acme/domain.key;#g' "/opt/local/etc/nginx/vhosts/${siteURL}.conf"
#sed -i '#ssl_dhparam dhparam.pem;/ssl_dhparam dhparam.pem;/g' "/opt/local/etc/nginx/vhosts/${siteURL}.conf"
}

doIt () {

# get siteURL
siteURL=$(mdata-get MsiteURL)

# install deps
pkgin -y in py36-acme-tiny

# make certbox dir
mkdir -p /opt/local/etc/acme /opt/local/www/acme

cd /opt/local/etc/acme || exit

# generate keys
openssl genrsa 4096 > account.key
openssl genrsa 4096 > domain.key

# generate csr
openssl req -new -sha256 -key domain.key -subj "/CN=${siteURL}" > domain.csr

# get cert from certbox
acme_tiny   --account-key /opt/local/etc/acme/account.key --csr /opt/local/etc/acme/domain.csr --acme-dir /opt/local/www/acme > /opt/local/etc/acme/signed.crt
curl -s 'https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem' > /opt/local/etc/acme/intermediate.pem

# create full cert
cat /opt/local/etc/acme/signed.crt /opt/local/etc/acme/intermediate.pem > /opt/local/etc/acme/fullchain.pem

# generate dhparam THIS WILL TAKE FOREVER
openssl dhparam 4096 > /opt/local/etc/nginx/dhparam.pem

changeSSL

# reload nginx
nginx -s reload
}

makeRenew () {
cat > /opt/local/etc/acme/renew.sh <<EOF
#!/bin/bash
acme_tiny --account-key /opt/local/etc/acme/account.key --csr /opt/local/etc/acme/domain.csr --acme-dir /opt/local/www/acme > /opt/local/etc/acme/signed.crt
curl -s 'https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem' > /opt/local/etc/acme/intermediate.pem
cat /opt/local/etc/acme/signed.crt /opt/local/etc/acme/intermediate.pem > /opt/local/etc/acme/fullchain.pem
cp fullchain.pem /opt/local/etc/nginx/ssl/fullchain.pem 
nginx -s reload
EOF

chmod +x /opt/local/etc/acme/renew.sh

crontab -l > /root/sdc-wordpress/cron
echo "5 5 * * * root /opt/local/etc/acme/renew.sh" >> /root/sdc-wordpress/cron
crontab /root/sdc-wordpress/cron
}


removeCron () {
#rm -f /etc/cron.d/crontabs/wpCertbot
crontab -l > /root/sdc-wordpress/cron
sed -i 's#0,15,30,45 \* \* \* \* root /root/sdc-wordpress/wpCertbot.sh##g' /root/sdc-wordpress/cron
crontab /root/sdc-wordpress/cron
}

##########################################################################
#                                                                        #
#                           START HERE #
#                                                                        #
##########################################################################

if [[ $(mdata-get McbReady) == "yes" ]]; then
	doIt
	removeCron
	echo "DONE: $(date +'%Y%m%d_%H%M')" >> /root/sdc-wordpress/certbot.log
else
	echo "Not Done: $(date +'%Y%m%d_%H%M')" >> /root/sdc-wordpress/certbot.log
fi

