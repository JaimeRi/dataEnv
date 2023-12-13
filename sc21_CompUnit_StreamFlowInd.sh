#!/bin/bash

#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc21_CompUnit_StreamFlowInd.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc21_CompUnit_StreamFlowInd.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc21_CompUnit_StreamFlowInd.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G --x11 -p interactive bash
module purge
source ~/bin/grass78m
source ~/bin/gdal3
source ~/bin/pktools

#export PROJ=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

# path to temporal folder
export TMP=/vast/palmer/scratch/sbsc/jg2657/sfi


##### Prepare directories to store results

export DIR=$1

export CU=$2
#export CU=192
export DATFOLDER=$3
#export DATFOLDER=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
#export DIR=$PROJ/CU_${CU}

export TOPO=(cti spi sti)

export VAR=${TOPO["$SLURM_ARRAY_TASK_ID"]}

ulx=$(pkinfo -i $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif -ulx | awk -F= '{print $2}')
uly=$(pkinfo -i $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif -uly | awk -F= '{print $2}')
lrx=$(pkinfo -i $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif -lrx | awk -F= '{print $2}')
lry=$(pkinfo -i $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif -lry | awk -F= '{print $2}')

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES \
        -projwin $ulx $uly $lrx $lry \
        $DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_${VAR}_dis.vrt  \
        $TMP/${VAR}_CU_${CU}.tif

export VARINPUT=$TMP/${VAR}_CU_${CU}.tif

grass78  -f -text --tmp-location  -c $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif  <<'EOF'


#  Read files with subcatchments
r.in.gdal --o \
input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
output=micb 

############################
##  STREAM FLOW INDICES 
############################

#    if [ "$VAR" == "cti" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_cti_dis.vrt; fi
#    if [ "$VAR" == "spi" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_spi_dis.vrt; fi
#    if [ "$VAR" == "sti" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_sti_dis.vrt; fi

###############################################################################

  r.external input=$VARINPUT output=$VAR --overwrite

  echo "subcID min max range mean sd" > $DIR/out/stats_${CU}_${VAR}.txt  

  r.univar -t --o map=$VAR zones=micb | \
    awk -F"|"  'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } \
    NR > 1 { printf "%s %.4f %.4f %.4f %.4f %.4f\n", \
    $(f["zone"]), $(f["min"]), $(f["max"]), $(f["range"]), \
    $(f["mean"]), $(f["stddev"]) }' >> $DIR/out/stats_${CU}_${VAR}.txt

EOF

rm $VARINPUT


exit

