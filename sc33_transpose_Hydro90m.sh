#! /bin/bash

export tmp=/mnt/shared/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/EnvTablesTiles
export layers=/mnt/shared/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

TransposeTable_Hydro90m(){

# define the tile to work with
nm=${1}
# define variable of interest
var=${2}

# exit if file already exist
[[ -f $zip/Hydrography90m/${var}/${nm}_${var}.zip  ]] && \
    { echo >&2 "${nm}_${var}.zip already exist"; exit 1; }

# CHeck tables with ids for that tile
tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

# create output table with header
echo "subcID min max range mean sd" > ${tmp}/${nm}_${var}.txt

# for loop to go through each RU and extract the ids of interest
for i in ${tbids[@]}
do
    # if file is empty go to next one
    [[ ! -s $i ]] && continue

    # extract ru number
    ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${layers}/CU_${ru}/out -name "stats_${ru}_${var}.txt")
    
    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} FNR > 1 || $1 in a' \
     ${i} $tb >> ${tmp}/${nm}_${var}.txt
done

zip -jq $zip/Hydrography90m/${var}/${nm}_${var}.zip \
    ${tmp}/${nm}_${var}.txt

rm ${tmp}/${nm}_${var}.txt

}

# list of variables:
# bio1-19   source:/mnt/shared/regional_unit_bio 
tile=(h18v02 h20v02 h18v04 h20v04)
var=(flowpos)

for t in ${tile[@]}
do
    for i in ${var[@]}
    do
       echo $t $i 
    done 
done > $tmp/tbtrans_hydro.txt

export -f TransposeTable_Hydro90m
time parallel -j 8 --colsep ' ' TransposeTable_Hydro90m ::::  $tmp/tbtrans_hydro.txt
