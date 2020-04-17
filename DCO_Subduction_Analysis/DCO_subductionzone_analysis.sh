
# FILENAME: DCO_subductionzone_analysis.sh
# DESCRIPTION: Produces global temporal results depicting total subduction zone lengths,
#              total subuduction zone length intersecting with carbonate platforms,
#              total continental (Andean-style) subduction zones and percentage of total continental
#              (Andean-style) subduction to oceanic subduction zones.
# AUTHORS: Sebastiano Doss, Jodie Pall, Sabin Zahirovic
# START DATE: 29th of February 2016
# LAST EDIT: 27th of March 2020

# Instructions

# In order to run these workflows, GMT 6 or newer, Python 2.7 along with the python
# module pyGPlates (rev. 12 or newer) must be installed on your system. In terminal
# the curent directory should be changed to the folder where the
# DCO_subductionzone_analysis.sh is located.

# Latest test performed using GMT 6.1, and pyGPlates rev. 18

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
#   -c    files depicting carbonate platform activity or accumulation (gpml or shp)
#   -a    files depicting cotinental outlines  (gpml or shp)

# If there are multiple feature files or rotation files following the argument
# flag, separate the files with a space and enclose them with a double quotes
# i.e. -r “r1.rot r2.rot r3.rot”

# Examples

# For ACTIVE carbonate platforms only
# e.g. ./DCO_subductionzone_analysis.sh -r "Global_EB_250-0Ma_GK07_Matthews_etal.rot Global_EB_410-250Ma_GK07_Matthews_etal.rot" -m "Global_EarthByte_Mesozoic-Cenozoic_plate_boundaries_Matthews_etal.gpml Global_EarthByte_Paleozoic_plate_boundaries_Matthews_etal.gpml" -t 410-0 -c DCO_Active_Carbonate_Platform-v3.gpml -a Global_EarthByte_GeeK07_COB_Terranes_Matthews_etal.gpml

# For ACCUMULATING carbonate platforms 
# e.g. ./DCO_subductionzone_analysis.sh -r "Global_EB_250-0Ma_GK07_Matthews_etal.rot Global_EB_410-250Ma_GK07_Matthews_etal.rot" -m "Global_EarthByte_Mesozoic-Cenozoic_plate_boundaries_Matthews_etal.gpml Global_EarthByte_Paleozoic_plate_boundaries_Matthews_etal.gpml" -t 410-0 -c DCO_Accumulated_Carbonate_Platform-v3.gpml -a Global_EarthByte_GeeK07_COB_Terranes_Matthews_etal.gpml


# The analysis will produce a folder named Results containing four dat files:
# global_continent_arc_percentage_data, global_sz_length_carbonate_data,
# global_sz_length_continentarc_data and global_sz_length_data.
# A folder called PlateBoundaryFeatures will be produced, containing resolved plate boundaries
# (subduction, MOR and transform) at each time step.


# For more information on this project's methodologies, refer to the blog on the EarthByte Website:
# http://www.earthbyte.org/category/dco-project/dco-blog/

####################### Global Variables #######################
directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

rm -rf PlateBoundaryFeatures
rm -rf Results

# Initialise for PLOTTING

frame=d # geographic -180/180/-90/90
proj=W115/20c # Mollweide projection, central meridian, and width (in centimeters)

# GMT plotting defaults for reproducibility
gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A2 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=14p MAP_FRAME_PEN=thin FONT_LABEL=16p,Helvetica,black PROJ_LENGTH_UNIT=cm
coastlines=Matthews++_2016_Coastlines.gpmlz
plotting_cpt=carbonates_v2.cpt
#plotting_cpt=carbonates.cpt

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

# Iterate through each 1 myr timestep, conducting subduction zone analyses
while (( $age <= from_age ))
do

echo >&2 "Time Step: $age"
mkdir -p PlateBoundaryFeatures/${age}

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

# Append age and corresponding values calculated by the analysis functions to results files
echo $age $sz_total_length_km >> $global_sz_length
echo $age $sz_carbonate >> $global_sz_length_carbonate
echo $age $sz_length_con_arc >> $global_sz_length_continentarc
echo $age $con_arc_percent >> $global_continent_arc_percentage

python ${directory}/scripts/reconstruct_feature.py -r ${rotfile} -m ${coastlines} -t ${age} -e gmt -- coast

python ${directory}/scripts/resolve_topologies_V.2.py -r ${rotfile} -m ${topologies} -t ${age} -e xy 

# Migrate all resolved feature files at each timestep to a new age-stamped folder
mv topology*.xy *.gmt *.xml *.nc PlateBoundaryFeatures/${age}

#  ### START OF PLOTTING SECTION ###

carbonate_platform_grid=PlateBoundaryFeatures/${age}/carbonate_platforms_plotting_${age}.nc

psfile=carbonates_${age}.ps

continents=PlateBoundaryFeatures/${age}/continental_polygons_closed_${age}.gmt
coastline=PlateBoundaryFeatures/${age}/reconstructed_coast_${age}.0Ma.gmt
topologies=PlateBoundaryFeatures/${age}/topology_boundary_polygons_${age}.00Ma.xy
subduction_left=PlateBoundaryFeatures/${age}/topology_subduction_boundaries_sL_${age}.00Ma.xy
subduction_right=PlateBoundaryFeatures/${age}/topology_subduction_boundaries_sR_${age}.00Ma.xy

gmt psbasemap -R${frame} -J${proj} -Ba30 -G224 -Y5c -P -K -V4 > $psfile
     
gmt psxy -R -J $continents -G210/180/140 -L -K -O -V4 >> $psfile

gmt psxy -R -J $coastline -Gnavajowhite4 -K -O -V4 >> $psfile

gmt grdimage -C${plotting_cpt} ${carbonate_platform_grid} -J -R -V -Q -K -O -t20 >> $psfile

gmt psxy -R -J -W1p,80 $topologies -K -O -V4 -N >> $psfile

gmt psxy -R -J -W1p,80 -Sf7p/2plt -K -O ${subduction_left} -V4 -N >> $psfile
gmt psxy -R -J -W1p,80 -Sf7p/2prt -K -O ${subduction_right} -V4 -N >> $psfile

echo "18 0 $age Ma" | gmt pstext -F+f26,Helvetica,black -R0/15/0/1 -Jx1 -N -O -V4 >> $psfile

gmt psconvert ${psfile} -A -Tj -P

#  ### END OF PLOTTING SECTION ###
# rm *.xy # *.ps


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


gmt grdtrack $szLlayer -G${feature_mask_grid}  -nn+c \
-C${prof_length}/${prof_interval}/${prof_spacing} > ${feature_mask_grid}_feature_L_xprofiles.gmt -V

gmt grdtrack $szRlayer -G${feature_mask_grid}   -nn+c \
-C${prof_length}/${prof_interval}/${prof_spacing} > ${feature_mask_grid}_feature_R_xprofiles.gmt -V

# Create one-sided cross-profile 'whiskers' in the direction of the down-going slab
awk '{ if ( $1 == ">") print $0 ; else if ($3 <= 0) print $0 }' ${feature_mask_grid}_feature_L_xprofiles.gmt > ${feature_mask_grid}_feature_L_halfxprofiles.gmt
awk '{ if ( $1 == ">") print $0 ; else if ($3 >= 0) print $0 }' ${feature_mask_grid}_feature_R_xprofiles.gmt > ${feature_mask_grid}_feature_R_halfxprofiles.gmt

cp *profiles.gmt PlateBoundaryFeatures/${age}/

# Identify and count cross-profiles that intersect with feature
local feature_total_L_intersect=$(awk \
'BEGIN {intersect_count=0;checkprofile=1;prevlatlong=0;} \
{if (($1 == ">") && (prevlatlong != $7)) \
{checkprofile = 1; prevlatlong = $7;} \
if (( checkprofile == 1 ) && ( $5 == 1 )) \
{intersect_count++; checkprofile=0;}} \
END { print intersect_count }' ${feature_mask_grid}_feature_L_halfxprofiles.gmt)

local feature_total_R_intersect=$(awk \
'BEGIN {intersect_count=0;checkprofile=1;prevlatlong=0;} \
{if (($1 == ">") && (prevlatlong != $7)) \
{checkprofile = 1; prevlatlong = $7;} \
if (( checkprofile == 1 ) && ( $5 == 1 )) \
{intersect_count++; checkprofile=0;}} \
END { print intersect_count }' ${feature_mask_grid}_feature_R_halfxprofiles.gmt)

# Calculate length of subduction zones that intersect with feature
local sz_length_intersect_feature=$( echo "$prof_spacing * ( $feature_total_R_intersect + $feature_total_L_intersect )" | bc )

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
local prof_spacing="10" # Cross profile are created at 10 km spacing from each other
local prof_interval="5.5875" # 5.5875 km spacing interval along the cross profile, with a 447 km whisker length,
#there are a total of 10 units along the cross profile (447/5.5875=80)
local prof_length="894k" # Will search 447 km from the subduction zone for a carbonate platform feature. (894/2=447)

# Subduction boundaries have either a left- or right-polarity depending on the original direction of digitisation.
local szLlayer=${outfilename_prefix}subduction_boundaries_sL_${age}.00Ma.gmt
local szRlayer=${outfilename_prefix}subduction_boundaries_sR_${age}.00Ma.gmt

local carbonate_mask_grid="reconstructed_carbonate_mask_${age}.nc"

# Reconstruct carboante platform polygons with given age and plate kinetmatic model
python ${directory}/scripts/reconstruct_feature.py -r ${rotfile} -m ${carbonate} -t ${age} -e gmt -- carbonate

cp reconstructed_carbonate_${age}.0Ma.gmt PlateBoundaryFeatures/${age}/reconstructed_carbonate_${age}.0Ma.gmt

# Convert reconstructed feature from vector (gmt) into a mask grid (netCDF) format
gmt grdmask reconstructed_carbonate_${age}.0Ma.gmt -fg -Rd -I10k -N0/1/1 -G${carbonate_mask_grid} -V
# Try arc units to ensure geographic grid 
# gmt grdmask reconstructed_carbonate_${age}.0Ma.gmt -fg -Rd -I1s -N0/1/1 -G${carbonate_mask_grid} -V
# low res for testing, 1 degree
# gmt grdmask reconstructed_carbonate_${age}.0Ma.gmt -fg -Rd -I1d -N0/1/1 -G${carbonate_mask_grid} -V
# grid for plotting
gmt grdmask reconstructed_carbonate_${age}.0Ma.gmt -fg -Rd -I10k -NNaN/1/1 -Gcarbonate_platforms_plotting_${age}.nc -V

cp ${carbonate_mask_grid} PlateBoundaryFeatures/reconstructed_carbonate_mask_${age}.nc

# Call function to calculate length of subduction zones that intersect with given feature. Receives feature mask grid and sz geometry
local sz_carbonate=$(find_sz_length_containing_feature $carbonate_mask_grid $szLlayer $szRlayer $prof_spacing $prof_interval $prof_length)
echo >&2 "Total subduction zones with neighbouring carbonate platforms $sz_carbonate km"

# clean temp files
rm reconstructed_carbonate_${age}.0Ma.gmt


#return value
echo $sz_carbonate

}

# Function used to calculate global subduction zone lengths at a given timestep
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
local closed_continental_polygons="continental_polygons_closed_${age}.gmt"

# Close continent featurtes masked grid (netCDF) format
local continent_mask_grid="reconstructed_continent_raster_${age}.nc"

# Subduction boundaries have either a left- or right-polarity depending on the original direction of digitisation.
local szLlayer=${outfilename_prefix}subduction_boundaries_sL_${age}.00Ma.gmt
local szRlayer=${outfilename_prefix}subduction_boundaries_sR_${age}.00Ma.gmt

# reconstruct continental polygons with given age and plate kinetmatic model
python ${directory}/scripts/reconstruct_feature.py -r ${rotfile} -m ${continental_polygons} -t ${age} -e xy -- COB

# Force closure of polylines to create closed continental polygons
gmt spatial reconstructed_COB_${age}.0Ma.xy -F > ${closed_continental_polygons}

# Convert reconstructed feature from vector (gmt) to mask grid (netCDF) format
gmt grdmask ${closed_continental_polygons} -Rd -I50k -fg -N0/1/1 -G${continent_mask_grid} -V

cp ${closed_continental_polygons} PlateBoundaryFeatures/${age}/continental_polygons_closed_${age}.gmt
cp ${continent_mask_grid} PlateBoundaryFeatures/reconstructed_continent_raster_${age}.nc

# Call function to calculate length of subduction zones that intersect with given feature. Receives feature mask grid and SZ geometry
local sz_length_con_arc=$(find_sz_length_containing_feature $continent_mask_grid $szLlayer $szRlayer $prof_spacing $prof_interval $prof_length)
echo >&2 "Total length of continental arcs:  $sz_length_con_arc km"

# Clean legacy files
rm reconstructed_COB_${age}.0Ma.xy ${closed_continental_polygons}

# Return value
echo ${sz_length_con_arc}

}

calculate_sz_percentage_continentArc(){

local sz_length_con_arc=$1
local sz_total_length_km=$2

local con_arc_percent=$( echo "(${sz_length_con_arc}/${sz_total_length_km})*100" | bc -l )
echo >&2 "Percentage of global subduction zones that produce continental arcs = $con_arc_percent"
echo $con_arc_percent

}

####################### CALL MAIN #######################
main "$@"
