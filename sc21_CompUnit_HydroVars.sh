#!/bin/bash

#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc21_CompUnit_HydroVars.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc21_CompUnit_HydroVars.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc21_CompUnit_HydroVars.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash
module purge
source ~/bin/grass78m

export DIR=$1
export CU=$2
export DATFOLDER=$3

# list of available variables: see description below
# elev flow changraddwseg changradupseg changradupcel chancurv  chanelvdwseg chanelvupseg chanelvupcel chanelvdwcel chandistdwseg chandistupseg chandistupcel strdistupnear strdiffupnear strdistupfarth strdiffupfarth strdistdwnear strdiffdwnear outdistdwbasin outdiffdwbasin outdistdwscatch outdiffdwscatch strdistprox slopcmax slopcmin slopdiff slopgrad cti spi sti

export TOPO=(elev flowpos flow changraddwseg changradupseg changradupcel chancurv  chanelvdwseg chanelvupseg chanelvupcel chanelvdwcel chandistdwseg chandistupseg chandistupcel strdistupnear strdiffupnear strdistupfarth strdiffupfarth strdistdwnear strdiffdwnear outdistdwbasin outdiffdwbasin outdistdwscatch outdiffdwscatch strdistprox slopcmax slopcmin slopdiff slopgrad)

export VAR=${TOPO["$SLURM_ARRAY_TASK_ID"]}

grass78  -f -text --tmp-location  -c $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif  <<'EOF'

#  Read files with subcatchments
r.in.gdal --o \
input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
output=micb 

#  Calculate the statistics for each microbasin for the selected variables and save in txt file
###################################
##  ELEVATION AND FLOW ACCUMULATION
##################################

    if [ "$VAR" == "elev" ]; then VARINPUT=$DATFOLDER/CompUnit_elv/elv_${CU}_msk.tif; fi
    if [ "$VAR" == "flowpos" ]; then VARINPUT=$DATFOLDER/CompUnit_flow_pos_noenlarge/flow_${CU}_msk.tif; fi
    if [ "$VAR" == "flow" ]; then VARINPUT=$DATFOLDER/CompUnit_flow/flow_${CU}_msk.tif; fi

#############################
##  CHANNEL RELATED VARIABLES
############################

# gradient=channel_grad_dw_seg / Segment downstream (between current cell and the join/outlet) 
    if [ "$VAR" == "changraddwseg" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_grad_dw_seg/channel_grad_dw_seg_${CU}.tif; fi 

# gradient=channel_grad_up_seg / Segment upstream (between current cell and the init/join)
    if [ "$VAR" == "changradupseg" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_grad_up_seg/channel_grad_up_seg_${CU}.tif; fi

# gradient=channel_grad_up_cel / Cell upstream (between current cell and next cell) 
    if [ "$VAR" == "changradupcel" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_grad_up_cel/channel_grad_up_cel_${CU}.tif; fi

# curvature=channel_curv_cel / Cell stream course curvature (current cell) 
    if [ "$VAR" == "chancurv" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_curv_cel/channel_curv_cel_${CU}.tif; fi

# difference=channel_elv_dw_seg
    if [ "$VAR" == "chanelvdwseg" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_elv_dw_seg/channel_elv_dw_seg_${CU}.tif; fi

# difference=channel_elv_up_seg / Segment upstream (between current cell and the init/join) 
    if [ "$VAR" == "chanelvupseg" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_elv_up_seg/channel_elv_up_seg_${CU}.tif; fi

# difference=channel_elv_up_cel / Cell upstream (between current cell and next cell) 
    if [ "$VAR" == "chanelvupcel" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_elv_up_cel/channel_elv_up_cel_${CU}.tif; fi

# difference=channel_elv_dw_cel / Cell downstream (between current cell and next cell) 
    if [ "$VAR" == "chanelvdwcel" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_elv_dw_cel/channel_elv_dw_cel_${CU}.tif; fi

# distance=channel_dist_dw_seg / Segment downstream (between current cell and the join/outlet)
    if [ "$VAR" == "chandistdwseg" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_dist_dw_seg/channel_dist_dw_seg_${CU}.tif; fi

# distance=channel_dist_up_seg / Segment upstream (between current cell and the init/join) 
    if [ "$VAR" == "chandistupseg" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_dist_up_seg/channel_dist_up_seg_${CU}.tif; fi

# distance=channel_dist_up_cel / Cell upstream (between current cell and next cell) 
    if [ "$VAR" == "chandistupcel" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_channel/channel_dist_up_cel/channel_dist_up_cel_${CU}.tif; fi

#############################
##  DISTANCE RELATED VARIABLES
############################

# distance=distance_stream_upstream / Distance of the shortest path from a stream pixel to the divide
    if [ "$VAR" == "strdistupnear" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/stream_dist_up_near/stream_dist_up_near_${CU}.tif; fi

# difference=difference_stream_upstream / Elevation difference of the shortest path from a stream pixel to the divide
    if [ "$VAR" == "strdiffupnear" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/stream_diff_up_near/stream_diff_up_near_${CU}.tif; fi

# distance=distance_stream_upstream / Distance of the longest path from a stream pixel to the divide
    if [ "$VAR" == "strdistupfarth" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/stream_dist_up_farth/stream_dist_up_farth_${CU}.tif; fi

# difference=difference_stream_upstream / Elevation difference of the longest path from a stream pixel to the divide
    if [ "$VAR" == "strdiffupfarth" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/stream_diff_up_farth/stream_diff_up_farth_${CU}.tif; fi

# distance=distance_stream_downstream / Distance of the longest pathfrom the divide to reach a stream pixel
    if [ "$VAR" == "strdistdwnear" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/stream_dist_dw_near/stream_dist_dw_near_${CU}.tif; fi

# difference=difference_stream_downstream / Elevation difference of the longest path from the divide to reach a stream pixel
    if [ "$VAR" == "strdiffdwnear" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/stream_diff_dw_near/stream_diff_dw_near_${CU}.tif; fi

# distance=distance_stream_downstream / Distance of the longest path from the divide to reach an outlet pixel
    if [ "$VAR" == "outdistdwbasin" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/outlet_dist_dw_basin/outlet_dist_dw_basin_${CU}.tif; fi

# difference=difference_stream_downstream / Elevation difference of the longest path from the divide to reach an outlet pixel
    if [ "$VAR" == "outdiffdwbasin" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/outlet_diff_dw_basin/outlet_diff_dw_basin_${CU}.tif; fi

# distance=distance_stream_downstream / Distance of the longest path from the divide to reach a stream node pixel
    if [ "$VAR" == "outdistdwscatch" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/outlet_dist_dw_scatch/outlet_dist_dw_scatch_${CU}.tif; fi

# difference=difference_stream_downstream / Elevation difference of the longest path from the divide to reach a stream node pixel
    if [ "$VAR" == "outdiffdwscatch" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/outlet_diff_dw_scatch/outlet_diff_dw_scatch_${CU}.tif; fi

# distance=streams_proximity / Euclidean distance from the streams
    if [ "$VAR" == "strdistprox" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_dist/stream_dist_proximity/stream_dist_proximity_${CU}.tif; fi

#############################
##  SLOPE RELATED VARIABLES
############################
    
# maxcurv=slope_curv_max_dw_cel /  Cell (between highest upstream cell, current cell anddownstream cell) 
    if [ "$VAR" == "slopcmax" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_slope/slope_curv_max_dw_cel/slope_curv_max_dw_cel_${CU}.tif; fi

# mincurv=slope_curv_min_dw_cel / Cell (between lowest upstream cell, current cell anddownstream cell)
    if [ "$VAR" == "slopcmin" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_slope/slope_curv_min_dw_cel/slope_curv_min_dw_cel_${CU}.tif; fi
   
# difference=slope_elv_dw_cel / Cell (between current cell anddownstream cell) 
    if [ "$VAR" == "slopdiff" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_slope/slope_elv_dw_cel/slope_elv_dw_cel_${CU}.tif; fi
   
# gradient=slope_grad_dw_cel / Cell gradient (elevation differencedivided by distance) 
    if [ "$VAR" == "slopgrad" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_slope/slope_grad_dw_cel/slope_grad_dw_cel_${CU}.tif; fi

############################
##  STREAM FLOW INDICES 
############################

#    if [ "$VAR" == "cti" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_cti_dis.vrt; fi
#    if [ "$VAR" == "spi" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_spi_dis.vrt; fi
#    if [ "$VAR" == "sti" ]; then VARINPUT=$DATFOLDER/CompUnit_stream_indices_tiles20d/all_tif_sti_dis.vrt; fi

############################
##  GARID (aridity) & GEVAPT (evapotranspiration) 
############################

#    if [ "$VAR" == "arid" ]; then VARINPUT=$DATFOLDER/../GARID/out/ARID_annual.tif; fi
#    if [ "$VAR" == "gevap" ]; then VARINPUT=$DATFOLDER/../GEVAPT/out/EVAPT_annual.tif; fi
 
###############################################################################

  r.external input=$VARINPUT output=$VAR --overwrite

  echo "subcID min max range mean sd" > $DIR/out/stats_${CU}_${VAR}.txt  

  r.univar -t --o map=$VAR zones=micb | \
    awk -F"|"  'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } \
    NR > 1 { printf "%s %.4f %.4f %.4f %.4f %.4f\n", \
    $(f["zone"]), $(f["min"]), $(f["max"]), $(f["range"]), \
    $(f["mean"]), $(f["stddev"]) }' >> $DIR/out/stats_${CU}_${VAR}.txt

EOF

exit

