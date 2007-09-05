#!/bin/bash


PROG=nn

DATASET=$1

INPUT=$DATASET/features.dat
TEST=$DATASET/test.dat
MATCH=$DATASET/match.dat
OUTPUT_DIR=$DATASET/results/
NN=1
CHECKS=2,4,8,16,32,64,128,256,512,1024


if [ ! -d ${OUTPUT_DIR} ] ;
then
	mkdir ${OUTPUT_DIR}
fi

ALGO=kmeans
for br in 2 4 8 16 32 64; 
do
	OUTPUT_FILE=$OUTPUT_DIR/${ALGO}_$br.dat
	echo ${OUTPUT_FILE}
	echo $PROG -a $ALGO -n $NN -c $CHECKS -i $INPUT -t $TEST -m $MATCH -b $br -v simple
	time $PROG -a $ALGO -n $NN -c $CHECKS -i $INPUT -t $TEST -m $MATCH -b $br -C gonzales -v simple > ${OUTPUT_FILE}
done



ALGO=kdtree
for tr in 1 4 10 16; 
do
	OUTPUT_FILE=$OUTPUT_DIR/${ALGO}_$tr.dat
	echo $PROG -a $ALGO -n $NN -c $CHECKS -i $INPUT -t $TEST -m $MATCH -r $tr -v simple
	time $PROG -a $ALGO -n $NN -c $CHECKS -i $INPUT -t $TEST -m $MATCH -r $tr -v simple > ${OUTPUT_FILE}
done
