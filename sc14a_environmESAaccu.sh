#!/bin/bash

#SBATCH -p day ####scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc14a_environmESAaccu.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc14a_environmESAaccu.sh.%A_%a.err
#SBATCH --mem-per-cpu=8000M
#SBATCH --array=1-27

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc14a_environmESAaccu.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/scripts

# sbatch /home/jg2657/project/BenthicEU/scripts/sc14a_environmESAaccu.sh

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

module purge
source ~/bin/gdal3

###  LAND COVER CATEGORIES BASED ON:
#https://datastore.copernicus-climate.eu/documents/satellite-land-cover/D3.3.12-v1.2_PUGS_ICDR_LC_v2.1.x_PRODUCTS_v1.2.pdf

# 10  cropland, rainfed 10  11  12
# 20  cropland, irrigated or post-flooding  20
# 30  Mosaic cropland (>50%) / natural vegetation (tree, shrub, herbaceous cover) (<50%)  30
# 40  Mosaic natural vegetation (tree, shrub, herbaceous cover) (>50%) / cropland (<50%)  40
# 50  Tree cover, broadleaved, evergreen, closed to open (>15%) 50
# 60  Tree cover, broadleaved, deciduous, closed to open (>15%) 60  61  62
# 70  Tree cover, needleleaved, evergreen, closed to open (>15%)  70 71  72
# 80  Tree cover, needleleaved, deciduous, closed to open (>15%)  80  81  82
# 90  Tree cover, mixed leaf type (broadleaved and needleleaved)  90
# 100 Mosaic tree and shrub (>50%) / herbaceous cover (<50%)  100
# 110 Mosaic herbaceous cover (>50%) / tree and shrub (<50%)  110
# 120 Shrubland 120 121 122
# 130 Grassland 130
# 140 Lichens and mosses  140
# 150 Sparse vegetation (tree, shrub, herbaceous cover) (<15%)  150 151 152 153
# 160 Tree cover, flooded, fresh or brackish water  160
# 170 Tree cover, flooded, saline water 170
# 180 Shrub or herbaceous cover, flooded, fresh/saline/brackish water 180
# 190 Urban areas 190
# 200 Bare areas  200 201 202
# 210 Water bodies  210
# 220 Permanent snow and ice  220

export DIR=/home/jg2657/project/BenthicEU
export TEMP=/home/jg2657/scratch60/esa_accu

mkdir -p $TEMP

export LCACCU=/gpfs/loomis/project/sbsc/hydro/dataproces/ESALC
export ESALC=$DIR/ESALC



export YEAR=$(echo 1991 + $SLURM_ARRAY_TASK_ID | bc)

cat $DIR/BasisDataBasinsIDs.csv | awk -F',' 'BEGIN{OFS=",";} {print $1, $2, $3}' > $TEMP/ESALC_ACCU_${YEAR}.csv


for CAT in 10 11 12 20 30 40 50 60 61 62 70 71 72 80 81 90 100 110 120 121 122 130 140 150 152 153 160 170 180 190 200 201 202 210 220; do

  echo ---------------------------------------------
  echo Calculating year = $YEAR and category = $CAT
  echo ---------------------------------------------

    FILE=${LCACCU}/LC${CAT}_acc/${YEAR}/LC${CAT}_Y${YEAR}.vrt

    paste -d "," $TEMP/ESALC_ACCU_${YEAR}.csv  \
    <(printf "%s\n" LC_${CAT}_${YEAR} $(awk -F, 'FNR > 1 {print $2, $3}' $TEMP/ESALC_ACCU_${YEAR}.csv | gdallocationinfo -valonly -geoloc  ${FILE})) \
    > $TEMP/ESALC_ACCU_${YEAR}_cp.csv

    mv $TEMP/ESALC_ACCU_${YEAR}_cp.csv $TEMP/ESALC_ACCU_${YEAR}.csv

done


exit
