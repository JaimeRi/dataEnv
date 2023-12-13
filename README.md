# TO DOs

- sc10 can be converted to array and add the calculation of the area for each basin
- Check r.lfp to extract the stream where the dam overlap
- http://amber.international data check
- Edit scripts to run in IGB servers


# Editions

REQUIREMENTS:
1. Input table should consist of record ID and X and Y coordinates
2. lat and long column names must be stardard (Latitud & Longitud)


------------------------------------

## Dataset

```sh
cat Coordinates_forSami_3moSeason_24Nov2020.csv | head

Site_ID,Country,River,Longitude_X,Latitude_Y,Starting_year,Ending_year,NEW?
100000001,France,Rhone,5.294382,45.829523,1980,2014,
100000002,France,Rhone,5.299435,45.8323815,1999,2014,
100000003,France,AUTHIE,1.918195639,50.30448305,1998,2014,
100000004,France,ANCRE,2.513745757,49.9332428,1995,2014,
100000005,France,NOYE,2.385456242,49.79422815,1997,2015,
100000006,France,SELLE,2.169124882,49.71432717,1997,2015,
100000007,France,EVOISSONS,2.016358357,49.74211763,1997,2015,
100000009,France,DOLLER,7.232714668,47.74561836,1997,2016,
100000010,France,THUR,7.264966594,47.82728771,1997,2016,
```

Table has 1841 rows, i.e., 1 header and 1840 records (Site_IDs)

example of duplicates:
```sh
114000022,Hungary,Tisza,20.10484453,46.18551547,2005,2017,1214749,35431284
114000054,Hungary,Tisza,20.10484453,46.18551547,2005,2017,1214749,35431284
```

Some points differ ONLY  on the year range!  Example:

```sh
104000016,Sweden,Kitki�joki,23.25594389,67.76318579,2007,2019,1183837,15386097
104000093,Sweden,Kitki�joki,23.25594388,67.76318579,2011,2019,1183837,15386097
```

Example of three points within the same macrobasin AND the same microbasin. BUT the river name is different in the first site!
```sh
103000610,Spain,Deba,-2.4474737,43.0814872,2002,2019,1091692,16487651
103000655,Spain,Gipuzkoa,-2.447404836,43.0819959,1987,2017,1091692,16487651
103000677,Spain,Gipuzkoa,-2.445787064,43.08249595,1987,2017,1091692,16487651
```
Another example

```sh
103000533,Spain,Estanda,-2.2191363,43.0504046,2002,2019,1097230,16814175
103000666,Spain,Gipuzkoa,-2.217898878,43.052181,1996,2017,1097230,16814175

103000578,Spain,Oria,-2.1527286,43.0810712,1994,2019,1097230,20742621
103000683,Spain,Gipuzkoa,-2.152853589,43.08181051,2003,2017,1097230,20742621
```
<!-- Table has 8 columns but column "NEW?" was deleted -->

## Variables of interest

Selected after consultation:

- Elevation
- Stream order
- Slope
- Flow accumulation
- Distance between locations
- Climate
  - Evapotranspiration
  - Precipitation
  - Runoff
  - Maximum Temperature
  - Minimum Temperature
- Land cover / Proportion of different land cover categories
- Minimum Distance to dams upstream
- Global irrigated areas (presence/absence)
- Nitrogen fertilizer input (NH4 and NO3)

**Output saved to:** https://drive.google.com/drive/folders/1Wv4UIBbQxerYN54JtZ-m49QfoIvr4jd5?usp=sharing
<!-- # Actual Evapotranspiration (TERRACLIMATE) (aet) (4km)
# Precipitation (TERRACLIMATE) (ppt) (4km)
# Runoff (TERRACLIMATE) (q) (4km)
# Max Temperature (TERRACLIMATE) (tmax) (4km)
# Min Temperature (TERRACLIMATE) (tmin) (4km)
# NH4_input (55km)
# NO3_input (55km) -->

## Sites geographical distribution
![screen03](/assets/screen03_ptwfmnkcu.png)

```sh
touch roi.csv
printf "gid,WKT\n1,\"POLYGON((-10.5 34.5, -10.5 68, 34 68, 34 34.5, -10.5 34))\"\n" > roi.csv
ogr2ogr -f "GPKG" roi.gpkg -dialect sqlite -sql "SELECT gid, ST_GeomFromText(WKT,4326) FROM roi" roi.csv
```



## Baseline Hydrological Global Data at 90 x 90 m pixel size

Work in preparation:  _Amatulli, G., Domisch, S, Kiesel, J, Shen, L, García-Márquez, J._
http://spatial-ecology.net/hydrography-demo/

Hidrographical variables derived from latest MERIT DEM (Digital Elevation Model -  NASA SRTM3 DEM v2.1)
- Basin delineation  (**Macrobasin**)
- Sub-basin delineation per stream reach (**Microbasin**)
![screen04](/assets/screen04.png)
- Stream network
  - *The minimum upstream flow accumulation threshold for initiating a headwater stream was set to 0.05 km²*
![screen05](/assets/screen05.png)
- Flow direction
- Flow accumulation





# Tools

**Bash** as the main back-end language and command utilities, integrated with  **GDAL** libraries, **GRASS GIS**, **pktools**, **GNU awk**.

All process were run in the High Performance Computing (HPC) clusters at Yale.

- Baseline data resides there and is constantly updating.
- More efficient when applying same procedures at global scale.
- Efficient pararell processing (The **Slurm** Workload Manager).

# Scripts

Organised in a gitlab repository (*soon available*)

![screen01](/assets/screen01.png)

They follow a logic order given by:

- Data properties
- Dependencies
- Trying to simplify computing processing
- *Array* as parallelization tecnique

## sc01

Script to assign macro and micro basin IDs to each Site_ID

The script should be provided with a csv table `BasisData.csv` located in `DIR`. The table must consist of an ID `Site_ID` in the first column, X coordinates `Longitude_X` in the second column and the Y coordinates `Latitude_Y` in the third column. Coordinates must be given in WGS84.

```sh
DATASET=$DIR/BasisData.csv

paste -d "," $DATASET     \
<(printf "%s\n" MacrobasinID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET | gdallocationinfo -valonly -geoloc  $MACROB))   \
<(printf "%s\n" MicrobasinID $(awk -F, 'FNR > 1 {print $2, $3}' $DATASET | gdallocationinfo -valonly -geoloc  $MICROB))    \
> $DIR/BasisDataBasinsIDs.csv
```

Output table `BenthicEU.csv`

```sh
cat $DIR/BenthicEU.csv | head

Site_ID,Country,River,Longitude_X,Latitude_Y,Starting_year,Ending_year,MacrobasinID,MicrobasinID
100000001,France,Rhone,5.294382,45.829523,1980,2014,1096615,15625285
100000002,France,Rhone,5.299435,45.8323815,1999,2014,1096615,15624776
100000003,France,AUTHIE,1.918195639,50.30448305,1998,2014,1096625,29534865
100000004,France,ANCRE,2.513745757,49.9332428,1995,2014,1097050,28056659
100000005,France,NOYE,2.385456242,49.79422815,1997,2015,1097050,27343464
100000006,France,SELLE,2.169124882,49.71432717,1997,2015,1097050,25665510
100000007,France,EVOISSONS,2.016358357,49.74211763,1997,2015,1097050,23561450
100000009,France,DOLLER,7.232714668,47.74561836,1997,2016,1097310,12650897
100000010,France,THUR,7.264966594,47.82728771,1997,2016,1097310,13395462
```

2. Create a spatial object, i.e., point vector file, for further analysis

```sh
ogr2ogr -f "GPKG" -nln orig_points -a_srs EPSG:4326 $DIR/BenthicEU.gpkg $DIR/BenthicEU.csv -oo X_POSSIBLE_NAMES=Longitude_X -oo Y_POSSIBLE_NAMES=Latitude_Y -oo AUTODETECT_TYPE=YES
```
3. Crop to the region of interest the global map of basins

```sh
gdalwarp  -co COMPRESS=DEFLATE -co ZLEVEL=9 -cutline /home/jg2657/project/BenthicEU/roi.gpkg -crop_to_cutline /gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_HYDRO/lbasin_tiles_final20d_ovr/all_lbasin.tif  /home/jg2657/project/BenthicEU/basins_benthicEU.tif
```
## sc02

**Data preparation**: Script to extract (crop) all the baseline data for each macrobasin.

Process is running in parallel with the _array_ technique

Script preamble:
```sh
#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_envprep.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_envprep.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M
#SBATCH --array=1-309
```

| Variables | File example |
|-----------|--------------|
| Mask   | _bid_1217647_mask.tif_   |
| Elevarion   | _bid_1217647_elev.tif_   |
| Flow accumulation  | _bid_1217647_flow.tif_  |
| Flow direction  | _bid_1217647_dire.tif_  |
| Stream network  | _bid_1217647_stre.tif_  |
|  Microbasins | _bid_1217647_micr.tif_  |


## sc03

Script to calculate: (_calculations done in **GRASS GIS**_)
- Stream order ``r.stream.order``

```sh
r.stream.order  --o stream_rast=stre direction=dire elevation=elev accumulation=accu stream_vect=orderV_bid${ID} strahler=orderStrahler_bid${ID} memory=25000
```

The selected outputs of stream order is a raster of Strahler order technique and a vector file that provides several statistics :
![screen06](/assets/screen06.png)

- Stream slope ``r.stream.slope``

Calculations done in **grass78**

## sc04

Script to snap **Sites** to the stream network (Topological correction).

Run for each macrobasin independently (_array_)

Given the output of the modeled stream network, spatial inaccuracies occur. The snapping procedure is necessary, for example to measure "as the fish swims"- distances between sites.

**The issue:**

![snap_01](/assets/snap_01.png)

**Snapping based only on distance**

![snap_02](/assets/snap_02.png)

**Snapping based on distance BUT only within microbasin**

![snap_05](/assets/snap_05.png)

## sc05

Script to merge the output of the snapping procedure in previous script

```sh
LISTFILES=$(find  /home/jg2657/project/BenthicEU/snappoints/ -name '*.gpkg')
ogrmerge.py -o $DIR/benthicEU_snap.gpkg  $LISTFILES -f "GPKG" -single -nln benthicEUsnap -overwrite_ds
```

### distance all points

Calculate pair-wise distance between all sites.

```sh
grass78  -f -text --tmp-location  -c $DIR/basins_benthicEU.tif

##  import data
v.in.ogr --o input=$DIR/benthicEU_snap.gpkg layer=benthicEUsnap output=benthicEUall type=point key=Site_ID

##  Calculate distance, results are given in meters
v.distance -pa from=benthicEUall to=benthicEUall upload=dist separator=comma > $OUTDIR/dist_matrix_all.csv
```
==OUTPUT== > 61MB  dist_matrix_all.csv  (_distances in meters_)

```sh
awk -F, ' {print $1, $2, $3, $4, $5, $6}' distance/dist_matrix_all.csv | head

  100000001 100000002 100000003 100000004 100000005
100000001 0 558.38773889015806 557522.75564395776 501401.52668902522 491590.51367079717
100000002 558.38773889015806 0 557203.2931071152 501065.54271283286 491268.24171374703
100000003 557522.75564395776 557203.2931071152 0 59353.313918152962 66011.93276185391
100000004 501401.52668902522 501065.54271283286 59353.313918152962 0 17980.69620238318
100000005 491590.51367079717 491268.24171374703 66011.93276185391 17980.69620238318 0
100000006 491473.15774197556 491167.85527366446 67951.380583140941 34726.597571041959 18036.975745996449
100000007 499536.16644178284 499238.41611911432 62975.087097696174 41620.028711805462 27319.283818689324
100000009 259439.55288153357 258882.94212618639 481481.00060224102 423104.17151866172 422620.98204680887

```

## sc06

Script to calculate distance between sites in each macrobasin.

Two approaches were followed:
- as the fish swims
- as the crow flyes

The output tables consists of three columns (and not a matrix!)

```sh
echo 'Site_ID,dist_Site_ID,dist' > $OUTDIR/dist_fly/dist_fly_allp_${ID}.csv

echo 'Site_ID,dist_Site_ID,dist' > $OUTDIR/dist_fish/dist_fish_allp_${ID}.csv
```

## sc07

Script to merge the temporal files of pair-wise distances per macrobasin

```sh
echo 'Site_ID_from,Site_ID_to,distanceKM' > $OUTDIR/tb_dist_fly.csv

for FILE in $(ls $OUTDIR/dist_fly); do
    awk 'FNR > 1' $OUTDIR/dist_fly/$FILE >> $OUTDIR/tb_dist_fly.csv
done
```
==OUTPUT==
3,7M tb_dist_fish.csv
2,8M tb_dist_fly.csv

The output format is a three columns table:

```sh
cat distance/tb_dist_fish.csv  | head

Site_ID_from,Site_ID_to,distanceKM
109000100,109000101,11.2864761067484
109000101,109000100,11.2864761067484
109000086,109000089,1.95432514882915
109000086,109000090,2.19174435656529
109000089,109000086,1.95432514882915
109000089,109000090,4.14606950539444
109000090,109000086,2.19174435656529
109000090,109000089,4.14606950539443
103000715,103000721,42.3693903348804
```

Could be transform to a pair-wise matrix in R

```R
library(tidyr)
tb = read.csv("tb_dist_fly.csv")
pivot_wider(tb, names_from = c(Site_ID_from), values_from = distanceKM)

# A tibble: 1,669 x 1,670
   Site_ID_to `109000100` `109000101` `109000086` `109000089` `109000090`
        <int>       <dbl>       <dbl>       <dbl>       <dbl>       <dbl>
 1  109000101        8.71       NA          NA          NA          NA
 2  109000100       NA           8.71       NA          NA          NA
 3  109000089       NA          NA           1.71       NA           3.59
 4  109000090       NA          NA           1.90        3.59       NA
 5  109000086       NA          NA          NA           1.71        1.90
 6  103000721       NA          NA          NA          NA          NA
 7  103000723       NA          NA          NA          NA          NA
 8  103000715       NA          NA          NA          NA          NA
 9  103000568       NA          NA          NA          NA          NA
10  103000555       NA          NA          NA          NA          NA
```

## sc08

Calculation of variable statistics for each Site based on all the pixels within the microbasin each Site is located in.

```sh
##  Calculate the statistics for each microbasin for each variable and save in csv file
for VAR in slope elev accu; do
  r.external  input=$BASIN/basin_${ID}/bid_${ID}_${VAR}.tif    output=$VAR  --overwrite
  r.univar -t --o map=$VAR zones=micbonly  separator=comma | awk -F, 'BEGIN{OFS=",";} {print $1, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14 }' > $OUTDIR/basin_$ID/stats_${ID}_${VAR}.csv
done
```
https://grass.osgeo.org/grass79/manuals/r.univar.html

Extract the information on stream order and distance downstream to outlet from the stream order vector calculated previously

```sh
# read the cleaned stream network generated by r.stream.order (but only the reaches where the points are located)
v.in.ogr  --o input=$BASIN/basin_${ID}/bid_${ID}_stre_order.gpkg layer=orderV_bid${ID} output=stre_cl type=line key=stream where="stream IN ($(v.db.select benthicEU | awk -F'|' 'NR > 1 {print $9}' ORS=',' | sed 's/,*$//g'))"

#v.db.select stre_cl | awk -F'|' 'BEGIN{OFS=",";} {print $1, $8, $20, $23}' > $OUTDIR/basin_$ID/stats_${ID}_order.csv
v.db.select stre_cl | awk -F'|' 'NR==1 { for (i=1; i<=NF; i++) {f[$i] = i}} BEGIN{OFS=",";} { print $(f["stream"]), $(f["strahler"]), $(f["out_dist"]), $(f["elev_drop"]) }' > $OUTDIR/basin_$ID/stats_${ID}_order.csv
```
## sc09

Script to join temporal tables of variable statistics

==OUTPUT==
365K stats_accu_complete.csv
347K stats_elev_complete.csv
101K stats_order_complete.csv
357K stats_slope_complete.csv


```sh
cat statsOUT/stats_elev_complete.csv | head

Site_ID,MacrobasinID,MicrobasinID,zone,min,max,range,mean,mean_of_abs,stddev,variance,coeff_var,sum,sum_abs
100000001,1096615,15625285,15625285,193.400009155273,197.400009155273,4,195.100005300421,195.100005300421,1.25068420317425,1.5642109760696,0.641047754585347,3706.90010070801,3706.90010070801
100000002,1096615,15624776,15624776,194.100006103516,203.400009155273,9.30000305175781,197.535298964557,197.535298964557,2.93316535568994,8.6034590038197,1.48488162422871,3358.10008239746,3358.10008239746
100000003,1096625,29534865,29534865,9.10000038146973,63.1000022888184,54.0000019073486,24.906667098999,24.906667098999,17.3409140127848,300.707298798795,69.6235828899069,1868.00003242493,1868.00003242493
100000004,1097050,28056659,28056659,29.8000011444092,36,6.19999885559082,32.8583343823751,32.8583343823751,2.32825342027558,5.42076398902494,7.08573171476529,394.300012588501,394.300012588501
100000005,1097050,27343464,27343464,39.5,43.7000007629395,4.20000076293945,40.6250007152557,40.6250007152557,1.33064823160848,1.77062471628278,3.27544174321402,650.000011444092,650.000011444092
100000006,1097050,25665510,25665510,62.7000007629395,87.4000015258789,24.7000007629395,68.9888905419244,68.9888905419244,7.81237627711181,61.0332230951794,11.3241077161029,1241.80002975464,1241.80002975464
100000007,1097050,23561450,23561450,88.5,158.800003051758,70.3000030517578,111.553573608398,111.553573608398,21.9650944369805,482.465373625472,19.6901755152081,3123.50006103516,3123.50006103516
100000009,1097310,12650897,12650897,256.800018310547,268.100006103516,11.2999877929688,261.469286550883,261.469286550883,2.53230688763994,6.4125781731887,0.968491145191213,40004.8008422852,40004.8008422852
100000010,1097310,13395462,13395462,243.600006103516,251.300003051758,7.69999694824219,246.809094515714,246.809094515714,2.24396233311063,5.03536695241928,0.909189484088382,13574.5001983643,13574.5001983643
```
```sh
cat statsOUT/stats_order_complete.csv | head

Site_ID,MacrobasinID,MicrobasinID,stream,strahler,out_dist,elev_drop
100000001,1096615,15625285,15625285,8,400037.296909,0.699997
100000002,1096615,15624776,15624776,8,400581.963116,0
100000003,1096625,29534865,29534865,6,37842.379332,0
100000004,1097050,28056659,28056659,6,102634.954275,0
100000005,1097050,27343464,27343464,2,98200.046125,0
100000006,1097050,25665510,25665510,5,103575.406525,0
100000007,1097050,23561450,23561450,5,113974.527667,0.599998
100000009,1097310,12650897,12650897,5,929032.590463,6.600006
100000010,1097310,13395462,13395462,5,912367.716312,0
```
## sc10
Create a tif file with only the microbasins where sites overlap

## sc11

Script to extract the value **at point** of the environmental variable of interest.

Only the value at point (and not statistics) since the resolution of the environmental layer is bigger than the total extention of the microbasin

![screen02](/assets/screen02.png)

Variables:

- **Climate** (from TERRACLIMATE, 4 km) {1958..2019 - Monthly}
  - Actual Evapotranspiration (aet)
  - Precipitation (ppt)
  - Runoff (q)
  - Maximum temperature (tmax)
  - Minimum temperature (tmin)
- **NH4** input (55 km) {1961..2010 - Monthly}
- **NO3** input (55 km) {1961..2010 - Monthly}
- **Irrigated Areas** (1 km)

Runs fast even though _for loops_ are used. Could improve using e.g. ``xargs``

```sh
for VARTERRA in aet ppt q tmax tmin ; do

  awk 'BEGIN{OFS=","; FPAT = "([^,]*)|(\"[^\"]*\")"} {print $1, $4, $5, $8, $9}' $DIR/BenthicEU.csv  >  $OUTDIR/TERRA_$VARTERRA.csv

    for YEAR in {1958..2019} ; do

    echo "Calculating $VARTERRA ---- year $YEAR"

          for MES in {01..12} ; do

                  paste -d "," $OUTDIR/TERRA_${VARTERRA}.csv  \
                  <(printf "%s\n" ${VARTERRA}_${YEAR}_${MES} $(awk -F, 'FNR > 1 {print $2, $3}' $OUTDIR/TERRA_${VARTERRA}.csv | gdallocationinfo -valonly -geoloc  ${TERRA}/${VARTERRA}/${VARTERRA}_${YEAR}_${MES}.tif)) \
                  > $OUTDIR/TERRA_${VARTERRA}_cp.csv

                  mv $OUTDIR/TERRA_${VARTERRA}_cp.csv $OUTDIR/TERRA_${VARTERRA}.csv
          done

    done

done
```
==OUTPUT==
|Size| File | Dimension|
|----------|:-------------:|------:|
|90K|GIA.csv| 1840 * 6
|8,3M |NITRO_NH4.csv| 1840 * 605
|8,3M |NITRO_NO3.csv| 1840 * 605
|4,0M |TERRA_aet.csv| 1840 * 749
|4,3M |TERRA_ppt.csv| 1840 * 749
|3,3M |TERRA_q.csv|1840 * 749
|5,4M |TERRA_tmax.csv| 1840 * 749
|5,4M |TERRA_tmin.csv| 1840 * 749

Example of Irrigated areas:

```sh
cat terraN/GIA.csv | head

Site_ID,Longitude_X,Latitude_Y,MacrobasinID,MicrobasinID,irrigated
100000001,5.294382,45.829523,1096615,15625285,0
100000002,5.299435,45.8323815,1096615,15624776,0
100000003,1.918195639,50.30448305,1096625,29534865,0
100000004,2.513745757,49.9332428,1097050,28056659,0
100000005,2.385456242,49.79422815,1097050,27343464,0
100000006,2.169124882,49.71432717,1097050,25665510,0
100000007,2.016358357,49.74211763,1097050,23561450,0
100000009,7.232714668,47.74561836,1097310,12650897,0
100000010,7.264966594,47.82728771,1097310,13395462,0
```
Values of the irrigated column:

```sh
awk -F, 'FNR > 1 {print $6}' terraN/GIA.csv | sort | uniq

0
1
3
```

Example of NH4:

```sh
awk -F, '{print$1,$2,$3,$4,$5,$6,$7,$8,$9,$10}' terraN/NITRO_NH4.csv | head

Site_ID Longitude_X Latitude_Y MacrobasinID MicrobasinID NH4_1961_01 NH4_1961_02 NH4_1961_03 NH4_1961_04 NH4_1961_05
100000001 5.294382 45.829523 1096615 15625285 -9999 -9999 6.54742813110352 -9999 2.8060405254364
100000002 5.299435 45.8323815 1096615 15624776 -9999 -9999 6.54742813110352 -9999 2.8060405254364
100000003 1.918195639 50.30448305 1096625 29534865 -9999 -9999 6.59218263626099 2.82522106170654 -9999
100000004 2.513745757 49.9332428 1097050 28056659 -9999 -9999 7.68574666976929 3.29389142990112 -9999
100000005 2.385456242 49.79422815 1097050 27343464 -9999 -9999 6.61846399307251 2.83648467063904 -9999
100000006 2.169124882 49.71432717 1097050 25665510 -9999 -9999 6.61846399307251 2.83648467063904 -9999
100000007 2.016358357 49.74211763 1097050 23561450 -9999 -9999 6.61846399307251 2.83648467063904 -9999
100000009 7.232714668 47.74561836 1097310 12650897 -9999 -9999 4.66617488861084 -9999 1.99978923797607
100000010 7.264966594 47.82728771 1097310 13395462 -9999 -9999 4.66617488861084 -9999 1.99978923797607
```

Example of TERRA evapotranspiration:

```sh
Site_ID Longitude_X Latitude_Y MacrobasinID MicrobasinID aet_1958_01 aet_1958_02 aet_1958_03 aet_1958_04 aet_1958_05
100000001 5.294382 45.829523 1096615 15625285 19 32 57 67 103
100000002 5.299435 45.8323815 1096615 15624776 19 32 57 67 103
100000003 1.918195639 50.30448305 1096625 29534865 17 27 35 49 73
100000004 2.513745757 49.9332428 1097050 28056659 17 27 34 52 73
100000005 2.385456242 49.79422815 1097050 27343464 18 28 35 53 72
100000006 2.169124882 49.71432717 1097050 25665510 18 27 36 55 75
100000007 2.016358357 49.74211763 1097050 23561450 17 27 36 55 77
100000009 7.232714668 47.74561836 1097310 12650897 9 28 34 54 86
100000010 7.264966594 47.82728771 1097310 13395462 11 30 35 52 81
```

**NOTE:** Values for all terra climate variables are scaled!

## sc12

Script to calculate the proportion of different land cover types in each microbasin

Land cover based on the Consistent global land cover maps ESA (1992 - 2018) (250*250 meters pixel resolution)

Categories:
https://datastore.copernicus-climate.eu/documents/satellite-land-cover/D3.3.12-v1.2_PUGS_ICDR_LC_v2.1.x_PRODUCTS_v1.2.pdf

```sh
cat esa_categories.txt

10	cropland, rainfed	10	11	12
20	cropland, irrigated or post-flooding	20
30	Mosaic cropland (>50%) / natural vegetation (tree, shrub, herbaceous cover) (<50%)	30
40	Mosaic natural vegetation (tree, shrub, herbaceous cover) (>50%) / cropland (<50%)	40
50	Tree cover, broadleaved, evergreen, closed to open (>15%)	50
60	Tree cover, broadleaved, deciduous, closed to open (>15%)	60 	61	62
70	Tree cover, needleleaved, evergreen, closed to open (>15%)	70	71	72
80	Tree cover, needleleaved, deciduous, closed to open (>15%)	80	81	82
90	Tree cover, mixed leaf type (broadleaved and needleleaved)	90
100	Mosaic tree and shrub (>50%) / herbaceous cover (<50%)	100
110	Mosaic herbaceous cover (>50%) / tree and shrub (<50%)	110
120	Shrubland	120	121	122
130	Grassland	130
140	Lichens and mosses	140
150	Sparse vegetation (tree, shrub, herbaceous cover) (<15%)	150	151	152	153
160	Tree cover, flooded, fresh or brackish water	160
170	Tree cover, flooded, saline water	170
180	Shrub or herbaceous cover, flooded, fresh/saline/brackish water	180
190	Urban areas	190
200	Bare areas	200	201	202
210	Water bodies	210
220	Permanent snow and ice	220
```
Calculation done by reclassifying each land cover (1 and 0) and then dividing how many pixels in each category in each microbasin by the total number of pixel in each microbasin

```sh
r.reclass --o input=esalc output=esalc_recl_${YEAR}_${CAT} rules=$TEMP/reclass_esa_${YEAR}_${CAT}.txt

r.univar -t map=esalc_recl_${YEAR}_${CAT} zones=micb separator=comma | awk -F, 'FNR > 1 {print $1, $3+$4, $13, $13/($3+$4)}' > $TEMP/esa_stats/stats_esa_${YEAR}_${CAT}.txt
```


## sc13

Script to join temporal files

The script, in the second section, creates the final file where each Site is assigned the values of its corresponding microbasin.

==OUTPUT==
4,5M  stats_ESALC_complete.csv

Output table has 1840 rows and 598 columns (27 years * 22 categories)

Example:

```sh
cat ESALC/stats_ESALC_complete.csv | awk -F, '{print $1,$2,$3,$4,$6,$578}' | head

Site_ID MacrobasinID MicrobasinID MicrobasinID cat10_1992 cat10_2018
100000001 1096615 15625285 15625285 0.421053 0.421053
100000002 1096615 15624776 15624776 0.705882 0.705882
100000003 1096625 29534865 29534865 0.506667 0.32
100000004 1097050 28056659 28056659 1 0.916667
100000005 1097050 27343464 27343464 0.125 0.125
100000006 1097050 25665510 25665510 0.722222 0.722222
100000007 1097050 23561450 23561450 0.607143 0.607143
100000009 1097310 12650897 12650897 0.496732 0.424837
100000010 1097310 13395462 13395462 0.472727 0.436364
```

## sc14

Script to pre-process dam data:

GRAND v.1.3 (2019)
1958-2017
http://globaldamwatch.org/data/#core_global

- Clip to region of interest

```sh
ogr2ogr $OUTDIR/dams_roi_all.gpkg $DAMP -clipsrc $ROI -clipsrclayer benthicEU
```

- Add information of macro and microbasins (ID)

```sh
ogrinfo $OUTDIR/dams_roi_all.gpkg -sql "ALTER TABLE Grand_Dams ADD COLUMN MacrobasinID INTEGER"
ogrinfo $OUTDIR/dams_roi_all.gpkg -sql "ALTER TABLE Grand_Dams ADD COLUMN MicrobasinID INTEGER"

BBID=$(ogrinfo $OUTDIR/dams_roi_all.gpkg -al | awk -F "[()]" '/POINT/ {print $2}' | gdallocationinfo -valonly -geoloc  $MACROB)
MMID=$(ogrinfo $OUTDIR/dams_roi_all.gpkg -al | awk -F "[()]" '/POINT/ {print $2}' | gdallocationinfo -valonly -geoloc  $MICROB)
FFID=$(ogrinfo $OUTDIR/dams_roi_all.gpkg -al | awk -F":"  '/OGRFeature/{print $2}')
MAXNUM=$(ogrinfo $OUTDIR/dams_roi_all.gpkg -al -so | awk '/Feature Count/ {print $3}')

for i in $(seq 1 $MAXNUM); do
  echo $i
  echo .....
  macroid=$(printf "%s\n" $BBID | head -n $i | tail -n 1)
  microid=$(printf "%s\n" $MMID | head -n $i | tail -n 1)
  fidid=$(printf "%s\n" $FFID | head -n $i | tail -n 1)
  ogrinfo $OUTDIR/dams_roi_all.gpkg -dialect SQLite -sql "UPDATE Grand_Dams SET MacrobasinID =  $macroid WHERE fid = $fidid"
  ogrinfo $OUTDIR/dams_roi_all.gpkg -dialect SQLite -sql "UPDATE Grand_Dams SET MicrobasinID =  $microid WHERE fid = $fidid"
  echo ....
done

```

- Extract only dams from macrobasins where Sites are available
```sh
LISTMC=$(cat $DIR/BenthicEU.csv | awk 'BEGIN{FPAT = "([^,]*)|(\"[^\"]*\")"} FNR > 1 {print $8}'  | sort | uniq | awk '{print}' ORS=','  | sed 's/,*$//g')

ogr2ogr $OUTDIR/dams_roi.gpkg $OUTDIR/dams_roi_all.gpkg -nln dams_benthic_EU -sql "SELECT * FROM Grand_Dams WHERE MacrobasinID IN ($LISTMC)"
```
A total of **609** dam and reservoirs remaining.
Dams overlap over 51 macrobasins.

![screen07](/assets/screen07.png)
![screen08](/assets/screen08.png)

## sc15

Script to snap the dams to the stream network.

**The issue**: distance and microbasin based approaches snapping to the wrong stream!

**The solution**: stream network using only streams with strahler order > 4

```sh
v.in.ogr  --o input=$DIR/basins/basin_${ID}/bid_${ID}_stre_order.gpkg layer=orderV_bid${ID} output=streams_${ID} type=line key=stream where="strahler > 4"
```

![screen09](/assets/screen09.png)


## sc16

Script to join temporal files (per macrobasin)

## sc17
Script to calculate distance and influence of Dams on Sites

**The issue**:
![screen10](/assets/screen10.png)

**The rule**: if elevation of dam is greater than elevation of Site AND accumulation of dam is less than accumulation of Site, then the dam has an influence on Site

```sh
v.report -c map=occurrrence_to_dams layer=1 option=length units=kilometers | awk -F"|" 'BEGIN{OFS=",";} {
if ($5 > $8 && $6 < $9)
	print $1, $4, $5, $6, $8, $9, $10, "Connected";
else
	print $1, $4, $5, $6, $8, $9, $10, "NotConnected";
}' > $TEMP/damOut/dist_to_DAM_${ID}_${PN}.csv
```

## sc18_env_DAM_join

Script to join tables of previous script.

==OUTPUT==   (_Still running!!!!_)
2,8M dist_to_DAMs.csv

```sh
cat tmp/dist_to_DAMs.csv | head

Site_ID,dam_ID,dam_ELEV,dam_ACCU,Site_ELEV,Site_ACCU,DistanceKm,Influence
103000576,95,104.200004577637,171.819183349609,6.20000028610229,235.286651611328,17.1710917507765,Connected
103000669,95,104.200004577637,171.819183349609,13.3000001907349,226.042541503906,13.9621338185456,Connected
103000704,95,104.200004577637,171.819183349609,107.300003051758,0.0547920987010002,8.41052224237338,NotConnected
103000705,95,104.200004577637,171.819183349609,18.8999996185303,217.688125610352,12.8067186707657,Connected
103000706,95,104.200004577637,171.819183349609,65,0.528247356414795,21.7599648209977,NotConnected
103000707,95,104.200004577637,171.819183349609,2.90000009536743,242.698104858398,18.5610559509487,Connected
103000708,95,104.200004577637,171.819183349609,1.70000004768372,250.715209960938,20.5499203272976,Connected
109000377,521,1.20000004768372,162.912322998047,31.5,49.0289077758789,18.8002795322202,NotConnected
109000380,521,1.20000004768372,162.912322998047,17.2000007629395,107.771499633789,17.1422702910431,NotConnected
```
