#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /vast/palmer/scratch/sbsc/jg2657/stdout/sc01c_UpstreamBasin.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/jg2657/stderr/sc01c_UpstreamBasin.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp /home/jaime/Code/environmental-data-extraction/sc01c_UpstreamBasin.sh  grace:/home/jg2657/project/code/environmental-data-extraction

# sbatch --time=02:00:00 --array=1-1896 /home/jg2657/project/code/environmental-data-extraction/sc01c_UpstreamBasin.sh /home/jg2657/project/BenthicEU  /home/jg2657/project/BenthicEU BasisDataBasinsIDs2.csv



#export MERITVAR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
#export DATASET=/home/jg2657/project/BenthicEU/BasisData.csv
#
### path to computational units
#export COMPUNIT=$MERITVAR/lbasin_compUnit_overview/lbasin_compUnit.tif
###  path to macrobasin
#export MACROB=$MERITVAR/lbasin_tiles_final20d_ovr/all_lbasin.tif
### path to microbasins
#export MICROB=$MERITVAR/hydrography90m_v.1.0/r.watershed/sub_catchment_tiles20d/sub_catchment.tif
#
#
#    paste -d "," $DATASET     \
#    <(printf "%s\n" CompUnitID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET \
#    | gdallocationinfo -valonly -geoloc  $COMPUNIT))   \
#    <(printf "%s\n" MacrobasinID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET \
#    | gdallocationinfo -valonly -geoloc  $MACROB))   \
#    <(printf "%s\n" MicrobasinID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET \
#    | gdallocationinfo -valonly -geoloc  $MICROB))    \
#    > $DIR/BasisDataBasinsIDs2.csv
#

module purge
source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export DIR=$1
export TMP=$2
export DATA=$3

export C=$(awk -F, -v row=$SLURM_ARRAY_TASK_ID 'NR==row+1 {print $4}' $DIR/$DATA)
export B=$(awk -F, -v row=$SLURM_ARRAY_TASK_ID 'NR==row+1 {print $5}' $DIR/$DATA)
export M=$(awk -F, -v row=$SLURM_ARRAY_TASK_ID 'NR==row+1 {print $6}' $DIR/$DATA)
export S=$(awk -F, -v row=$SLURM_ARRAY_TASK_ID 'NR==row+1 {print $1}' $DIR/$DATA)


#export B=$(awk -F, -v row=$1 'NR==row+1 {print $4}' $DIR/BasisDataBasinsIDs.csv)
#export M=$(awk -F, -v row=$1 'NR==row+1 {print $5}' $DIR/BasisDataBasinsIDs.csv)
#export S=$(awk -F, -v row=$1 'NR==row+1 {print $1}' $DIR/BasisDataBasinsIDs.csv)

export richt=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_dir

grass78 -f -text --tmp-location -c ${richt}/dir_${C}_msk.tif <<'EOF'

#  read direction map
r.external --o input=${richt}/dir_${C}_msk.tif output=dir

# calculate the sub-basin
r.water.outlet --overwrite input=dir output=bf_${S} \
    coordinates=$(awk -F, -v micid=${S} 'BEGIN{OFS=",";} $4==micid {print $1,$2}' \
    $DIR/Locations_snap.csv)

# zoom to the region of interest (only upstream basin extent)
g.region -a --o zoom=bf_${S}

#  Export the basin as tif file
r.out.gdal --o -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" \
    type=Int32  format=GTiff nodata=0 \
    input=bf_${S} output=$DIR/upstreamB/ubasin_${S}.tif

EOF

##  Cropping basin
#gdal_polygonize.py -8 -f "GPKG" \
#    $TMP/upstreamB/ubasin_${S}.tif \
#    $TMP/upstreamB/ubasin_${S}.gpkg
#
#EXTENSION=$( ogrinfo  $TMP/upstreamB/ubasin_${S}.gpkg -so -al \
#                | grep Extent | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' )
#ulx=$( echo $EXTENSION | awk '{print $1}' )
#uly=$( echo $EXTENSION | awk '{print $4}' )
#lrx=$( echo $EXTENSION | awk '{print $3}' )
#lry=$( echo $EXTENSION | awk '{print $2}' )
#
#pkcrop  -co COMPRESS=LZW -co ZLEVEL=9 -nodata 0 \
#    -i $TMP/upstreamB/ubasin_${S}.tif      \
#    -ulx $ulx -uly $uly -lrx $lrx -lry $lry     \
#    -o $TMP/upstreamB/UPS_basin_${S}.tif
#
#gdal_edit.py -a_nodata 0  $TMP/upstreamB/UPS_basin_${S}.tif
#
#rm $TMP/upstreamB/ubasin_${S}.gpkg \
#   $TMP/upstreamB/ubasin_${S}.tif 

exit


