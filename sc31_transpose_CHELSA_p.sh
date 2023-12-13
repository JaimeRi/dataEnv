#! /bin/bash

export tmp=/mnt/shared/tiles_tb/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/EnvTablesTiles
export biop=/mnt/shared/regional_unit_bio

TransposeTable_CHELSA_p(){

# define the tile to work with
nm=${1}
# define variable of interest
var=${2}

[[ -f $zip/Climate/present/${var}/${nm}_${var}.zip  ]] && \
    { echo >&2 "${nm}_${var}.zip already exist"; exit 1; }

# Check tables with ids for that tile
tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

# create output table with header
echo "subcID min max range mean sd" > ${tmp}/${nm}_${var}.txt

# validate table
#echo "${nm}_${var}" > $out/valid/${nm}_${var}.txt

# for loop to go through each RU and extract the ids of interest
for i in ${tbids[@]}
do
    # if file is empty go to next one
    [[ ! -s $i ]] && continue

    #wc -l < $i >> $out/valid/${nm}_${var}.txt 

    # extract ru number
    ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${biop} -name "stats_${ru}_${var}.txt")
    
    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     ${i} $tb >> ${tmp}/${nm}_${var}.txt

done

zip -jq $zip/Climate/present/${var}/${nm}_${var}.zip ${tmp}/${nm}_${var}.txt

#wc -l < ${tmp}/${nm}_${var}.txt >> $out/valid/${nm}_${var}.txt

rm ${tmp}/${nm}_${var}.txt

echo "${nm} ${var} done" >> $out/biop_tiles_done.txt

}

# list of variables:
# bio1-19   source:/mnt/shared/regional_unit_bio 

for tile in $(cat $tmp/tiles.txt)
do
    for var in bio1 bio2 bio3 bio4 bio5 bio6 bio7 bio8 bio9 bio10 bio11 bio12 bio13 bio14 bio15 bio16 bio17 bio18 bio19
    do echo $tile $var 
    done
done > $tmp/tbtrans.txt 


#for tile in h20v02 h18v02 h20v04 h18v04 
#do
#    for var in bio1 bio12 bio15
#    do echo $tile $var 
#    done
#done > $tmp/tbtrans.txt 



export -f TransposeTable_CHELSA_p
time parallel -j 20 --colsep ' ' TransposeTable_CHELSA_p ::::  $tmp/tbtrans.txt
#time parallel -j 1 --colsep ' ' TransposeTable_CHELSA_p ::: h18v04 ::: bio1


#awk 'NR > 1 {total+=$1; print $1,total}' h18v04_bio1.txt



