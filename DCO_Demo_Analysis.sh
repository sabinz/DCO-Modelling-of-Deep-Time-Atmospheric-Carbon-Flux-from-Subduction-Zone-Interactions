# !/bin/bash

# FILE NAME: DCO_Demo_Analysis.sh
# DESCRIPTION: Establishes all arguments and executes DCO Subduction Zone Analysis and DCO Crust Analysis
#
# AUTHORS: Sebastiano Doss, Jodie Pall
# START DATE: 30th of June 2016
# LAST EDIT: 14th of September 2016

################################### Read Me ###################################

# If there are multiple feature files or rotation files preceding the argument
# flag, separate the files with a space and enclose them with a double quotes
# I.e.( -r “r1.rot r2.rot r3.rot”) Without the double quotes the parser will
# not recognize the second varible.

# DCO_subductionzone_analysis.sh must have its global variable 'gmt_developement_directory' adjusted, before you
# commence this analysis. The varible must include the bin path of the latest gmt development build. If this is not
# adjusted appropriately the analysis on carboante platforms and continenal arc vs oceanic arc will produce incorrect
# results. Instructions in creating a developement build of gmt5 can be found
# here: http://gmt.soest.hawaii.edu/projects/gmt/wiki/BuildingGMT The reason for using the development build is
# because a bug was found in the tool grdtrack. The fix is implamented in the developement build, however on a whole
# it is unstable to use. Only the fixed tool grdtrack is called from the development build. For futher instructions,
# refer to the blog post on the EarthByte Website: http://www.earthbyte.org/setting-up-environment-for-dco-demo-analysis/

# The Matthews plate model has been included in the DCO_Subduction_Analysis folder, the DCO_subductionzone_analysis.sh script
# below recieves the Matthews Model. A different continents file was used for the original analysis however the file is not
# clean enough for release. The continents file provided, will likely produce different results. It has been inlcuded for
# the purposes of demonstration.

# The Müller et al. (2016) plate model has been included within the DCO_OceanicCrust_Analysis folder, the
# DCO_crust_analysis.sh script below recives the Müller et al. (2016) plate model. The age grids can be found on the
# EarthByte website: ftp://ftp.earthbyte.org/Data_Collections/Muller_etal_2016_AREPS/ . Please be aware these grids
# have some sections masked by continent-ocean boundary polygons. They may produce different results from the original
# analysis, where unmasked grids were used.


#################################### References ###############################

# Matthews, K.J., Maloney, K.T., Zahirovic, S., Williams, S.E., Seton, M. and Müller, R.D., In Review. Global plate
# boundary evolution and kinematics since the late Paleozoic. Global and Planetary Change

# Müller, R.D., Seton, M., Zahirovic, S., Williams, S.E., Matthews, K.J., Wright, N.M., Shephard, G.E., Maloney, K.T.,
# Barnett-Moore, N., Hosseinpour, M., Bower, D.J., Cannon, J., 2016. Ocean basin evolution and global-scale plate
# reorganization events since Pangea breakup, Annual Reviews of Earth and Planetary Sciences, 44(1).


#################### Make all sub shell scripts executable ####################

chmod u+x **/*.sh


########################### Run DCO Subduction Zone Analysis #############################

# Make sure all arguments are enclosed in double quotes
rotfiles="DCO_Subduction_Analysis/Global_EB_250-0Ma_GK07_Matthews_etal.rot \
DCO_Subduction_Analysis/Global_EB_410-250Ma_GK07_Matthews_etal.rot"  #Matthews et al. (in prep)

model_features="DCO_Subduction_Analysis/Global_EarthByte_Mesozoic-Cenozoic_plate_boundaries_Matthews_etal.gpml \
DCO_Subduction_Analysis/Global_EarthByte_Paleozoic_plate_boundaries_Matthews_etal.gpml DCO_Subduction_Analysis/Topology\
BuildingBlocks_AREPS.gpml"  #Matthews et al. (in prep)

carbonate="DCO_Subduction_Analysis/DCO_Active_Carbonate_Platform.gpml"

continents="DCO_Subduction_Analysis/Matthews_etal_GPC_inrev_ContinentalPolygons.gpml"

fromage=400

toage=0

prefix="DCO_Subduction_Analysis"

# Execute analysis
DCO_Subduction_Analysis/DCO_subductionzone_analysis.sh -r "$rotfiles" -c "$carbonate" -t "$fromage-$toage" -a "$continents" \
-m "$model_features" -n "$prefix"


############################ Run DCO Oceanic Crust Analysis ###############################

# Make sure all arguments are enclosed in double quotes
rotfiles="DCO_OceanicCrust_Analysis/Global_EarthByte_230-0Ma_GK07_AREPS.rot" #Müller et al. (2016)

model_features="DCO_OceanicCrust_Analysis/Global_EarthByte_230-0Ma_GK07_AREPS_Topology_BuildingBlocks.gpml \
DCO_OceanicCrust_Analysis/Global_EarthByte_230-0Ma_GK07_AREPS_PlateBoundaries.gpml" #Müller et al. (2016)

sediment_grids="<Sediment_Thickness_Grid_Path>"

age_grids="<Age_Grid_Path>"

fromage=230

toage=0

prefix="DCO_Crust_Analysis"

# Execute analysis
DCO_OceanicCrust_Analysis/DCO_crust_analysis.sh -r "$rotfiles" -t "$fromage-$toage" -a "$age_grids" -s "$sediment_grids" \
-m "$model_features" -n "$prefix"


################################ Plot Results ################################

./DCO_Demo_Plot.sh Royer  # the second variable specifies which co2 study to graph and compare with the DCO analysis result
./DCO_Demo_Plot.sh Park
./DCO_Demo_Plot.sh Bergman
