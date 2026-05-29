#!/bin/bash

CSV=$(realpath "$1")

CPUS=24
MEMORY=96
CLUSTERCPUS=23

SING_DIR="/mnt/Storage/software/containers/singularity"


for SAMPLE in $(grep germline "$CSV" | cut -d, -f2 | sort | uniq); do
  PROJECT_ID="${SAMPLE:0:6}"
  INPUTDIR="/mnt/Storage/raw_mgi/$PROJECT_ID/raw_data"
  OUTPUTDIR="/mnt/Storage/results/$PROJECT_ID"

  if [[ ! -d "$OUTPUTDIR/$SAMPLE" ]]; then 
    mkdir -p "$OUTPUTDIR/$SAMPLE"/{Alignments,Logs,Temp,Misc}
  fi

  for BARCODE in $(grep ",${SAMPLE}," "$CSV" | cut -d, -f1); do 
    for FLOWCELL in $(ls "$INPUTDIR/$SAMPLE/" | grep -v .txt | cut -d_ -f1 | sort | uniq); do
      for LANE in $(ls "$INPUTDIR/$SAMPLE/" | grep "$FLOWCELL" | grep -v .txt | cut -d_ -f2); do
				SPFLB="${SAMPLE}.MGI.${FLOWCELL}_${LANE}_${BARCODE}"
				SFLB_FQ="${SAMPLE}-${FLOWCELL}_${LANE}_${BARCODE}"

        OUTPUT="/OUTPUT_DIR/${SFLB_FQ}_library1.MGI.cutadapt.bwa.bam"
        # OUTPUT="/OUTPUT_DIR/$SPFLB.cutadapt.bwa.bam"

        if [[ -e "$INPUTDIR/$SAMPLE/${FLOWCELL}_${LANE}/${SFLB_FQ}_1.fq.gz" ]]; then
          echo Sumbit "$SFLB_FQ" TrimMap

          echo -e "#!/bin/bash\n" singularity run \
            --bind /mnt/Storage/bd/reference:/reference:ro \
            --bind "$INPUTDIR:/inputdir:ro" \
            --bind "$OUTPUTDIR/$SAMPLE/Temp:/outputdir" \
            --workdir /outputdir \
            "$SING_DIR/trim_map_2.1.sif" \
              "/inputdir/$SAMPLE/${FLOWCELL}_${LANE}/${SFLB_FQ}"_{1,2}.fq.gz \
              /reference/GRCh38.d1.vd1.fa \
              "$OUTPUT" "$OUTPUT.bai" \
              "$FLOWCELL" "$LANE" "$SAMPLE" "$BARCODE" "$CPUS" "$MEMORY" |
            sbatch --parsable --job-name "MGI.trim-map-$SFLB_FQ" \
              --mem ${MEMORY}G --cpus-per-task $CLUSTERCPUS \
              --time 24:00:00 \
              -o "$OUTPUTDIR/$SAMPLE/Logs/$SFLB_FQ.trim-map.out" \
              -e "$OUTPUTDIR/$SAMPLE/Logs/$SFLB_FQ.trim-map.err" \
              --partition CPU,GPU 
        fi
      done
    done
  done
done
