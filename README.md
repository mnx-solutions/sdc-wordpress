# installWP
Installs WordPress from nothing on smartOS.  

This installs and configures the following  
* NGINX  
* PHP-FPM  
* MySQL  
* WordPress  

Right now this can only do one site, but eventually I'd like to have it do more than one.  

MsiteName: site name  
MsiteTitle: site title  
MsiteProto: ssl for ssl don't include the variable if not ssl  
MsiteURL: site url minus the http/s://  
MWPinstall: do you want to run the install?  
McbReady: cerbot ready. If so it will install certbot and do all of the required things. I would leave this as is or don't put anything until DNS is pinted to your server  

This is an example to add into the internal metadata  
```
{
  "MsiteName": "testIT",
  "MsiteTitle": "testing",
  "MsiteProto": "ssl",
  "MsiteURL": "testing.com",
  "MWPinstall": "yes"
  "McbReady": "yes"
}
```
