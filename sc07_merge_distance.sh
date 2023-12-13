#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc07_merge_distance.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc07_merge_distance.sh.%A_%a.err

#  scp /home/jaime/Code/environmental-data-extraction/sc07_merge_distance.sh grace:/home/jg2657/project/code/environmental-data-extraction

export DIR=$1
export OUTDIR=$DIR/distance

###  These are distance calculation between all pairs within a basin

echo 'Site_ID_from,Site_ID_to,distanceKM' > $OUTDIR/tb_dist_fly.csv
for FILE in $(find $OUTDIR/dist_fly/ -name 'dist_fly_*'); do
awk 'FNR > 1' $FILE >> $OUTDIR/tb_dist_fly.csv
done

echo 'Site_ID_from,Site_ID_to,distanceKM' > $OUTDIR/tb_dist_fish.csv
for FILE in $(find $OUTDIR/dist_fish/ -name 'dist_fish_*'); do
  awk 'FNR > 1' $FILE >> $OUTDIR/tb_dist_fish.csv
done

rm -rf $OUTDIR/dist_fish  $OUTDIR/dist_fly

exit

module load R/3.6.1-foss-2018b-X11-20180604
R
library(tidyr)
tb = read.csv("tb_dist_fly.csv")
pivot_wider(tb, names_from = c(Site_ID_from), values_from = distanceKM)
