#!/bin/sh

wget -N http://svn.icculus.org/*checkout*/twilight/trunk/dpmod/qc/dpextensions.qc
wget -N http://svn.icculus.org/*checkout*/nexuiz/trunk/data/qcsrc/server/extensions.qh
vimdiff dpextensions.qc extensions.qh qcsrc/server/extensions.qh
