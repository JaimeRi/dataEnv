#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
####SBATCH -t 00:10:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_envprep.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_envprep.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp /home/jaime/Code/environmental-data-extraction/sc02_envprep.sh grace:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
module purge
source ~/bin/gdal3
source ~/bin/pktools

########-------------------------------------------
######### Steps to extract layers for a macro-basin
########-------------------------------------------


export DIR=$1
export TMP=$2

export BASIN=$TMP/basins

FOLDER=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_HYDRO_BK

export MACROBLR=$FOLDER/lbasin_tiles_final20d_ovr/all_lbasin_5p.tif

export MACROB=$FOLDER/lbasin_tiles_final20d_ovr/all_lbasin.tif

ID=$( echo $(awk -F, 'FNR > 1 {print $4}' $DIR/BasisDataBasinsIDs.csv \
    | sort | uniq) | awk -v id=$SLURM_ARRAY_TASK_ID '{print $id}' )

[ ! -d $TMP/basins ] && mkdir $TMP/basins

while [ ! -d $BASIN/basin_$ID ]
do
    mkdir $BASIN/basin_$ID
    BASINDIR=$BASIN/basin_$ID

    # create mask of macrobasin of interest based on the low resolution file
    pksetmask -co COMPRESS=LZW -co ZLEVEL=9 -ot UInt32 \
        -i $MACROBLR -m $MACROBLR  --operator='!' --msknodata ${ID} \
        --nodata 0 -o $TMP/bid${ID}.vrt

    # poligonizing extension
    gdal_polygonize.py -8 -f "GPKG" $TMP/bid${ID}.vrt $TMP/bid${ID}.gpkg

    # extract coordinates of bbox
    EXTENSION=$( ogrinfo $TMP/bid${ID}.gpkg -so -al | grep Extent \
        | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' )
    #  add a bit of space around the basin
    ulx=$( echo $( echo $EXTENSION | awk '{print $1}' ) - 0.02 | bc )
    uly=$( echo $( echo $EXTENSION | awk '{print $4}' ) + 0.02 | bc )
    lrx=$( echo $( echo $EXTENSION | awk '{print $3}' ) + 0.02 | bc )
    lry=$( echo $( echo $EXTENSION | awk '{print $2}' ) - 0.02 | bc )

    # crop macro basin based on the known extent and now using the high 
    # resolution macrobasin file
    gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
        -projwin $ulx $uly $lrx $lry $MACROB $TMP/bid_${ID}_mask.tif

    # create final macrobasin mask
    pksetmask -co COMPRESS=LZW -co ZLEVEL=9 -ot UInt32 \
        -i $TMP/bid_${ID}_mask.tif -m $TMP/bid_${ID}_mask.tif \
        --operator='!' --msknodata ${ID} --nodata 0 \
        -o $BASINDIR/bid_${ID}_mask.tif

    ########-------------------------------------------
    ######### Elevation
    ########-------------------------------------------

    ELEV=/gpfs/loomis/project/sbsc/hydro/dataproces/MERIT_HYDRO/elv/all_tif_dis.vrt

    # crop to extent of interest
    gdal_translate -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
        -projwin $ulx $uly $lrx $lry $ELEV  $TMP/Elevation_bid_${ID}.vrt

    # mask variable values to macro basin of interest
    pksetmask  -co  COMPRESS=DEFLATE  -co ZLEVEL=9 \
        -m $BASINDIR/bid_${ID}_mask.tif -msknodata 0 -nodata -9999 \
        -i $TMP/Elevation_bid_${ID}.vrt -o $BASINDIR/bid_${ID}_elev.tif

    ########-------------------------------------------
    ########  Flow accumulation
    ########-------------------------------------------

    FLOW=$FOLDER/flow_tiles/all_tif_dis.vrt

    gdal_translate -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
        -projwin $ulx $uly $lrx $lry $FLOW $TMP/FlowAccumulation_bid_${ID}.vrt

    pksetmask -co  COMPRESS=DEFLATE  -co ZLEVEL=9 \
        -m $BASINDIR/bid_${ID}_mask.tif -msknodata 0 -nodata  -9999999 \
        -i $TMP/FlowAccumulation_bid_${ID}.vrt -o $BASINDIR/bid_${ID}_accu.tif

    ########-------------------------------------------
    ########  Flow direction
    ########-------------------------------------------

    DIRECTION=$FOLDER/dir_tiles_final20d_ovr/all_dir_dis.vrt

    gdal_translate -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
        -projwin $ulx $uly $lrx $lry $DIRECTION  $TMP/FlowDirection_bid_${ID}.vrt

    pksetmask  -co  COMPRESS=DEFLATE  -co ZLEVEL=9 \
        -m $BASINDIR/bid_${ID}_mask.tif  -msknodata 0 -nodata -10 \
        -i  $TMP/FlowDirection_bid_${ID}.vrt  -o $BASINDIR/bid_${ID}_dire.tif

    ########-------------------------------------------
    ########  Stream network
    ########-------------------------------------------

    #STREAM=/home/jg2657/project/data/stream_uniq.vrt
    STREAM=$FOLDER/stream_tiles_final20d_ovr/all_stream_dis.vrt

    gdal_translate -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
        -projwin $ulx $uly $lrx $lry $STREAM $TMP/Stream_bid_${ID}.vrt

    pksetmask  -co  COMPRESS=DEFLATE  -co ZLEVEL=9 \
        -m $BASINDIR/bid_${ID}_mask.tif  -msknodata 0 -nodata 0 \
        -i $TMP/Stream_bid_${ID}.vrt -o $BASINDIR/bid_${ID}_stre.tif

    ########-------------------------------------------
    ########  Micro basins
    ########-------------------------------------------

    SUBBASIN=$FOLDER/CompUnit_basin_uniq_tiles20d/all_tif_basin_uniq_dis.vrt

    gdal_translate -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
        -projwin $ulx $uly $lrx $lry $SUBBASIN  $TMP/MicroBasin_bid_${ID}.vrt

    pksetmask  -co  COMPRESS=DEFLATE  -co ZLEVEL=9 \
        -m $BASINDIR/bid_${ID}_mask.tif -msknodata 0 -nodata 0 \
        -i $TMP/MicroBasin_bid_${ID}.vrt -o $BASINDIR/bid_${ID}_micb.tif

    ########-------------------------------------------
    ######## Slope 
    ########-------------------------------------------

    SLOPE=$FOLDER/CompUnit_stream_slope_tiles20d/all_tif_stream_slope_grad_dis.vrt
    
    gdal_translate -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
        -projwin $ulx $uly $lrx $lry $SLOPE $TMP/slope_bid_${ID}.vrt

    pksetmask  -co  COMPRESS=DEFLATE  -co ZLEVEL=9 \
        -m $BASINDIR/bid_${ID}_mask.tif -msknodata 0 -nodata 0 \
        -i $TMP/slope_bid_${ID}.vrt -o $BASINDIR/bid_${ID}_slop.tif

    ########-------------------------------------------

    rm $TMP/*${ID}*

done

exit


