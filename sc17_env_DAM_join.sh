#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 00:10:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc17_env_DAM_join.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc17_env_DAM_join.sh.%A_%a.err
#SBATCH --mem-per-cpu=20000M

#  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/environmental-data-extraction/sc17_env_DAM_join.sh jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/scripts

# sbatch /home/jg2657/project/BenthicEU/scripts/sc17_env_DAM_join.sh

# srun --pty -t 6:00:00 --mem=20G  --x11 -p interactive bash
module purge
source ~/bin/gdal3

export DIR=$1

### Merge into one file all the snapped dams
ogrmerge.py -o $DIR/dam/dams_snap.gpkg  $(find $DIR/dam/basin* -name '*.gpkg') -f "GPKG" -single -nln DAMSsnap -overwrite_ds
#scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace1.hpc.yale.edu:/home/jg2657/project/BenthicEU/dam/dams_snap.gpkg  /home/jaime/data/benthicEU/dam

rm -r /home/jg2657/project/BenthicEU/dam/basin_*
