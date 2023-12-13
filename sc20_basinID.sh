#!/bin/bash

#SBATCH -p day
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc20_basinID.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc20_basinID.sh.%A_%a.err
#SBATCH --mem-per-cpu=10000M

#  scp /home/jaime/Code/environmental-data-extraction/sc20_basinID.sh  grace:/home/jg2657/project/code/environmental-data-extraction


module purge
source ~/bin/gdal3

export DIR=${1}
export DATASET=${2}
export CU=${3} 
export MERITVAR=${4}

export MACROB=$MERITVAR/lbasin_tiles_final20d_ovr/all_lbasin.tif

paste -d " " $DATASET \
    <(printf "%s\n" MacrobasinID $(awk 'FNR > 1 {print $2, $3}' $DATASET \
    | gdallocationinfo -valonly -geoloc  $MACROB)) \
    > $DIR/out/stats_${CU}_BasinsIDs.txt

