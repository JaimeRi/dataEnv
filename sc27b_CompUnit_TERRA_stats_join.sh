#!/bin/bash

#SBATCH -p day
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc27b_CompUnit_TERRA_stats_join.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc27b_CompUnit_TERRA_stats_join.sh.%A_%a.err
#SBATCH --mem-per-cpu=10000M

#  scp /home/jaime/Code/environmental-data-extraction/sc27b_CompUnit_TERRA_stats_join.sh  grace:/home/jg2657/project/code/environmental-data-extraction

# srun --pty -t 6:00:00 --mem=20G  -p interactive bash

export DIR=$1
export TMP=$2
export ref=$3

export varterra=('aet' 'q' 'ppt' 'tmax' 'tmin')

export terra=${varterra[$SLURM_ARRAY_TASK_ID]}

#time for terra in aet q ppt tmax tmin
#do
	## JOIN tables 
	terrastats=( $(find $TMP/ -name "stats_terra_${ref}_${terra}*.txt") )
	# sort the array
	IFS=$'\n' sorted=($(sort <<<"${terrastats[*]}"))
	unset IFS
	# create the table
	paste -d' ' \
	    <(awk '{print $1}' $DIR/out/stats_${ref}_BasinsIDs.txt) \
	    ${sorted[@]} > $DIR/out/stats_${ref}_TERRA_${terra}_YearAver.txt
#done

