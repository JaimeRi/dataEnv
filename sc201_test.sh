#!/bin/bash


export VECTORS=( $(find /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order/vect  -name 'order_vect_[0-9]*.gpkg')  )


cus=( $( for I in ${VECTORS[@]}; do echo $( basename $I .gpkg | awk -F_ '{print $3}' ); done | sort) )

for CU in ${cus[@]}
do
    b=$( wc -l < CU_${CU}/out/stats_${CU}_BasinsIDs.txt )
    l=$( wc -l < CU_${CU}/out/stats_${CU}_LCprop.txt )
    echo "CU_${CU} = $b rows, LC = $l rows" >> checkLC.txt
done

102 59 66 73 74


# path to hydro variables
export MERITVAR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

# path to scripts
export SCRIPTS=/home/jg2657/project/code/environmental-data-extraction

# path to project
export PROJ=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

# path to temporal folder
export TMP=/vast/palmer/scratch/sbsc/jg2657/tables


for ref in 102 66 73 74
do

export ref=74
export DIR=$PROJ/CU_${ref}
mkdir $TMP/esa_stats_${ref}

sbatch --array=1-27 --time=05:00:00 --job-name=ESA_${ref} \
    $SCRIPTS/sc22_CompUnit_ESA.sh $DIR $TMP \
    /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/input ${ref} $MERITVAR  

# this next depends on the previous
sbatch --time=02:50:00 --job-name=ESAjoin_${ref} \
    --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j" | grep ESA_${ref} | awk '{print $1}') \
    $SCRIPTS/sc22b_CompUnit_ESA_join.sh $DIR $TMP $ref
done



