#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc05_merge_snapping.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc05_merge_snapping.sh.%A_%a.err

#  scp  /home/jaime/Code/environmental-data-extraction/sc05_merge_snapping.sh grace:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

module purge
source ~/bin/gdal3

export DIR=$1
export TMP=$2

# First create the gpkg file
export LISTFILES=$(find  $TMP/snappoints/ -name 'basin_*.gpkg')

ogrmerge.py -o $DIR/Locations_snap.gpkg  $LISTFILES -f "GPKG" -single -nln LocationSnap -overwrite_ds

# Make also the csv file
ogr2ogr -f "CSV" -lco STRING_QUOTING=IF_NEEDED $DIR/Locations_snap.csv $DIR/Locations_snap.gpkg

# remove temporal files and folders
#rm -rf $TMP/snappoints

exit

