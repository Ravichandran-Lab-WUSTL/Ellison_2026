#BSUB -G compute-ccdg
#BSUB -q ccdg
#BSUB -n 1
#BSUB -a "docker(pl92297/atac)"
#BSUB -J "l.paullee atac SAMP"  
#BSUB -e error/merge_SAMP.err 
#BSUB -o out/merge_SAMP.out
#BSUB -M 50GB
#BSUB -R 'select[mem>50GB] rusage[mem=50GB] span[hosts=1]'

# Step 5: build a consensus peak set for each condition and day.
# Overlapping Genrich peaks are merged with bedops, then converted to SAF format for featureCounts.
# Output: results/peaks/<condition>_<day>.merge.bed and <condition>_<day>.merge.saf

atacpath="/ccdg/Active/analysis/l.paullee/Ravi_ATAC"
cd $atacpath/results/peaks

# Merge overlapping peaks for each condition and day
for times in d_0 d_1 d_2
do
for conditions in cre svf
do
bedops --merge ${conditions}_*${times}.genrich.narrowPeak > ${conditions}_${times}.merge.bed
# Convert to SAF (GeneID, Chr, Start, End, Strand). SAF starts are 1-based, so BED start + 1;
# the peak ID is chr.start.end
awk 'OFS="\t" {print $1"."$2+1"."$3, $1, $2+1, $3, "."}' ${conditions}_${times}.merge.bed > ${conditions}_${times}.merge.saf
done
done

