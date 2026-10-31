#BSUB -G compute-ccdg
#BSUB -q ccdg
#BSUB -n 2
#BSUB -a "docker(pl92297/atac)"
#BSUB -J "l.paullee atac SAMP"  
#BSUB -e error/picard_SAMP.err 
#BSUB -o out/picard_SAMP.out
#BSUB -M 100GB
#BSUB -R 'select[mem>100GB] rusage[mem=100GB] span[hosts=1]'

# Step 2: read filtering.
#   - adds a read group (required by Picard)
#   - marks PCR duplicates with Picard MarkDuplicates
#   - keeps properly paired, non-duplicate reads with MAPQ >= 30
#   - removes reads overlapping the mm39 blacklist
# Input:  bams/<SAMP>.sorted.rmChrM.bam (from step 1)
# Output: bams/<SAMP>.blacklist-filtered.bam (+ .bai)

atacpath="/ccdg/Active/analysis/l.paullee/Ravi_ATAC"

samp=SAMP

# Optional: check whether the BAM already has a read group
#samtools view -H $atacpath/bams/${samp}.sorted.rmChrM.bam | grep '@RG' 

# Add a read group
samtools addreplacerg -r "@RG\tID:RGSAMP\tSM:SAMP\tPL:Illumina\tLB:Library.fa" -o $atacpath/bams/${samp}.sorted.rmChrM.reheader.bam $atacpath/bams/${samp}.sorted.rmChrM.bam

# Mark PCR duplicates (flagged here, removed in the next step)
/opt/java/openjdk/bin/java -jar /usr/picard/picard.jar MarkDuplicates QUIET=true INPUT=$atacpath/bams/${samp}.sorted.rmChrM.reheader.bam OUTPUT=$atacpath/bams/${samp}.marked.bam METRICS_FILE=$atacpath/bams/${samp}.dup.metrics REMOVE_DUPLICATES=false CREATE_INDEX=true VALIDATION_STRINGENCY=LENIENT TMP_DIR=.

# Keep properly paired reads (-f 2) with MAPQ >= 30 (-q 30), and drop reads that are
# unmapped (4), have an unmapped mate (8), fail QC (512) or are duplicates (1024): -F 1548
samtools view -h -b -f 2 -F 1548 -q 30 $atacpath/bams/${samp}.marked.bam | samtools sort -o $atacpath/bams/${samp}.sort.filtered.bam
samtools index $atacpath/bams/${samp}.sort.filtered.bam

#Remove reads within the blacklist regions
#mm39 blacklist: https://dev.bedbase.org/bed/67c08efd44d558f0aafbb1240e93a97a 
bedtools intersect -nonamecheck -v -abam $atacpath/bams/${samp}.sort.filtered.bam -b /ccdg/Active/analysis/l.paullee/genome_ref/mm39/mm39_exclude.bed > $atacpath/bams/${samp}.tmp.bam

#Sort and index the bam file
samtools sort -O bam -o $atacpath/bams/${samp}.blacklist-filtered.bam $atacpath/bams/${samp}.tmp.bam
samtools index $atacpath/bams/${samp}.blacklist-filtered.bam

# Remove the intermediate file
rm $atacpath/bams/${samp}.tmp.bam