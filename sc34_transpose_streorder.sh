#! /bin/bash

export tmp=/mnt/shared/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/EnvTablesTiles
export layers=/mnt/shared/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

TransposeTable_streamorder(){

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
echo "subcID $var" > ${tmp}/${nm}_${var}.txt

# validate table
echo "${nm}_${var}" > $out/valid/${nm}_${var}.txt

# for loop to go through each RU and extract the ids of interest
for i in ${tbids[@]}
do

    # if file is empty go to next one
    [[ ! -s $i ]] && continue

    wc -l < $i >> $out/valid/${nm}_${var}.txt 
    
    # extract ru number
    ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${layers}/CU_${ru}/out -name "stats_${ru}_streamorder.txt")
 
    # subset the table with subcatchment id and column of interest
     awk -v VAR="$var"  'NR == 1 { for (i=1; i<=NF; i++) {f[$i] = i} } 
     {print $1, $(f[VAR])}' $tb > $tmp/sub_${var}_${ru}_${nm}.txt

    # extract subc of interst only
     awk 'NR == FNR {a[$1]; next} $1 in a' \
         $i $tmp/sub_${var}_${ru}_${nm}.txt \
         >> ${tmp}/${nm}_${var}.txt 
    
     rm $tmp/sub_${var}_${ru}_${nm}.txt 

 done

zip -jq $zip/Hydrography90m/${var}/${nm}_${var}.zip \
    ${tmp}/${nm}_${var}.txt

wc -l < ${tmp}/${nm}_${var}.txt >> $out/valid/${nm}_${var}.txt

rm ${tmp}/${nm}_${var}.txt

echo "${nm} ${var} done" >> $tmp/streamorder_tiles_done.txt

}

#####   OJO
### make sure the folders for each variable exist

# list of variables:
tile=(h18v04)
var=(length)

for t in ${tile[@]}
do
    for i in ${var[@]}
    do
       echo $t $i 
    done 
done > $tmp/tbtrans_streamorder.txt

export -f TransposeTable_streamorder
time parallel -j 2 --colsep ' ' TransposeTable_streamorder ::::  $tmp/tbtrans_streamorder.txt
