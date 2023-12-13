#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc28_CompUnit_VarsSingleFile.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc28_CompUnit_VarsSingleFile.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc28_CompUnit_VarsSingleFile.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash
module purge
source ~/bin/grass78m

export DIR=$1
export CU=$2
export DATFOLDER=$3

## PATH to variables of interest

# Global Aridity Index
export GARID=/gpfs/gibbs/pi/hydro/hydro/dataproces/GARID/out/ARID_annual.tif

# Global Potential Evapotranspiration
export GEVAPT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEVAPT/out/EVAPT_annual.tif


grass78  -f -text --tmp-location  -c $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif  <<'EOF'

#  Read files with subcatchments
r.in.gdal --o \
input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
output=micb 

export TOPO=(garid gevapt)


#  Calculate the statistics for each microbasin for the selected variables and save in txt file
for VAR in ${TOPO[@]}
do

    if [ "$VAR" == "garid" ]; then VARINPUT=$GARID; fi
    if [ "$VAR" == "gevapt" ]; then VARINPUT=$GEVAPT; fi

 
#############################################################################

  r.external input=$VARINPUT output=$VAR --overwrite
  
  echo "subcID min max range mean sd" > $DIR/out/stats_${CU}_${VAR}.txt  

  time r.univar -t --o map=$VAR zones=micb separator=space | \
      awk 'NR > 1 {print $1, $4, $5, $6, $7, $9}' \
      >> $DIR/out/stats_${CU}_${VAR}.txt

done


EOF
