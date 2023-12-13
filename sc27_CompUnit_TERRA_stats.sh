#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc27_CompUnit_TERRA_stats.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc27_CompUnit_TERRA_stats.sh.%A_%a.err
#SBATCH --mem-per-cpu=15000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc27_CompUnit_TERRA_stats.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash

DIR=$1
TMP=$2
CU=$3

VAR=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'NR==row {print $1}' $DIR/../terra_seq.txt)
YEAR=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'NR==row {print $2}' $DIR/../terra_seq.txt)
F=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'NR==row {print $3}' $DIR/../terra_seq.txt)
S=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'NR==row {print $4}' $DIR/../terra_seq.txt)

cut -d' ' -f$F-$S $DIR/out/stats_${CU}_TERRA_$VAR.txt > $TMP/terra_${CU}_${VAR}_${YEAR}.txt 

## create table to store results
echo "min_${YEAR} max_${YEAR} mean_${YEAR} sd_${YEAR}" >  $TMP/stats_terra_${CU}_${VAR}_${YEAR}.txt

awk 'NR > 1 {

    # minimum and maximum calculation	
    a=0; b=0; for (i=1;i<=NF;i++) if ($i < a || i == 1)a = $i; else if($i > b|| i == 1)b = $i

    # mean
    N=0; for(i=1; i <= NF; i++) N += $i
    MEAN = N/NF

    # standard deviation
    A=0; V=0; for(N=1; N<=NF; N++) A+=$N ; A/=NF ; for(N=1; N<=NF; N++) V+=(($N-A)*($N-A))/(NF-1)
    STDEV = sqrt(V)
}
NR > 1 {
print a, b, MEAN, STDEV
}' $TMP/terra_${CU}_${VAR}_${YEAR}.txt >> $TMP/stats_terra_${CU}_${VAR}_${YEAR}.txt

rm $TMP/terra_${CU}_${VAR}_${YEAR}.txt
