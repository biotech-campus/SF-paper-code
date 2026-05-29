#!/bin/bash

CSV=$(realpath "$1")
DEPEND=$2

CLUSTERCPUS=23
CLUSTERMEMORY=32

SING_DIR="/mnt/Storage/software/containers/singularity"

if [[ -n $DEPEND ]] ; then
  DEPEND_STRING="--dependency afterok:$DEPEND"
fi

for SAMPLE in $(grep germline "$CSV" | cut -d, -f2 | sort | uniq); do
  PROJECT_ID="${SAMPLE:0:6}"
  OUTPUTDIR="/mnt/Storage/results/$PROJECT_ID"

  if [[ ! -d "$OUTPUTDIR/$SAMPLE/Variation" ]] ; then
    mkdir "$OUTPUTDIR/$SAMPLE/Variation"
  fi
  if [[ ! -d "$OUTPUTDIR/$SAMPLE/Logs" ]] ; then
    mkdir "$OUTPUTDIR/$SAMPLE/Logs"
  fi

  echo "Submit $SAMPLE DeepVariant"

  DV_JOB=$(
    echo -e "#!/bin/bash\n" \
    singularity run --nv \
      --bind /mnt/Storage/bd/reference:/reference:ro \
      --bind "$OUTPUTDIR/$SAMPLE:/outputdir" \
      --workdir /outputdir \
      "$SING_DIR/parabricks_4.0.0.sif" \
        pbrun deepvariant \
        --ref /reference/GRCh38.d1.vd1.fa \
        --disable-use-window-selector-model \
        --normalize-reads \
        --track-ref-reads \
        --min-mapping-quality 10 \
        --gvcf \
        --in-bam "/outputdir/Alignments/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.bam" \
        --out-variants "/outputdir/Variation/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.DeepVariant.g.vcf.gz" |
    sbatch --parsable --job-name "deepvariant-$SAMPLE" \
      --mem ${CLUSTERMEMORY}G --cpus-per-task $CLUSTERCPUS \
      --time 24:00:00 \
      -o "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.deepvariant.out" \
      -e "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.deepvariant.err" \
      --partition GPU --gres=gpu:1 \
      $DEPEND_STRING
  )

  echo -e "#!/bin/bash\n" \
  touch "$OUTPUTDIR/$SAMPLE/shortvariation.done\n" \
  singularity run \
    --bind "$OUTPUTDIR/$SAMPLE/Variation:/outputdir" \
    --workdir /outputdir \
    "$SING_DIR/mgi_latest.sif" \
      tabix --force --preset vcf "/outputdir/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.DeepVariant.g.vcf.gz" |
  sbatch --parsable --job-name "deepvariant-ok-$SAMPLE" \
    --mem 1G --cpus-per-task 1 \
    --time 10:00 \
    -o /dev/null -e /dev/null \
    --partition CPU,GPU \
    --dependency="afterok:$DV_JOB" > /dev/null
done
