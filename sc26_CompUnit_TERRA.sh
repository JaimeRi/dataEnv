#!/bin/bash

#SBATCH -p day
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc26_CompUnit_TERRA.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc26_CompUnit_TERRA.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp /home/jaime/Code/environmental-data-extraction/sc26_CompUnit_TERRA.sh  grace:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash

module purge
source ~/bin/gdal3

export DIR=${1}
export TMP=${2}
export CU=${3}

export TERRA=${4}

export VAR=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'FNR==row {print $1}' $DIR/../terra_array.txt)
export YEAR=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'FNR==row {print $2}' $DIR/../terra_array.txt)
export MES=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'FNR==row {print $3}' $DIR/../terra_array.txt) 

NA=$( gdalinfo ${TERRA}/${VAR}/${VAR}_${YEAR}_${MES}.tif | awk -F= /NoData/'{print $2}'  )

time printf "%s\n" ${VAR}_${YEAR}_${MES} $(awk 'FNR > 1 {print $1, $2}' $DIR/coordinates_${CU}.txt | gdallocationinfo -valonly -geoloc  ${TERRA}/${VAR}/${VAR}_${YEAR}_${MES}.tif) | awk -v NA="$NA" '{gsub(NA, "na"); print $0}' > $TMP/terra_${CU}/${VAR}_${YEAR}_${MES}.txt

exit
