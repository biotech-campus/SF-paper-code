#!/bin/bash

CSV=$(realpath "$1")

SING_DIR="/mnt/Storage/software/containers/singularity"

for SAMPLE in $(grep -v Pipeline "$CSV" | cut -d, -f2 | sort | uniq); do
  PROJECT_ID="${SAMPLE:0:6}"
  OUTPUTDIR="/mnt/Storage/results/$PROJECT_ID"

  if [[ ! -d "$OUTPUTDIR/$SAMPLE/Misc" ]] ; then
    mkdir "$OUTPUTDIR/$SAMPLE/Misc"
  fi
  if [[ ! -d "$OUTPUTDIR/$SAMPLE/Logs" ]] ; then
    mkdir "$OUTPUTDIR/$SAMPLE/Logs"
  fi

  BAM="$OUTPUTDIR/$SAMPLE/Alignments/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.bam"

  if [[ -e "$BAM" ]] ; then
    let CLUSTERMEMORY=200 # Big alignments apparently need this much

    if [[ ! -s "$OUTPUTDIR/$SAMPLE/Misc/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.CollectWGSMetrics.txt" ]] ; then
      echo "Submit $SAMPLE CollectWGSMetrics"
  
      echo -e "#!/bin/bash\n" \
      singularity run \
        --bind /mnt/Storage/bd/reference:/reference:ro \
        --bind "$OUTPUTDIR/$SAMPLE:/outputdir" \
        --workdir /outputdir \
        "$SING_DIR/parabricks_4.0.0.sif" pbrun bammetrics \
          --ref /reference/GRCh38.d1.vd1.fa \
          --bam "/outputdir/Alignments/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.bam" \
          --out-metrics-file "/outputdir/Misc/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.CollectWGSMetrics.txt" \
          --minimum-base-quality 20 \
          --minimum-mapping-quality 0 \
          --count-unpaired \
          --num-threads 8 |
      sbatch --parsable --job-name "bammetrics-$SAMPLE" \
        --mem ${CLUSTERMEMORY}G --cpus-per-task 13 \
        --time 2-0 \
        -o "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.bammetrics.out" \
        -e "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.bammetrics.err" \
        --partition CPU,GPU --nice
    fi
  
    if [[ ! -s "$OUTPUTDIR/$SAMPLE/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.CollectMultipleMetrics/alignment.txt" ]] &&
       [[ ! -s "$OUTPUTDIR/$SAMPLE/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.CollectMultipleMetrics/$SAMPLE.alignment_summary_metrics" ]] ; then 
      echo "Submit $SAMPLE CollectMultipleMetrics"
  
      CMM_JOB=$(
        echo -e "#!/bin/bash\n" \
        singularity run --nv \
          --bind /mnt/Storage/bd/reference:/reference:ro \
          --bind "$OUTPUTDIR/$SAMPLE:/outputdir" \
          --workdir /outputdir \
          "$SING_DIR/parabricks_4.0.0.sif" pbrun collectmultiplemetrics \
            --ref /reference/GRCh38.d1.vd1.fa \
            --bam "/outputdir/Alignments/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.bam" \
            --out-qc-metrics-dir "/outputdir/Misc/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.CollectMultipleMetrics" \
            --gen-all-metrics |
        sbatch --parsable --job-name "collectmultiplemetrics-$SAMPLE" \
          --mem 32G --cpus-per-task 7 \
          --time 6:00:00 \
          -o "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.collectmultiplemetrics.out" \
          -e "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.collectmultiplemetrics.err" \
          --partition GPU --gres=gpu:1
      )
    
      echo "Submit $SAMPLE CollectMultipleMetrics-GATK, depends on $CMM_JOB-fail"
      echo -e "#!/bin/bash\n" \
      singularity run \
        --bind /mnt/Storage/bd/reference:/reference:ro \
        --bind "$OUTPUTDIR/$SAMPLE:/outputdir" \
        --workdir /outputdir \
        "$SING_DIR/bgi_0.3.sif" java -jar /opt/gatk.jar CollectMultipleMetrics \
          --REFERENCE_SEQUENCE /reference/GRCh38.d1.vd1.fa \
          -I "/outputdir/Alignments/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.bam" \
          -O "/outputdir/Misc/$SAMPLE.MGI.cutadapt.bwa.MarkDuplicates.CollectMultipleMetrics/$SAMPLE" \
          --PROGRAM CollectAlignmentSummaryMetrics \
          --PROGRAM CollectInsertSizeMetrics \
          --PROGRAM CollectBaseDistributionByCycle \
          --PROGRAM CollectGcBiasMetrics \
          --PROGRAM CollectSequencingArtifactMetrics \
          --PROGRAM CollectQualityYieldMetrics \
          --PROGRAM MeanQualityByCycle \
          --PROGRAM QualityScoreDistribution |
      sbatch --parsable --job-name "collectmultiplemetrics-gatk-$SAMPLE" \
        --mem 4G --cpus-per-task 1 \
        --time 24:00:00 \
        -o "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.collectmultiplemetrics-gatk.out" \
        -e "$OUTPUTDIR/$SAMPLE/Logs/$SAMPLE.collectmultiplemetrics-gatk.err" \
        --partition CPU,GPU --nice \
        --kill-on-invalid-dep=yes --dependency "afternotok:$CMM_JOB" --nice
    fi
  fi
done
