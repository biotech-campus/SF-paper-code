#!/bin/bash

set -o errexit -o pipefail -o nounset

export IN_FQ1=${1}
export IN_FQ2=${2}
export REFERENCE=${3}
export OUT_BAM=${4}
export OUT_BAI=${5}
export FLOWCELL=${6}
export LANE=${7}
export SAMPLE=${8}
export BARCODE=${9}
export THREADS=${10}
export MEMORY=${11}

if [ -z ${IN_FQ1+x} ]; then echo "IN_FQ1 is unset"; exit; else echo "IN_FQ1: ${IN_FQ1}"; fi
if [ -z ${IN_FQ2+x} ]; then echo "IN_FQ2 is unset"; exit; else echo "IN_FQ2: ${IN_FQ2}"; fi
if [ -z ${REFERENCE+x} ]; then echo "REFERENCE is unset"; exit; else echo "REFERENCE: ${REFERENCE}"; fi
if [ -z ${OUT_BAM+x} ]; then echo "OUT_BAM is unset"; exit; else echo "OUT_BAM: ${OUT_BAM}"; fi
if [ -z ${OUT_BAI+x} ]; then echo "OUT_BAI is unset"; exit; else echo "OUT_BAI: ${OUT_BAI}"; fi
if [ -z ${FLOWCELL+x} ]; then echo "FLOWCELL is unset"; exit; else echo "FLOWCELL: ${FLOWCELL}"; fi
if [ -z ${LANE+x} ]; then echo "LANE is unset"; exit; else echo "LANE: ${LANE}"; fi
if [ -z ${SAMPLE+x} ]; then echo "SAMPLE is unset"; exit; else echo "SAMPLE: ${SAMPLE}"; fi
if [ -z ${BARCODE+x} ]; then echo "BARCODE is unset"; exit; else echo "BARCODE: ${BARCODE}"; fi
if [ -z ${THREADS+x} ]; then echo "THREADS is unset"; exit; else echo "THREADS: ${THREADS}"; fi
if [ -z ${MEMORY+x} ]; then echo "MEMORY is unset"; exit; else echo "MEMORY: ${MEMORY}"; fi

export ADD_THREADS=$((THREADS - 1))
export MPT=$(awk -v THREADS=${THREADS} -v MEMORY=${MEMORY} 'BEGIN {print (int(2^10 * MEMORY / THREADS - 2^9 - 2^8))"M"}')
# for example, if THREADS="6" and MEMORY="24", then MPT="3328M", because 3328 = 4096 - 512 - 256 = 2^10 * 4 - 2^9 - 2^8
# MPT (Memory Per Thread) should not be measured in G (gigabytes) because there will be a memory allocation error otherwise

if [ -z ${ADD_THREADS+x} ]; then echo "ADD_THREADS is unset"; exit; else echo "ADD_THREADS: ${ADD_THREADS}"; fi
if [ -z ${MPT+x} ]; then echo "MPT is unset"; exit; else echo "MPT: ${MPT}"; fi

########################################################################################################################

function do_unpack() {
    paste <(zcat ${IN_FQ1}) <(zcat ${IN_FQ2}) | \
    paste - - - - | awk -v FS="\t" -v OFS="\n" '{print $1, $3, $5, $7, $2, $4, $6, $8}'
}

function do_cutadapt() {
    # remove low-quality read ends and BGI adapters
    cutadapt --cores ${THREADS} --trim-n --quality-cutoff 30,30 \
    -a AAGTCGGAGGCCAA -a TTGGCCTCCGACTT -A AAGTCGGATCGTAG \
    -g CTACGATCCGACTT -G CTACGATCCGACTT -G TTGGCCTCCGACTT \
    --error-rate 0.1 --times 99 --minimum-length 0 --pair-filter both --interleaved /dev/stdin | \
    awk '{if (length($0) == 0) {if (NR % 4 == 2) print "N"; if (NR % 4 == 0) print "#"} else print $0}'
}

# old format 
# -R "@RG\\tID:${FLOWCELL}_${LANE}_${SAMPLE}_${LIBRARY}\\tPL:DNBSEQ\\tPU:${FLOW_CELL}_${LANE}\\tSM:${SAMPLE}\\tLB:${LIBRARY}" \
# TODO: change everywhere in old bams 

function do_bwa_interleaved() {
    # -k 30 to filter admixtures
    # -K 100000000 to achieve deterministic alignment results
    # -Y to force soft-clipping rather than default hard-clipping of supplementary alignments
    bwa mem -t ${THREADS} -k 30 -K 100000000 -Y \
    -R "@RG\\tID:${SAMPLE}.MGI.${FLOWCELL}_${LANE}_${BARCODE}\\tPL:MGI\\tPU:${FLOWCELL}_${LANE}_${BARCODE}\\tSM:${SAMPLE}\\tLB:library1\\tPM:DNBSEQ" \
    -p ${REFERENCE} /dev/stdin
}

function do_samtools_sort() {
    samtools sort -@ ${ADD_THREADS} -m ${MPT} /dev/stdin -o ${OUT_BAM}
    samtools index -@ ${ADD_THREADS} ${OUT_BAM} ${OUT_BAI}
}

########################################################################################################################

do_unpack | do_cutadapt | do_bwa_interleaved | do_samtools_sort
