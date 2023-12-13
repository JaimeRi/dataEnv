#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 00:10:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc14b_environmESAaccuJoin.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc14b_environmESAaccuJoin.sh.%A_%a.err
#SBATCH --mem-per-cpu=8000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc14b_environmESAaccuJoin.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/scripts

# sbatch /home/jg2657/project/BenthicEU/scripts/sc14b_environmESAaccuJoin.sh


export DIR=/home/jg2657/project/BenthicEU
export TEMP=/home/jg2657/scratch60/esa_accu

export ESALC=$DIR/ESALC


awk -F, '{print $1}' $TEMP/ESALC_ACCU_2018.csv > $ESALC/ESA_stats_accu.csv

for FILE in $(ls $TEMP); do

  echo $FILE
  paste -d "," $ESALC/ESA_stats_accu.csv   \
  <(cat $TEMP/${FILE} | cut -d, -f4-38) \
  > ${ESALC}/ESA_stats_accu2.csv

  mv $ESALC/ESA_stats_accu2.csv $ESALC/ESA_stats_accu.csv

done


exit

rclone copy /home/jg2657/project/BenthicEU/ESALC/ESA_stats_accu.csv YaleGDrive:BenthicEllen
