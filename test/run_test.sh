#!/bin/bash


PROG=nn


function run_test()
{
	echo $@
	time $@ > $OUTPUT_FILE
}

for DATASET in $@;
do

#	DATASET=$1

	INPUT=$DATASET/features.dat
	TEST=$DATASET/test.dat
	MATCH=$DATASET/match.dat
	OUTPUT_DIR=$DATASET/results-`date +%Y%m%d%H%M%S`/
	NN=1
	CHECKS=2,4,8,16,32,64,128,256,512,1024


	if [ ! -d ${OUTPUT_DIR} ] ;
	then
		mkdir ${OUTPUT_DIR}
	fi

	ALGO=kmeans
	for br in 2 4 8 16 32 64 128 256; 
	do
		OUTPUT_FILE=$OUTPUT_DIR/${ALGO}_$br.dat
		run_test $PROG -a $ALGO -n $NN -c $CHECKS -i $INPUT -t $TEST -m $MATCH -b $br -v simple
	done



	ALGO=kdtree
	for tr in 1 4 10 16 32; 
	do
		OUTPUT_FILE=$OUTPUT_DIR/${ALGO}_$tr.dat
		run_test $PROG -a $ALGO -n $NN -c $CHECKS -i $INPUT -t $TEST -m $MATCH -r $tr -v simple
	done

done
