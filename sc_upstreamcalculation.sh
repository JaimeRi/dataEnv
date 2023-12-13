#! /bin/bash


export TMP=/data/marquez/phil2/tmp
export DIR=/data/marquez/phil2
export S=${1} 

grass78 -f -text --tmp-location -c $TMP/direction_tmp.tif <<'EOF'

r.external --o input=$TMP/direction_tmp.tif output=dir

r.water.outlet --overwrite input=dir output=bf_${S} \
    coordinates=$(awk -F, -v micid=${S} 'BEGIN{OFS=",";} $1==micid {print $5,$6}' \
    $DIR/basisdatanew.csv)

# zoom to the region of interest (only upstream basin extent)
g.region -a --o zoom=bf_${S}

#  Export the basin as tif file
r.out.gdal --o -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" \
    type=Byte  format=GTiff nodata=0 \
    input=bf_${S} output=$TMP/upstreamB/ubasin_${S}.tif

EOF
