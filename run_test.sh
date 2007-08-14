#!/bin/bash


PROG=./aggnn

DATASET=data/sift100K.nn
OUTPUT=kmeans100K.out
ALGO=kmeans
NN=1
BRANCHING=32
CHECKS=2:256

echo "# algo dataset checks  nn branching" > $OUTPUT
echo "# $ALGO $DATASET $CHECKS $NN $BRANCHING" >> $OUTPUT

$PROG -a $ALGO -n $NN -c $CHECKS -i $DATASET -b $BRANCHING -v simple >> $OUTPUT