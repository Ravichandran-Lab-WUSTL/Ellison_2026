#BSUB -G compute-ccdg
#BSUB -q ccdg
#BSUB -n 15
#BSUB -a "docker(pl92297/atac)"
#BSUB -J "l.paullee atac SAMP"  
#BSUB -e error/bamcoverage_SAMP.err 
#BSUB -o out/bamcoverage_SAMP.out
#BSUB -M 500GB
#BSUB -R 'select[mem>500GB] rusage[mem=500GB] span[hosts=1]'

# Step 11: make bigWig coverage tracks for IGV or the UCSC browser with deepTools bamCoverage.
# Coverage is computed at 1 bp resolution (--binSize 1) and normalized to 1x genome coverage
# (--normalizeUsing RPGC) using the mm39 effective genome size; duplicate reads are ignored.
#https://www.biostars.org/p/442707/
# Sample numbers:
# 25 27 28 30 for neg1 neg2 pos1 pos2 
# 31 32 35 36 for DMSO DMSO CaCC CaCC

atacpath="/ccdg/Active/analysis/l.paullee/Ravi_ATAC"
number=SAMP

# Output: bams/s_d2_<SAMP>.bw (change the s_d2_ prefix when running other sample groups)
bamCoverage --bam $atacpath/bams/${number}.blacklist-filtered.bam --outFileName $atacpath/bams/s_d2_${number}.bw --ignoreDuplicates -p 10 -v --binSize 1 --normalizeUsing RPGC --effectiveGenomeSize 2654621783
