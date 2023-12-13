#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
####SBATCH -t 02:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc04_snapping.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc04_snapping.sh.%A_%a.err
#SBATCH --mem-per-cpu=30000M
####SBATCH --array=1-?

#  scp  /home/jaime/Code/environmental-data-extraction/sc04_snapping.sh grace:/home/jg2657/project/code/environmental-data-extraction

# sbatch /home/jg2657/project/BenthicEU/scripts/sc04_snapping.sh

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash

module purge
source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export DIR=$1
export TMP=$2

export MERITVAR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
#export BASIN=$TMP/basins

export basinID=$(awk -F, 'FNR > 1 {print $4}' $DIR/BasisDataBasinsIDs.csv | sort | uniq)

[ ! -d $TMP/snappoints ] && mkdir $TMP/snappoints 
export OUTDIR=$TMP/snappoints

# Macro-basin
export ID=$(echo $basinID | awk -v id=$SLURM_ARRAY_TASK_ID '{print $id}')
# Name of column for unique ID
export SITE=$( awk -F, 'NR==1 {print $1}' $DIR/BasisDataBasinsIDs.csv )

#[ ! -f $BASIN/basin_${ID}/bid_${ID}_stre_order.gpkg ] && exit

[ ! -d $OUTDIR/basin_${ID} ] && mkdir $OUTDIR/basin_${ID}

if [ ! -f $OUTDIR/basin_${ID}/order_vect_${ID}.gpkg  ]; then
    ogr2ogr \
    $OUTDIR/basin_${ID}/order_vect_${ID}.gpkg \
    $MERITVAR/CompUnit_stream_order/vect/order_vect_${ID}.gpkg \
    -sql "SELECT * FROM vect  WHERE ST_GeometryType(geom) LIKE 'LINESTRING'"
fi 

echo
echo "*****  RUN : $SLURM_ARRAY_TASK_ID ---  Processing BASIN : $ID  *****"
echo

##################################
######     START GRASS
grass78 -f -text --tmp-location -c $MERITVAR/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${ID}.tif  <<'EOF'

# Points in microbasin
#v.in.ogr  input=$DIR/BasisDataBasinsIDs.gpkg layer=orig_points output=benthicEU \
#type=point  where="MacrobasinID = ${ID}"  key=$SITE   
v.in.ogr -o input=$DIR/BasisDataBasinsIDs.gpkg layer=orig_points output=benthicEU \
type=point  where="CompUnitID = ${ID}"  key=$SITE   

# Raster with microbasins
#r.in.gdal input=$TMP/basins/basin_${ID}/bid_${ID}_micb.tif output=micb
r.in.gdal input=$MERITVAR/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${ID}.tif  output=micb

# list of Site_ID of points available in microbasin
RANGE=$(v.db.select -c benthicEU col=$SITE)

# for loop to make the snap of each point at a time
for PN in $RANGE; do

    # select micro basin id at point
    MB=$(v.db.select benthicEU | awk -F'|' -v X="${PN}" '$1==X {print $6}')

    # vector line (stream reach) associated with point
    #v.in.ogr  --o input=$BASIN/basin_${ID}/bid_${ID}_stre_order.gpkg \
    #layer=orderV_bid${ID} output=streams_${PN}_${MB} type=line key=stream \
    #where="stream = ${MB}"
    v.in.ogr  --o input=$OUTDIR/basin_${ID}/order_vect_${ID}.gpkg \
    layer=SELECT output=streams_${PN}_${MB} type=line key=stream \
    where="stream = ${MB}"

    # extract point
    v.extract --o input=benthicEU type=point cats=${PN} output=point_${PN}

    # extract microbasin of stream reach $PN as raster
    r.mapcalc --o "micr_${PN} = if(micb != ${MB}, null(), 1)"        
          
    # make the raster a vector points
    r.to.vect --o input=micr_${PN} output=micr_vp_${PN} type=point     
    
    # of how many pixels the raster consist? 
    # 1 if stream reach with only one pixel
    # meaning the points already overlap
    NUMP=$(v.info micr_vp_${PN}  | awk '/points/{print $5}')
            
    if [ $NUMP -eq 1 ]
    then
        v.net --o -s input=streams_${PN}_${MB}  points=point_${PN} \
        output=snap_${PN} operation=connect threshold=90 arc_layer=1 \
        node_layer=2

        v.out.ascii input=snap_${PN} layer=2 separator=comma \
        > ${OUTDIR}/basin_${ID}/coords_${PN}
    
    else 

        v.distance -pa from=micr_vp_${PN} to=micr_vp_${PN}  upload=dist \
          > $TMP/dist_mat_p${PN}_${ID}_${MB}.txt
          
        # calculate maximum distance between all points in microbasin
        MAXDIST=0
        for i in \
        $( seq -s' ' 2 $(v.info micr_vp_${PN}  | awk '/points/{print $5}') )
        do
          newmax=$(awk -F'|' -v X="$i" '{print $X}' \
          $TMP/dist_mat_p${PN}_${ID}_${MB}.txt | sort -n | tail -n1)
          if (( $(echo "$newmax > $MAXDIST" | bc -l) ));then MAXDIST=$newmax;fi
        done

        v.net --o -s input=streams_${PN}_${MB}  points=point_${PN} \
        output=snap_${PN} operation=connect threshold=$MAXDIST arc_layer=1 \
        node_layer=2

        v.out.ascii input=snap_${PN} layer=2 separator=comma \
        > ${OUTDIR}/basin_${ID}/coords_${PN}

        rm $TMP/dist_mat_p${PN}_${ID}_${MB}.txt
    fi 
done


#  Join all single tables in one file
echo XcoordSnap,YcoordSnap,Site_ID_snap > ${OUTDIR}/basin_${ID}/coords_all_${ID}.csv
for i in $RANGE; do cat ${OUTDIR}/basin_${ID}/coords_${i} \
>> ${OUTDIR}/basin_${ID}/coords_all_${ID}.csv; done

#  Read back to GRASS as a vector point
v.in.ascii --o input=${OUTDIR}/basin_${ID}/coords_all_${ID}.csv \
output=allPoints_${ID} \
columns='XcoordSnap double precision, YcoordSnap double precision, Site_ID_snap int' \
skip=1 x=1 y=2 z=0 separator=comma

# join attribute table from original file
v.db.join map=allPoints_${ID} column=Site_ID_snap other_table=benthicEU \
other_column=$SITE

# create the new vector gpkg file
v.out.ogr  -s --overwrite input=allPoints_${ID} type=point  \
output=${OUTDIR}/basin_${ID}/basin_${ID}.gpkg format=GPKG output_layer=snapped

EOF

exit


sacct -j 18593817 --format=JobID,State,Elapsed
