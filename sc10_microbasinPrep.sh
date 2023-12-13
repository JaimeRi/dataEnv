#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
##SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc10_microbasinPrep.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc10_microbasinPrep.sh.%A_%a.err
##SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc10_microbasinPrep.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# sbatch /home/jg2657/project/code/environmental-data-extraction/sc10_microbasinPrep.sh


# srun --pty -t 02:00:00 --mem=20G  --x11 -p interactive bash
source ~/bin/grass78m

export DIR=$1
export TMP=$2

grass78  -f -text --tmp-location  -c EPSG:4326 <<'EOF'

v.in.ogr  --o input=$DIR/BasisDataBasinsIDs.gpkg layer=orig_points output=benthicEU type=point key=Site_ID

FILES=$(find $TMP/basins/*/  -name '*micb.tif')
for ARCHIVO in ${FILES}; do
  name=$(basename $ARCHIVO _micb.tif)
  macro=$(echo $name | awk -F'_' '{print $2}')
  micro=$(v.db.select benthicEU | awk -F'|' -v micro=$macro 'NR > 1 && $4 == micro {print $5}' ORS=' ')
  for i in $micro; do
   echo $i = 1 >> $TMP/reclass_micb_${macro}.txt
  done
  echo '* = NULL' >>  $TMP/reclass_micb_${macro}.txt
  # echo "$micro= 1
  # * = NULL" > $TMP/reclass_micb_${macro}.txt
  r.in.gdal --o input=$ARCHIVO output=micb_${name}
  g.region rast=micb_${name}
  r.reclass --o input=micb_${name} output=micb_${name}_recl rules=$TMP/reclass_micb_${macro}.txt
  r.mapcalc --o "mic_only_${name} = if(micb_${name}_recl==1,micb_${name},null())"
  g.remove -fb --quiet type=raster name=micb_${name},micb_${name}_recl
  rm $TMP/reclass_micb_${macro}.txt
done

MAPS=`g.list type=raster separator=comma pat="mic_only_bid_*"`
g.region raster=$MAPS
r.patch --o input=$MAPS output=micb_EU

# calculate area of each microbasin
r.cell.area out=microbArea units=km2
r.univar --o -t map=microbArea zones=micb_EU output=$DIR/micb_area.csv sep=comma
cut -d, -f1,13 $DIR/micb_area.csv > $DIR/micb_area_final.csv
sed -i s/zone,sum/MicrobasinID,Area_km2/g $DIR/micb_area_final.csv

# export microbasin map
r.out.gdal --o -f -m -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=-9999 input=micb_EU output=$DIR/micb_ROI.tif

EOF

exit

#scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/micb_ROI.tif  /home/jaime/data/benthicEU/

### Calculate the number of pixels in each microbasin (proxy for area)
pkstat -i micb_EU.tif -hist > hist.txt
awk '$2 > 0 && $1 != -9999' hist.txt > mic_count.txt
