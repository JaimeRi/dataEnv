module load parallel/20210222-GCCcore-10.2.0
gdal3
pktools

export TERRAOUTDIR=/home/jg2657/project/TERRA
export RAM=/dev/shm

wgetTERRA(){
	VARTERRA=$1
	YEAR=$2
	mkdir $TERRAOUTDIR/$VARTERRA
	cd $TERRAOUTDIR/$VARTERRA
	wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_${VARTERRA}_${YEAR}.nc
}

export -f wgetTERRA
parallel -j5 wgetTERRA ::: aet ppt q tmax tmin ::: 2020


#####  EXTRACT variables with subsets   ####-------
for VARTERRA in aet q ppt tmax tmin ; do for YEAR in 2020 ; do for MES in {01..12} ; do echo $VARTERRA $YEAR $MES ; done ; done ; done | xargs -n 3 -P 4 bash -c $'
VARTERRA=$1
YEAR=$2
MES=$3
OUTNAME=$TERRAOUTDIR/${VARTERRA}/${VARTERRA}_${YEAR}_${MES}.tif
gdal_translate -of GTiff -b $MES NETCDF:"$TERRAOUTDIR/$VARTERRA/TerraClimate_${VARTERRA}_${YEAR}.nc":${VARTERRA} $RAM/${VARTERRA}_${YEAR}_${MES}.tif -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9
pksetmask  -m $RAM/${VARTERRA}_${YEAR}_${MES}.tif -msknodata -32766 -nodata -9999  -p "<" -co COMPRESS=DEFLATE -co ZLEVEL=9   -i $RAM/${VARTERRA}_${YEAR}_${MES}.tif  -o $OUTNAME
gdal_edit.py  -tr 0.041666666666666666666666666  -0.041666666666666666666666666   -a_nodata -9999 $OUTNAME
rm $RAM/${VARTERRA}_${YEAR}_${MES}.tif
' _

######  Calculation of TERRACLIMATE

export DIR=/home/jg2657/project/BenthicEU

export FINAL=$DIR/final

export TERRA=/home/jg2657/project/TERRA

export OUTDIR=$DIR/terraN




for VARTERRA in aet ppt q tmax tmin ; do

  cp $DIR/BasisDataBasinsIDs.csv $OUTDIR/TERRA_${VARTERRA}_2020.csv

    for YEAR in 2020 ; do

    echo "Calculating $VARTERRA ---- year $YEAR"

          for MES in {01..12} ; do

                  paste -d "," $OUTDIR/TERRA_${VARTERRA}_2020.csv  \
                  <(printf "%s\n" ${VARTERRA}_${YEAR}_${MES} $(awk -F, 'FNR > 1 {print $2, $3}' $OUTDIR/TERRA_${VARTERRA}.csv | gdallocationinfo -valonly -geoloc  ${TERRA}/${VARTERRA}/${VARTERRA}_${YEAR}_${MES}.tif)) \
                  > $OUTDIR/TERRA_${VARTERRA}_cp.csv

                  mv $OUTDIR/TERRA_${VARTERRA}_cp.csv $OUTDIR/TERRA_${VARTERRA}_2020.csv
          done

    done

    mv $OUTDIR/TERRA_${VARTERRA}_2020.csv $FINAL/TERRA_${VARTERRA}_2020.csv

done


rclone copy /home/jg2657/project/BenthicEU/final/ YaleGDrive:BenthicEllen/Norway_siteIDs_Corrected/


