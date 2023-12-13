#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
####SBATCH -t 02:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc06_distance.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc06_distance.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M
####SBATCH --array=1-314  ###  306 diferent macro basins

#  scp /home/jaime/Code/environmental-data-extraction/sc06b_distance_Fish.sh grace:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=50G  --x11 -p interactive bash
module purge
#source ~/bin/gdal3
#source ~/bin/pktools
source ~/bin/grass78m

export DIR=$1

export TEMP=$2

export BASIN=$TEMP/basins

export basinID=$(awk -F, 'FNR > 1 {print $4}' $DIR/BasisDataBasinsIDs.csv \
    | sort | uniq)

[ ! -d $DIR/distance ] && mkdir $DIR/distance
export OUTDIR=$DIR/distance

[ ! -d $DIR/distance/dist_fly ] && mkdir $DIR/distance/dist_fly
[ ! -d $DIR/distance/dist_fish ] && mkdir $DIR/distance/dist_fish

# Macro-basin
export ID=$(echo $basinID | awk -v id=$SLURM_ARRAY_TASK_ID '{print $id}')

# Name of column for unique ID
export SITE=$( awk -F, 'NR==1 {print $1}' $DIR/BasisDataBasinsIDs.csv )

### create table to store output of distance algorithms
echo 'Site_ID,dist_Site_ID,dist' > $OUTDIR/dist_fly/dist_fly_allp_${ID}.csv
echo 'Site_ID,dist_Site_ID,dist' > $OUTDIR/dist_fish/dist_fish_allp_${ID}.csv

echo
echo "*****  RUN SLURM: $SLURM_ARRAY_TASK_ID ---  Processing BASIN : $ID  *****"
echo

grass78 -f -text --tmp-location -c $BASIN/basin_${ID}/bid_${ID}_mask.tif <<'EOF'

# Points available in each basin
v.in.ogr --o input=$DIR/Locations_snap.gpkg layer=LocationSnap \
    output=benthicEU type=point  where="MacrobasinID = ${ID}" key=$SITE  

NUMPOINT=$( v.info benthicEU | awk '/points/{print $5}')
if [ $NUMPOINT -lt 2 ]; then exit;fi

# calculate matrix (euclidian) distance between all points in macrobasin
# v.distance -pa from=benthicEU to=benthicEU upload=dist separator=comma >> $OUTDIR/dist_fly_allp_${ID}.csv

# same as above BUT in a for loop to create a three column data frame
# sequence of number of points available
SEQUE=$(seq -s' ' 1 $NUMPOINT)
RANGE=$(v.db.select -c benthicEU col=$SITE)

for PN in $SEQUE; do

    echo "*****  Processing Point : $PN  of \
    $(v.info benthicEU | awk '/points/{print $5}') *****"

    POINT=$(printf "%s\n" $RANGE | head -n $PN | tail -n 1)
    COMPLEMENT=$(echo $RANGE | awk -v sequ="$PN" 'BEGIN{OFS=",";} \
    {$sequ=""; print $0}' |  cut -d, -f${PN} --complement)

      # Split points one at a time
    v.extract --o input=benthicEU type=point cats=${POINT} output=sampleOne
    v.extract --o input=benthicEU type=point cats=${COMPLEMENT} output=sampleRest

    # calculate distance from each point to all other points
    v.distance -pa --q from=sampleOne from_type=point to=sampleRest \
        to_type=point upload=dist separator=comma \
        | awk -F',' 'BEGIN{OFS=",";} NR > 1 {print $1, $2, $3/1000}'  \
        >> $OUTDIR/dist_fly/dist_fly_allp_${ID}.csv

done

# calculation for all points using the streams (as the fish swims)

# read the cleaned stream network generated by r.stream.order
v.in.ogr  --o input=$BASIN/basin_${ID}/bid_${ID}_stre_order.gpkg \
    layer=orderV_bid${ID} output=stre_cl type=line key=stream

# Connect points to streams 
# (threshold does not matter because the snapping was done before)
v.net -s --o input=stre_cl points=benthicEU output=stream_pALL \
    operation=connect threshold=1 arc_layer=1 node_layer=2

#v.net -s --o input=orderV_bid504553 points=benthicEU output=stream_pALL \
#    operation=connect threshold=1 arc_layer=1 node_layer=2

# calculate distance in the stream network between all pairs
v.net.allpairs -g --o input=stream_pALL output=dist_all_${ID} cats=$(echo $RANGE | awk '{gsub(" ",","); print $0}')

# add results to table
v.report -c map=dist_all_${ID} layer=1 option=length units=kilometers  \
   | awk -F',' 'BEGIN{OFS=",";} {gsub(/[|]/, ","); print $2, $3, $5}' \
   >> $OUTDIR/dist_fish/dist_fish_allp_${ID}.csv

EOF

exit

sacct -j 18596065 --format=JobID,State,Elapsed 8596065
