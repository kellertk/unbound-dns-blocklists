# unbound-dns-blocklists
 Simple script to create pihole-like blocklists for Unbound DNS server

Installation
---
```bash
$ git clone https://github.com/kellertk/unbound-dns-blocklists.git && cd unbound-dns-blocklists
# mv get-dns-blocklists.sh /usr/local/bin
# chmod +x /usr/local/bin/get-dns-blocklists.sh
# mv get-dns-blocklists.{timer,service} /etc/systemd/system
# systemctl enable get-dns-blocklists.timer
```

Run it
---
It will run every day if you set the timer, otherwise
```bash
# systemctl start get-dns-blocklists.service
```

License
---
CC0
