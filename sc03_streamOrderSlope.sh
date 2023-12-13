#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc03_streamOrderSlope.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc03_streamOrderSlope.sh.%A_%a.err

#  scp /home/jaime/Code/environmental-data-extraction/sc03_streamOrderSlope.sh grace:/home/jg2657/project/code/environmental-data-extraction

# sbatch /home/jg2657/project/BenthicEU/scripts/sc03_streamOrderSlope.sh

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
module purge
source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export DIR=$1
export TMP=$2

export BASIN=$TMP/basins

# Macro-basin
export ID=$( echo $(awk -F, 'FNR > 1 {print $4}' $DIR/BasisDataBasinsIDs.csv | \
    sort | uniq) | awk -v id=$SLURM_ARRAY_TASK_ID '{print $id}' )

# exit run if variables already calculated
[ $(ls $TMP/basins/basin_$ID | wc -l) -eq 9  ] && exit

####  is it better to create a specific location and not tmp to avoid conflict when running in parallel?
grass78 -f -text --tmp-location -c $BASIN/basin_${ID}/bid_${ID}_mask.tif <<'EOF'

###  import data

echo stre elev dire accu | xargs -n 1 -P 1 bash -c $'
r.external  input=$BASIN/basin_${ID}/bid_${ID}_${1}.tif output=$1 --overwrite
' _

#----------------------
#####    STREAM ORDER
#----------------------

		r.stream.order  --o stream_rast=stre direction=dire elevation=elev \
        accumulation=accu stream_vect=orderV_bid${ID} \
        strahler=orderStrahler_bid${ID} memory=50000

		# Save outputs

		r.out.gdal --o -f -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 \
        format=GTiff nodata=-9999 input=orderStrahler_bid${ID} \
        output=$BASIN/basin_${ID}/bid_${ID}_stre_order.tif

		v.out.ogr --o input=orderV_bid${ID} \
        output=$BASIN/basin_${ID}/bid_${ID}_stre_order.gpkg format="GPKG" \
        type=line output_type=line

		#----------------------
		#####    STREAM SLOPE
		#----------------------
		#r.mask raster=elev

		#r.stream.slope direction=dire elevation=elev gradient=gradient \
        #--o --verbose

		#r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  \
        #type=Float64 format=GTiff nodata=-9999  input=gradient  \
        #output=$BASIN/basin_${ID}/bid_${ID}_slope.tif


EOF


exit

sacct -j 18195145 --format=JobID,State,Elapsed

scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/basins/basin_1094549/bid_1094549_slope.tif  /home/jaime/data/benthicEU/basins/basin_1094549


###  CHecking
for DIR in $( ls $BASIN); do 	echo $DIR : $(ls $BASIN/$DIR | wc -l); done
for FILE in $(find $BASIN/*  -name '*_slope.tif'); do wc -c $FILE | awk '{print $1/1000000}'; done
find $BASIN/*  -name '*_slope.tif' | wc -l
find $BASIN/*  -name '*stre_order.gpkg' | wc -l
