#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc17_env_DAM_dist.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc17_env_DAM_dist.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M
#SBATCH --array=1-51   ###  total number of basins where dams are located >>> ogrinfo $DIR/dam/dams_roi.gpkg -al | awk '/MacrobasinID/ {print $4}' | sort | uniq | wc -l  #(note that first row is empty!)

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/benthicEU/sc17_env_DAM_dist.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/scripts

# sbatch /home/jg2657/project/BenthicEU/scripts/sc17_env_DAM_dist.sh

source ~/bin/grass78m

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

export DIR=/home/jaime/data/benthicEU
#export DIR=/home/jg2657/project/BenthicEU
export DAMP=/home/jaime/data/benthicEU/dam
#DAMP=/home/jg2657/project/BenthicEU/dam
export OUTDIR=/home/jaime/data/benthicEU/dam
#export OUTDIR=/home/jg2657/project/BenthicEU/dam
export TEMP=/home/jaime/data/benthicEU/tmp
#export TEMP=/home/jg2657/project/BenthicEU/tmp

export basinID=$(ogrinfo $OUTDIR/dams_roi.gpkg -al | awk '/MacrobasinID/ {print $4}' | sort | uniq)
export ID=$(echo $basinID | awk -v id=$SLURM_ARRAY_TASK_ID '{print $id}')



###     2. Calculate distance between points and dams
###       2.1 IF zero distance then discard
###           else
###       2.2. find out if the dam is upstream or downstream
###           2.2.1. consider the point as the outlet and calculate the new basin  (r.water.outlet)
###           2.2.2. calculate elevation and accumulation. if elevation is greater than point and accumulation is less than point then dam is upstream
###           2.2.2. mask for the new basin the stream network
###           2.2.3. If the dam is still in the new basin then is upstream and calculate distance

#1215536 One dam, multiple Points
#1217938 One point, no dams
#1215184 multiple dams, multiple Points

#scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/basins/basin_1215184/*  /home/jaime/data/benthicEU/basins/basin_1215184

export ID=1215184

grass78  -f -text --tmp-location  -c $DIR/basins/basin_${ID}/bid_${ID}_mask.tif   #<<'EOF'


### Ocurrence points available in basin
v.in.ogr --o input=$DIR/benthicEU_snap.gpkg layer=benthicEUsnap output=benthicEU type=point  where="MacrobasinID = ${ID}" key=Site_ID

### create external table with point id, elevation and accumulation values
paste -d "," \
<(printf "%s\n" pointID $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $1}'))  \
<(printf "%s\n" pointELEV $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  $DIR/basins/basin_${ID}/bid_${ID}_elev.tif)) \
<(printf "%s\n" pointACCU $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  $DIR/basins/basin_${ID}/bid_${ID}_accu.tif)) \
> $TEMP/pointsIEA_${ID}.csv
echo \"Integer\",\"Real\",\"Real\" > $TEMP/pointsIEA_${ID}.csvt
db.in.ogr --o $TEMP/pointsIEA_${ID}.csv  out=pointsIEA_${ID}

### Dams points in basin
v.in.ogr --o input=$OUTDIR/dams_snap.gpkg layer=DAMSsnap output=dams_${ID} type=point  where="MacrobasinID = ${ID}" key=fid_snap  ###

### create external table with dam id, elevation and accumulation values
paste -d "," \
<(printf "%s\n" damID $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $1}'))  \
<(printf "%s\n" damELEV $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  $DIR/basins/basin_${ID}/bid_${ID}_elev.tif)) \
<(printf "%s\n" damACCU $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  $DIR/basins/basin_${ID}/bid_${ID}_accu.tif)) \
> $TEMP/damsIEA_${ID}.csv
echo \"Integer\",\"Real\",\"Real\" > $TEMP/damsIEA_${ID}.csvt
db.in.ogr --o $TEMP/damsIEA_${ID}.csv  out=damsIEA_${ID}

# read the cleaned stream network generated by r.stream.order
v.in.ogr  --o input=$DIR/basins/basin_${ID}/bid_${ID}_stre_order.gpkg layer=orderV_bid${ID} output=stre_cl type=line key=stream

#  DELETE v.patch -n --o input=dams_${ID},benthicEU output=alldamsandpoints


# connect streams to occurrence points
v.net --o input=stre_cl points=benthicEU output=streams_net1 operation=connect thresh=1 arc_layer=1 node_layer=2

# connect streams to dam points
v.net --o input=streams_net1 points=dams_${ID} output=streams_net2 operation=connect thresh=1 arc_layer=1 node_layer=3

# shortest paths from occurrence (points in layer 2) to nearest dam (points in layer 3)
v.net.distance --o in=streams_net2 out=occurrrence_to_dams flayer=2 to_layer=3

### calculate distance in the streeam network between all pairs
#v.net.allpairs -g --o input=streams_net2 output=dist_all_tmp cats=$(echo $RANGE | awk '{gsub(" ",","); print $0}')

# visualization
# d.mon wx0
# d.vect stre_cl color=220:220:220
# d.vect benthicEU color=blue size=10
# d.vect map=dams_${ID} icon=basic/cross3 size=15 color=black fcolor=red
# d.vect occurrrence_to_dams

## Join the tables with the vector
v.db.join map=occurrrence_to_dams column=tcat other_table=damsIEA_${ID} other_column=damID
v.db.join map=occurrrence_to_dams column=cat other_table=pointsIEA_${ID} other_column=pointID

v.report -c map=occurrrence_to_dams layer=1 option=length units=kilometers  | awk -F',' 'BEGIN{OFS=",";} {gsub(/[|]/, ","); print $1, $4, $5, $6, $8, $9, $10}' > $OUTDIR/DAM_stats_${ID}.csv

### rules:   if elevation of occurrence is greater than elevation of dam AND accumulation of occurrence is less than accumulation of dam THEN dam is upstream and distance is zero
v.report -c map=occurrrence_to_dams layer=1 option=length units=kilometers | awk -F"|" 'BEGIN{OFS=",";} {
if ($5 > $8 && $6 < $9)
	print $1, $4, $5, $6, $8, $9, $10;
else
	print $1, $4, $5, $6, $8, $9, 0;
}'


SEQUE=$(seq -s' ' 1 $(v.info benthicEU | awk '/points/{print $5}'))
RANGE=$(v.db.select -c benthicEU col=Site_ID)

for PN in $SEQUE; do

      echo "*****  Processing Point : $PN  of $(v.info benthicEU | awk '/points/{print $5}') *****"

			# extract one point at a time
			POINT=$(printf "%s\n" $RANGE | head -n $PN | tail -n 1)
			v.extract --o input=benthicEU type=point cats=${POINT} output=sampleOne

v.in.ogr --o input=$OUTDIR/dams_snap.gpkg layer=DAMSsnap output=dams_${ID} type=point  where="MacrobasinID = ${ID}" key=fid_snap  ###
v.extract --o input=dams_${ID} type=point cats=412 output=dam_412
r.water.outlet --o input=dire output=dam_basin_412 coordinates=$(v.to.db -p map=dam_412 option=coor separator=comma | awk -F, 'FNR >1{print $2"," $3}')

			r.water.outlet --o input=dire output=basin_pnt_${POINT} coordinates=$(v.to.db -p map=sampleOne option=coor separator=comma | awk -F, 'FNR >1{print $2"," $3}')

			r.out.gdal --o -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte  format=GTiff nodata=255 input=basin_pnt_${POINT} output=$DIR/basin_pnt_${POINT}.tif

			v.what.rast -p map=dams_${ID} raster=basin_pnt_${POINT}

      # POINT=$(printf "%s\n" $RANGE | head -n $PN | tail -n 1)
      # COMPLEMENT=$(echo $RANGE | awk -v sequ="$PN" 'BEGIN{OFS=",";} {$sequ=""; print $0}' |  cut -d, -f${PN} --complement)
			#
      # ### Split points one at a time
    	# v.extract --o input=benthicEU type=point cats=${POINT} output=sampleOne
    	# v.extract --o input=benthicEU type=point cats=${COMPLEMENT} output=sampleRest
			#
      # ### calculate distance from each point to all other points
      # v.distance -pa --q from=sampleOne from_type=point to=sampleRest to_type=point upload=dist separator=comma | awk -F',' 'BEGIN{OFS=",";} NR > 1 {print $1, $2, $3/1000}'  >> $OUTDIR/dist_fly/dist_fly_allp_${ID}.csv

done


# d.mon wx0
# d.vect stre_cl color=220:220:220
# d.vect benthicEU color=blue size=10
# d.vect map=dams_${ID} icon=basic/cross3 size=15 color=black fcolor=red
# d.vect occurrrence_to_dams
d.mon wx0
d.erase
d.rast dam_basin_412 color=blue
d.rast basin_pnt_${POINT}
d.vect  stre_cl color=220:220:220
d.vect sampleOne
d.vect map=dams_${ID} icon=basic/cross3 size=15 color=black fcolor=red


### rules:   if elevation is greater than point and accumulation is less than point then dam is upstream
# if $3 > $5 && $4 < $6 then $7 = $7 else $7 = 0
# awk -F"|" 'BEGIN{OFS=",";} {
# if ($3 > $5 && $4 < $6)
# 	print $1, $4, $5, $6, $8, $9, $10;
# else
# 	print $1, $4, $5, $6, $8, $9, 0;
# }' $OUTDIR/DAM_stats_${ID}.csv

















##############################################################################

##################    Version with creation of upstream watershed

##############################################################################


grass78  -f -text --tmp-location  -c $DIR/basins/basin_${ID}/bid_${ID}_mask.tif   #<<'EOF'


r.external  input=$DIR/basins/basin_${ID}/bid_${ID}_dire.tif    output=dire  --overwrite


### Ocurrence points available in basin
v.in.ogr --o input=$DIR/benthicEU_snap.gpkg layer=benthicEUsnap output=benthicEU type=point  where="MacrobasinID = ${ID}" key=Site_ID

### create external table with point id, elevation and accumulation values
# paste -d "," \
# <(printf "%s\n" pointID $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $1}'))  \
# <(printf "%s\n" pointELEV $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  $DIR/basins/basin_${ID}/bid_${ID}_elev.tif)) \
# <(printf "%s\n" pointACCU $(v.db.select benthicEU | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  $DIR/basins/basin_${ID}/bid_${ID}_accu.tif)) \
# > $TEMP/pointsIEA_${ID}.csv
# echo \"Integer\",\"Real\",\"Real\" > $TEMP/pointsIEA_${ID}.csvt
# db.in.ogr --o $TEMP/pointsIEA_${ID}.csv  out=pointsIEA_${ID}

### Dams points in basin
v.in.ogr --o input=$OUTDIR/dams_snap.gpkg layer=DAMSsnap output=dams_${ID} type=point  where="MacrobasinID = ${ID}" key=fid_snap  ###

### create external table with dam id, elevation and accumulation values
# paste -d "," \
# <(printf "%s\n" damID $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $1}'))  \
# <(printf "%s\n" damELEV $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  $DIR/basins/basin_${ID}/bid_${ID}_elev.tif)) \
# <(printf "%s\n" damACCU $(v.db.select dams_${ID} | awk -F"|" 'FNR>1{print $2, $3}' | gdallocationinfo -valonly -geoloc  $DIR/basins/basin_${ID}/bid_${ID}_accu.tif)) \
# > $TEMP/damsIEA_${ID}.csv
# echo \"Integer\",\"Real\",\"Real\" > $TEMP/damsIEA_${ID}.csvt
# db.in.ogr --o $TEMP/damsIEA_${ID}.csv  out=damsIEA_${ID}

# read the cleaned stream network generated by r.stream.order
v.in.ogr  --o input=$DIR/basins/basin_${ID}/bid_${ID}_stre_order.gpkg layer=orderV_bid${ID} output=stre_cl type=line key=stream

v.patch -n --o input=dams_${ID},benthicEU output=alldamsandpoints


# connect streams to occurrence points
v.net --o input=stre_cl points=benthicEU output=streams_net1 operation=connect thresh=1 arc_layer=1 node_layer=2

# connect streams to dam points
v.net --o input=streams_net1 points=dams_${ID} output=streams_net2 operation=connect thresh=1 arc_layer=1 node_layer=3

# shortest paths from occurrence (points in layer 2) to nearest dam (points in layer 3)
v.net.distance --o in=streams_net2 out=occurrrence_to_dams flayer=2 to_layer=3

### calculate distance in the streeam network between all pairs
v.net.allpairs -g --o input=streams_net2 output=dist_all_tmp cats=$(echo $RANGE | awk '{gsub(" ",","); print $0}')

# visualization
# d.mon wx0
# d.vect stre_cl color=220:220:220
# d.vect benthicEU color=blue size=10
# d.vect map=dams_${ID} icon=basic/cross3 size=15 color=black fcolor=red
# d.vect occurrrence_to_dams

## Join the tables with the vector
v.db.join map=occurrrence_to_dams column=tcat other_table=damsIEA_${ID} other_column=damID
v.db.join map=occurrrence_to_dams column=cat other_table=pointsIEA_${ID} other_column=pointID

v.report -c map=occurrrence_to_dams layer=1 option=length units=kilometers  | awk -F',' 'BEGIN{OFS=",";} {gsub(/[|]/, ","); print $1, $4, $5, $6, $8, $9, $10}' > $OUTDIR/DAM_stats_${ID}.csv

### rules:   if elevation of occurrence is greater than elevation of dam AND accumulation of occurrence is less than accumulation of dam THEN dam is upstream and distance is zero
v.report -c map=occurrrence_to_dams layer=1 option=length units=kilometers | awk -F"|" 'BEGIN{OFS=",";} {
if ($5 > $8 && $6 < $9)
	print $1, $4, $5, $6, $8, $9, $10;
else
	print $1, $4, $5, $6, $8, $9, 0;
}'


SEQUE=$(seq -s' ' 1 $(v.info benthicEU | awk '/points/{print $5}'))
RANGE=$(v.db.select -c benthicEU col=Site_ID)

for PN in $SEQUE; do

      echo "*****  Processing Point : $PN  of $(v.info benthicEU | awk '/points/{print $5}') *****"

			# extract one point at a time
			POINT=$(printf "%s\n" $RANGE | head -n $PN | tail -n 1)
			v.extract --o input=benthicEU type=point cats=${POINT} output=sampleOne

v.in.ogr --o input=$OUTDIR/dams_snap.gpkg layer=DAMSsnap output=dams_${ID} type=point  where="MacrobasinID = ${ID}" key=fid_snap  ###
v.extract --o input=dams_${ID} type=point cats=412 output=dam_412
r.water.outlet --o input=dire output=dam_basin_412 coordinates=$(v.to.db -p map=dam_412 option=coor separator=comma | awk -F, 'FNR >1{print $2"," $3}')

			r.water.outlet --o input=dire output=basin_pnt_${POINT} coordinates=$(v.to.db -p map=sampleOne option=coor separator=comma | awk -F, 'FNR >1{print $2"," $3}')

			r.out.gdal --o -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte  format=GTiff nodata=255 input=basin_pnt_${POINT} output=$DIR/basin_pnt_${POINT}.tif

			v.what.rast -p map=dams_${ID} raster=basin_pnt_${POINT}

      # POINT=$(printf "%s\n" $RANGE | head -n $PN | tail -n 1)
      # COMPLEMENT=$(echo $RANGE | awk -v sequ="$PN" 'BEGIN{OFS=",";} {$sequ=""; print $0}' |  cut -d, -f${PN} --complement)
			#
      # ### Split points one at a time
    	# v.extract --o input=benthicEU type=point cats=${POINT} output=sampleOne
    	# v.extract --o input=benthicEU type=point cats=${COMPLEMENT} output=sampleRest
			#
      # ### calculate distance from each point to all other points
      # v.distance -pa --q from=sampleOne from_type=point to=sampleRest to_type=point upload=dist separator=comma | awk -F',' 'BEGIN{OFS=",";} NR > 1 {print $1, $2, $3/1000}'  >> $OUTDIR/dist_fly/dist_fly_allp_${ID}.csv

done
