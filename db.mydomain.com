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
