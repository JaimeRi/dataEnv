#!/bin/bash

#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc22b_CompUnit_ESA_join.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc22b_CompUnit_ESA_join.sh.%A_%a.err
#SBATCH --mem-per-cpu=10000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc22b_CompUnit_ESA_join.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

export DIR=$1
export TMP=$2
export ref=$3

# create array
esastats=( $(find $TMP/esa_stats_${ref}/ -name "stats_esa_*${ref}.txt") )
# sort the array
IFS=$'\n' sorted=($(sort <<<"${esastats[*]}"))
unset IFS

# create the table
paste -d' ' \
    <(awk '{print $1}' $DIR/out/stats_${ref}_BasinsIDs.txt) \
    ${sorted[@]} > $DIR/out/stats_${ref}_LCprop.txt 

b=$(wc -l < $DIR/out/stats_${ref}_BasinsIDs.txt)
n=$(wc -l < $DIR/out/stats_${ref}_LCprop.txt)

[[ "$b" -eq "$n" ]] && rm -rf $TMP/esa_stats_${ref} || echo "$ref LCprop no completa"


exit


ref=195
DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES/CU_$ref

paste -d' ' \
    <(awk '{print $1}' $DIR/out/stats_${ref}_BasinsIDs.txt) \
    $DIR/out/stats_${ref}_LCprop.txt \
    > $DIR/out/stats_${ref}_LCprop2.txt 

cut -d" " -f1,3- $DIR/out/stats_${ref}_LCprop2.txt > $DIR/out/stats_${ref}_LCprop3.txt

mv $DIR/out/stats_${ref}_LCprop3.txt $DIR/out/stats_${ref}_LCprop.txt

rm $DIR/out/stats_${ref}_LCprop2.txt
