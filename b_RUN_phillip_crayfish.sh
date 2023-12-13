# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

export DIR=/home/jg2657/project/phillip/crayfish

mkdir /home/jg2657/scratch60/tmpcrayfish
export TMP=/home/jg2657/scratch60/tmpcrayfish

## create folder to save final outputs
mkdir $DIR/final
export FINAL=$DIR/final

# (Wenn es sich bei der Temperatur bei euch auch um Luft-Daten handelt dann brauchts nicht - hab ja bereits E-OBS. Selbiges gilt demnach wohl auch für die NIederschlagsdaten.)
# 1. Precipitation --> local or upstream accumulated? which time period?
# 2. Mean temperature oder Annual mean temperature as the mean of the monthly temperatures (°C)
# 3. Runoff --> annual flow, which time period? Or multi-year average?  Runoff wären annuelle Werte super.
# 4. NH4 und NO3 input --> need to check coverage for study region
# 5. stream order --> OK
# 6. stream slope --> OK
# 7. Elevation --> OK
# 8. Etwaige Informationen über die Landnutzung --> annual data, which time period is needed? local and / or upstream average? Landnutzung reicht annual data im Bezug zur local Site.
# 9. Die Distanz zum Outlet wäre aber sicherlich interessant!

INPUTTB=$DIR/Longterm_crayfish_meta.csv
dos2unix $INPUTTB  # some columns have trailing spaces and need to be repair

# replace headers (Is this important?)
sed -i 's/site_id,Latitude,Longitude/Site_ID,Latitude_Y,Longitude_X/g' $INPUTTB

# re-order columns to have site_id, long, lat
awk -F, 'BEGIN{OFS=",";} {print $1, $3, $2}' $INPUTTB > $DIR/BasisData.csv

### Check that the unique ID is really unique!
awk -F, '{print $1}' $DIR/BasisData.csv | sort | uniq -c | awk '$1 > 1 '

###   RUN SC01
bash /home/jg2657/project/code/environmental-data-extraction/sc01_basinID.sh $DIR

## figure out how many basins
export NMC=$(awk -F, 'FNR > 1 {print $4}' $DIR/BasisDataBasinsIDs.csv | sort | uniq | wc -l)

###   RUN SC02
mkdir $TMP/basins

sbatch --array=1-${NMC} --time=00:20:00 /home/jg2657/project/code/environmental-data-extraction/sc02_envprep.sh $DIR $TMP

###   RUN SC03
sbatch --array=1-${NMC} --time=03:00:00  /home/jg2657/project/code/environmental-data-extraction/sc03_streamOrderSlope.sh $DIR $TMP

# check that all folders have the same number of files
for file in $( ls $TMP/basins); do 	echo $file : $(ls $TMP/basins/$file | wc -l); done

###  RUN SC04
mkdir $TMP/snappoints

sbatch --array=1-${NMC}  --time=02:00:00   /home/jg2657/project/code/environmental-data-extraction/sc04_snapping.sh $DIR $TMP

### RUN SC05
bash /home/jg2657/project/code/environmental-data-extraction/sc05_merge_snapping.sh $DIR $TMP

#  remove temporal files and folders
rm -rf $TMP/snappoints

### RUN SC08
mkdir $TMP/variables

sbatch --array=1-${NMC}  --time=00:30:00  /home/jg2657/project/code/environmental-data-extraction/sc08_environmLayers.sh $DIR $TMP

### RUN SC09
mkdir $DIR/statsOUT

bash /home/jg2657/project/code/environmental-data-extraction/sc09_Join_environmLayers.sh $DIR $TMP $FINAL

rm $TMP/tojoin_ENV.csv $TMP/temp_*.csv
rm -rf $TMP/variables $DIR/statsOUT

###  RUN SC10
sbatch /home/jg2657/project/code/environmental-data-extraction/sc10_microbasinPrep.sh  $DIR $TMP

###  RUN SC11
mkdir $DIR/terraN

sbatch /home/jg2657/project/code/environmental-data-extraction/sc11_environmTERRA.sh  $DIR $FINAL

rm -rf $DIR/terraN

### RUN SC12

mkdir $TMP/esa_stats/

# location of esa tif files
export ESATIF=/gpfs/loomis/project/sbsc/hydro/dataproces/ESALC/input

cat > $DIR/esa_categories.txt << EOF
10 "cropland, rainfed" 10 11 12
20 "cropland, irrigated or post-flooding" 20
30 "Mosaic cropland (>50%) / natural vegetation (tree, shrub, herbaceous cover) (<50%)" 30
40 "Mosaic natural vegetation (tree, shrub, herbaceous cover) (>50%) / cropland (<50%)" 40
50 "Tree cover, broadleaved, evergreen, closed to open (>15%)" 50
60 "Tree cover, broadleaved, deciduous, closed to open (>15%)" 60 61 62
70 "Tree cover, needleleaved, evergreen, closed to open (>15%)" 70 71 72
80 "Tree cover, needleleaved, deciduous, closed to open (>15%)" 80 81 82
90 "Tree cover, mixed leaf type (broadleaved and needleleaved)" 90
100 "Mosaic tree and shrub (>50%) / herbaceous cover (<50%)" 100
110 "Mosaic herbaceous cover (>50%) / tree and shrub (<50%)" 110
120 "Shrubland" 120 121 122
130 "Grassland" 130
140 "Lichens and mosses" 140
150 "Sparse vegetation (tree, shrub, herbaceous cover) (<15%)" 150 151 152 153
160 "Tree cover, flooded, fresh or brackish water" 160
170 "Tree cover, flooded, saline water" 170
180 "Shrub or herbaceous cover, flooded, fresh/saline/brackish water" 180
190 "Urban areas" 190
200 "Bare areas" 200 201 202
210 "Water bodies" 210
220 "Permanent snow and ice" 220
EOF

sbatch --array=1-27 --time=01:00:00  /home/jg2657/project/code/environmental-data-extraction/sc12_environmESA.sh $DIR $TMP $ESATIF

rm $TMP/esa_stats/reclass_*

###  RUN SC13
sbatch  --time=00:05:00  /home/jg2657/project/code/environmental-data-extraction/sc13_Join_environmESA.sh $DIR $TMP $FINAL

rm -rf $STATDIR/ESA_stats.csv $STATDIR/stats_esa* $TEMP/temp_ESA* $TEMP/tojoin* $TEMP/esa_stats


####  COpy output to YaleGDrive

cd $DIR
rclone mkdir YaleGDrive:phillip/crayfish
rclone copy ./final YaleGDrive:phillip/crayfish

rclone copy /home/jg2657/project/phillip/crayfish/esa_categories.txt YaleGDrive:phillip/crayfish

rclone copy /home/jg2657/project/phillip/crayfish/Locations_snap.gpkg YaleGDrive:phillip/crayfish
