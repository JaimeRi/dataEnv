#! /bin/bash

export tmp=/mnt/shared/tmp
export out=/mnt/shared/tiles_tb
export zip=/mnt/shared/EnvTablesTiles
export biop=/mnt/shared/regional_unit_tables_bio_fut

TransposeTable_CHELSA_f(){

# define the tile to work with
nm=${1}
# define variable of interest
var=${2}
year=${3}
model=${4}
ssp=${5}

# CHeck tables with ids for that tile
tbids=( $(find /mnt/shared/tiles_tb/indx -name "${nm}_*.txt") )

# create output table with header
echo "subcID min max range mean sd" > ${tmp}/${nm}_${var}_${year}_${model}_${ssp}.txt

# validate table
#echo "${nm}_${var}" > $out/valid/${nm}_${var}.txt

# for loop to go through each RU and extract the ids of interest
for i in ${tbids[@]}
do
    # if file is empty go to next one
    [[ ! -s $i ]] && continue

    wc -l < $i >> $out/valid/${nm}_${var}.txt 

    # extract ru number
    ru=$(basename $i .txt | awk -F_ '{print $2}')

    # identify table of interest
    tb=$(find ${biop}/CU_${ru} -name "stats_${ru}_*_${var}_${year}*${model}*${ssp}*.txt")
    
    # retrieve only records with IDs of interest
    awk 'NR==FNR {a[$1]; next} $1 in a' \
     ${i} $tb >> ${tmp}/${nm}_${var}_${year}_${model}_${ssp}.txt
done

zip -jq $zip/Climate/future/${var}/${nm}_${var}_${year}_${model}_${ssp}.zip \
    ${tmp}/${nm}_${var}_${year}_${model}_${ssp}.txt

#wc -l < ${tmp}/${nm}_${var}.txt >> $out/valid/${nm}_${var}.txt

rm ${tmp}/${nm}_${var}_${year}_${model}_${ssp}.txt

echo "${nm} ${var} ${year} ${model} ${ssp}  done" >> $tmp/biof_tiles_done.txt

}

# list of variables:
# bio1-19   source:/mnt/shared/regional_unit_bio 
tile=(h18v02 h20v02 h18v04 h20v04)
var=(bio1)
year=(2071)
model=(mpi)
ssp=(ssp585)

for t in ${tile[@]}
do
    for i in ${var[@]}
    do
        for y in ${year[@]}
        do
            for m in ${model[@]}
            do
                for s in ${ssp[@]}
                do echo $t $i $y $m $s
                done
            done
        done
    done 
done > $tmp/tbtrans_bf.txt

export -f TransposeTable_CHELSA_f
time parallel -j 4 --colsep ' ' TransposeTable_CHELSA_f ::::  $tmp/tbtrans_bf.txt
