#!/bin/bash
#  bash sc04_snapping_Parallel.sh /data/marquez/tomnear /data/marquez/tomnear 54745
SnapPoint(){

### unique id of the point 
export ID=$1

export DIR=$2
export TMP=$3

# path to basins info
export BASIN=$DIR/basins

# prepare target folder
[ ! -d $TMP/snappoints ] && mkdir $TMP/snappoints 
export OUTDIR=$TMP/snappoints

# name of unique id identifier
export SITE=$( awk -F, 'NR==1 {print $1}' $DIR/BasisDataBasinsIDs.csv )

# identify macrobasin ID for that point
export MAB=$(awk -F, -v id="$ID" '$1==id {print $4}' BasisDataBasinsIDs.csv)
# identify microbasin ID for that point
export MIB=$(awk -F, -v id="$ID" '$1==id {print $5}' BasisDataBasinsIDs.csv)


# based on this vector, if it does not exist then exit
[ ! -f $BASIN/basin_${MAB}/bid_${MAB}_stre_order.gpkg ] && exit

#[ ! -d $OUTDIR/basin_${ID} ] && mkdir $OUTDIR/basin_${ID}

# extract point of interest
ogr2ogr -where "$SITE = $ID" -f GPKG $TMP/point_$ID.gpkg \
    $DIR/BasisDataBasinsIDs.gpkg 

# extract vector line (stream reach) associated with point
[ ! -f  $TMP/Microb_${MIB}.gpkg ] &&  \
ogr2ogr -where "stream = ${MIB}" -f GPKG $TMP/Microb_${MIB}.gpkg \
    $BASIN/basin_${MAB}/bid_${MAB}_stre_order.gpkg

# open grass session based on microbasin raster
grass78 -f -text --tmp-location -c $BASIN/basin_${MAB}/bid_${MAB}_mask.tif <<'EOF'

    # read in point of interest
    v.in.ogr input=$TMP/point_$ID.gpkg layer=orig_points output=point_$ID \
    type=point key=$SITE

    # read vector line representing stream reach
    v.in.ogr input=$TMP/Microb_$MIB.gpkg layer=orderV_bid${MAB} \
        output=streamReach_$MIB type=line key=stream

    # Raster with microbasins
    r.in.gdal input=$BASIN/basin_${MAB}/bid_${MAB}_micb.tif output=micb

    # extract microbasin of stream reach $MIB as raster
    r.mapcalc --o "micr_${ID} = if(micb != ${MIB}, null(), 1)"        
          
    # make the raster a vector points
    r.to.vect --o input=micr_${ID} output=micr_vp_${ID} type=point     
    
    # of how many pixels the raster consist? 
    # 1 if stream reach with only one pixel
    # meaning the points already overlap
    NUMP=$(v.info micr_vp_${ID}  | awk '/points/{print $5}')
            
    if [ $NUMP -eq 1 ]
    then
        v.net --o -s input=streamReach_$MIB  points=point_${ID} \
        output=snap_${ID} operation=connect threshold=90 arc_layer=1 \
        node_layer=2

        v.out.ascii input=snap_${ID} layer=2 separator=comma \
        > ${OUTDIR}/coords_${ID}
    
    else 

        v.distance -pa from=micr_vp_${ID} to=micr_vp_${ID}  upload=dist \
          > $TMP/dist_mat_p${ID}_${MAB}_${MIB}.txt
          
        # calculate maximum distance between all points in microbasin
        MAXDIST=0
        for i in \
        $( seq -s' ' 2 $(v.info micr_vp_${ID}  | awk '/points/{print $5}') )
        do
          newmax=$(awk -F'|' -v X="$i" '{print $X}' \
          $TMP/dist_mat_p${ID}_${MAB}_${MIB}.txt | sort -n | tail -n1)
          if (( $(echo "$newmax > $MAXDIST" | bc -l) ));then MAXDIST=$newmax;fi
        done

        v.net --o -s input=streamReach_${MIB}  points=point_${ID} \
        output=snap_${ID} operation=connect threshold=$MAXDIST arc_layer=1 \
        node_layer=2

        v.out.ascii input=snap_${ID} layer=2 separator=comma \
        > ${OUTDIR}/coords_${ID}

        rm $TMP/dist_mat_p${ID}_${MAB}_${MIB}.txt $TMP/point_${ID}.gpkg \
        $TMP/Microb_${MIB}.gpkg
    fi 
EOF
}

export -f SnapPoint

IDS=$(awk -F, 'NR > 1 {print $1}' BasisDataBasinsIDs.csv)

time parallel -j 20 SnapPoint ::: $IDS ::: $DIR ::: $TMP

#MISSING=$(for i in $(ls tmp/snappoints/); do [ -s tmp/snappoints/$i ] || echo $i; done | awk -F_ '{print $2}')


#  Join all single tables in one file
echo XcoordSnap,YcoordSnap,Site_ID_snap > ${OUTDIR}/snap_all.csv
cat ${OUTDIR}/coords_* >> ${OUTDIR}/snap_all.csv

# Join attributes with basis table
paste -d","  \
    $DIR/BasisDataBasinsIDs.csv  \
    <(sort -t, -k3 -h ${OUTDIR}/snap_all.csv)  \
    > $DIR/Locations_snap.csv


#------------------------------------------------------------------------------
# make a vector file from the main table
XPOS=$( awk -F, 'NR==1 {print $6}' $DIR/Locations_snap.csv)
YPOS=$( awk -F, 'NR==1 {print $7}' $DIR/Locations_snap.csv)

ogr2ogr -f "GPKG" -nln Locations_snap -a_srs EPSG:4326 \
    $DIR/Locations_snap.gpkg  $OUTDIR/snap_all.csv  \
    -oo X_POSSIBLE_NAMES=$XPOS -oo Y_POSSIBLE_NAMES=$YPOS -oo AUTODETECT_TYPE=YES

#------------------------------------------------------------------------------

exit
