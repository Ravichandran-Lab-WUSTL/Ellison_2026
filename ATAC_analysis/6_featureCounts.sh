#BSUB -G compute-ccdg
#BSUB -q ccdg
#BSUB -n 1
#BSUB -a "docker(pl92297/atac)"
#BSUB -J "l.paullee atac SAMP"  
#BSUB -e error/featurecounts_SAMP.err 
#BSUB -o out/featurecounts_SAMP.out
#BSUB -M 50GB
#BSUB -R 'select[mem>50GB] rusage[mem=50GB] span[hosts=1]'

# Step 6: count reads in consensus peaks with featureCounts.
# Loops over every sample in sample_names.txt (columns: sample number, sample name, day) and
# counts its reads in the merged peak set for its condition and day (from step 5).
#   -p           paired-end data
#   -F SAF       annotation is in SAF format
#   --ignoreDup  skip reads flagged as duplicates
#   -R BAM       also write per-read assignments
# Output: results/counts/<name>_<day>_<rep>_counts.txt

atacpath="/ccdg/Active/analysis/l.paullee/Ravi_ATAC"
cd $atacpath/results/peaks

readarray -t lines < "$atacpath/sample_names.txt"

for line in "${lines[@]}"
do
# Parse sample number, name, condition (first part of the name) and day
number=$(echo $line | awk '{print $1}')
name=$(echo $line | awk '{print $2}')
cond=$(echo $name | cut -d'_' -f 1)
day=$(echo $line | awk '{print $3}')
rep=1

# Replicate number: 2 if this name/day already has a replicate-1 counts file, otherwise 1
if [[ -e $atacpath/results/counts/${name}_${day}_1_counts.txt ]]; then
    rep=2
fi

# Log the sample being counted
echo $number
echo $name
echo $day
echo $cond
echo $rep

featureCounts -T 5 -p -F SAF --ignoreDup \
-a $atacpath/results/peaks/${cond}_${day}.merge.saf \
-o $atacpath/results/counts/${name}_${day}_${rep}_counts.txt \
-R BAM $atacpath/bams/${number}.blacklist-filtered.bam
done