#!/usr/bin/env bash
set -uo pipefail

URL="https://v.firebog.net/hosts/lists.php?type=tick"

echo "$(date -Is) Getting list of blocklists" 
LISTS=$(/usr/bin/curl -s ${URL})
TMP=$(/usr/bin/mktemp)

echo "$(date -Is) Getting blocklist contents"
for i in ${LISTS}
do
        if curl -s $i | sed -e '/^[[:blank:]]*#/d' -re 's/^([0-9]\.){3}[0-9] //' -e '/./!d' -re 's/(.*)(#.*)/\1/' -e 's/^/local\-zone\: "/' -e 's/[[:alnum:]][[:blank:]]*$/" always_nxdomain/' >> $TMP
        then 
                echo "$(date -Is) Got ${i}"
        else
                echo "$(date -Is) ERROR getting ${i}"
        fi
done

if cp -f $TMP /etc/unbound/unbound.conf.d/blacklist.conf && rm $TMP
then
        echo "$(date -Is) Reconfigured unbound"
else
        echo "$(date -Is) ERROR reconfiguring unbound"
        exit 1
fi
if systemctl restart unbound
then
        echo "$(date -Is) Restarted DNS server"
else
        echo "$(date -Is) ERROR restarting DNS server!"
        exit 1
fi

exit 0
