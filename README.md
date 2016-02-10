# bash_scripts
Just a collection of down and dirty bash scripts I have written, or tweaked for my own use. You may find some of the helpful. 


### nginxS.sh
This still need work, but basically is an attempt to replicate the apachectl -S functionality with Nginx in that it gives you the domains and port information in the configuration.  Still needs some work, but works on most standard setups. 


### vhosts.sh
Script that will take 3 arguments: -d <domain.com> -r </document/root/> -p <port number> and will created the virtual host for you, most of the script was written by Lindsey Anderson and more info on it can be found on justcurl.com, I only tweaked it to be used locally as a script that will take arguments.  

Has been updated to accomidate Ubuntu 14, which now decided to have it's virtual host files end in .conf...

####usage
<code> bash vhosts.sh -d $domain -r $docroot -p $port </code>

Obviously subsitute $domain, $docroot and $port with your actual information.

**NOTE: if no $docroot or $port are given, it will default to /var/www/vhosts/$domain and port 80**


### wpstack_deploy.sh

I have a couple WordPress sites set up using a particular stack:

Traffic--> Nginx (for static content, compression and caching) --> Varnish (moar cache!) --> Apache (for only the thgings we must bother Apache for/mod_php)

I have seen great results with this for WordPress used with W3 Total cache to integrate Varnish purging and Memcached. This script only deploys the Web stack for now and does not have arguments for now. 


