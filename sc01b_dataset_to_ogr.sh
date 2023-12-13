
#------------------------------------------------------------------------------
# make a vector file from the main table
XPOS=$( awk -F, 'NR==1 {print $2}' $DIR/BasisDataBasinsIDs.csv )
YPOS=$( awk -F, 'NR==1 {print $3}' $DIR/BasisDataBasinsIDs.csv )

ogr2ogr -f "GPKG" -nln orig_points -a_srs EPSG:4326 $DIR/BasisDataBasinsIDs.gpkg $DIR/BasisDataBasinsIDs.csv -oo X_POSSIBLE_NAMES=$XPOS -oo Y_POSSIBLE_NAMES=$YPOS -oo AUTODETECT_TYPE=YES

#------------------------------------------------------------------------------
