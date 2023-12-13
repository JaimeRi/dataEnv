#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc23_CompUnit_SOIL.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc23_CompUnit_SOIL.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc23_CompUnit_SOIL.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash

source ~/bin/grass78m

export SoilVar=('BLDFIE' 'ACDWRB' 'AWCtS' 'BDRICM' 'BDRLOG' 'CECSOL' 'CLYPPT' 'CRFVOL' 'HISTPR' 'ORCDRC' 'PHIHOX' 'SLGWRB' 'SLTPPT' 'SNDPPT' 'TEXMHT' 'WWP')

export DIR=$1

export CU=$2

export DATFOLDER=$3

export SOIL=${4}

export sv=${SoilVar[$SLURM_ARRAY_TASK_ID]}

grass78  -f -text --tmp-location  -c $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif  << 'EOF'

    #  Read files with subcatchments
    r.in.gdal --o \
    input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
    output=micb 

    if [ $sv = 'ACDWRB' ] || [ $sv = 'BDRICM' ] || [ $sv = 'BDRLOG' ] || [ $sv = 'HISTPR' ] || [ $sv = 'SLGWRB' ]; then
        srast=$(find $SOIL/$sv -name '*tif')
        r.in.gdal --o -r input=$srast output=$sv
        
        echo "subcID min max range mean sd" > $DIR/out/stats_${CU}_soil_${sv}.txt  

        r.univar -t map=$sv zones=micb separator=space | \
        awk 'NR > 1 {print $1, $4, $5, $6, $7, $9}' \
        | awk '{gsub("-nan", "na"); print $0}' \
        >> $DIR/out/stats_${CU}_soil_${sv}.txt
    else
        r.in.gdal --o -r input=$SOIL/${sv}_WeAv/${sv}_WeigAver.tif output=$sv
        
        echo "subcID min max range mean sd" > $DIR/out/stats_${CU}_soil_${sv}.txt  
        
        r.univar -t map=$sv zones=micb separator=space | \
        awk 'NR > 1 {print $1, $4, $5, $6, $7, $9}' \
        | awk '{gsub("-nan", "na"); print $0}' \
        >> $DIR/out/stats_${CU}_soil_${sv}.txt
    fi
EOF 


exit

