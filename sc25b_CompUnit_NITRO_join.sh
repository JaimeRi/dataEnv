#!/bin/bash

#SBATCH -p day
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc25b_CompUnit_NITRO_join.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc25b_CompUnit_NITRO_join.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp /home/jaime/Code/environmental-data-extraction/sc25b_CompUnit_NITRO_join.sh  grace:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash

export DIR=$1
export TMP=$2
export ref=$3

##  JOIN tables for NH4
nhstats=( $(find $TMP/NHO_${ref}/ -name 'NH4*.txt') )
# sort the array
IFS=$'\n' sorted=($(sort <<<"${nhstats[*]}"))
unset IFS
# create the table
time paste -d' ' \
    <(awk '{print $1}' $DIR/out/stats_${ref}_BasinsIDs.txt) \
    ${sorted[@]} > $DIR/out/stats_${ref}_NH4.txt 

## JOIN tables for NO3
nostats=( $(find $TMP/NHO_${ref}/ -name 'NO3*.txt') )
# sort the array
IFS=$'\n' sorted=($(sort <<<"${nostats[*]}"))
unset IFS
# create the table
time paste -d' ' \
    <(awk '{print $1}' $DIR/out/stats_${ref}_BasinsIDs.txt) \
    ${sorted[@]} > $DIR/out/stats_${ref}_NO3.txt 


rm -fr $TMP/NHO_${ref}

