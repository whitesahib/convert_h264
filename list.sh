#!/bin/bash

# List v 3.9.2

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

find $(pwd) -name '*.avi' -o -name '*.AVI' -o -name '*.VOB' -o -name '*.vob' -o -name '*.ts' -o -name '*.TS' -o -name '*.webm' -o -name '*.WEBM' -o -name '*.mkv' -o -name '*.MKV' -o -name '*.mpg' -o -name '*.MPG' -o -name '*.wmv' -o -name '*.WMV' -o -name '*.rmvb' -o -name '*.RMVB' -o -name '*.mov' -o -name '*.MOV'> list.txt

IFS=$SAVEIFS
