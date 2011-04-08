#!/bin/bash

DIR=`dirname $0`
uncrustify --no-backup -c ${DIR}/uncrustify.cfg  $1

