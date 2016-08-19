# !/bin/bash

# FILE NAME: DCO_Demo_Analysis.sh
# DESCRIPTION: Establishes all arguments and executes DCO Subduction Zone Analysis and DCO Crust Analysis
#              
# AUTHORS: Sebastiano Doss, Jodie Pall
# START DATE: 30th of June 2016 
# LAST EDIT: 17th of August 2016

################################### Read Me ###################################

# If there are multiple feature files or rotation files preceding the argument 
# flag, separate the files with a space and enclose them with a double quotes 
# I.e.( -r “r1.rot r2.rot r3.rot”) Without the double quotes the parser will 
# not recognize the second varible.

# For more information on this project's methodologies, refer to the blog on the EarthByte Website: http://www.earthbyte.org/category/dco-project/dco-blog/

#################### Make all sub shell scripts executable ####################

chmod u+x **/*.sh

####################### Run DCO Subduction Zone Analysis ######################

# Make sure all arguments are enclosed in double quotes
rotfiles="<Rotation_File_Paths>" 
model_features="<Model_Features_Paths>" 
carbonate="<Carbonate_Features_Path>"
COB="<COB_Features_Path>"
fromage="<From_Age>"
toage="<To_Age>"
prefix="DCO_Subduction_Analysis"

DCO_Subduction_Analysis/DCO_subductionzone_analysis.sh -r "$rotfiles" -c "$carbonate" -t "$fromage-$toage" -a "$COB" \
-m "$model_features" -n "$prefix"

####################### Run DCO Oceanic Crust Analysis #######################

# Make sure all arguments are enclosed in double quotes
rotfiles="<Rotation_File_Paths>"
model_features="<Model_Features_Paths>"
sediment_grids="<Sediment_Grid_Path>"
age_grids="<Age_Grid_Path>"
fromage="<From_Age>"
toage="<To_Age>"
prefix="DCO_Crust_Analysis"

DCO_OceanicCrust_Analysis/DCO_crust_analysis.sh -r "$rotfiles" -t "$fromage-$toage" -a "$age_grids" -s "$sediment_grids" \
-m "$model_features" -n "$prefix"

################################ Plot Results ################################
./DCO_Demo_Plot.sh Royer  # The second variable specifies which palaeo-CO2 data to graph and compare with the DCO analysis result
./DCO_Demo_Plot.sh Park
./DCO_Demo_Plot.sh Bergman

