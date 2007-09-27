#!/bin/bash


PROG=nn
TEST_NAME=$1
shift

function run_test()
{
	echo $@
	time $@ > ${OUTPUT_FILE}
}

DATASETS=$@

if [ -z "${DATASETS}" ];
then
	DATASETS=`cat datasets`
fi

for DATASET in ${DATASETS};
do
	INPUT=${DATASET}/features.dat
	TEST=${DATASET}/test.dat
	MATCH=${DATASET}/match.dat
	OUTPUT_DIR=${DATASET}/results-${TEST_NAME}/
	NN=1

	if [ ! -d ${OUTPUT_DIR} ] ;
	then
		mkdir ${OUTPUT_DIR}
	fi


	CHECKS=2,4,8,16,32,64,128,256,512,1024
	ALGO=kmeans
	for BR in 2 8 16 32 64 128 256 512 1024; 
	do
		OUTPUT_FILE=${OUTPUT_DIR}/${ALGO}_${BR}.dat
		run_test ${PROG} -a ${ALGO} -n ${NN} -c ${CHECKS} -i ${INPUT} -t ${TEST} -m ${MATCH} -b ${BR} -M 1 -v simple
	done



	CHECKS=2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768
	ALGO=kdtree
	for TR in 1 4 10 16 32; 
	do
		OUTPUT_FILE=${OUTPUT_DIR}/${ALGO}_${TR}.dat
		run_test ${PROG} -a ${ALGO} -n ${NN} -c ${CHECKS} -i ${INPUT} -t ${TEST} -m ${MATCH} -r ${TR} -v simple
	done

done
