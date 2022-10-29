# Jarkom-Modul-2-ITB08-2022
## Anggota:
| Nama                      | NRP        |
|---------------------------|------------|
| Salsabila Briliana A. S.  | 5027201003 |
| Muhammad Rifqi Fernanda   | 5027201050 |
| Gilang Bayu Gumantara     | 5027201062 | 

## Soal 1 
---
WISE akan dijadikan sebagai DNS Master, Berlint akan dijadikan DNS Slave, dan Eden akan digunakan sebagai Web Server. Terdapat 2 Client yaitu SSS, dan Garden. Semua node terhubung pada router Ostania, sehingga dapat mengakses internet 
               gambar topologi
![image](https://user-images.githubusercontent.com/90242686/198825007-543a3982-aa4c-4592-91d2-1ccc5e830c0a.png)
---
##### Konfigurasi Ostania
```
auto eth0
iface eth0 inet dhcp

auto eth1
iface eth1 inet static
	address 192.218.1.1
	netmask 255.255.255.0

 auto eth2
 iface eth2 inet static
	address 192.218.2.1
	netmask 255.255.255.0

auto eth3
iface eth3 inet static
	address 192.218.3.1
	netmask 255.255.255.0
```
##### Konfigurasi SSS
```

SSS
auto eth0
iface eth0 inet static
	address 192.218.1.2
	netmask 255.255.255.0
	gateway 192.218.1.1 
```
##### Konfigurasi Garden
auto eth0
iface eth0 inet static
	address 192.218.1.3
	netmask 255.255.255.0
	gateway 192.218.1.1
```
##### Konfigurasi Garden
auto eth0
iface eth0 inet static
	address 192.218.2.2
	netmask 255.255.255.0
	gateway 192.218.2.1
```
##### Konfigurasi Berlint
auto eth0
iface eth0 inet static
	address 192.218.3.2
	netmask 255.255.255.0
	gateway 192.218.3.1
```


##### Konfigurasi Eden
auto eth0
iface eth0 inet static
	address 192.218.3.3
	netmask 255.255.255.0
	gateway 192.218.3.1

## Soal 4
---
Buat juga reverse domain untuk domain utama

### Solution
---
Server WISE
Edit file `/etc/bind/named.conf.local` 

```
zone "wise.itb08.com"{
        type master;
        file "/etc/bind/wise/wise.itb08.com";
};

zone "2.218.192.in-addr.arpa" {
        type master;
        file "/etc/bind/wise/2.218.192.in-addr.arpa";
};
```

Kemudian konfigurasi pada file `/etc/bind/wise/2.218.192.in-addr.arpa`

```
$TTL    604800
@       IN      SOA     wise.itb08.com. root.wise.itb08.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
2.218.192.in-addr.arpa.   IN      NS      wise.itb08.com.
2                       IN      PTR     wise.itb08.com.
```
Setelah itu, restart service bind9 dengan `service bind9 restart`

### Testing
---
- host -t PTR 192.218.2.2
![testing4](image/soal4/testing4.png)

## Soal 5
---
Agar dapat tetap dihubungi jika server WISE bermasalah, buatlah juga Berlint sebagai DNS Slave untuk domain utama.

### Solution
**Server WISE**
---
Pertama, konfigurasi pada file `/etc/bind/named.conf.local` untuk melakukan konfigurasi DNS Slave yang mengarah ke Berlint

```
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
```
Setelah itu, restart service bind9 dengan `service bind9 restart` 

**Server Berlint**
Lakukan konfigurasi pada file `/etc/bind/named.conf.local` 

```
zone "wise.itb08.com" {
    type slave;
    masters { 192.218.2.2; }; // Masukan IP WISE tanpa tanda petik
    file "/var/lib/bind/wise.itb08.com";
};
```
Setelah itu, restart service bind9 dengan `service bind9 restart` 

### Testing
---
- Stop service bind9 pada server WISE
![testing5a](image/soal5/testing5a.png)

- Ping dengan server SSS
![testing5b](image/soal5/testing5b.png)

## Soal 6
Karena banyak informasi dari Handler, buatlah subdomain yang khusus untuk operation yaitu operation.wise.yyy.com dengan alias www.operation.wise.yyy.com yang didelegasikan dari WISE ke Berlint dengan IP menuju ke Eden dalam folder operation.

### Solution
---
**Server WISE**
Melakukan konfigurasi pada `/etc/bind/wise/wise.itb08.com`

```
$TTL    604800
@       IN      SOA     wise.itb08.com. root.wise.itb08.com. (
                              2         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@             IN      NS      wise.itb08.com.
@             IN      A       192.218.2.2 ; IP WISE
@             IN      AAAA    ::1
www           IN      CNAME   wise.itb08.com.
eden          IN      A       192.218.3.3 ; IP Eden
www.eden      IN      CNAME   eden.wise.itb08.com.
ns1           IN      A       192.218.3.2 ; IP Berlint
operation     IN      NS      ns1
www.operation IN      CNAME   wise.itb08.com.
```

Kemudian melakukan konfigurasi option pada `/etc/bind/named.conf.options`

```
options {
        directory \"/var/cache/bind\";
        allow-query{any;};
        auth-nxdomain no;    # conform to RFC1035
        listen-on-v6 { any; };
};
```

Selanjutnya, edit konfigurasi pada `/etc/bind/named.conf.local`

```
zone "wise.itb08.com"{
        type master;
 	    //notify yes;
        //also-notify { 192.218.3.2; };
        allow-transfer { 192.218.3.2; };
        file "/etc/bind/wise/wise.itb08.com";
};

zone "2.218.192.in-addr.arpa" {
        type master;
        file "/etc/bind/wise/2.218.192.in-addr.arpa";
};
```

Lakukan restart bind9 dengan `service bind9 restart`

**Server Berlint**
Edit file `/etc/bind/named.conf.options` dan comment `dnssec-validation auto;` lalu tambahkan `allow-query{any;};` pada file `/etc/bind/named.conf.options`

Kemudian edit file `/etc/bind/named.conf.local` untuk delegasi `operation.wise.yyy.com`

```
zone "wise.itb08.com" {
    type slave;
    masters { 192.218.2.2; }; 
    file "/var/lib/bind/wise.itb08.com";
};

zone "operation.wise.itb08.com" {
	type master;
	file "/etc/bind/operation/operation.wise.itb08.com";
};
```

Buat direktori `mkdir /etc/bind/operation` dan konfigurasi pada file `/etc/bind/operation/operation.wise.itb08.com`

```
$TTL    604800
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
```
Lalu restart service bind9 dengan `service bind9 restart`

### Testing
- ping operation.wise.itb08.com dan www.operation.wise.itb08.com
![testing6](image/soal6/testing6.png)
