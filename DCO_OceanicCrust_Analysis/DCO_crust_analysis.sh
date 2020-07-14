#!/bin/bash

# FILENAME: DCO_crust_analysis.sh
# DESCRIPTION: Produces time-dependent grid files depicting CO2 levels in the
#              upper crust as well as summary statistics of the subducting crust
#              age and CO2 concentration in the upper crust.
# AUTHORS: Sebastiano Doss, Jodie Pall, Sabin Zahirovic
# START DATE: 15th of May 2016
# LAST EDIT: 27th of March 2020

# Instructions

# In order to run these workflows, GMT 6, Python 2.7 along with the python
# module pyGPlates (rev. 12 or newer) must be installed on your system. In terminal
# the curent directory should be changed to the folder where the DCO_crust_analysis.sh
# is located. To run the analysis, the workflow folder must include:
# the DCO_crust_analysis.sh script; the plate model (including all geometry (gpml) and
# rotation (rot) files); a folder containing all relevant time-dependent age grids;
# a folder containing all relevant time-dependent sediment thickness grids;
# and the 'scripts' folder containing all other dependencies.

# To commence the analysis in terminal,
# call the DCO_crust_analysis script using the following format:

# ./DCO_crust_analysis.sh -r “RotationFiles” -m "FeatureFiles" -t 230-0 -a "AgeGridFolderDiretory" -s "SedimentGridFolderDirectory"

# Where the flags indicate the following:
#   -r    rotation files (rot)
#   -m    model geometry files (gpml)
#   -t    time window from oldest time to youngest (i.e. 230-200)
#		  (if a single value is provided, it will assume a time window
#		  from the specified time to 0 Ma)
#   -a    folder directory containing only the age grid files (grd)
#   -s    folder directory containing only the sediment thickness grid files (grd)

# If there are multiple feature files or rotation files following the argument
# flag, separate the files with a space and enclose them with a double quotes
# I.e. -r “r1.rot r2.rot r3.rot”

# The analysis will produce a folder named CO2_Grid_Files containing all
# time dependent .grd files at each timestep, depicting predicted CO2 concentration in the upper crust.
# It will also produce a Results folder containing two .dat files (sz_crust_age_data.dat
# and sz_crust_co2_data.dat), containing the statistics of the subducting crust age and
# co2 levels in the upper crust. A folder called PlateBoundaryFeatures will be produced,
# containing resolved plate boundaries (subduction, MOR and transform) at each time step.

# For more information on this project's methodologies, refer to the blog on the EarthByte Website:
# http://www.earthbyte.org/category/dco-project/dco-blog/

############################################################################################################################

# Main function called to initialise script
main(){

# Empty Input files reqired: rotation file, topology file, and gpml feature collection files.
local rotfile=""
local topologies=""
local raw_time=""
local to_age=0
local from_age=0
local age_grid_direc=""
local sed_grid_direc=""
local outfilename_prefix="Crust_Analysis_" # Default name unless specified by user
local age_grid_prefix=""
local sed_grid_prefix=""

# Parse Input Arguments
while getopts "r:t:m:n:a:s:" opt; do
case $opt in
r)
rotfile="$OPTARG"
;;

t)
raw_time="$OPTARG"
# Partitions 'from age' and 'to age' from raw input
if [[ $raw_time =~ ^[0-9]+-[0-9]+$ ]]
then
from_age=$(echo $raw_time | cut -f1 -d-)
to_age=$(echo $raw_time | cut -f2 -d-)
elif [[ $raw_time =~ ^[0-9]+$ ]]
then
from_age=$raw_time
else
from_age=""
fi
;;

m)
topologies="$OPTARG"
;;

n)
outfilename_prefix="$OPTARG"
outfilename_prefix="${outfilename_prefix}_"

;;

a)
age_grid_direc="$OPTARG"
age_grid_prefix=$(find_grid_prefix "$age_grid_direc")
;;

s)
sed_grid_direc="$OPTARG"
sed_grid_prefix=$(find_grid_prefix "$sed_grid_direc")
;;

\?)
echo >&2 "Invalid option: -$OPTARG"
exit 1
;;

:)
echo >&2 "Option -$OPTARG requires an argument."
exit 1
;;
esac
done

shift $((OPTIND-1))

# Function call validate input arguments
validate_arguments "$rotfile" "$topologies" "$to_age" "$from_age" "$age_grid_direc" "$sed_grid_direc"

# Function call prompts user with inputs before analysis
prompt_inputs

# Excute analysis function
run_analysis "$rotfile" "$topologies" "$to_age" "$from_age" "$outfilename_prefix" "$age_grid_direc" "$age_grid_prefix" \
"$sed_grid_direc" "$sed_grid_prefix"

echo >&2 "Analysis Complete"

exit 1

}

# Function to find the prefix of the age grid files
find_grid_prefix(){

local grid_direc=$1
local grid_prefix=''

for entry in "$grid_direc"/*.nc # Change .nc to .grd in case dealing with older netcdf files
do

grid_suffix=$( echo $entry | rev | awk -F/ '{ print $1 }' | awk -F'[-_]' '{print $1}' | rev ) # SZ2020

# grid_prefix=$(echo $entry | sed 's/.*\/\([^0-9]*\).*/\1/')
grid_prefix=$( echo $entry | rev | awk -F/ '{ print $1 }' | rev | sed 's/'${grid_suffix}'//g' )  # SZ2020

break
done

echo $grid_prefix

}

# Test user input variables before analysis
validate_arguments(){

local rotfile=$1
local topologies=$2
local to_age=$3
local from_age=$4
local age_grid_direc=$5
local sed_grid_direc=$6

# Index
local i=0

if [[ -z $from_age ]]
then
echo >&2 "missing or invalid time format"
exit 1
fi

if (( "$from_age" < "$to_age" )); then
echo >&2 "fromAge cannot be less than toAge"
exit 1
fi

if [[ -z $rotfile ]]; then
echo >&2 "Analysis cannot continue without rotfile(s)"
exit 1
fi

if [[ -z $topologies ]]; then
echo >&2 "Analysis cannot continue without topologies file(s)"
exit 1
fi

local rot_list=($rotfile)
for i in "${rot_list[@]}"
do
if [[ ! -f $i ]] || [[ $i != *.rot ]]; then
echo >&2 "$i: rotation file invalid type or does not exist"
exit 1
fi
done

local topologies_list=($topologies)
for i in "${topologies_list[@]}"
do
if [[ ! -f $i ]] || [[ $i != *.gpml ]] && [[ $i != *.shp ]]; then
echo >&2 "$i: topologies file invalid type or does not exist"
exit 1
fi
done

if  [ -z "$age_grid_direc" ] || [ ! -d "$age_grid_direc" ]; then
echo >&2 "$age_grid_direc: does not exist"
echo >&2 "***** WARNING ***** Crust Age Analysis will be unsuccessful without age grid files!"
echo >&2 "***** WARNING ***** Crust CO2 Analysis will be unsuccessful without age grid files!"
echo >&2 "Press return to confirm or ctrl+z to abort"
read input_variable
fi

if [ -z "$sed_grid_direc" ] || [ ! -d "$sed_grid_direc" ]; then
echo >&2 "$sed_grid_direc: does not exist"
echo >&2 "***** WARNING ***** Crust Sediment Thickness Analysis will be unsuccessful without sediment grid files!"
echo >&2 "Press return to confirm or ctrl+z to abort"
read input_variable
fi

}


# Present user with input files and variables
prompt_inputs(){

echo -e >&2 "\n\n ---------------- Loading Arguments ----------------   \n"
echo >&2 "    Rotation File(s):             $rotfile"
echo >&2 "    Topology File(s):             $topologies"
echo >&2 "    From Age:                     $from_age"
echo >&2 "    To Age:                       $to_age"
echo >&2 "    Age Grids:                    $age_grid_direc"
echo >&2 "    Sediment Thickness Grids:     $sed_grid_direc"

sleep 2
echo -e >&2 "\n\n ---------------- Start Analysis ----------------    \n\n"
sleep 2

}

# Function called to run all analyses
run_analysis(){


# Function arguments
local rotfile=$1
local topologies=$2
local age=$3
local from_age=$4
local outfilename_prefix=$5
local age_grid_direc=$6
local age_grid_prefix=$7
local sed_grid_direc=$8
local sed_grid_prefix=$9

# Helper variables
local outfile_format="gmt"
local sz_layer=''
local age_grid_file=''
local co2_grid_file=''

# Raw dat file containing grid values sampled along subduction zones
local raw_dat_crust_age=''
local raw_dat_crust_co2=''
local raw_dat_crust_sed=''

# Final result statistics files
local global_crust_age=global_crust_age_data.dat
local global_crust_co2=global_crust_co2_data.dat
local global_crust_sed=global_crust_sed_data.dat
rm $global_crust_age $global_crust_co2 $global_crust_sed
echo "Age" "Mean" "Stdev" "Median" "Max" "Min" "Sample_Size" >> $global_crust_age
echo "Age" "Mean" "Stdev" "Median" "Max" "Min" "Sample_Size" >> $global_crust_co2
echo "Age" "Mean" "Stdev" "Median" "Max" "Min" "Sample_Size" >> $global_crust_sed


# Create folder to store CO2 grids
if [ ! -d "CO2_Grid_Files" ]; then
mkdir "CO2_Grid_Files"
fi

# Creates folder to store the results (dat files)
if [ ! -d "Results" ]; then
mkdir "Results"
fi

# Creates folder to store the plate boundary features produced by GPlates resolved topoolgies
if [ ! -d "PlateBoundaryFeatures" ]; then
mkdir "PlateBoundaryFeatures"
fi

# Iterates through each 1 m.yr timestep conducting subduction zone analyses
while (( $age <= from_age ))
do

echo >&2 "Time Step: $age"

age_grid_file="${age_grid_direc}/${age_grid_prefix}${age}.nc"
sed_grid_file="${sed_grid_direc}/${sed_grid_prefix}${age}.nc"

# Use pygplates to export resolved topologies and remove duplicate segments
python $directory/scripts/resolve_topologies_V.2.py -r ${rotfile} -m $topologies -t ${age} -e ${outfile_format} \
-- ${outfilename_prefix}

sz_layer=${outfilename_prefix}subduction_boundaries_${age}.00Ma.gmt

# Analysis of crustal age as it intersects with subduction zones
raw_dat_crust_age=$(samples_grid_with_sz $age_grid_file $sz_layer)
calculate_stats $raw_dat_crust_age $global_crust_age $age

# Analysis of CO2 content in the upper crust as it intersects with subduction zones
co2_grid_file=$(build_co2_grid $age_grid_file $age)
raw_dat_crust_co2=$(samples_grid_with_sz $co2_grid_file $sz_layer)
calculate_stats $raw_dat_crust_co2 $global_crust_co2 $age

# Analysis of seafloor sediment thickness as it intesects with subduction zones
raw_dat_crust_sed=$(samples_grid_with_sz $sed_grid_file $sz_layer)
calculate_stats $raw_dat_crust_sed $global_crust_sed $age

# Move all resolved feature files at each timestep to a new age-stamped folder within the PlateBoundaryFeatures folder
mkdir -p PlateBoundaryFeatures/$age
mv *.gmt *.xml PlateBoundaryFeatures/$age

# Increment age
age=$(( $age + 1 ))
done

# Remove legacy files
rm $raw_dat_crust_age $raw_dat_crust_co2 $raw_dat_crust_sed 'gmt.history'

# Move final statistics results to Results folder
mv *.dat Results
}

# Recieves the raw dat file of the sample distribution and calculates various general stats
calculate_stats(){

local raw_results=$1
local global_stats=$2
local age=$3

local mean=$(awk 'BEGIN {count=0;sum = 0} {if ($1 != "NaN") {sum=sum+$1; count++;}} \
END { average=sum/count; print average; }' $raw_results)

local median=$(sort -g $raw_results | awk \
'{a[i++]=$1;} END { x=int((i+1)/2); if (x < (i+1)/2) print (a[x-1]+a[x])/2; else print a[x-1]; }')

local stdev=$(awk -v average="$average" 'BEGIN {count=0;sum_square_dif = 0} \
{if ($1 != "NaN") {sum_square_dif = sum_square_dif + ($1-average)^2; count++;}} \
END { stdev=sqrt(sum_square_dif/count); print stdev; }' $raw_results)

local max=$(awk 'BEGIN {max=0} {if($1 > max) max= $1} END {print max}' $raw_results)

local min=$(awk 'NR==1 {min=$1} {if($1 < min) min= $1} END {print min}' $raw_results)

local samplesize=$(awk 'END{print NR}' $raw_results)

echo $age $mean $stdev $median $max $min $samplesize >> $global_stats

}


# Function recieves grid file and subduction zone layer of a given age. Using gmt grdtrack the grid values are
# sampled along the subduction zone layer geometry at 10 km intervals. The results are extracted from the grdtrack
# output and listed in single column of a dat file.
samples_grid_with_sz(){

local grid_file=$1
local sz_layer=$2

local prof_spacing=10
local prof_interval=1
local prof_length=2k

local grid_file_xyz="tmp_grid.xyz"
local raw_dat="raw_dat.dat"

gmt grdtrack $sz_layer -G${grid_file} -C${prof_length}/${prof_interval}/${prof_spacing} > $grid_file_xyz -V

awk 'BEGIN {count=0; prevlatlong=0;} {if(($1 == ">")&&(prevlatlong!=$7)) {count = 1; prevlatlong=$7;}
if((count==3)&&($5!="NaN")&&($5>0)){print $5; count=0;} if(count>=1){count++;}}' $grid_file_xyz > $raw_dat

rm $grid_file_xyz

echo $raw_dat

}

# Computes oceanic crustal CO2 content of subducting oceanic crust.
# Function receives agegrid file (grd) at a given timestep.
# Converts age to crustal CO2 content using linear log-age-CO2 relationship from Jarrard (2003, G-cubed)
# # CO2 (wt %) = -1.55 + 2.49 * log(age)
build_co2_grid(){

local age_grid_file=$1
local age=$2
local tmp_co2_grid="tmp_co2_grid.nc"

local prof_spacing=10
local prof_interval=1
local prof_length=2k

local frame=-180/180/-90/90
local grdint=0.1/0.1

local raw_dat_crust_co2="raw_dat_crust_co2.dat"
local co2_grid_file_xyz="tmp_co2_grid.xyz"


echo -e >&2 "\n\t   Converting $agegrd to $tmp_co2_grid\n"

gmt grdmath -V ${age_grid_file} LOG10 2.49 MUL -1.55 ADD = tmp.grd

# Remove all negative values
gmt grd2xyz tmp.grd -V >tmp1.xyz
awk '{ if ($3 < 0 ) $3 = 0
print ($1, $2, $3)}' tmp1.xyz >tmp2.xyz

gmt xyz2grd tmp2.xyz -R${frame} -I${grdint} -G${tmp_co2_grid} -fg -V

mv -f $tmp_co2_grid "CO2_Grid_Files/co2_grid_file_${age}.nc"

rm tmp.grd tmp?.xyz $co2_grid_file_xyz

echo "CO2_Grid_Files/co2_grid_file_${age}.nc"

}

# Global Variable
directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

####################### CALL MAIN #######################
main "$@"
