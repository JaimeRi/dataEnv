#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
####SBATCH -t 5:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc12_environmESA.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc12_environmESA.sh.%A_%a.err
#SBATCH --mem-per-cpu=10000M
###SBATCH --array=1-27

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc12_environmESA.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# sacct -j 18699015  --format=JobID,State,Elapsed

# sbatch /home/jg2657/project/BenthicEU/scripts/sc12_environmESA.sh

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

source ~/bin/grass78m

###  LAND COVER CATEGORIES BASED ON:
#https://datastore.copernicus-climate.eu/documents/satellite-land-cover/D3.3.12-v1.2_PUGS_ICDR_LC_v2.1.x_PRODUCTS_v1.2.pdf


#export DIR=/home/jg2657/project/BenthicEU
export DIR=$1
#export TMP=/home/jg2657/scratch60
export TMP=$2

# location of ESALC tif files
export ESATIF=$3 #/gpfs/loomis/project/sbsc/hydro/dataproces/ESALC/input


#export ESALC=$DIR/ESALC

export YEAR=$(echo 1991 + $SLURM_ARRAY_TASK_ID | bc)

grass78  -f -text --tmp-location  -c $DIR/micb_ROI.tif <<'EOF'

r.in.gdal --o input=$DIR/micb_ROI.tif output=micb
r.in.gdal --o input=$ESATIF/ESALC_${YEAR}.tif output=esalc

cut -d' ' -f1 $DIR/esa_categories.txt | xargs -I % -P 1 bash -c $'

CAT=%
CATIDS=$(cat $DIR/esa_categories.txt | cut -d \'"\' -f3 \
    | awk -v CAT=$CAT \'$1==CAT\')

echo "$CATIDS = 1
* = NULL" > $TMP/esa_stats/reclass_esa_${YEAR}_${CAT}.txt

r.reclass --o input=esalc output=esalc_recl_${YEAR}_${CAT} \
    rules=$TMP/esa_stats/reclass_esa_${YEAR}_${CAT}.txt

# Take $1 zone (microbasin), $3+$4 NON_null_cells+null_cells  
# (total number of cells in microbasin), $13 number of pixels with values 
# (in this case same as $3 because values are 1 or 0). 
# $13/($3+$4) > proportion of cells with values 
# (proportion of category i in microbasin)

r.univar -t map=esalc_recl_${YEAR}_${CAT} zones=micb separator=comma \
    | awk -F, \'FNR > 1 {print $1, $3+$4, $13, $13/($3+$4)}\' \
    > $TMP/esa_stats/stats_esa_${YEAR}_${CAT}.txt

' _

EOF


exit

for FILE in $(find ./tmp/esa_stats/ -name "stats*"); do cat $FILE | wc -l; done
for FILE in $(find ./tmp/esa_stats/ -name "stats*"); do cat $FILE | awk '{print NF}' | sort | uniq; done | sort | uniq
