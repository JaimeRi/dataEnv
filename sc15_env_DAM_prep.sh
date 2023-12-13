#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
###SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc15_env_DAM_prep.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc15_env_DAM_prep.sh.%A_%a.err
###SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc15_env_DAM_prep.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/scripts

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
module purge
source ~/bin/gdal3

export DIR={}

export MACROB=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_HYDRO/lbasin_tiles_final20d_ovr/all_lbasin.tif

export MICROB=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO/basin_tiles_final20d_ovr/all_basin_dis.vrt

export DAMP=$DIR/dam/dams_all.gpkg

export OUTDIR=$DIR/dam


######     DAM data preparation   #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# add new columns 
ogrinfo $DAMP -sql "ALTER TABLE Grand_Dams ADD COLUMN MacrobasinID INTEGER"
ogrinfo $DAMP -sql "ALTER TABLE Grand_Dams ADD COLUMN MicrobasinID INTEGER"

# identify macrobasin and microbasin id of each dam
BBID=$(ogrinfo $DAMP -al | awk -F "[()]" '/POINT/ {print $2}' | gdallocationinfo -valonly -geoloc  $MACROB)
MMID=$(ogrinfo $DAMP -al | awk -F "[()]" '/POINT/ {print $2}' | gdallocationinfo -valonly -geoloc  $MICROB)
FFID=$(ogrinfo $DAMP -al | awk -F":"  '/OGRFeature/{print $2}')
MAXNUM=$(ogrinfo $DAMP -al -so | awk '/Feature Count/ {print $3}')

## fill in the new columns
time for i in $(seq 1 $MAXNUM); do # takes 21 minutes
  echo $i
  echo .....
  macroid=$(printf "%s\n" $BBID | head -n $i | tail -n 1)
  microid=$(printf "%s\n" $MMID | head -n $i | tail -n 1)
  fidid=$(printf "%s\n" $FFID | head -n $i | tail -n 1)
  ogrinfo $DAMP -dialect SQLite -sql "UPDATE Grand_Dams SET MacrobasinID =  $macroid WHERE fid = $fidid"
  ogrinfo $DAMP -dialect SQLite -sql "UPDATE Grand_Dams SET MicrobasinID =  $microid WHERE fid = $fidid"
  echo ....
done

# list of macrobasins ID (apend commas for the ogr2ogr format)
LISTMC=$(awk -F, 'FNR > 1 {print $4}' $DIR/BasisDataBasinsIDs.csv | sort | uniq | awk '{print}' ORS=','  | sed 's/,*$//g')

# extract only dams for the macrobasins of interest
ogr2ogr $OUTDIR/dams_roi.gpkg $DAMP -nln dams_benthic_EU -sql "SELECT * FROM Grand_Dams WHERE MacrobasinID IN ($LISTMC)"
