#!/bin/bash

set -o errexit -o pipefail -o nounset

export ARGUMENTS_ARR=("$@")
export MEMORY=${1}
export THREADS=${2}
export OUT_BAM=${3}
export IN_BAM_LIST=${ARGUMENTS_ARR[@]:3}

if [ -z ${IN_BAM_LIST+x} ]; then echo "IN_BAM_LIST is unset"; exit; else echo "IN_BAM_LIST: ${IN_BAM_LIST}"; fi
if [ -z ${OUT_BAM+x} ]; then echo "OUT_BAM is unset"; exit; else echo "OUT_BAM: ${OUT_BAM}"; fi
if [ -z ${THREADS+x} ]; then echo "THREADS is unset"; exit; else echo "THREADS: ${THREADS}"; fi
if [ -z ${MEMORY+x} ]; then echo "MEMORY is unset"; exit; else echo "MEMORY: ${MEMORY}"; fi

########################################################################################################################

function do_markdup() {
    java -Xmx${MEMORY}G -jar /opt/gatk.jar MarkDuplicatesSpark ${IN_BAM_LIST} -O ${OUT_BAM} --conf 'spark.executor.cores=${THREADS}' \
    --read-name-regex null --read-validation-stringency STRICT --create-output-bam-index True \
    --allow-multiple-sort-orders-in-input True
}

########################################################################################################################

do_markdup
