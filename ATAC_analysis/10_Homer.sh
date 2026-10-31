#BSUB -G compute-ccdg
#BSUB -q ccdg
#BSUB -n 1
#BSUB -a "docker(imegusu/homer_motif:v4_11)"
#BSUB -J "l.paullee Homer SAMP"  
#BSUB -e error/Homer_SAMP.err 
#BSUB -o out/Homer_SAMP.out
#BSUB -M 50GB
#BSUB -R 'select[mem>50GB] rusage[mem=50GB] span[hosts=1]'

# Step 10: motif enrichment with HOMER.
# Runs findMotifsGenome.pl on a set of differential peaks (peaks_<SAMP>.bed, from 9_Homer_Setup.Rmd)
# against mm39, using the peak coordinates as given (-size given) and masking repeats (-mask).
# Uses HOMER's default background (random GC-matched genomic regions).
# SAMP is the peak-set ID, e.g. c_2 or s_2 (see sender.sh).
# Output: results/peak_bed/<SAMP>/ (knownResults.html and de novo homerResults/)

atacpath="/ccdg/Active/analysis/l.paullee/Ravi_ATAC"
samp=SAMP
#samp=s_2   # example value for running interactively
# Output directory
mkdir /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/${samp}

# Put HOMER on PATH inside the container
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/homer/bin:$PATH"

# Known and de novo motif enrichment
perl /home/homer/bin/findMotifsGenome.pl /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/peaks_${samp}.bed mm39 /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/${samp} -size given -mask -preparsedDir /ccdg/Active/analysis/l.paullee/Ravi_ATAC/homer_tmp

# Optional: find occurrences of individual de novo motifs in the peaks (output per peak)
#annotatePeaks.pl <peaks.bed> <genome_version> -m <motif_file> > <output_table.txt>

# De Novo Scan: Fra1
#perl /home/homer/bin/annotatePeaks.pl /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/peaks_c_2.bed mm39 -m  /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/c_2/homerResults/motif1.motif > /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/c_2/homerResults/Fra1_de_novo_motif_scan.txt

# De Novo Scan: CEBP
#perl /home/homer/bin/annotatePeaks.pl /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/peaks_c_2.bed mm39 -m  /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/c_2/homerResults/motif2.motif > /ccdg/Active/analysis/l.paullee/Ravi_ATAC/results/peak_bed/c_2/homerResults/Cebpa_de_novo_motif_scan.txt