#!/bin/bash

CSV=$(realpath "$1")

CPUS=48
#MEMORY=200
MEMORY=330 # huge samples will take >1T of /tmp so we can't allow parallel running of markdups on them
CLUSTERCPUS=43
#CLUSTERMEMORY=240
CLUSTERMEMORY=400

SING_DIR="/mnt/Storage/software/containers/singularity"

for SAMPLE in $(grep germline "$CSV" | cut -d, -f2 | sort | uniq); do
  PROJECT_ID="${SAMPLE:0:6}"
  OUTPUTDIR="/mnt/Storage/results/$PROJECT_ID"

  echo "Submit $SAMPLE MarkDuplicates"

  MD_JOB=$(
    echo -e "#!/bin/bash\n" \
      singularity run \
      --bind "$OUTPUTDIR/$SAMPLE:/outputdir" \
      --workdir /outputdir \
      "$SING_DIR/markdup_0.4.sif" \
        $MEMORY $CPUS \
        "/outputdir/Alignments/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.bam" \
        $( for FULLBAM in "$OUTPUTDIR/$SAMPLE"/Temp/*.bwa.bam; do
          BAM=$(basename "$FULLBAM"); echo " -I /outputdir/Temp/$BAM"
        done ) |
      sbatch --parsable --job-name "markdup-$SAMPLE" \
        --mem ${CLUSTERMEMORY}G --cpus-per-task $CLUSTERCPUS \
        --time 24:00:00 \
        -o "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.markdup.out" \
        -e "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.markdup.err" \
        --partition CPU,GPU --nice
  )

  echo -e "#!/bin/bash\n" \
  touch "$OUTPUTDIR/$SAMPLE/alignment.done" |
  sbatch --parsable --job-name "alignment-ok-$SAMPLE" \
    --mem 1M --cpus-per-task 1 \
    --time 1:00 \
    -o /dev/null -e /dev/null \
    --partition CPU,GPU \
    --dependency "afterok:$MD_JOB" > /dev/null
done
