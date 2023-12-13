#!/bin/bash

#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc22b_CompUnit_ESA_join.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc22b_CompUnit_ESA_join.sh.%A_%a.err
#SBATCH --mem-per-cpu=10000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc22c_CompUnit_ESA_joinNewData.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

export DIR=$1
export TMP=$2
export ref=$3

# create array
esastats=( $(find $TMP/esa_stats_${ref}/ -name "stats_esa_200*_${ref}.txt") )
# sort the array
IFS=$'\n' sorted=($(sort <<<"${esastats[*]}"))
unset IFS

# validation

b=$(paste -d' ' ${sorted[@]} | wc -l)
n=$(wc -l < $DIR/out/stats_${ref}_LCprop.txt)

[[ "$b" -ne "$n" ]] && echo "CompUnit $ref LCprop1920 no completa" \
    >> $HOME/LCprop19-20errors.txt && exit

# create the table 
paste -d' ' \
    $DIR/out/stats_${ref}_LCprop.txt \
    ${sorted[@]} > $DIR/out/stats_${ref}_LCprop_46.txt

# create the table with additional years



mv $DIR/out/stats_${ref}_LCprop_fn.txt $DIR/out/stats_${ref}_LCprop.txt

rm -rf $TMP/esa_stats_${ref}

exit
paste -d' ' \
    <(cut -d" " -f1-265 $DIR/out/stats_${ref}_LCprop.txt) \
    ${sorted[@]} \
    <(cut -d" " -f284-591 $DIR/out/stats_${ref}_LCprop.txt) \
    > $DIR/out/stats_${ref}_LCprop_fn.txt

cut -d" " -f1-265

cut -d" " -f284-591


###############################################################################
###############################################################################
###############################################################################
###############################################################################

# path to hydro variables
export MERITVAR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
# path to scripts
export SCRIPTS=/home/jg2657/project/code/environmental-data-extraction
# path to project
export PROJ=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES
# path to temporal folder
export TMP=/vast/palmer/scratch/sbsc/jg2657/tables


for i in 100 101 102 104 105 80 87 88 97 98 99
do

    export ref=$i


##### Prepare directories to store results
export DIR=$PROJ/CU_${ref}

# STEP 8
# ESALC data
mkdir $TMP/esa_stats_${ref}

sbatch --array=28-29 --time=05:00:00 --job-name=ESA_${ref} \
    $SCRIPTS/sc22_CompUnit_ESA.sh $DIR $TMP \
    /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/input ${ref} $MERITVAR  

# this next depends on the previous
sbatch --time=02:00:00 --job-name=ESAjoin_${ref} \
    --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j" | grep ESA_${ref} | awk '{print $1}') \
    $SCRIPTS/sc22c_CompUnit_ESA_joinNewData.sh $DIR $TMP $ref

done
