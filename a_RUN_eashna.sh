# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

export DIR=/home/jg2657/project/aeshna
mkdir /home/jg2657/scratch60/aeshna
export TMP=/home/jg2657/scratch60/aeshna
export SC=/home/jg2657/project/code/environmental-data-extraction

##########---------------------------------------------------------------
####  CHUNK 1

# Prepare database as required to run through the scripts, that is, a three
# column, comma separated table with record ID, longitud and latitud.
dos2unix $DIR/aeshna_occurr.csv

awk -F, 'BEGIN{OFS=","}; {print $2, $5, $6}' $DIR/aeshna_occurr.csv > $DIR/initialDB.csv

##########---------------------------------------------------------------
####  CHUNK 2

# Extract basin and subcatchment IDs
# the script needs three parameters:
# 1. main directory
# 2. temporal directory
# 3. name of the initial database (with ID, long, lat)
sbatch --time=00:10:00 --ntasks=10 $SC/sc01_basinID.sh $DIR $TMP initialDB.csv 

##########---------------------------------------------------------------
