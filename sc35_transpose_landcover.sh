#! /bin/bash

export tmp=/mnt/shared/tiles_tb/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/EnvTablesTiles
export layers=/mnt/shared/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

TransposeTable_LandCover(){

# define the tile to work with
nm=${1}
# define variable of interest
var=${2}

# exit if file already exist
[[ -f $zip/LandCover/${var}/${nm}_${var}.zip  ]] && \
    { echo >&2 "${nm}_${var}.zip already exist"; exit 1; }

# CHeck tables with ids for that tile
tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

# create output table with header
echo "subcID $(for i in {1992..2020}; do printf "%s " ${var}_y$i; done)" > ${tmp}/${nm}_${var}.txt

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
    tb=$(find ${layers}/CU_${ru} -name "stats_${ru}_LCprop.txt")

    # subset the table with subcatchment id and columns of interest
    flds=$(head -n1 $tb | tr ' ' '\n' | grep -ne "^${var}" \
         | cut -d: -f1 | paste -sd,)

    cut -d' ' -f1,"${flds}" $tb > $tmp/sub_${var}_${ru}_${nm}.txt

    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     ${i} $tmp/sub_${var}_${ru}_${nm}.txt \
     >> ${tmp}/${nm}_${var}.txt

    rm $tmp/sub_${var}_${ru}_${nm}.txt

done

years=($(echo {1992..2020}))
time for i in ${!years[@]}
do
    col=$(echo "$i + 2" | bc)
    y="${years[$i]}"
    cut -d' ' -f1,"${col}"  ${tmp}/${nm}_${var}.txt \
        > $tmp/${nm}_${var}_${y}.txt

    TOT=$(awk '{sum+=$2}END{print sum}' $tmp/${nm}_${var}_${y}.txt)

    [[ "$TOT" -eq 0  ]] && continue

    zip -jq $zip/LandCover/${var}/${nm}_${var}_${y}.zip \
    $tmp/${nm}_${var}_${y}.txt

    rm $tmp/${nm}_${var}_${y}.txt
done

wc -l < ${tmp}/${nm}_${var}.txt >> $out/valid/${nm}_${var}.txt

rm ${tmp}/${nm}_${var}.txt

echo "${nm} ${var} done" >> $tmp/landcover_tiles_done.txt

}


#for cat in c10 c20 c30 c40 c50 c60 c70 c80 c90 c100 c110 c120 c130 c140 c150 c160 c170 c180 c190 c200 c210 c220; do mkdir $zip/LandCover/${cat}; done


# list of variables:
tile=(h18v02 h20v02 h18v04 h20v04)
tile=(h18v02)
var=(c60)

for t in ${tile[@]}
do
    for i in ${var[@]}
                do echo $t $i 
    done 
done > $tmp/landcover_trans.txt

export -f TransposeTable_LandCover
time parallel -j 1 --colsep ' ' TransposeTable_LandCover ::::  $tmp/landcover_trans.txt

awk '{total+=$1; print $1,total}' h18v04_c60.txt
