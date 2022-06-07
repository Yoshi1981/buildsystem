#!/bin/bash

CURDIR=$1
DATETIME=_`date +%d.%m.%Y-%H.%M`
BOXTYPE=$2

gitversion="_NHD2$DATETIME"

echo "GITVERSION = $gitversion"
export gitversion
