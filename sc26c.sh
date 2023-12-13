#!/bin/bash

#SBATCH -p day
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc26c.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc26c.sh.%A_%a.err

#  scp /home/jaime/Code/environmental-data-extraction/sc26c.sh  grace:/home/jg2657/project/code/environmental-data-extraction
TMP=$1
ref=$2
rm -rf $TMP/terra_${ref}
