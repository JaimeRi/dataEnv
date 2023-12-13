#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 23:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc21_CompUnit_CHELSAfut.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc21_CompUnit_CHELSAfut.sh.%A_%a.err
#SBATCH --mem-per-cpu=25000M


#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc21_CompUnit_CHELSAfut.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash

module purge
source ~/bin/grass78m

export DIR=$1
export CHELSA=$2
export CU=$3
export DATFOLDER=$4


grass78  -f -text --tmp-location  -c $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif  <<'EOF'

#  Read files with subcatchments
r.in.gdal --o input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
    output=micb 

for file in $(find $CHELSA -name "*.tif");
do


 VAR=$(basename $file .tif)
  
  [[ -f $DIR/CU_${CU}/out/stats_${CU}_${VAR}.txt  ]] && continue
  
  r.external input=$file output=$VAR --overwrite
  
  echo "subcID min max range mean sd" > $DIR/CU_${CU}/out/stats_${CU}_${VAR}.txt  

  #r.univar -t --o map=$VAR zones=micb separator=space | \
  #    awk 'NR > 1 {print $1, $4, $5, $6, $7, $9}' \
  #    >> $DIR/CU_${CU}/out/stats_${CU}_${VAR}.txt
  
  r.univar -t --o map=$VAR zones=micb | \
    awk -F"|"  'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } \
    NR > 1 { printf "%s %.4f %.4f %.4f %.4f %.4f\n", \
    $(f["zone"]), $(f["min"]), $(f["max"]), $(f["range"]), \
    $(f["mean"]), $(f["stddev"]) }' >> $DIR/CU_${CU}/out/stats_${CU}_${VAR}.txt

done

EOF
exit

