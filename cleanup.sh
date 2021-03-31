#!/bin/bash
# Script for cleaning up the mess from the bvc.sh scripts.
# 
for i in $( 'ls' projects/ ); do
    sudo groupdel $i
    echo -e "Group: $i removed"
done
rm -r projects/
rm ~/.bvc/.editor.txt