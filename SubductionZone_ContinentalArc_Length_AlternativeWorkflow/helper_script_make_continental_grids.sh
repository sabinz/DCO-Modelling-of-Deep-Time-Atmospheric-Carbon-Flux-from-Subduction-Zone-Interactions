#!/bin/bash

# -- specify directories and files
rotfile=CombinedRotations.rot 
cob_mask_gpml=ContinentalTerranes.gpml

framegrid=d
grdspace=0.1d # m is arc-minute, d is degree
anchored_plate=0

age=$1 # minimum age is fed from a batching script

while (( $age <= $2 )) # maximum age is fed from a batching script
do

		 maskgrd=continental_grid_${age}.nc
		
		 # Need to remove existing continental grid to avoid inconsistenies if gridding fails
		 rm ${maskgrd}
		 python ./reconstruct_features_v2.py -r ${rotfile} -m ${cob_mask_gpml} -t ${age} -e xy --anchor ${anchored_plate} -- cobs

		 gmt grdmask reconstructed_cobs_${age}.0Ma.xy -R${framegrid} -I${grdspace} -NNaN/1/1 -fg -V -G${maskgrd}

	psfile=continental_grid_${age}.ps

	# Making continental grids

	gmt grdimage -Ccontinents.cpt $maskgrd -JW200/10 -Rd -B30 -V > $psfile
	gmt ps2raster $psfile -A -Tg -P

	mv $maskgrd ../ContinentalGrids/

age=$(($age + 1))
done
