#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc06a_distance_Crow.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc06a_distance_Crow.sh.%A_%a.err

#  scp /home/jaime/Code/environmental-data-extraction/sc06a_distance_Crow.sh grace:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
source ~/bin/grass78m

export DIR=$1

[ ! -d $DIR/output ] && mkdir $DIR/output

export OUTDIR=$DIR/output

# Name of column for unique ID
export SITE=$( awk -F, 'NR==1 {print $1}' $DIR/BasisDataBasinsIDs.csv )

###  Calculate Euclidean distance between all points
grass78  -f -text --tmp-location  -c EPSG:4326 <<'EOF'

#  import points
v.in.ogr --o input=$DIR/Locations_snap.gpkg layer=LocationSnap \
output=benthicEUall type=point key=$SITE

#  Calculate distance, results are given in meters
v.distance -pa from=benthicEUall to=benthicEUall upload=dist separator=comma \
> $OUTDIR/dist_matrix_all.csv

EOF

exit

