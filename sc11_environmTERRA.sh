#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc11_environmTERRA.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc11_environmTERRA.sh.%A_%a.err
#SBATCH --mem-per-cpu=10000M


#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc11_environmTERRA.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# sbatch /home/jg2657/project/BenthicEU/scripts/sc11_environmTERRA.sh

# Actual Evapotranspiration (TERRACLIMATE) (aet) (4km)
# Precipitation (TERRACLIMATE) (ppt) (4km)
# Runoff (TERRACLIMATE) (q) (4km)
# Max Temperature (TERRACLIMATE) (tmax) (4km)
# Min Temperature (TERRACLIMATE) (tmin) (4km)
# NH4_input (55km)
# NO3_input (55km)

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
source ~/bin/gdal3

#export DIR=/home/jg2657/project/BenthicEU
export DIR=$1

export FINAL=$2

export TERRA=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA

export OUTDIR=$3

export NITRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO

export GIA=/gpfs/gibbs/pi/hydro/hydro/dataproces/GIA/global_irrigated_areas

######  Calculation of irrigated areas

#awk 'BEGIN{OFS=","; FPAT = "([^,]*)|(\"[^\"]*\")"} {print $1, $4, $5, $8, $9}' $DIR/BenthicEU.csv  >  $OUTDIR/GIA.csv
#cp $DIR/BasisDataBasinsIDs.csv $OUTDIR/GIA.csv
#cp $DIR/Locations_snap.csv $OUTDIR/GIA.csv
awk -F, 'BEGIN {OFS=","} {print $3, $1, $2, $8, $9}' $DIR/Locations_snap.csv \
    > $OUTDIR/GIA.csv

paste -d "," $OUTDIR/GIA.csv  \
<(printf "%s\n" $(echo irrigated) $( awk -F, 'FNR > 1 {print $2, $3}' $OUTDIR/GIA.csv | gdallocationinfo -valonly -geoloc  ${GIA}/global_irrigated_areas_4c.tif ))  \
> $OUTDIR/GIA_cp.csv

#awk -F, '{print $4, $10}' 
mv $OUTDIR/GIA_cp.csv $FINAL/GIA.csv

######  Calculation of TERRACLIMATE

for VARTERRA in aet ppt q tmax tmin ; do

awk -F, 'BEGIN {OFS=","} {print $3, $1, $2, $8, $9}' $DIR/Locations_snap.csv \
    > $OUTDIR/TERRA_${VARTERRA}.csv

    for YEAR in {1958..2019} ; do

    echo "Calculating $VARTERRA ---- year $YEAR"

          for MES in {01..12} ; do

                  paste -d "," $OUTDIR/TERRA_${VARTERRA}.csv  \
                  <(printf "%s\n" ${VARTERRA}_${YEAR}_${MES} $(awk -F, 'FNR > 1 {print $2, $3}' $OUTDIR/TERRA_${VARTERRA}.csv | gdallocationinfo -valonly -geoloc  ${TERRA}/${VARTERRA}/${VARTERRA}_${YEAR}_${MES}.tif)) \
                  > $OUTDIR/TERRA_${VARTERRA}_cp.csv

                  mv $OUTDIR/TERRA_${VARTERRA}_cp.csv $OUTDIR/TERRA_${VARTERRA}.csv
          done

    done

    mv $OUTDIR/TERRA_${VARTERRA}.csv $FINAL/TERRA_${VARTERRA}.csv

done


######  Calculation of Nitrogen fertilizer

for VAR in NH4 NO3 ; do

awk -F, 'BEGIN {OFS=","} {print $3, $1, $2, $8, $9}' $DIR/Locations_snap.csv \
    > $OUTDIR/NITRO_${VAR}.csv

  for YEAR in {1961..2010} ; do

    echo "Calculating $VAR ---- year $YEAR"

          for MES in {01..12} ; do

                  paste -d "," $OUTDIR/NITRO_${VAR}.csv  \
                  <(printf "%s\n" ${VAR}_${YEAR}_${MES} $(awk -F, 'FNR > 1 {print $2, $3}' $OUTDIR/NITRO_${VAR}.csv | gdallocationinfo -valonly -geoloc  ${NITRO}/${VAR}/${VAR}_${YEAR}_${MES}.tif)) \
                  > $OUTDIR/NITRO_${VAR}_cp.csv

                  mv $OUTDIR/NITRO_${VAR}_cp.csv $OUTDIR/NITRO_${VAR}.csv
          done

  done

  mv $OUTDIR/NITRO_${VAR}.csv $FINAL/NITRO_${VAR}.csv

done

exit


#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/terraN/NITRO_NH4.csv  /home/jaime/data/benthicEU
rclone copy /home/jg2657/project/BenthicEU/terraN/NITRO_NH4.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/terraN/NITRO_NO3.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/terraN/GIA.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/terraN/TERRA_aet.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/terraN/TERRA_ppt.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/terraN/TERRA_q.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/terraN/TERRA_tmax.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/terraN/TERRA_tmin.csv YaleGDrive:BenthicEllen/
