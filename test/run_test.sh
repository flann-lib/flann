#!/bin/bash


PROG=./aggnn

INPUT=data/sift100K.data
TEST=data/sift_test.data
MATCH=data/match100K.data
OUTPUT=results/kmeans100K
ALGO=kmeans
NN=1
BRANCHING=32
CHECKS=1:256



for br in `seq 2 64`; 
do
	echo "# algo dataset checks  nn branching" >> ${OUTPUT}_$br.dat
	echo "# $ALGO $DATASET $CHECKS $NN $br" >> ${OUTPUT}_$br.dat
	$PROG -a $ALGO -n $NN -c $CHECKS -i $INPUT -t $TEST -m $MATCH -b $br -v simple >> ${OUTPUT}_$br.dat
done