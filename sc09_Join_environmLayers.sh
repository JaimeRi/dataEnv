#!/bin/bash

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc09_Join_environmLayers.sh  jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction


#DIR=/home/jg2657/project/BenthicEU
DIR=$1
#TMP=/home/jg2657/scratch60
TMP=$2

FINAL=$3

[ ! -d $DIR/statsOUT ] && mkdir $DIR/statsOUT
OUTSTAT=$DIR/statsOUT

###   Part I
###  Join tables from sc08 (note that the rows or records in these tables represent each microbasin)

for VAR in accu slope elev; do
    echo "---- Joining ${VAR} ----"
    if [ -f $OUTSTAT/stats_${VAR}.csv ];then rm $OUTSTAT/stats_${VAR}.csv; fi
    echo "zone,${VAR}_min,${VAR}_max,${VAR}_range,${VAR}_mean,${VAR}_mean_of_abs,${VAR}_stddev,${VAR}_variance,${VAR}_coeff_var,${VAR}_sum,${VAR}_sum_abs" > $OUTSTAT/stats_${VAR}.csv
    FILES=$( find $TMP/r_univar/* -name "*${VAR}.csv" ! -name '*atpoint*')
    cat $FILES > $TMP/TMP_${VAR}.csv
    awk -F, '!(/zone/)' $TMP/TMP_${VAR}.csv > $TMP/TMP_${VAR}2.csv
    cat $TMP/TMP_${VAR}2.csv >> $OUTSTAT/stats_${VAR}.csv
    rm $TMP/TMP_${VAR}.csv $TMP/TMP_${VAR}2.csv
done

echo "stream,strahler,out_dist,elev_drop" > $OUTSTAT/stats_order.csv
FILES=$( find $TMP/r_univar/* -name '*order*' ! -name '*atpoint*')
cat $FILES > $TMP/TMP_order.csv
awk -F, '!(/stream/)' $TMP/TMP_order.csv > $TMP/TMP_order2.csv
cat $TMP/TMP_order2.csv >> $OUTSTAT/stats_order.csv
rm $TMP/TMP_order2.csv $TMP/TMP_order.csv


######################################################################

### Part II
### Assign to the original table, that is, to each Site_ID, the environmental values given in the previous joined tables by using the microbasin as the joining ID

cat $DIR/BasisDataBasinsIDs.csv | awk -F',' 'BEGIN{OFS=",";} {print $1, $4, $5}' > $TMP/tojoin_ENV.csv

for VAR in accu slope elev order
do
      if [ "$VAR" == "order" ]
      then
        echo "stream,strahler,out_dist,elev_drop"  > $TMP/TMP_${VAR}.csv
      else
        echo "zone,${VAR}_min,${VAR}_max,${VAR}_range,${VAR}_mean,${VAR}_mean_of_abs,${VAR}_stddev,${VAR}_variance,${VAR}_coeff_var,${VAR}_sum,${VAR}_sum_abs" > $TMP/TMP_${VAR}.csv
      fi
          for i in $( seq 1 $( awk -F, 'FNR > 1' $DIR/BasisDataBasinsIDs.csv | wc -l  ) )
          do
            microID=$(cat $TMP/tojoin_ENV.csv | awk -F, -v ROW=$i 'NR==1+ROW {print $3}')
            echo "calculating $VAR microbasin $i"
            linea=$(cat $OUTSTAT/stats_${VAR}.csv | awk -F, -v microID=$microID '$1 == microID')
                if [ -z "$linea" ]
                then
                    echo "$microID,Empty" >> $TMP/TMP_${VAR}.csv
                else
                    echo $linea >> $TMP/TMP_${VAR}.csv
                fi
          done
      paste -d "," $TMP/tojoin_ENV.csv $TMP/TMP_${VAR}.csv > $FINAL/stats_${VAR}_complete.csv
done

#rm $TMP/tojoin_ENV.csv $TMP/TMP_*.csv
#rm -rf $TMP/r_univar

cat $(find $TMP/r_univar/* -name 'stats_atpoint_*_elev.csv') | sort -n  > $TMP/elev_atpoint.txt
cat $(find $TMP/r_univar/* -name 'stats_atpoint_*_accu.csv') | sort -n  > $TMP/accu_atpoint.txt
cat $(find $TMP/r_univar/* -name 'stats_atpoint_*_slope.csv') | sort -n  > $TMP/slope_atpoint.txt

echo "Site_ID,Elevation,Accumulation,Slope" > $FINAL/elev_accu_slope_atpoint.csv

paste -d','   \
    <(cut -d'|' -f1 $TMP/elev_atpoint.txt) \
    <(cut -d'|' -f2 $TMP/elev_atpoint.txt) \
    <(cut -d'|' -f2 $TMP/accu_atpoint.txt) \
    <(cut -d'|' -f2 $TMP/slope_atpoint.txt) \
    >> $FINAL/elev_accu_slope_atpoint.csv

rm $TMP/{elev,accu,slope}_atpoint.txt

exit


############## check for empty rows and rerun sc08 to identify the issue

VAR=elev
cat $OUTSTAT/stats_${VAR}_complete.csv | awk -F, '/Empty/'

rclone copy /home/jg2657/project/BenthicEU/final/elev_accu_slope_atpoint.csv YaleGDrive:BenthicEllen/Norway_siteIDs_Corrected
rclone copy /home/jg2657/project/BenthicEU/statsOUT/stats_accu_complete.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/statsOUT/stats_elev_complete.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/statsOUT/stats_order_complete.csv YaleGDrive:BenthicEllen/
rclone copy /home/jg2657/project/BenthicEU/statsOUT/stats_slope_complete.csv YaleGDrive:BenthicEllen/
