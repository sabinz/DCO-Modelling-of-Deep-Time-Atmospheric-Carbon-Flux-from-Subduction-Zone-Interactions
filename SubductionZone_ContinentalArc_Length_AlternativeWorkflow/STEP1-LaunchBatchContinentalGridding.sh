#!/bin/bash

# Continental gridding automated script

rotation_file=Muller_etal_2019_CombinedRotations.rot
continental_geometries=Global_EarthByte_GeeK07_COB_Terranes_ContinentsOnly.gpml

rm -rf CONTINENTAL_GRIDS_*

age1=40 #larger number
age2=38 #smaller number
proc_tot=4
script=helper_script_make_continental_grids.sh

mkdir ContinentalGrids

step=$(echo "($age1-$age2)/$proc_tot" | bc -l | awk '{ print int($1)+1}')
#echo $step
nproc=$(echo "($age1-$age2)/$step" | bc -l | awk '{ print int($1)+1}')
#echo $nproc

proc=0
while (($proc <= ($nproc-1)))

do
	
	age_max=$(echo "$age1-($proc*$step)" | bc -l)
	age_min=$(echo "$age_max-($step-1)" | bc -l)

	if [ $age_min -lt $age2 ];
	then
		age_min=$age2
	fi	
	
	mkdir CONTINENTAL_GRIDS_${age_min}_${age_max}	

	cp ${script} CONTINENTAL_GRIDS_${age_min}_${age_max}
	cp reconstruct_features_v2.py CONTINENTAL_GRIDS_${age_min}_${age_max}
	cp continents.cpt CONTINENTAL_GRIDS_${age_min}_${age_max}
	cp $rotation_file CONTINENTAL_GRIDS_${age_min}_${age_max}/CombinedRotations.rot
	cp $continental_geometries CONTINENTAL_GRIDS_${age_min}_${age_max}/ContinentalTerranes.gpml
		
	cd CONTINENTAL_GRIDS_${age_min}_${age_max}/	

	nohup ./${script} ${age_min} ${age_max} > stdout_${age_max}-${age_min} & 
	echo "Continental gridding job for ages " ${age_min} " to " ${age_max} " launched!"
	cd ..	
		
proc=$(($proc + 1))
done	
	


	
	
