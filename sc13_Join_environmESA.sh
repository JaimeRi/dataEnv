#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#####SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc13_Join_environmESA.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc13_Join_environmESA.sh.%A_%a.err

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc13_Join_environmESA.sh  jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# sbatch /home/jg2657/project/BenthicEU/scripts/sc13_Join_environmESA.sh

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
#DIR=/home/jg2657/project/BenthicEU
DIR=$1
#TMP=/home/jg2657/scratch60
TMP=$2

FINAL=$3

STATDIR=$TMP/esa_stats
#ESALC=$DIR/ESALC

######     FIRST SECTION    #####################
###  Join tables from sc12 (note that the rows or records in these tables represent each microbasin)

printf "%s\n" MicrobasinID $(cat $STATDIR/stats_esa_1992_100.txt | awk '{print $1}') > $STATDIR/ESA_stats.csv


for FILE in $(find $STATDIR -name 'stats_esa*.txt'); do

  paste -d "," $STATDIR/ESA_stats.csv   \
  <(printf "%s\n" $(basename $FILE .txt | awk -F_ '{print "cat_" $4 "_" $3}')  $(cat $FILE | awk '{print $4}'))  \
  > $STATDIR/ESA_stats2.csv
  mv $STATDIR/ESA_stats2.csv $STATDIR/ESA_stats.csv

done

######     SECOND SECTION    #####################
### Assign to the original table, that is, to each Site_ID, the environmental values given in the previous joined tables by using the microbasin as the joining ID


cat $DIR/BasisDataBasinsIDs.csv | awk -F',' 'BEGIN{OFS=",";} {print $1, $4, $5}' > $TMP/tojoin_ENV.csv

awk -F, 'NR==1' $STATDIR/ESA_stats.csv  > $TMP/temp_ESA_Stats.csv

for i in $( seq 1 $( awk -F, 'FNR > 1' $DIR/BasisDataBasinsIDs.csv | wc -l  ) )
do
  microID=$(cat $TMP/tojoin_ENV.csv | awk -F, -v ROW=$i 'NR==1+ROW {print $3}')
  linea=$(cat $STATDIR/ESA_stats.csv | awk -F, -v microID=$microID '$1 == microID')
  if [ -z "$linea" ]
    then
       echo "$microID,Empty" >> $TMP/temp_ESA_Stats.csv
    else
       echo $linea >> $TMP/temp_ESA_Stats.csv
    fi
done

paste -d "," $TMP/tojoin_ENV.csv $TMP/temp_ESA_Stats.csv > $FINAL/stats_ESALC_complete.csv


####   Delete all temporal files

#rm -rf $STATDIR/ESA_stats.csv $STATDIR/stats_esa* $TMP/temp_ESA* $TMP/tojoin* $TMP/esa_stats

exit

rclone copy /home/jg2657/project/BenthicEU/ESALC/stats_ESALC_complete.csv  YaleGDrive:BenthicEllen
