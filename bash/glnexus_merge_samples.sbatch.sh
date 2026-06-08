#!/bin/bash
#SBATCH --cpus-per-task 23
#SBATCH --mem 410G
#SBATCH --partition RAM,CPU,GPU,DEV
#SBATCH --time 100:00:00
#SBATCH -o /dev/null

### ARGS ###

GVCFLIST=$(realpath "$1")
OUTFILE=$(realpath "$2")
SPLIT_MULTI=$3

GVCFLIST_BASENAME=$(basename "$GVCFLIST" .gvcflist)
GVCFLIST_DIRNAME=$(dirname "$GVCFLIST")

OUT_DIRNAME=$(dirname "$OUTFILE")

if [[ -z $SPLIT_MULTI ]]; then
  MULTI_ARG="--multiallelics -both"
else
  MULTI_ARG=""
fi


### DIRS ###

SINGULARITY_IMAGES="/mnt/Storage/software/containers/singularity"

TMP_DIR="/tmp/$(whoami)-glnexus-$GVCFLIST_BASENAME"
if [[ -d "$TMP_DIR" ]] ; then
  rm -rf "$TMP_DIR"
fi
# Remove temp if script is interrupted or exited
trap "rm -rf '$TMP_DIR'" EXIT

FASTA_REF="/mnt/Storage/databases/reference/GRCh38.d1.vd1.fa"
FASTA_DIR=$(dirname "$FASTA_REF")

BIND_STR="--bind /mnt/Storage/results:/mnt/Storage/results:ro"
BIND_STR="${BIND_STR} --bind ${FASTA_DIR}:${FASTA_DIR}:ro"
BIND_STR="${BIND_STR} --bind ${OUT_DIRNAME}:${OUT_DIRNAME}:rw'"
if [[ "$GVCFLIST_DIRNAME" != "$OUT_DIRNAME" ]]; then
  BIND_STR="${BIND_STR} --bind ${GVCFLIST_DIRNAME}:${GVCFLIST_DIRNAME}:ro"
fi


### MAIN ###

# nice as it requests just 23 cores from slurm but actually wants 48
nice singularity run \
  ${BIND_STR} \
  $SINGULARITY_IMAGES/glnexus_1.4.1.sif bash -c "
    glnexus_cli \
    --dir '$TMP_DIR' \
    --threads 48 --mem-gbytes 400 \
    --config DeepVariant \
    --list '$GVCFLIST' |
    bcftools norm       -O u --fasta-ref '$FASTA_REF' $MULTI_ARG |
    bcftools filter     -O u --set-GTs . -i 'FORMAT/GQ>15 & FORMAT/DP>10' |
    bcftools +fill-tags -O u | 
    bcftools view       -O b -o '$OUTFILE' &&
    bcftools index '$OUTFILE' "
