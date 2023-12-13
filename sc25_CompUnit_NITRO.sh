#!/bin/bash

#SBATCH -p day
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc25_CompUnit_NITRO.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc25_CompUnit_NITRO.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp /home/jaime/Code/environmental-data-extraction/sc25_CompUnit_NITRO.sh  grace:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash

module purge
source ~/bin/gdal3

export DIR=${1}
export TMP=${2}
export CU=${3}
export NITRO=${4}

export VAR=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'FNR==row {print $1}' $DIR/../nh_array.txt)     ### (nh4 no3)
export YEAR=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'FNR==row {print $2}' $DIR/../nh_array.txt)    ### (1961--2010)
export MES=$(awk -v row="$SLURM_ARRAY_TASK_ID" 'FNR==row {print $3}' $DIR/../nh_array.txt)   ### (01..12)


time printf "%s\n" ${VAR}_${YEAR}_${MES} $(awk 'FNR > 1 {print $1, $2}' $DIR/coordinates_${CU}.txt | gdallocationinfo -valonly -geoloc  ${NITRO}/${VAR}/${VAR}_${YEAR}_${MES}.tif) | awk '{gsub("-9999", "na"); print $0}' > $TMP/NHO_${CU}/${VAR}_${YEAR}_${MES}.txt


exit



