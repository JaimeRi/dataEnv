#!/bin/bash

#SBATCH -p day
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_basinID.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_basinID.sh.%A_%a.err
#SBATCH --mem-per-cpu=10000M

#  scp /home/jaime/Code/environmental-data-extraction/sc01_basinID.sh  grace:/home/jg2657/project/code/environmental-data-extraction


module purge
source ~/bin/gdal3
module load parallel/20210222-GCCcore-10.2.0

export MERITVAR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

DIR=${1}
TMP=${2}

export DATASET=${DIR}/${3}

## path to computational units
export COMPUNIT=$MERITVAR/lbasin_compUnit_overview/lbasin_compUnit.tif

##  path to macrobasin
export MACROB=$MERITVAR/lbasin_tiles_final20d_ovr/all_lbasin.tif

## path to microbasins
export MICROB=$MERITVAR/hydrography90m_v.1.0/r.watershed/sub_catchment_tiles20d/sub_catchment.tif

if [[ $(cat $DATASET | wc -l) -lt 2000  ]]
then
    
    paste -d "," $DATASET     \
    <(printf "%s\n" CompUnitID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET \
    | gdallocationinfo -valonly -geoloc  $COMPUNIT))   \
    <(printf "%s\n" MacrobasinID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET \
    | gdallocationinfo -valonly -geoloc  $MACROB))   \
    <(printf "%s\n" MicrobasinID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET \
    | gdallocationinfo -valonly -geoloc  $MICROB))    \
    > $DIR/BasisDataBasinsIDs.csv

else

    awk -F, 'FNR > 1' $DATASET > $TMP/temp.csv
    ROWS=$(cat $TMP/temp.csv | wc -l)
    inc=4000
    r=$( echo $(( $ROWS % $inc )) )

    if [[ $r -gt 0  ]]
    then
        paste -d" " <(seq 1 $inc $ROWS) \
            <(printf "%s\n" $(seq $inc $inc $ROWS) $ROWS ) \
            > $TMP/sequence.txt
    else
        paste -d" " <(seq 1 $inc $ROWS) <(seq $inc $inc $ROWS) \
            > $TMP/sequence.txt
    fi
    
    # just to be sure and avoid problems remove if they exist
    if compgen -G "$TMP/mac*.txt" > /dev/null; then rm $TMP/mac*.txt; fi
    if compgen -G "$TMP/mic*.txt" > /dev/null; then rm $TMP/mic*.txt; fi
    if compgen -G "$TMP/all_seq.txt" > /dev/null; then rm $TMP/all_seq.txt; fi

    LocationInfo(){
        X=${1}
        Y=${2}
        awk -F, -v x=$X -v y=$Y  'NR >= x  && NR <= y {print $1}' $TMP/temp.csv \
            > $TMP/all_seq_$X.txt
        awk -F, -v x=$X -v y=$Y  'NR >= x  && NR <= y {print $2, $3}' $TMP/temp.csv \
            |  gdallocationinfo -valonly -geoloc  $MACROB > $TMP/macrogdal_$X.txt
        awk -F, -v x=$X -v y=$Y  'NR >= x  && NR <= y {print $2, $3}' $TMP/temp.csv \
            |  gdallocationinfo -valonly -geoloc  $MICROB > $TMP/microgdal_$X.txt
    }

    export -f LocationInfo
    time parallel -j 20 --colsep ' '  LocationInfo :::: $TMP/sequence.txt

    cat $TMP/all_seq_*.txt > $TMP/all_seq.txt
    cat $TMP/macrogdal_*.txt > $TMP/macrogdal.txt
    cat $TMP/microgdal_*.txt > $TMP/microgdal.txt

    echo "pointID,MacrobasinID,MicrobasinID" > $TMP/output.txt
    paste -d "," $TMP/all_seq.txt $TMP/macrogdal.txt $TMP/microgdal.txt \
        >> $TMP/output.txt

    sort -k1 -t',' -n $TMP/output.txt -o $TMP/out_sort.txt
    sort -k1 -t',' -n $DATASET -o $TMP/init_sort.txt

    paste -d "," $TMP/init_sort.txt \
        <( cut -d, -f2,3 $TMP/out_sort.txt) \
        > $DIR/BasisDataBasinsIDs.csv

    # delete temporal files
    rm $TMP/all_s*.txt  $TMP/temp.csv $TMP/macrogdal*.txt $TMP/microgdal*.txt \
    $TMP/sequence.txt $TMP/init_sort.txt $TMP/output.txt $TMP/out_sort.txt
fi



# Are there still records with no ID and how many?
NOREC=$( awk -F, '$5 < 1' $DIR/BasisDataBasinsIDs.csv | wc -l)

# if all records have an ID then everything fine and exit
[ $NOREC -eq 0 ] && exit

# if there are records with zeros is because they overlap with the ocean OR for
# some unknown reason the gdallocation info did not work. The script needs to 
# run again until the number of records with zero data is the same as the dataset
# before

# first, save the succesful records apart
awk -F, '$5 > 0' $DIR/BasisDataBasinsIDs.csv > $TMP/run_0.csv

# extract the unsuccesful records
awk -F, 'NR==1; $5 < 1' $DIR/BasisDataBasinsIDs.csv \
    | cut -d, -f1-3 > $TMP/dataNoOverlap.csv

LOOP=$NOREC

for i in $(seq 1 $LOOP)
do
    DATASET=$TMP/dataNoOverlap.csv

    paste -d "," $DATASET     \
    <(printf "%s\n" MacrobasinID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET \
    | gdallocationinfo -valonly -geoloc  $MACROB))   \
    <(printf "%s\n" MicrobasinID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET \
    | gdallocationinfo -valonly -geoloc  $MICROB))    \
    > $TMP/basisdata.csv

    # are there records without ID again?
    NEWNOREC=$(  awk -F, '$5 < 1'  $TMP/basisdata.csv | wc -l )

    if [ $NEWNOREC -eq $NOREC ]
    then
        break
    else
        NOREC=$NEWNOREC
        # save succesful records
        awk -F, 'NR > 1 && $5 > 0'  $TMP/basisdata.csv > $TMP/run_$i.csv
        # extract the unsuccesful records
        awk -F, '$5 < 1' $TMP/basisdata.csv \
            | cut -d, -f1-3 > $TMP/dataNoOverlap.csv
    fi
done

if [ $(find $TMP/ -name 'run_*.csv' | wc -l) -lt 2 ]
then
    mv $TMP/run_0.csv $DIR/BasisDataBasinsIDs.csv
    mv $TMP/basisdata.csv $DIR/NoOverlappingPoints.csv        
    rm $TMP/* 
    exit    
else
    # join complete record tables
    awk -F, 'NR==1;' $DIR/BasisDataBasinsIDs.csv > $DIR/header.csv
    cat $(find $TMP/ -name 'run_*.csv') >> $DIR/header.csv
    mv $DIR/header.csv $DIR/BasisDataBasinsIDs.csv
    mv $TMP/basisdata.csv $DIR/NoOverlappingPoints.csv        
    # remove temporal files
    rm $TMP/*
fi

exit


