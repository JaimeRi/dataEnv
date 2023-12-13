#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#####SBATCH -t 23:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc18_env_DAM_dist.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc18_env_DAM_dist.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M
#####SBATCH --array=1-51  ###  total number of basins where dams are located >>> ogrinfo $DIR/dam/dams_roi.gpkg -al | awk '/MacrobasinID/ {print $4}' | sort | uniq | wc -l  #(note that first row is empty!)

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc18_env_DAM_dist.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/scripts

# sbatch /home/jg2657/project/BenthicEU/scripts/sc18_env_DAM_dist.sh

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
module purge
source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

#export DIR=/home/jaime/data/benthicEU
#export DIR=/home/jg2657/project/BenthicEU
export DIR=$1
#export DAMP=/home/jaime/data/benthicEU/dam
#export DAMP=/home/jg2657/project/BenthicEU/dam
#export OUTDIR=/home/jaime/data/benthicEU/dam
export OUTDIR=$DIR/dam
#export TMP=/home/jaime/data/benthicEU/tmp
export TMP=$2
export BASIN=$3
export basinID=$(ogrinfo $OUTDIR/dams_roi.gpkg -al | awk '/MacrobasinID/ {print $4}' | sort | uniq)
export ID=$(echo $basinID | awk -v id=$SLURM_ARRAY_TASK_ID '{print $id}')


grass78  -f -text --tmp-location  -c $BASIN/basin_${ID}/bid_${ID}_mask.tif   <<'EOF'


### Ocurrence points available in basin
v.in.ogr --o input=$DIR/Locations_snap.gpkg layer=LocationSnap output=benthicEU type=point  where="MacrobasinID = ${ID}" key=Site_ID

### create external table with point id, elevation and accumulation values
paste -d "," \
<(printf "%s\n" pointID $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $1}'))  \
<(printf "%s\n" pointELEV $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  /home/jg2657/scratch60/basins/basin_${ID}/bid_${ID}_elev.tif)) \
<(printf "%s\n" pointACCU $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  /home/jg2657/scratch60/basins/basin_${ID}/bid_${ID}_accu.tif)) \
> $TMP/pointsIEA_${ID}.csv
echo \"Integer\",\"Real\",\"Real\" > $TMP/pointsIEA_${ID}.csvt
db.in.ogr --o $TMP/pointsIEA_${ID}.csv  out=pointsIEA_${ID}

### Dams points in basin
v.in.ogr --o input=$OUTDIR/dams_snap.gpkg layer=DAMSsnap output=dams_${ID} type=point  where="MacrobasinID = ${ID}" key=fid_snap  ###

### create external table with dam id, elevation and accumulation values
paste -d "," \
<(printf "%s\n" damID $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $1}'))  \
<(printf "%s\n" damELEV $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  /home/jg2657/scratch60/basins/basin_${ID}/bid_${ID}_elev.tif)) \
<(printf "%s\n" damACCU $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  /home/jg2657/scratch60/basins/basin_${ID}/bid_${ID}_accu.tif)) \
> $TMP/damsIEA_${ID}.csv
echo \"Integer\",\"Real\",\"Real\" > $TMP/damsIEA_${ID}.csvt
db.in.ogr --o $TMP/damsIEA_${ID}.csv  out=damsIEA_${ID}

# read the cleaned stream network generated by r.stream.order
v.in.ogr  --o input=$BASIN/basin_${ID}/bid_${ID}_stre_order.gpkg layer=orderV_bid${ID} output=stre_cl type=line key=stream

# connect streams to occurrence points and save in layer=2
v.net --o input=stre_cl points=benthicEU output=streams_net1 operation=connect thresh=1 arc_layer=1 node_layer=2

### start loop to go through each dam

SEQUE=$(seq -s' ' 1 $(v.info dams_${ID} | awk '/points/{print $5}'))
RANGE=$(v.db.select -c dams_${ID} col=fid_snap)

echo Basin ID = ${ID}, Number of dams = $(v.info dams_${ID} | awk '/points/{print $5}') > $TMP/damOut/Run_${SLURM_ARRAY_TASK_ID}_basin_${ID}.txt

for PN in $SEQUE; do

# extract one point at a time
POINT=$(printf "%s\n" $RANGE | head -n $PN | tail -n 1)
v.extract --o input=dams_${ID} type=point cats=${POINT} output=sampleOne
v.net --o input=streams_net1 points=sampleOne output=streams_net2 operation=connect thresh=1 arc_layer=1 node_layer=3
v.net.distance --o in=streams_net2 out=occurrrence_to_dams flayer=2 to_layer=3

## Join the tables with the vector
v.db.join map=occurrrence_to_dams column=tcat other_table=damsIEA_${ID} other_column=damID
v.db.join map=occurrrence_to_dams column=cat other_table=pointsIEA_${ID} other_column=pointID

#v.report -c map=occurrrence_to_dams layer=1 option=length units=kilometers  | awk -F',' 'BEGIN{OFS=",";} {gsub(/[|]/, ","); print $1, $4, $5, $6, $8, $9, $10}' > $OUTDIR/DAM_stats_${ID}.csv

### rules:   if elevation of dam is greater than elevation of sample point AND accumulation of dam is less than accumulation of sample point, then the dam has an influence and distance should be kept, else no influence (NI)
v.report -c map=occurrrence_to_dams layer=1 option=length units=kilometers | awk -F"|" 'BEGIN{OFS=",";} {
if ($5 > $8 && $6 < $9)
	print $1, $4, $5, $6, $8, $9, $10, "Connected";
else
	print $1, $4, $5, $6, $8, $9, $10, "NotConnected";
}' > $TMP/damOut/dist_to_DAM_${ID}_${PN}.csv

done

EOF

rm $TMP/pointsIEA_${ID}.csvt $TMP/damsIEA_${ID}.csvt

exit
