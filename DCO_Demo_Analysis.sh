# !/bin/zsh

# FILE NAME: DCO_Demo_Analysis.sh
# DESCRIPTION: Establishes all arguments and executes DCO Subduction Zone Analysis and DCO Crust Analysis
#
# AUTHORS: Sebastiano Doss, Jodie Pall, Sabin Zahirovic
# START DATE: 30th of June 2016
# LAST EDIT: 14th of July 2020

################################### Read Me ###################################

# If there are multiple feature files or rotation files preceding the argument
# flag, separate the files with a space and enclose them with a double quotes
# i.e.( -r “r1.rot r2.rot r3.rot”) Without the double quotes the parser will
# not recognize the second varible.

# IMPORTANT!
# The Matthews et al. (2016) has been updated with a fix for the Pacific 
# reference frame following Torsvik et al. (2019). The Pall et al. (2018) paper 
# had used older variants of the models before the fixes were made to Pacific plate motions. 

#################################### References ###############################

# Matthews, K.J., Maloney, K.T., Zahirovic, S., Williams, S.E., Seton, M. and Müller, R.D., (2016) Global plate
# boundary evolution and kinematics since the late Paleozoic. Global and Planetary Change


#################### Make all sub shell scripts executable ####################

chmod u+x **/*.sh

########################### Run DCO Subduction Zone Analysis #############################

# Make sure all arguments are enclosed in double quotes
rotfiles="PlateMotionModel_and_GeometryFiles/Global_EB_250-0Ma_GK07_Matthews_etal.rot \
PlateMotionModel_and_GeometryFiles/Global_EB_410-250Ma_GK07_Matthews_etal.rot"  #Matthews et al. (2016, CORRECTED)

model_features="PlateMotionModel_and_GeometryFiles/Global_EarthByte_Mesozoic-Cenozoic_plate_boundaries_Matthews_etal.gpml \
PlateMotionModel_and_GeometryFiles/Global_EarthByte_Paleozoic_plate_boundaries_Matthews_etal.gpml"  #Matthews et al. (2016, CORRECTED)

coastlines="PlateMotionModel_and_GeometryFiles/Matthews++_2016_Coastlines.gpmlz"

# Accumulating carbonate platform interactions
# carbonate="PlateMotionModel_and_GeometryFiles/DCO_Accumulated_Carbonate_Platform-v3.gpml"

# Active carbonate platform interactions
carbonate="PlateMotionModel_and_GeometryFiles/DCO_Active_Carbonate_Platform-v3.gpml"

continents="PlateMotionModel_and_GeometryFiles/Global_EarthByte_GeeK07_COB_Terranes_Matthews_etal.gpml"

fromage=410

toage=0

prefix="DCO_Subduction_Analysis"

# Execute analysis
DCO_Subduction_Analysis/DCO_subductionzone_analysis.sh -r "$rotfiles" -c "$carbonate" -t "$fromage-$toage" -a "$continents" \
-m "$model_features" -n "$prefix" -s "$coastlines"



############################ Run DCO Oceanic Crust Analysis ###############################

# Make sure all arguments are enclosed in double quotes
# Download InputGrids from Zenodo, as these will not be stored on Github
age_grids="InputGrids/Matthews_etal_2016_CORRECTED_AgeGrid/NoMask"

sediment_grids="InputGrids/Matthews_etal_2016_CORRECTED_SedThickness/NoMask"

fromage=200 # Crust analysis is limited to the last 250 Ma, and sediment thickness analysis back to 200 Ma

toage=0

prefix="DCO_Crust_Analysis"

# Execute analysis
DCO_OceanicCrust_Analysis/DCO_crust_analysis.sh -r "$rotfiles" -t "$fromage-$toage" -a "$age_grids" -s "$sediment_grids" \
-m "$model_features" -n "$prefix"


################################ Plot Results ################################

./DCO_Demo_Plot.sh Royer  # the second variable specifies which co2 study to graph and compare with the DCO analysis result
./DCO_Demo_Plot.sh Park
./DCO_Demo_Plot.sh Bergman
