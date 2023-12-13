#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01d_LandCover_prop.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01d_LandCover_prop.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp /home/jaime/Code/environmental-data-extraction/sc01d_LandCover_prop.sh  grace:/home/jg2657/project/code/environmental-data-extraction

# make folders to store output
# mkdir $DIR/esa_rast $DIR/esa_txt

#cat > $DIR/esa_cat_once.txt << EOF
#10 11 12 = 10
#20 = 20
#30 = 30
#40 = 40
#50 = 50
#60 61 62 = 60
#70 71 72 = 70
#80 81 82 = 80
#90 = 90
#100 = 100
#110 = 110
#120 121 122 = 120 
#130 = 130
#140 = 140
#150 151 152 153 = 150
#160 = 160
#170 = 170
#180 = 180
#190 = 190
#200 201 202 = 200
#210 = 210
#220 = 220
#EOF

##   array = iSite IDs * N.years
#for i in $(awk -F, 'NR > 1 {print $1}' BasisDataBasinsIDs.csv); do for j in {1992..2018};do echo $i $j;done;done > $DIR/upst_lc_array.txt

# sbatch --time=00:20:00 --array=1-$(wc -l < $DIR/upst_lc_array.txt) /home/jg2657/project/code/environmental-data-extraction/sc01d_LandCover_prop.sh $DIR $TMP $DIR/upst_lc_array.txt

# sbatch --time=00:20:00 --array=1-54 /home/jg2657/project/code/environmental-data-extraction/sc01d_LandCover_prop.sh /home/jg2657/project/BenthicEU /home/jg2657/scratch60 /home/jg2657/project/BenthicEU/upst_lc_array.txt

module purge
source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m
 
# Calculate land cover proportion in each ubasin

################-----------------------------
##  Land Cover Proportion:
###############------------------------------

# location of ESA land cover data
#export LCESA=/mnt/shared/data_from_yale/dataproces/ESALC/input
export LCESA=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/input

export DIR=$1  # /home/jg2657/project/BenthicEU 
export TMP=$2  # /home/jg2657/scratch60


# Site ID
#export S=$3
export S=$(awk -v row=$SLURM_ARRAY_TASK_ID ' NR==row {print $1}' $3)
# Year
#export YEAR=$4
export YEAR=$(awk -v row=$SLURM_ARRAY_TASK_ID ' NR==row {print $2}' $3)

#[ -f $DIR/esa_txt/esa_ub_${S}_${YEAR}.txt ] && exit

# Upstream Basin
export UB=$TMP/upstreamB/UPS_basin_${S}.tif

# Land COver file
export LCTIF=$LCESA/ESALC_${YEAR}.tif

ulx=$( gdalinfo $UB \
    | grep 'Upper Left' | awk '{print $4}' | sed 's/,//g' )
uly=$( gdalinfo $UB \
    | grep 'Upper Left' | awk '{print $5}' | sed 's/)//g' )
lrx=$( gdalinfo $UB \
    | grep 'Lower Right' | awk '{print $4}' | sed 's/,//g')
lry=$( gdalinfo $UB \
    | grep 'Lower Right' | awk '{print $5}' | sed 's/)//g' )

[ -f $DIR/esa_rast/esa_ub_${S}_tmp.tif ] && rm $DIR/esa_rast/esa_ub_${S}_tmp.tif

gdalwarp  -co COMPRESS=LZW -co ZLEVEL=9 -dstnodata 0 \
    -te $ulx $lry $lrx $uly  \
    -tr 0.000833333333333 -0.000833333333333  \
    $LCTIF \
    $DIR/esa_rast/esa_ub_${S}_${YEAR}_tmp.tif

pksetmask -co COMPRESS=LZW -co ZLEVEL=9  \
    -i $DIR/esa_rast/esa_ub_${S}_${YEAR}_tmp.tif  \
    -m $UB -msknodata 0 -nodata 0 \
    -o $DIR/esa_rast/esa_ub_${S}_${YEAR}.tif

grass78 -f -text --tmp-location -c $DIR/esa_rast/esa_ub_${S}_${YEAR}.tif <<'EOF'
    r.in.gdal input=$DIR/esa_rast/esa_ub_${S}_${YEAR}.tif output=esa_ub_${S}_${YEAR}
    ## reclass
    r.reclass --o input=esa_ub_${S}_${YEAR} output=rcl_esa_ub_${S}_${YEAR} \
    rules=$DIR/esa_cat_once.txt
    ## stats calc
    r.stats -an in=rcl_esa_ub_${S}_${YEAR} > $DIR/esa_txt/esa_ub_${S}_${YEAR}.txt
EOF
 
    SUMTOT=$( awk '{sum+=$2;} END {print sum;}' \
        $DIR/esa_txt/esa_ub_${S}_${YEAR}.txt )

    awk -v TOTAL=$SUMTOT '{print $0, $3=$2/TOTAL}' \
        $DIR/esa_txt/esa_ub_${S}_${YEAR}.txt \
        > $DIR/esa_txt/f_esa_ub_${S}_${YEAR}.txt

mv $DIR/esa_txt/f_esa_ub_${S}_${YEAR}.txt $DIR/esa_txt/esa_ub_${S}_${YEAR}.txt

rm $DIR/esa_rast/esa_ub_${S}_${YEAR}_tmp.tif $DIR/esa_rast/esa_ub_${S}_${YEAR}.tif

#zip esa_rast.zip esa_rast/* 
#zip esa_txt.zip esa_txt/* 
#rclone copy esa_txt.zip YaleGDrive:gtrend
#rclone copy esa_rast.zip YaleGDrive:gtrend

