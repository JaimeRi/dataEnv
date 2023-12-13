#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc24_CompUnit_flow1k.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc24_CompUnit_flow1k.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc24_CompUnit_flow1k.sh   jg2657@grace1.hpc.yale.edu:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash

source ~/bin/grass78m

export DIR=$1
export FLOW=$2
export CU=$3
export DATFOLDER=$4


grass78  -f -text --tmp-location  -c $DATFOLDER/CompUnit_msk/msk_${CU}_msk.tif  <<'EOF'

#  Read files with subcatchments
r.in.gdal --o \
input=$DATFOLDER/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_${CU}.tif \
output=micb 

# Read file of flow 1k
r.in.gdal --o -r input=$FLOW output=flow

echo "subcID min max range mean sd" > $DIR/out/stats_${CU}_flow1k.txt

# Calculate statistics
r.univar -t map=flow zones=micb separator=space | \
awk 'NR > 1 {print $1, $4, $5, $6, $7, $9}' \
| awk '{gsub("-nan", "na"); print $0}' \
>> $DIR/out/stats_${CU}_flow1k.txt

EOF

exit
