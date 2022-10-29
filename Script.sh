#!/bin/env bash

#Variabel
HOSTNAME=`hostname`
PREFIX="192.218"
DNS="192.168.122.1"
OSTANIA_e1_IP="$PREFIX.1.1"
OSTANIA_e2_IP="$PREFIX.2.1"
OSTANIA_e3_IP="$PREFIX.3.1"
SSS_IP="$PREFIX.1.2"
GARDEN_IP="$PREFIX.1.3"
WISE_IP="$PREFIX.2.2"
BERLINT_IP="$PREFIX.3.2"
EDEN_IP="$PREFIX.3.3"

#WISE
if [[ $HOSTNAME = "WISE" ]]; then
        echo nameserver $DNS > /etc/resolv.conf

        apt update
        apt install bind9 -y
        apt install dnsutils -y

## Konfigurasi zone untuk domain baru wise.itb08.com
        echo '
zone "wise.itb08.com"{
        type master;
        notify yes;
        also-notify { 192.218.3.2; };
        allow-transfer { 192.218.3.2; };
        file "/etc/bind/wise/wise.itb08.com";
};

zone "2.218.192.in-addr.arpa" {
        type master;
        file "/etc/bind/wise/2.218.192.in-addr.arpa";
};
' > /etc/bind/named.conf.local

## buat direktori wise
        mkdir -p /etc/bind/wise

## konfigurasi db lokal untuk wise.itb08.com
        echo "\
\$TTL    604800
@       IN      SOA     wise.itb08.com. root.wise.itb08.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@             IN      NS      wise.itb08.com.
@             IN      A       $WISE_IP ; IP WISE
@             IN      AAAA    ::1
www           IN      CNAME   wise.itb08.com.
eden          IN      A       $EDEN_IP ; IP Eden
www.eden      IN      CNAME   eden.wise.itb08.com
ns1           IN      A       192.218.3.2 ; IP Berlint
operation     IN      NS      ns1
www.operation IN      CNAME   wise.itb08.com
" > /etc/bind/wise/wise.itb08.com

## konfigurasi db lokal untuk reverse dns
        echo "\
\$TTL    604800
@       IN      SOA     wise.itb08.com. root.wise.itb08.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
2.218.192.in-addr.arpa.   IN      NS      wise.itb08.com.
2                       IN      PTR     wise.itb08.com.
" > /etc/bind/wise/2.218.192.in-addr.arpa

        echo "
options {
        directory \"/var/cache/bind\";
        allow-query{any;};
        auth-nxdomain no;    # conform to RFC1035
        listen-on-v6 { any; };
};
" >/etc/bind/named.conf.options

        service bind9 restart

# Berlint
elif [[ $HOSTNAME = "Berlint" ]]; then
        echo nameserver $DNS > /etc/resolv.conf

        apt update
        apt install bind9 -y
        apt install dnsutils -y

        echo '
zone "wise.itb08.com" {
    type slave;
    masters { 192.218.2.2; }; // Masukan IP WISE tanpa tanda petik
    file "/var/lib/bind/wise.itb08.com";
};

zone "operation.wise.itb08.com" {
        type master;
        file "/etc/bind/operation/operation.wise.itb08.com";
};
' > /etc/bind/named.conf.local

        echo "
options {
        directory \"/var/cache/bind\";
        allow-query{any;};
        auth-nxdomain no;    # conform to RFC1035
        listen-on-v6 { any; };
};
" > /etc/bind/named.conf.options

        mkdir -p /etc/bind/operation

        echo "\
\$TTL    604800
@       IN      SOA     operation.wise.itb08.com. root.operation.wise.itb08.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@          IN      NS      operation.wise.itb08.com.
@          IN      A       192.218.3.3 ; IP Eden
www        IN      CNAME   operation.wise.itb08.com.
strix      IN      A       192.218.3.3 ; IP Eden
www.strix  IN      CNAME   strix.operation.wise.itb08.com.
" > /etc/bind/operation/operation.wise.itb08.com

        service bind9 restart


# Eden
elif [[ $HOSTNAME = "Eden" ]]; then
        echo nameserver $DNS > /etc/resolv.conf

apt-get install apache2 -y
apt-get install php -y
apt-get install libapache2-mod-php7.0 -y
apt-get install wget -y
apt-get install unzip -y
apt-get install apache2-utils -y

mkdir /var/www/wise.itb08.com
wget "https://drive.google.com/uc?id=1S0XhL9ViYN7TyCj2W66BNEXQD2AAAw2e&export=download" -O wise.zip
unzip wise.zip
mv wise/* /var/www/wise.itb08.com
rm -r wise

echo "
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/wise.itb08.com
        ServerName wise.itb08.com
        ServerAlias www.wise.ITB10.com
        <Directory /var/www/wise.itb08.com/>
                Options +Indexes
        </Directory>
 
        Alias \"/home\" \"/var/www/wise.itb08.com/index.php/home\"
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" > /etc/apache2/sites-available/wise.itb08.com.conf

a2ensite wise.itb08.com
a2enmod rewrite
service apache2 restart


echo "
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/eden.wise.itb08.com
        ServerName eden.wise.itb08.com
        ServerAlias www.eden.wise.itb08.com
        <Directory /var/www/eden.wise.itb08.com/public>
                Options +Indexes
        </Directory>
        #<Directory /var/www/eden.wise.itb08.com/public/*>
        #        Options -Indexes
        #</Directory>
        Alias \"/js\" \"/var/www/eden.wise.itb08.com/public/js\"
        ErrorDocument 404 /error/404.html
        <Files \"/var/www/eden.wise.itb08.com/error/404.html\">
                <If \"-z %{ENV:REDIRECT_STATUS}\">
                        RedirectMatch 404 ^/error/404.html$
                </If>
        </Files>
         <Directory /var/www/eden.wise.itb08.com>
                Options +FollowSymLinks -Multiviews
                AllowOverride All
        </Directory>
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" > /etc/apache2/sites-available/eden.wise.itb08.com.conf

mkdir /var/www/eden.wise.itb08.com
wget "https://drive.google.com/uc?id=1q9g6nM85bW5T9f5yoyXtDqonUKKCHOTV&export=download" -O eden.wise.zip
unzip eden.wise.zip
mv eden.wise/* /var/www/eden.wise.itb08.com
rm -r eden.wise
echo '
RewriteEngine On
RewriteCond %{REQUEST_URI} !^/public/images/eden.png$
RewriteCond %{REQUEST_FILENAME} !-d 
RewriteRule ^(.*)eden(.*)$ /public/images/eden.png [R=301,L]
' > /var/www/eden.wise.itb08.com/.htaccess

a2ensite eden.wise.itb08.com

htpasswd -b -c /var/www/strix.operation.wise.itb08 Twilight opStrix

echo -e "Listen 15000 \nListen 15500" >> /etc/apache2/ports.conf

echo "
<VirtualHost *:15000 *:15500>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/strix.operation.wise.itb08.com
        ServerName strix.operation.wise.itb08.com
        ServerAlias www.strix.operation.wise.itb08.com
        <Directory \"/var/www/strix.operation.wise.itb08.com\">
                AuthType Basic
                AuthName \"Restricted Content\"
                AuthUserFile /var/www/strix.operation.wise.itb08
                Require valid-user
        </Directory>
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" > /etc/apache2/sites-available/strix.operation.wise.itb08.com.conf

mkdir /var/www/strix.operation.wise.itb08.com
wget "https://drive.google.com/uc?id=1bgd3B6VtDtVv2ouqyM8wLyZGzK5C9maT&export=download" -O operation.wise.zip
unzip operation.wise.zip
mv strix.operation.wise/* /var/www/strix.operation.wise.itb08.com
rm -r strix.operation.wise

a2ensite strix.operation.wise.itb08.com

echo "
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        redirect permanent / http://wise.itb08.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with \"a2disconf\".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" > /etc/apache2/sites-available/000-default.conf

service apache2 restart
# SSS
elif [[ $HOSTNAME = "SSS" ]]; then
        echo nameserver $WISE_IP > /etc/resolv.conf
        echo nameserver $DNS >> /etc/resolv.conf

apt update
apt install dnsutils -y
apt install lynx -y

# Garden
elif [[ $HOSTNAME = "Garden" ]]; then
        echo nameserver $WISE_IP > /etc/resolv.conf
        echo nameserver $DNS >> /etc/resolv.conf

apt update
apt install dnsutils -y
apt install lynx -y

fi

echo "nameserver 192.168.122.1" > /etc/resolv.conf 
apt-get install apache2 -y
apt-get install php -y
apt-get install libapache2-mod-php7.0 -y
apt-get install wget -y
apt-get install unzip -y
apt-get install apache2-utils -y

mkdir /var/www/wise.itb08.com
wget "https://drive.google.com/uc?id=1S0XhL9ViYN7TyCj2W66BNEXQD2AAAw2e&export=download" -O wise.zip
unzip wise.zip
mv wise/* /var/www/wise.itb08.com
rm -r wise

echo "
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/wise.itb08.com
        ServerName wise.itb08.com
        ServerAlias www.wise.itb08.com
        <Directory /var/www/wise.itb08.com/>
                Options +Indexes
        </Directory>
 
        Alias \"/home\" \"/var/www/wise.ITB10.com/index.php/home\"
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" > /etc/apache2/sites-available/wise.itb08.com.conf

a2ensite wise.itb08.com
a2enmod rewrite
service apache2 restart


echo "
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/eden.wise.itb08.com
        ServerName eden.wise.itb08.com
        ServerAlias www.eden.wise.itb08.com
        <Directory /var/www/eden.wise.itb08.com/public>
                Options +Indexes
        </Directory>
        #<Directory /var/www/eden.wise.ITB10.com/public/*>
        #        Options -Indexes
        #</Directory>
        Alias \"/js\" \"/var/www/eden.wise.itb08.com/public/js\"
        ErrorDocument 404 /error/404.html
        <Files \"/var/www/eden.wise.itb08.com/error/404.html\">
                <If \"-z %{ENV:REDIRECT_STATUS}\">
                        RedirectMatch 404 ^/error/404.html$
                </If>
        </Files>
         <Directory /var/www/eden.wise.itb08.com>
                Options +FollowSymLinks -Multiviews
                AllowOverride All
        </Directory>
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" > /etc/apache2/sites-available/eden.wise.itb08.com.conf

mkdir /var/www/eden.wise.itb08.com
wget "https://drive.google.com/uc?id=1q9g6nM85bW5T9f5yoyXtDqonUKKCHOTV&export=download" -O eden.wise.zip
unzip eden.wise.zip
mv eden.wise/* /var/www/eden.wise.itb08.com
rm -r eden.wise
echo '
RewriteEngine On
RewriteCond %{REQUEST_URI} !^/public/images/eden.png$
RewriteCond %{REQUEST_FILENAME} !-d 
RewriteRule ^(.*)franky(.*)$ /public/images/eden.png [R=301,L]
' > /var/www/eden.wise.itb08.com/.htaccess

a2ensite eden.wise.itb08.com

htpasswd -b -c /var/www/strix.operation.wise.itb08 Twilight opStrix

echo -e "Listen 15000 \nListen 15500" >> /etc/apache2/ports.conf

echo "
<VirtualHost *:15000 *:15500>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/strix.operation.wise.itb08.com
        ServerName strix.operation.wise.itb08.com
        ServerAlias www.strix.operation.wise.itb08.com
        <Directory \"/var/www/strix.operation.wise.itb08.com\">
                AuthType Basic
                AuthName \"Restricted Content\"
                AuthUserFile /var/www/strix.operation.wise.itb08
                Require valid-user
        </Directory>
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" > /etc/apache2/sites-available/strix.operation.wise.itb08.com.conf

mkdir /var/www/strix.operation.wise.itb08.com
wget "https://drive.google.com/uc?id=1bgd3B6VtDtVv2ouqyM8wLyZGzK5C9maT&export=download" -O operation.wise.zip
unzip operation.wise.zip
mv strix.operation.wise/* /var/www/strix.operation.wise.itb08.com
rm -r strix.operation.wise

a2ensite strix.operation.wise.itb08.com

echo "
<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        redirect permanent / http://wise.itb08.com
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with \"a2disconf\".
        #Include conf-available/serve-cgi-bin.conf
</VirtualHost>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
" > /etc/apache2/sites-available/000-default.conf

service apache2 restart