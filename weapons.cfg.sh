#!/bin/sh
<qcsrc/server/w_all.qc perl -ne 'BEGIN{$i=230}/w_(.*?)\./ or+next;printf qq{alias weapon_%s "impulse %d"\n},$1,$i++;'
