
export DIR=/home/jg2657/project/BenthicEU
export TMP=/home/jg2657/scratch60

echo "site year cat_10 cat_20 cat_30 cat_40 cat_50 cat_60 cat_70 cat_80 cat_90 cat_100 cat_110 cat_120 cat_130 cat_140 cat_150 cat_160 cat_170 cat_180 cat_190 cat_200 cat_210 cat_220" > $DIR/landcover_prop.txt

farray=($(find $DIR/esa_txt -name 'esa*.txt'))

time for file in "${farray[@]}"; do

    S=$(echo $file | awk -F[_.] '{print $4}')
    Y=$(echo $file | awk -F[_.] '{print $5}')

    echo $S > $TMP/linea_tmp.txt
    echo $Y >> $TMP/linea_tmp.txt

    for i in $(seq 10 10 220); do
       prop=$(awk -v cat=$i '$1 == cat {print $3}' $file)
       [ -z "$prop" ] && prop=0
       echo $prop >> $TMP/linea_tmp.txt
    done

    xargs < $TMP/linea_tmp.txt >> $DIR/landcover_prop2.txt

done

rclone copy landcover_prop2.txt YaleGDrive:BenthicEllen

100000312
107000190
109000173
109000292
117000024
