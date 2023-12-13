#!/bin/bash

#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc22_CompUnit_ESA.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc22_CompUnit_ESA.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc22_CompUnit_ESA.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# sacct -j 18699015  --format=JobID,State,Elapsed
# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

source ~/bin/grass78m

###  LAND COVER CATEGORIES BASED ON:
#https://datastore.copernicus-climate.eu/documents/satellite-land-cover/D3.3.12-v1.2_PUGS_ICDR_LC_v2.1.x_PRODUCTS_v1.2.pdf

export DIR=$1
export TMP=$2

# location of ESALC tif files
#/gpfs/loomis/project/sbsc/jg2657/data/ESALC
#/gpfs/loomis/project/sbsc/hydro/dataproces/ESALC/input
export ESATIF=$3 
export CU=$4
export DATFOLDER=$5
# export CU=88

export YEAR=$(echo 2003 + $SLURM_ARRAY_TASK_ID | bc)

grass78  -f -text --tmp-location  -c $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif <<'EOF'

#  Read files with subcatchments
r.in.gdal --o input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
    output=micb 
# read esa lc file
r.in.gdal --o -r input=$ESATIF/ESALC_${YEAR}.tif output=esalc

for CAT in $(cut -d' ' -f1 $DIR/../esa_categories.txt) 
do

    CATIDS=$(cat $DIR/../esa_categories.txt | cut -d '"' -f3 \
        | awk -v CAT=$CAT '$1==CAT')

    echo "$CATIDS = 1
    * = NULL" > $TMP/esa_stats_${CU}/reclass_esa_${YEAR}_${CAT}_${CU}.txt

    r.reclass --o input=esalc output=esalc_recl_${YEAR}_${CAT}_${CU} \
        rules=$TMP/esa_stats_${CU}/reclass_esa_${YEAR}_${CAT}_${CU}.txt

# Take $1 zone (microbasin), $3+$4 NON_null_cells+null_cells  
# (total number of cells in microbasin), $13 number of pixels with values 
# (in this case same as $3 because values are 1 or 0). 
# $13/($3+$4) > proportion of cells with values 
# (proportion of category i in microbasin)

    echo "c${CAT}_y${YEAR}" \
        > $TMP/esa_stats_${CU}/stats_esa_${YEAR}_${CAT}_${CU}.txt

    r.univar -t map=esalc_recl_${YEAR}_${CAT}_${CU} zones=micb separator=comma \
    | awk -F, 'FNR > 1 {printf "%.3f\n" , $13/($3+$4)}' \
    | awk '{gsub("nan", "0"); gsub("1.000", "1"); print $0}' \
    >> $TMP/esa_stats_${CU}/stats_esa_${YEAR}_${CAT}_${CU}.txt

done



EOF

rm $TMP/esa_stats_${CU}/reclass_esa_${YEAR}_*.txt

exit

