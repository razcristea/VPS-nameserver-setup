# VPS-nameserver-setup
How to setup own nameservers for your domain on a debian VPS.

## Install bind and DNS utils

After you SSH into server, run
```
apt-get install bind9 dnsutils
```
in order to install [bind9](https://www.isc.org/bind/) and DNS utils

## Define zones

Go to `/etc/bind`
```
cd /etc/bind
```
and create a new folder where we will put the DNS zone files, and create a new file for your domain (replace _mydomain.com_ with your own domain name):
```
mkdir -p zones
cd zones
nano db.mydomain.com
```

Inside this file, you should put those lines (make shure to replace _84.1.159.27_ with the ip of your VPS):
```
;
; BIND data file for mydomain.com
;
$TTL    3h
@       IN      SOA     ns1.mydomain.com. admin.mydomain.com. (
                          1        ; Serial
                          3h       ; Refresh after 3 hours
                          1h       ; Retry after 1 hour
                          1w       ; Expire after 1 week
                          1h )     ; Negative caching TTL of 1 day
;
@       IN      NS      ns1.mydomain.com.
@       IN      NS      ns2.mydomain.com.
mydomain.com.    IN      MX      10      mydomain.com.
mydomain.com.    IN      A       84.1.159.27
ns1                     IN      A       84.1.159.27
ns2                     IN      A       84.1.159.27
www                     IN      CNAME   mydomain.com.
mail                    IN      A       84.1.159.27
ftp                     IN      CNAME   mydomain.com.

```
Where :
* SOA record stands for Start of Authority record - is a record that holds administrative record about the zone and zone transfers
* NS records are the two nameservers ns1 and ns2 for _mydomain.com_
* MX record stands for Mail eXchange record
* A record points the name to the IP
* CNAME record stands for Canonical NAME - this type of record always points to a domain name, never to an IP address.

## Optional step - reverse
Right now, our DNS server can resolve requests - mapping IP addresses to its hosts. But we can also add the functionality of resolving a host from an IP address. For that matter, we need to create a file that will store reverse data: `nano db.192.168.0` <- no need to change those values!
Inside this newly created file _db.192.168.0_ put those lines:
```
;
; BIND reverse data file for 0.168.192.in-addr.arpa
;
$TTL    604800
0.168.192.in-addr.arpa.      IN      SOA     ns1.mydomain.com. admin.mydomain.com. (
                          1         ; Serial
                          3h       ; Refresh after 3 hours
                          1h       ; Retry after 1 hour
                          1w       ; Expire after 1 week
                          1h )     ; Negative caching TTL of 1 day
;
0.168.192.in-addr.arpa.       IN      NS      ns1.mydomain.com.
0.168.192.in-addr.arpa.       IN      NS      ns2.mydomain.com.

10.0.168.192.in-addr.arpa.   IN      PTR     mydomain.com.
```
## Update bind configuration file

We should now create a new file, where we will declare the zones: `nano named.conf.local` and add those lines into it:
```
zone "mydomain.com" {
       type master;
       file "/etc/bind/zones/db.mydomain.com";
};

zone "0.168.192.in-addr.arpa" {
       type master;
       file "/etc/bind/zones/db.192.168.0";
};
```
We should also edit `named.conf.options` and declare a DNS forwarder (Google Public DNS located at 8.8.4.4 would be a good option). In order to do so, we have to find the lines:
```
// forwarders {
//      0.0.0.0;
// };
```
inside `named.conf.option`, and un-comment them, editing like so:
```
forwarders {
            8.8.4.4;
       };
```
## Test before starting process
Next step would be to start bind process, but first we should test the configuration using `named-checkconf` like so:
```
named-checkconf
named-checkzone mydomain.com /etc/bind/zones/db.mydomain.com
named-checkzone 0.168.192.in-addr.arpa /etc/bind/zones/db.192.168.0
```
and the output should look like that:
```
zone mydomain.com/IN: loaded serial 1
OK

zone 0.168.192.in-addr.arpa/IN: loaded serial 1
OK
```
For _named-checkconf_ we should see no output, and for checkzone commands OK should be returned.
At this point, we can safely start bind9 dns server:
```
 /etc/init.d/bind9 start
Starting domain name service...: bind9.
```

## Test configuration and wait for propagation

Inside the DNS utils there is a tool named `dig` that can help us test the configuration of our newly created nameserver. In order to do that, run those commands (make shure to replace the IP _84.1.159.27_ with your own VPS IP, and _mydomain.com_ with the name of your domain):
```
dig @84.1.159.27 www.mydomain.com

dig @84.1.159.27 -x 192.168.0.10
```
The first dig command will test host to IP resolving, and the second one - reverse, IP to host. The result might look like that:
```
; <<>> DiG 9.10.3-P4-Debian <<>> @84.1.159.27 -x 192.168.0.10
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR,

```
Where `status: NOERROR` is what we hope for.

DNS propagation can take up to 24 hours, so it might take some time before everything is fully operational. Depending of your ISP, you might expect delays so it's a good thing to check using also using a cellular data connection.
Meanwhile, you can visit `https://intodns.com/yourdomain.com` - an online tool that can confirm everything is ok. 





