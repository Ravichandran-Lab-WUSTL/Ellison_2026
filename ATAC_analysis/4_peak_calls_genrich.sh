#BSUB -G compute-ccdg
#BSUB -q ccdg
#BSUB -n 1
#BSUB -a "docker(pl92297/atac)"
#BSUB -J "l.paullee atac SAMP"  
#BSUB -e error/genrich_SAMP.err 
#BSUB -o out/genrich_SAMP.out
#BSUB -M 50GB
#BSUB -R 'select[mem>50GB] rusage[mem=50GB] span[hosts=1]'

# Step 4: peak calling with Genrich.
# Both replicates of a condition/day are called together (-t rep1,rep2): Genrich scores each
# replicate and combines their p-values into one peak set. -j runs ATAC-seq mode, which
# builds intervals around Tn5 cut sites instead of using whole fragments. Peaks: q < 0.05.
# SAMP is "<rep1>,<rep2>" (two sample numbers); the output name comes from sample_names.txt
# (columns: sample number, sample name, day).
# Input:  bams/<rep>.blacklist-filtered.bam (from step 2), sorted by read name
# Output: results/peaks/<name>_<day>.genrich.narrowPeak

atacpath="/ccdg/Active/analysis/l.paullee/Ravi_ATAC"

samp=SAMP
samp1=$(echo $samp | cut -d',' -f 1)
samp2=$(echo $samp | cut -d',' -f 2)
name=$(cat $atacpath/sample_names.txt | grep -w $samp1 | awk '{print $2 "_" $3}')

# Sort BAMs by read name (required by Genrich)
samtools sort -n -o $atacpath/bams/${samp1}.blacklist-filtered-sort-n.bam $atacpath/bams/${samp1}.blacklist-filtered.bam
samtools sort -n -o $atacpath/bams/${samp2}.blacklist-filtered-sort-n.bam $atacpath/bams/${samp2}.blacklist-filtered.bam

# Run Genrich in ATAC-seq mode on both replicates
Genrich -j -t $atacpath/bams/${samp1}.blacklist-filtered-sort-n.bam,$atacpath/bams/${samp2}.blacklist-filtered-sort-n.bam -q 0.05 -o $atacpath/results/peaks/${name}.genrich.narrowPeak