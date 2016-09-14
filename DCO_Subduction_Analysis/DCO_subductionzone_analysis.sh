
# FILENAME: DCO_subductionzone_analysis.sh
# DESCRIPTION: Produces global temporal results depicting total subduction zone lengths,
#              total subuduction zone length intersecting with carbonate platforms,
#              total continental arc subduction zones and percentage of total continental
#              arc subduction to oceanic subduction zones.
# AUTHORS: Sebastiano Doss, Jodie Pall
# START DATE: 29th of February 2016
# LAST EDIT: 14th of September 2016

# Instructions

# In order to run these workflows, GMT 5.2.1, Python 2.7 along with the python
# module pyGPlates (2016, rev. 12) must be installed on your system.In terminal
# the curent directory should be changed to the folder where the
# DCO_subductionzone_analysis.sh is located.
# To run the analysis, the workflow folder must include:
# The DCO_subductionzone_analysis.sh script; the plate model (including all geometry (gpml)
# and rotation (rot) files); feature collection (gpml or shp) depicting carbonate platform
# evolution through time; continental polygon feature collection (gpml or shp) depicting
# continent-ocean boundary evolution through time.
# To commence the analysis in terminal,
# call the DCO_subductionzone_analysis script using the following format:

# ./DCO_subductionzone_analysis.sh -r “RotationFiles” -m "FeatureFiles" -t 230-0 -c "CarbonateFile" -a "CotinentalOceanBoundFile"

# Where the flags indicate the following:
#   -r    rotation files (rot)
#   -m    model geometry files (gpml)
#   -t    time window from oldest time to youngest (i.e. 330-300)
#		  (if a single value is provided, it will assume a time window
#		  from the specified time to 0 Ma)
#   -c    files depicting carbonate platform activity or accumalation (gpml or shp)
#   -a    files depciting cotinental ocean boundaries (gpml or shp)

# If there are multiple feature files or rotation files following the argument
# flag, separate the files with a space and enclose them with a double quotes
# I.e. -r “r1.rot r2.rot r3.rot”

# The analysis will produce a folder named Results containing four dat files:
# global_continent_arc_percentage_data, global_sz_length_carbonate_data,
# global_sz_length_continentarc_data and global_sz_length_data.
# A folder called PlateBoundaryFeatures will be produced, containing resolved plate boundaries
# (subduction, MOR and transform) at each time step.

###################### !IMPORTANT! READ ME ######################

# The global variable 'gmt_developement_directory' below must be adjusted, before you commence this analysis.
# The varible must include the bin path of the latest gmt development build. If this is not adjusted appropriately
# the analysis on carboante platforms and continenal arc vs oceanic arc will produce incorrect results. Instructions
# in creating a developement build of gmt5 can be found here: http://gmt.soest.hawaii.edu/projects/gmt/wiki/BuildingGMT
# The reason for using the development build is because a bug was found in the tool grdtrack. The fix is implamented in
# the developement build, however on a whole it is unstable to use. Only the fixed tool grdtrack is called from the
# development build

# For more information on this project's methodologies, refer to the blog on the EarthByte Website:
# http://www.earthbyte.org/category/dco-project/dco-blog/

####################### Global Variables #######################
directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# For gmt_developement_directory make sure a '/' character proceedes the directory path
# I.e. /Users/sam/Documents/GMT_Dev/gmt5-dev/bin/
gmt_developement_directory="<Set GMT Developement Directory>"

# Main function called to initialise script
main(){

# Empty Input files reqired: rotation file, topology file, and gpml feature collection files.
local rotfile=""
local topologies=""
local carbonate=""
local continental_polygons=""
local raw_time=""
local to_age=0
local from_age=0
local outfilename_prefix="Subduction_Zones_Analysis_" # Default name unless specified by user

# Parse Input Arguments
while getopts "r:t:m:n:c:a:" opt; do
case $opt in
r)
rotfile="$OPTARG"
;;

t)
raw_time="$OPTARG"
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

c)
carbonate="$OPTARG"
;;

a)
continental_polygons="$OPTARG"
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
validate_arguments "$rotfile" "$topologies" "$to_age" "$from_age" "$carbonate" "$continental_polygons"

# Function call prompts user with inputs before analysis
prompt_inputs

# Excute analysis function
run_analysis "$rotfile" "$topologies" "$to_age" "$from_age" "$carbonate" "$continental_polygons" "$outfilename_prefix"

echo >&2 "Analysis Complete"

exit 1

}

# test user input variables before analysis
validate_arguments(){

local rotfile=$1
local topologies=$2
local to_age=$3
local from_age=$4
local carbonate=$5
local continental_polygons=$6

# index
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


if [[ -z $carbonate ]]; then
echo >&2 "$i: carbonate file invalid type or does not exist"
echo >&2 "***** WARNING ***** Carbonate Platform Subduction Zone Analysis will be unsuccessful! *****"
echo >&2 "Press return to confirm or ctrl+z to abort"
read input_variable
fi

local carbonate_list=($carbonate)
for i in "${carbonate_list[@]}"
do
if [[ ! -f $i ]] || [[ $i != *.gpml ]] && [[ $i != *.shp ]]; then
echo >&2 "$i: carbonate file invalid type or does not exist"
echo >&2 "***** WARNING ***** Carbonate Platform Subduction Zone Analysis will be unsuccessful! *****"
echo >&2 "Press return to confirm or ctrl+z to abort"
read input_variable
fi
done


if [[ -z $continental_polygons ]]; then
echo >&2 "$i: continental polygon file invalid type or does not exist"
echo >&2 "***** WARNING ***** Continental Arc Subduction Zone Analysis will be unsuccessful! *****"
echo >&2 "Press return to confirm or ctrl+z to abort"
read input_variable
fi

local continental_polygons_list=($continental_polygons)
for i in "${continental_polygons_list[@]}"
do
if [[ -z $continental_polygons ]] || [[ ! -f $i ]] || [[ $i != *.gpml ]] && [[ $i != *.shp ]]; then
echo >&2 "$i: continental polygon file invalid type or does not exist"
echo >&2 "***** WARNING ***** Continental Arc Subduction Zone Analysis will be unsuccessful! *****"
echo >&2 "Press return to confirm or ctrl+z to abort"
read input_variable
fi
done

# test name specified by user


}

# present user with input files and variables
prompt_inputs(){

echo >&2 -e "\n\n ---------------- Loading Arguments ----------------   \n"
echo >&2 "    Rotation File(s):             $rotfile"
echo >&2 "    Topology File(s):             $topologies"

if [[ ! -z $carbonate ]]; then
echo >&2 "    Carbonate File(s):            $carbonate"
fi

if [[ ! -z $continental_polygons ]]; then
echo >&2 "    Continental Polygon File(s):  $continental_polygons"
fi

echo >&2 "    From Age:                     $from_age"
echo >&2 "    To Age:                       $to_age"

sleep 2
echo -e >&2 "\n\n ---------------- Start Analysis ----------------    \n\n"
sleep 2

}

run_analysis(){

local rotfile=$1
local topologies=$2
local age=$3
local from_age=$4
local carbonate=$5
local continental_polygons=$6
local outfilename_prefix=$7

# Result variables
local sz_total_length_km=0
local sz_carbonate=0
local sz_length_con_arc=0
local con_arc_percent=0

# Result files
local global_sz_length=global_sz_length_data.dat
local global_sz_length_carbonate=global_sz_length_carbonate_data.dat
local global_sz_length_continentarc=global_sz_length_continentarc_data.dat
local global_continent_arc_percentage=global_continent_arc_percentage_data.dat

# Helper variables
local outfile_format="gmt"

# Clean files from prior run
rm $global_sz_length $global_sz_length_carbonate $global_sz_length_continentarc $global_continent_arc_percentage

# Create directory folders
if [ ! -d "Results" ]
then
mkdir "Results"
fi

if [ ! -d "PlateBoundaryFeatures" ]
then
mkdir "PlateBoundaryFeatures"
fi

# Iterate through each 1 myr timestep, conducting subduction zone analyses
while (( $age <= from_age ))
do

echo >&2 "Time Step: $age"

# Use pygplates to export resolved topologies and remove duplicate segments
python ${directory}/scripts/resolve_topologies_V.2.py -r ${rotfile} -m $topologies -t ${age} -e ${outfile_format} \
-- ${outfilename_prefix}

# Calculate total global subduction zone length (km)
sz_total_length_km=$(calculate_sz_length_total "$outfilename_prefix")

# Calculate total subduction zone length (km) intersecting with carbonate platforms
sz_carbonate=$(calculate_sz_length_carbonate "$rotfile" "$age" "$carbonate" "$outfilename_prefix")

# Calculate total subduction zone length (km) intersecting with continents
sz_length_con_arc=$(calculate_sz_length_continentArc "$rotfile" "$age" "$continental_polygons" "$outfilename_prefix")

# Calculate proportion of global subduction zones that are continental arcs opposed to intra-oceanic arcs
con_arc_percent=$(calculate_sz_percentage_continentArc $sz_length_con_arc $sz_total_length_km)


# Migrate all resolved feature files at each timestep to a new age-stamped folder
mkdir -p PlateBoundaryFeatures/$age
mv *.gmt *.xml PlateBoundaryFeatures/$age

# Append age and corresponding values calculated by the analysis functions to results files
echo $age $sz_total_length_km >> $global_sz_length
echo $age $sz_carbonate >> $global_sz_length_carbonate
echo $age $sz_length_con_arc >> $global_sz_length_continentarc
echo $age $con_arc_percent >> $global_continent_arc_percentage

# Increment age
age=$(( $age + 1 ))
done

mv *.dat Results

}

# Function used to calculate total global subduction zone lengths at a given timestep
calculate_sz_length_total(){

local outfilename_prefix=$1
local sz_total_length=sz_length.dat

# Use gmtconvert to split the subduction zone file into the individual SZ segments, using the multi-segment file delimiter
gmt gmtconvert -Dgmtconvert_segment_sz_%d.txt -V  ${outfilename_prefix}subduction_boundaries_${age}.00Ma.gmt


# The loop below measures the length (km) of individual subduction zone segments using mapproject
for sz_portion in `ls gmtconvert_segment_*.txt`
do
gmt mapproject -V -fg -Gk $sz_portion > sz_length.test
local sz_length_km=$( tail -1 sz_length.test | awk '{ print $3 }' )
echo >&2 "Subduction Zone segment length is $sz_length_km km"
echo $sz_portion $sz_length_km >> $sz_total_length
done

local sz_total_length_km=$( awk '{ sum+=$2 } END { print int(sum) }' $sz_total_length )
echo >&2 "Total subduction zone length is $sz_total_length_km km"

rm gmtconvert_segment_*.txt $sz_total_length sz_length.test

# return value
echo $sz_total_length_km

}

# Receives reconstructed feature in netCDF format (nc) and subduction zone geometry of left and right polarity
# Function calculates the distance in which a feature intersects a subduction zone area on the subducting side.
# The search distance from the subduction zone can be specified by adjusting the value of prof_length
find_sz_length_containing_feature(){

local feature_mask_grid=$1
local sz_left=$2
local sz_right=$3
local prof_spacing=$4
local prof_interval=$5
local prof_length=$6

# !Disclaimer! A bug has been found for grdtrack and has been fixed within an unstable development build.
# Here, grdtrack is called from a developement build
${gmt_developement_directory}gmt grdtrack $szLlayer -G${feature_mask_grid}  -nn+c \
-C${prof_length}/${prof_interval}/${prof_spacing} > feature_L_xprofiles.gmt -V

${gmt_developement_directory}gmt grdtrack $szRlayer -G${feature_mask_grid}   -nn+c \
-C${prof_length}/${prof_interval}/${prof_spacing} > feature_R_xprofiles.gmt -V

# Create one-sided cross-profile 'whiskers' in the direction of the down-going slab
awk '{ if ( $1 == ">") print $0 ; else if ($3 <= 0) print $0 }' feature_L_xprofiles.gmt > feature_L_halfxprofiles.gmt
awk '{ if ( $1 == ">") print $0 ; else if ($3 >= 0) print $0 }' feature_R_xprofiles.gmt > feature_R_halfxprofiles.gmt

# Identify and count cross-profiles that intersect with feature
local feature_total_L_intersect=$(awk \
'BEGIN {intersect_count=0;checkprofile=1;prevlatlong=0;} \
{if (($1 == ">") && (prevlatlong!=$7)) \
{checkprofile = 1;prevlatlong=$7;} \
if (( checkprofile==1 ) && ( $5==1 )) \
{intersect_count++; checkprofile=0;}} \
END { print intersect_count }' feature_L_halfxprofiles.gmt)

local feature_total_R_intersect=$(awk \
'BEGIN {intersect_count=0;checkprofile=1;prevlatlong=0;} \
{if (($1 == ">") && (prevlatlong!=$7)) \
{checkprofile = 1;prevlatlong=$7;} \
if (( checkprofile==1 ) && ( $5==1 )) \
{intersect_count++; checkprofile=0;}} \
END { print intersect_count }' feature_R_halfxprofiles.gmt)

# Calculate length of subduction zones that intersect with feature
local sz_length_intersect_feature=$(($prof_spacing * ($feature_total_L_intersect + $feature_total_R_intersect)))

# Clean out legacy files
rm feature_*.gmt $feature_mask_grid

# Return value
echo $sz_length_intersect_feature

}

# Function used to calculate total global subduction zone lengths which intersect with carbonate platforms at a given timestep
calculate_sz_length_carbonate(){

local rotfile=$1
local age=$2
local carbonate=$3
local outfilename_prefix=$4

# Define sampling distance, intervals and lengths of cross-profiles.
local prof_spacing="10" # Cross profile are created at 10km spacing from each other
local prof_interval="5.5875" # 5.5875 km spacing interval along the cross profile, with a 447km whisker length,
#there are a total of 10 units along the cross profile (447/5.5875=80)
local prof_length="894k" # Will search 447 km from the subduction zone for a carbonate platform feature. (894/2=447)

# Subduction boundaries have either a left- or right-polarity depending on the original direction of digitisation.
local szLlayer=${outfilename_prefix}subduction_boundaries_sL_${age}.00Ma.gmt
local szRlayer=${outfilename_prefix}subduction_boundaries_sR_${age}.00Ma.gmt

local carboante_mask_grid="reconstructed_carbonate_mask.nc"

# Reconstruct carboante platform polygons with given age and plate kinetmatic model
python ${directory}/scripts/reconstruct_feature.py -r ${rotfile} -m ${carbonate} -t ${age} -e gmt -- carbonate

# Convert reconstructed feature from vector (gmt) into a mask grid (netCDF) format
gmt grdmask reconstructed_carbonate_${age}.0Ma.gmt -Rd-180/180/-90/90 -I10k -N0/1/1  -G${carboante_mask_grid} -V

# Call function to calculate length of subduction zones that intersect with given feature. Receives feature mask grid and sz geometry
local sz_carbonate=$(find_sz_length_containing_feature $carboante_mask_grid $szLlayer $szRlayer $prof_spacing $prof_interval $prof_length)
echo >&2 "Total subduction zones with neighbouring carbonate platforms $sz_carbonate km"

# clean legacy files
rm reconstructed_carbonate_${age}.0Ma.gmt

#return value
echo $sz_carbonate

}

# Function used to calculate total global Island Arc subduction zone lengths at a given timestep
calculate_sz_length_continentArc(){

local rotfile=$1
local age=$2
local continental_polygons=$3
local outfilename_prefix=$4

# Define sampling distance, intervals and lengths of cross-profiles.
local prof_spacing="10" # Cross profile are created at 10km spacing from each other
local prof_interval="11.175" # 11.175 km spacing interval along the cross profile, with a 447km whisker length,
#there are a total of 10 units along the cross profile (447/11.175=40)
local prof_length="894k" # Will search 447 km from the subduction zone for cotinent feature. (894/2=447)

# Close continental polygons
local closed_continental_polygons="continental_polygons_closed.gmt"

# Close cotinent featurtes masked grid (netCDF) format
local continent_mask_grid="reconstructed_continent_raster.nc"

# Subduction boundaries have either a left- or right-polarity depending on the original direction of digitisation.
local szLlayer=${outfilename_prefix}subduction_boundaries_sL_${age}.00Ma.gmt
local szRlayer=${outfilename_prefix}subduction_boundaries_sR_${age}.00Ma.gmt

# reconstruct continental polygons with given age and plate kinetmatic model
python ${directory}/scripts/reconstruct_feature.py -r ${rotfile} -m ${continental_polygons} -t ${age} -e xy -- COB

# Force closure of polylines to create closed continental polygons
gmt spatial reconstructed_COB_${age}.0Ma.xy -F > $closed_continental_polygons

# Convert reconstructed feature from vector (gmt) to mask grid (netCDF) format
gmt grdmask continental_polygons_closed.gmt -Rd-180/180/-90/90 -I50k -N0/1/1 -G${continent_mask_grid} -V

# Call function to calculate length of subduction zones that intersect with given feature. Receives feature mask grid and sz geometry
local sz_length_con_arc=$(find_sz_length_containing_feature $continent_mask_grid $szLlayer $szRlayer $prof_spacing $prof_interval $prof_length)
echo >&2 "Total length of continental arcs:  $sz_length_con_arc km"

# Clean legacy files
rm reconstructed_COB_${age}.0Ma.xy $closed_continental_polygons

# Return value
echo $sz_length_con_arc

}

calculate_sz_percentage_continentArc(){

local sz_length_con_arc=$1
local sz_total_length_km=$2

local con_arc_percent=$( echo "(${sz_length_con_arc}/${sz_total_length_km})*100" | bc -l )
echo >&2 "Percentage of subduction zones that produce continental arcs = $con_arc_percent"
echo $con_arc_percent

}

####################### CALL MAIN #######################
main "$@"
