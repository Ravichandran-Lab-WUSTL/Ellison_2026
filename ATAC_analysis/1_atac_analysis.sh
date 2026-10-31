#BSUB -G compute-ccdg
#BSUB -q ccdg
#BSUB -n 2
#BSUB -a "docker(pl92297/atac)"
#BSUB -J "l.paullee atac SAMP"  
#BSUB -e error/atac_SAMP.err 
#BSUB -o out/atac_SAMP.out
#BSUB -M 100GB
#BSUB -R 'select[mem>100GB] rusage[mem=100GB] span[hosts=1]'

# Step 1: preprocessing and alignment of paired-end ATAC-seq reads to mm39.
#   - merges the two sequencing lanes (L001, L002) for each read
#   - read QC with FastQC; adapter and quality trimming with fastp
#   - alignment with bowtie2, then sorting, indexing and alignment stats
#   - removal of mitochondrial (chrM) reads
# SAMP is replaced with the sample number when the job is submitted (sender.sh).
# Input:  atac_fastq/Ravichandran_<SAMP>_*_L00{1,2}_R{1,2}_001.fastq.gz
# Output: bams/<SAMP>.sorted.rmChrM.bam

atacpath="/ccdg/Active/analysis/l.paullee/Ravi_ATAC"

samp=SAMP

echo $samp
# Merge lanes L001 and L002 into one FASTQ per read (R1, R2)
cat $atacpath/atac_fastq/Ravichandran_${samp}_*_L001_R1_001.fastq.gz $atacpath/atac_fastq/Ravichandran_${samp}_*_L002_R1_001.fastq.gz > $atacpath/atac_fastq/Ravi_${samp}_R1.fastq.gz
cat $atacpath/atac_fastq/Ravichandran_${samp}_*_L001_R2_001.fastq.gz $atacpath/atac_fastq/Ravichandran_${samp}_*_L002_R2_001.fastq.gz > $atacpath/atac_fastq/Ravi_${samp}_R2.fastq.gz

# Read quality report
fastqc $atacpath/atac_fastq/Ravi_${samp}_R1.fastq.gz -o $atacpath/results/fastqc/
# Trim adapters (auto-detected for paired-end reads) and low-quality bases; writes JSON and HTML QC reports
~/../../fastp -i $atacpath/atac_fastq/Ravi_${samp}_R1.fastq.gz -I $atacpath/atac_fastq/Ravi_${samp}_R2.fastq.gz -o $atacpath/atac_fastq/Ravi_${samp}_R1.trimmed.fastq.gz -O $atacpath/atac_fastq/Ravi_${samp}_R2.trimmed.fastq.gz --detect_adapter_for_pe -j $atacpath/atac_fastq/${samp}.fastp.json -h $atacpath/atac_fastq/${samp}.fastp.html

# Align to mm39 with bowtie2 in local, very-sensitive mode.
# Only concordant pairs are kept (--no-mixed, --no-discordant), with fragment length 25-700 bp (-I, -X).
bt2idx="/ccdg/Active/analysis/l.paullee/genome_ref"
bowtie2 --local --very-sensitive --no-mixed --no-discordant -I 25 -X 700 -x $bt2idx/mm39/mm39 -1 $atacpath/atac_fastq/Ravi_${samp}_R1.trimmed.fastq.gz -2 $atacpath/atac_fastq/Ravi_${samp}_R2.trimmed.fastq.gz | samtools view -bS - > $atacpath/bams/${samp}.bam
#bowtie2 --local --very-sensitive --no-mixed --no-discordant -I 25 -X 700 -x $bt2idx/GRch38/GRch38 -1 $atacpath/atac_fastq/Ravi_${samp}_R1.trimmed.fastq.gz -2 $atacpath/atac_fastq/Ravi_${samp}_R2.trimmed.fastq.gz | samtools view -bS - > $atacpath/bams/${samp}.bam

#Sort the output bam file by coordinate
samtools sort $atacpath/bams/${samp}.bam -o $atacpath/bams/${samp}.sorted.bam

#Generate an index file
samtools index $atacpath/bams/${samp}.sorted.bam

#Generate the idxstats report
# (reads per chromosome; used to check the chrM fraction)
samtools idxstats $atacpath/bams/${samp}.sorted.bam> $atacpath/bams/${samp}_sorted.idxstats

#Generate the flagstat report
samtools flagstat $atacpath/bams/${samp}.sorted.bam > $atacpath/bams/${samp}_sorted.flagstat

#Remove reads aligned to the mitochondria
samtools view -h $atacpath/bams/${samp}.sorted.bam | grep -v chrM | samtools sort -O bam -o $atacpath/bams/${samp}.sorted.rmChrM.bam -T .