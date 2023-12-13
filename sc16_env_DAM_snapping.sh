#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
####SBATCH -t 3:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc16_env_DAM_snapping.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc16_env_DAM_snapping.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M
#####SBATCH --array=1-51   ###  total number of basins where dams are located >>>#  

#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc16_env_DAM_snapping.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/scripts

# sbatch /home/jg2657/project/BenthicEU/scripts/sc16_env_DAM_snapping.sh

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
module purge
source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m


export DIR=$1
export TMP=$2
export BASIN=$TMP/basins
export OUTDIR=$DIR/dam

export basinID=$(ogrinfo $OUTDIR/dams_roi.gpkg -al | awk '/MacrobasinID/ {print $4}' | sort | uniq)
export ID=$(echo $basinID | awk -v id=$SLURM_ARRAY_TASK_ID '{print $id}')

[ ! -d $OUTDIR/basin_${ID} ] &&  mkdir  $OUTDIR/basin_${ID}

grass78  -f -text --tmp-location  -c $BASIN/basin_${ID}/bid_${ID}_mask.tif   <<'EOF'

### Points (dams) available in each macro basin
v.in.ogr --o input=$OUTDIR/dams_roi.gpkg layer=dams_benthic_EU output=dams_${ID} type=point  where="MacrobasinID = ${ID}" key=fid  ###

### vector line (stream reach)  with order more than 4 for the whole macrobasin
v.in.ogr  --o input=$BASIN/basin_${ID}/bid_${ID}_stre_order.gpkg layer=orderV_bid${ID} output=streams_${ID} type=line key=stream where="strahler > 4"

# how many dams are there and what are their IDs (fid)?
RANGE=$(v.db.select -c dams_${ID} col=fid)

## for loop to make the snap of each point at a time
for PN in $RANGE; do

    ### extract point
    v.extract --o input=dams_${ID} type=point cats=${PN} output=point_${PN}

    v.net --o -s input=streams_${ID}  points=point_${PN} output=snap_${PN} operation=connect threshold=10000 arc_layer=1 node_layer=2
    v.out.ascii input=snap_${PN} layer=2 separator=comma > ${OUTDIR}/basin_${ID}/coords_${PN}
done

##  Join all single tables in one file
echo XcoordSnap,YcoordSnap,fid_snap > ${OUTDIR}/basin_${ID}/coords_all_${ID}.csv
for i in $RANGE; do cat ${OUTDIR}/basin_${ID}/coords_${i} >> ${OUTDIR}/basin_${ID}/coords_all_${ID}.csv; done

##  Read back to GRASS as a vector point
v.in.ascii --o input=${OUTDIR}/basin_${ID}/coords_all_${ID}.csv output=allPoints_${ID} columns='XcoordSnap double precision, YcoordSnap double precision, fid_snap int'  skip=1 x=1 y=2 z=0 separator=comma

## join attribute table from original file
v.db.join map=allPoints_${ID} column=fid_snap other_table=dams_${ID} other_column=fid

## create the new vector gpkg file
v.out.ogr  -s --overwrite input=allPoints_${ID} type=point  output=${OUTDIR}/basin_${ID}/basin_${ID}.gpkg format=GPKG output_layer=dams_snapped

EOF

exit
