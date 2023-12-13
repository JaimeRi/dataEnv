#! /bin/bash

#SBATCH -p day
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc200_EnvTables.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc200_EnvTables.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M
#SBATCH --mail-user=jrgarcia.marquez@gmail.com
#SBATCH --mail-type=END,FAIL,TIME_LIMIT

#  scp /home/jaime/Code/environmental-data-extraction/sc200_EnvTables.sh  grace:/home/jg2657/project/code/environmental-data-extraction

#####  data preparation

# path to project
#export PROJ=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

# ESA land cover categories
#cp $HOME/project/BenthicEU/esa_categories.txt $PROJ/

# array file for NH4 and NO3
#for v in NH4 NO3; do for y in {1961..2010}; do for m in {01..12}; do echo "$v $y $m" >> $PROJ/nh_array.txt; done; done; done

# array file for TERRAclimate variables
#for v in aet q ppt tmax tmin; do for y in {1958..2020}; do for m in {01..12}; do echo "$v $y $m" >> $PROJ/terra_array.txt; done; done; done



###  Create an array with the list (complete path) of all vector files (files are
###  on a computational Unit bases)
 export VECTORS=( $(find /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order/vect  -name 'order_vect_*.gpkg')  )
### printf "%s\n" ${VECTORS[@]} | cat -n | awk '/_178.gpkg/'

#S=( 6 19 46 137 81 21 132 158 41 68 3 73 143 63 151 52 90 127 )

### select file to work with
# export vect=${VECTORS[67]}

### extract computational unit number as a reference for output
### export ref=$( basename $vect .gpkg | awk -F_ '{print $3}' )

for I in ${S[@]} ;
do
  vect=${VECTORS["$I"]}
 ref=$( basename $vect .gpkg | awk -F_ '{print $3}' )
 sbatch --time=06:00:00 --job-name=CompUnit_$ref \
       /home/jg2657/project/code/environmental-data-extraction/sc200_EnvTables.sh ${vect}
done

###    export ref=$( basename $vect .gpkg | awk -F_ '{print $3}' )
###    export DIR=$PROJ/CU_${ref}
###    sbatch --time=02:00:00 $SCRIPTS/sc21_CompUnit_HydroVars.sh $DIR $ref $MERITVAR
#####
#####    sbatch --time=03:00:00 $SCRIPTS/sc21_CompUnit_HydroVars.sh $DIR $ref  \
#####    $MERITVAR
#done

## Modules
gdal3

#####  Read gpkg vector
export vect=$1
# extract computational unit ID
export ref=$( basename $vect .gpkg | awk -F_ '{print $3}' )

##### Define paths

# path to hydro variables
export MERITVAR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

# path to scripts
export SCRIPTS=/home/jg2657/project/code/environmental-data-extraction

# path to project
export PROJ=/gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES

# path to temporal folder
export TMP=/vast/palmer/scratch/sbsc/jg2657/tables


 export CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/climatologies/bio/future/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/

export CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/climatologies/bio/future/envicloud_uk 

 export VECTORS=( $(find /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order/vect  -name 'order_vect_*.gpkg')  )

#for I in ${VECTORS[@]}
#for ref in 1 10 100 101 102 103 104 105 106 107 108  109 
#for ref in 11 110 111 112 113 114 115 116 12 13 14 15
#for ref in 151 152 153 154 155 156 157 158 159 16 160 161 162 163 164 165 166 167 168 169  
#for ref in 17 171 172 173 174 175 176 177 178 179 18 180 181 182 183 184
#for ref in 185 186 187 188 189 19 190 191 192 193 194 195 196 197 198 199 2 20 200
#for ref in 21 22 23 24 25 26 27 28 29 3 30 31 32 33 34 35 36 37 38 39
#for ref in 4 40 41 42 43 44 45 46 47 48 49 5 50 51 52 53 54 55 56 57 58 59
#for ref in 6 60 61 62 63 64 65 66 67 68 69 7 70 71 72 73 74 75 76 77 78 79
#for ref in 8 80 81 82 83 84 85 86 87 88 89 9 91 92 93 94 95 96 97 98 99

uk: 90 170
ipsl 53 90 162 170 
mpi: 51 52 53 90 162 170 185

for ref in 90 170  
do
    # ref=$( basename $I .gpkg | awk -F_ '{print $3}' )
    sbatch  --job-name=CHELSA_uk_$ref $SCRIPTS/sc21_CompUnit_CHELSAfut.sh \
        $PROJ $CHELSA $ref  $MERITVAR
done

sacct -j  22611108 --format=JobID,State,Elapsed # CU 178
sbatch  --job-name=CHELSA_178 $SCRIPTS/sc21_CompUnit_CHELSAfut.sh \
        $PROJ $CHELSA 178  $MERITVAR

for i in {151..200} 
do  
    rclone copyto /gpfs/gibbs/pi/hydro/hydro/dataproces/ENVTABLES/CU_${i}/out/ --include="*CHELSA*2071*.txt"  YaleGDrive:CHELSA_bio_future/CU_${i}/ -P --drive-shared-with-me
done

##### Prepare directories to store results

mkdir -p $PROJ/CU_${ref}/out
export DIR=$PROJ/CU_${ref}

##### Start Analysis

# STEP 1
# create vector point file by extracting only the geometry points (original 
# files have lines and points as geometries) and removing points representing
# outlets (cat = 0)
ogr2ogr $DIR/points_$ref.gpkg $vect \
    -sql "SELECT * FROM vect WHERE ST_GeometryType(geom) LIKE 'POINT' AND NOT cat = 0" \
    -nln points_$ref -nlt POINT

# STEP 2
# create txt files with only coordinates
echo "X Y" > $DIR/coordinates_$ref.txt
ogrinfo $DIR/points_$ref.gpkg -al | grep POINT |  awk -F "[()]" '{print $2}' \
    | cut -d' ' -f1,2  >> $DIR/coordinates_$ref.txt

# STEP 3
# create csv file with all the information in the original stream order gpkg
ogr2ogr $TMP/stats_${ref}_streamorder.csv $DIR/points_$ref.gpkg \
    -f "CSV" -lco STRING_QUOTING=IF_NEEDED

# remove column 1 (duplicate of column 2)
cut -d',' -f2-26 $TMP/stats_${ref}_streamorder.csv > $TMP/stats_${ref}_streamorder_cut.csv

# replace column name to use subcID
sed -i 's/stream/subcID/' $TMP/stats_${ref}_streamorder_cut.csv 

# make the file a space separated file
sed 's/,/\ /g' $TMP/stats_${ref}_streamorder_cut.csv \
    >  $DIR/out/stats_${ref}_streamorder.txt

# remove temporal files
rm $TMP/stats_${ref}_streamorder*.csv

# STEP 4
# create basis data with subcID and coordinates
paste -d' '  \
    <(awk '{print $1}' $DIR/out/stats_${ref}_streamorder.txt) \
    $DIR/coordinates_$ref.txt > $DIR/initialDB_$ref.txt

# STEP 5
# create table with subcID, coordinates and Macrobasin ID
sbatch --time=02:00:00 --job-name=initialDB_$ref  $SCRIPTS/sc20_basinID.sh \
    $DIR $DIR/initialDB_$ref.txt $ref $MERITVAR

# STEP 6
# calculate the hidrography variables (e.g., slope, flow accumulation, 
# elevation, distances, etc....)
sbatch --array=0-28 --time=04:00:00 --job-name=HydroVars_$ref \
    $SCRIPTS/sc21_CompUnit_HydroVars.sh $DIR $ref $MERITVAR


#for sti in 64 65 67 69 71 72 73 79 94 98 99 165 166 170 183 184 185 192 195
#do
#    export ref=${sti}
#    export DIR=$PROJ/CU_${ref}
#    sbatch --array=2 --time=04:00:00 --job-name=StreamFlowInd_$ref \
#    $SCRIPTS/sc21_CompUnit_StreamFlowInd.sh $DIR $ref $MERITVAR
#done

#cti 18 19 23 24 26 29 35 36 37 40 43 53 60 64 79 94 99 165 166 170 183 184 185 192 195 

#sti 1 2 4 5 8 9 10 11 13 14 15 16 17 18 19 21 23 24 25 26 29 30 31 32 33 35 36 37 38 40 41 42 43 44 45 50 51 52 53 54 57 60 64 65 67 69 71 72 73 79 94 98 99 165 166 170 183 184 185 192 195  

#spi 9 13 18 19 23 26 29 35 36 37 40 43 53 54 64 73 79 94 98 99 165 166 170 183 184 185 192 195

# calculate the stream flow indices variables
sbatch --array=0-2 --time=04:00:00 --job-name=StreamFlowInd_$ref \
    $SCRIPTS/sc21_CompUnit_StreamFlowInd.sh $DIR $ref $MERITVAR

######
sbatch --time=03:00:00 --job-name=VarsSingleFile_$ref \
    $SCRIPTS/sc28_CompUnit_VarsSingleFile.sh $DIR $ref $MERITVAR 

# STEP 7
#  CHELSA DATA
export CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/bio/
sbatch  --job-name=CHELSA_$ref $SCRIPTS/sc21_CompUnit_CHELSA.sh \
    $DIR $CHELSA $ref $MERITVAR


#  CHELSA FUTURE
export CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/climatologies/bio/future/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/

sbatch  --job-name=CHELSA_$ref $SCRIPTS/sc21_CompUnit_CHELSAfut.sh \
    $DIR $CHELSA $ref  $MERITVAR


# STEP 8
# ESALC data
mkdir $TMP/esa_stats_${ref}

sbatch --array=1-3 --time=05:00:00 --job-name=ESA_${ref} \
    $SCRIPTS/sc22_CompUnit_ESA.sh $DIR $TMP \
    /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/input ${ref} $MERITVAR  

# this next depends on the previous
sbatch --time=02:50:00 --job-name=ESAjoin_${ref} \
    --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j" | grep ESA_${ref} | awk '{print $1}') \
    $SCRIPTS/sc22b_CompUnit_ESA_join.sh $DIR $TMP $ref

# STEP 9
# SOILGRIDS data
export SOIL=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
sbatch --array=0-15 --time=00:50:00 --job-name=SOIL_$ref \
    $SCRIPTS/sc23_CompUnit_SOIL.sh $DIR $ref $MERITVAR $SOIL ## 

# STEP 10
# FLOW1k
sbatch --time=01:20:00 --job-name=FLOW1K_$ref \
    $SCRIPTS/sc24_CompUnit_flow1k.sh $DIR \
    /gpfs/gibbs/pi/hydro/hydro/dataproces/FLOW1k/flow1k.tif $ref $MERITV

# STEP 11
# NH4 and NO3
#mkdir $TMP/NHO_${ref}
#export NH=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHNO

#sbatch --array=1-$(wc -l < $PROJ/nh_array.txt) --time=02:00:00 \
#    --job-name=NHNO_${ref}  $SCRIPTS/sc25_CompUnit_NITRO.sh $DIR $TMP $ref $NH 

#sbatch --job-name=NHNOjoin_${ref} --time=02:00:00  \
#    --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j" | grep NHNO_${ref} | awk '{print $1}') \
#    $SCRIPTS/sc25b_CompUnit_NITRO_join.sh $DIR $TMP $ref 


# STEP 12
# TERRACLIMATE
#e#xport TERRA=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
##
#m#kdir $TMP/terra_${ref}
##
#s#batch --array=1-$(wc -l < $PROJ/terra_array.txt) \
# #   --time=00:15:00 --job-name=TERRA_${ref} \
# #   $SCRIPTS/sc26_CompUnit_TERRA.sh $DIR $TMP $ref $TERRA 
##
### and join
#s#batch --time=05:00:00 --job-name=TERRAjoin_$ref \
# #   --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j" | grep TERRA_${ref} | awk '{print $1}') \
# #   --array=0-4 $SCRIPTS/sc26b_CompUnit_TERRA_join.sh $DIR $TMP $ref 
##
### and delete
#s#batch --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j" | grep TERRAjoin_$ref | awk '{print $1}') \
# #   $SCRIPTS/sc26c.sh $TMP $ref
##
##
### STEP 13
### TERRACLIMATE STATS PER YEAR
#mkdir $TMP/terra_${ref}_stats
# #   
#sbatch --array=1-$(wc -l < $PROJ/terra_seq.txt) --time=03:30:00 \
#    --job-name=TERRst_$ref  \
#    --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j" | grep TERRAjoin_$ref | awk '{print $1}') \
#    $SCRIPTS/sc27_CompUnit_TERRA_stats.sh $DIR $TMP/terra_${ref}_stats $ref
#sbatch --array=1-$(wc -l < $PROJ/terra_seq.txt) --time=03:30:00 \
#    --job-name=TERRst_$ref  \
#    $SCRIPTS/sc27_CompUnit_TERRA_stats.sh $DIR $TMP/terra_${ref}_stats $ref
#
#### and join
#sbatch --time=15:00:00 --array=0-4 --job-name=TERRstJOIN_${ref}  \
#    --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j"  | grep TERRst_$ref | awk '{print $1}') \
#    $SCRIPTS/sc27b_CompUnit_TERRA_stats_join.sh \
#    $DIR $TMP/terra_${ref}_stats $ref 
##
#### and delete
#sbatch --dependency=afterok:$(squeue -u $USER -o "%.9F %.40j" | grep TERRstJOIN_${ref} | awk '{print $1}') \
#    $SCRIPTS/sc27c.sh $TMP $ref


exit



for file in $(find . -name '*.txt');
do
    nm=$(basename $file .txt)
    zip ${nm}.zip $file
done

find . -name '*.txt' | xargs rm
