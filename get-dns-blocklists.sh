#!/usr/bin/env bash
set -uo pipefail

URL="https://v.firebog.net/hosts/lists.php?type=tick"

echo "$(date -Is) Getting list of blocklists" 
LISTS=$(/usr/bin/curl -s ${URL})

echo "$(date -Is) Got $(echo ${LISTS} | awk '{print NF}') lists"
echo "$(date -Is) Getting blocklist contents"

procs=()
names=()
tmps=()
for i in ${LISTS}
do
        procs+=("curl -s -f $i ")
        names+=("$i")
done
pids=()
for i in "${procs[@]}"
do
        TMP=$(/usr/bin/mktemp)
        tmps+=("$TMP")
        $i | sed -e '/^[[:blank:]]*#/d' -re 's/^([0-9]\.){3}[0-9] //' -e '/./!d' -e 's/\r//' -re 's/(.*)(#.*)/\1/' -e 's/^/local\-zone\: \"/' -e 's/\.$//' -e 's/[[:alnum:]][[:blank:]]*$/\" always_nxdomain/' >> $TMP &
        pids+=("$!")
done
while true
do
        for i in "${!pids[@]}"
        do
        pid="${pids[$i]}"
                ps --pid "$pid" > /dev/null
                if [ $? -ne 0 ]
                then
                        wait "$pid"
                        code="$?"
                        if [ "$code" -eq "0" ] 
                        then
                                echo "Got ${names[$i]}"
                        else
                                echo "ERROR getting ${names[$i]}, code ${code}, continuing"
                        fi
                        unset pids[$i]
                        unset names[$i]
                fi
        done
        if [ "${#pids[@]}" -eq 0 ]
        then
                break
        fi
        sleep 0.5
done
echo "$(date -Is) Concatenating results"
BIGTMP=$(/usr/bin/mktemp)
for i in "${tmps[@]}"
do
        cat $i >> $BIGTMP
        echo "" >> $BIGTMP
        rm $i
done

echo "$(date -Is) Sorting and deduping"
if sort $BIGTMP | uniq -u > /etc/unbound/unbound.conf.d/blacklist.conf && rm $BIGTMP
then
        echo "$(date -Is) Reconfigured unbound"
        if systemctl restart unbound
        then
                echo "$(date -Is) Restarted DNS server"
        else
                echo "$(date -Is) ERROR restarting DNS server!"
               exit 1
       fi
else
        echo "$(date -Is) ERROR reconfiguring unbound"
        exit 1
fi

exit 0