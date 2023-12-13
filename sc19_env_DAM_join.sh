#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc19_env_DAM_join.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc19_env_DAM_join.sh.%A_%a.err
#SBATCH --mem-per-cpu=10000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc19_env_DAM_join.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/scripts

# sbatch /home/jg2657/project/BenthicEU/scripts/sc19_env_DAM_join.sh
DIR=$1

OUTDIR=$DIR/dam

TMP=$2

###  create header of the table where output will be append to
echo "Site_ID,dam_ID,dam_ELEV,dam_ACCU,Site_ELEV,Site_ACCU,DistanceKm,Influence" > $TMP/dist_to_DAMs.csv

###  Join all the tables together
for CSVTABLE in $( find $TMP/damOut/dist_* ); do
  cat $CSVTABLE >>  $TMP/dist_to_DAMs.csv
done

### reorder by Site ID
awk -F, 'NR == 1; NR > 1 {print $0 | "sort -n"}' $TMP/dist_to_DAMs.csv > $OUTDIR/dist_to_DAMs.csv

exit

rclone copy /home/jg2657/project/BenthicEU/dam/dist_to_DAMs.csv YaleGDrive:BenthicEllen/Norway_siteIDs_Corrected
