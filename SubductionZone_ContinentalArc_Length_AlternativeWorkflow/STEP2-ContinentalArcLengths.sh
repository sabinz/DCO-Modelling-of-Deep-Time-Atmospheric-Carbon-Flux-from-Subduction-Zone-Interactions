#!/bin/bash
gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A2 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=14p MAP_FRAME_PEN=thin FONT_LABEL=16p,Helvetica,black PROJ_LENGTH_UNIT=cm MAP_GRID_PEN_PRIMARY=0.1p,220/220/220

# Supply rotation files if using pyGPlates 
rotation_file=Muller_etal_2019_CombinedRotations.rot
coastline_file=Muller_etal_2019_Coastlines.gpmlz

# Projection
width=16
proj="W100/${width}c"
region=d

anchored_plate=0

prof_spacing=50k # IN KM, e.g. 50k, Cross profile are created at x km spacing from each other
prof_interval=20k # IN KM, e.g. 20k, Spacing of points ALONG the cross-profile

prof_spacing_for_calc=$( echo $prof_spacing | sed 's/[A-Za-z]*//g' )
prof_interval_for_calc=$( echo $prof_interval | sed 's/[A-Za-z]*//g' )


for scenario in 281 # Provide the distances from the trench into the overriding plate (km) as integer
do

	full_length=$(( $scenario * 2 )) # GMT "doubles" the length of the track so that it initially searches on BOTH sides of the subduction zone
	prof_length=${full_length}k 

	rm total_sz_length.txt
	rm continental_arc_portion_${scenario}km.txt
	rm continental_arc_length_${scenario}km.txt

	age=0
	max_age=250

	while (( $age <= $max_age ))
	do

		# Reconstruct coastlines
		python reconstruct_features_v2.py -r ${rotation_file} -m ${coastline_file} -a ${anchored_plate} -t $age -e gmt -- coasts
		
		coastlines=reconstructed_coasts_${age}.0Ma.gmt
		topologies=GPlates_Export/topology_${age}.00Ma.gmt
		subduction_boundaries=GPlates_Export/topology_subduction_boundaries_${age}.00Ma.gmt
		subduction_left=GPlates_Export/topology_subduction_boundaries_sL_${age}.00Ma.gmt
		subduction_right=GPlates_Export/topology_subduction_boundaries_sR_${age}.00Ma.gmt
		continental_grid=ContinentalGrids/continental_grid_${age}.nc

		# Total subduction zone length (km)
		subduction_length_total=$( gmt spatial $subduction_boundaries -Qk -Rd | awk  '{sum += $3} END {print sum}' )

		echo "Age is $age Ma and total sz length is $subduction_length_total km "
		echo $age $subduction_length_total >> total_sz_length.txt

		# Extract continental arc

		gmt grdtrack $subduction_left -G${continental_grid} -Ar -nn+c -C${prof_length}/${prof_interval}/${prof_spacing} > ${scenario}km_feature_L_xprofiles.gmt -V

		gmt grdtrack $subduction_right -G${continental_grid} -Ar -nn+c -C${prof_length}/${prof_interval}/${prof_spacing} > ${scenario}km_feature_R_xprofiles.gmt -V

		# Create one-sided cross-profile 'whiskers' in the direction of the down-going slab
		awk '{ if ( $1 == ">") print $0 ; else if ($3 <= 0) print $0 }' ${scenario}km_feature_L_xprofiles.gmt > ${scenario}km_feature_L_halfxprofiles.gmt
		awk '{ if ( $1 == ">") print $0 ; else if ($3 >= 0) print $0 }' ${scenario}km_feature_R_xprofiles.gmt > ${scenario}km_feature_R_halfxprofiles.gmt

		subduction_left_points_global=$( awk '{ if ( $1 == ">") print $0  }' ${scenario}km_feature_L_halfxprofiles.gmt | wc -l )
		subduction_right_points_global=$( awk '{ if ( $1 == ">") print $0  }' ${scenario}km_feature_R_halfxprofiles.gmt | wc -l )

		# awk '{ if ( $1 == ">") print $0  }' ${scenario}km_feature_L_halfxprofiles.gmt > L.test
		# awk '{ if ( $1 == ">") print $0  }' ${scenario}km_feature_R_halfxprofiles.gmt > R.test

		# exit
		subduction_global_total_number_of_points=$( echo "$subduction_left_points_global + $subduction_right_points_global" | bc )
		# Sanity Check		
		# subduction_zone_global_length_test=$( echo "$prof_spacing_for_calc * ( $subduction_left_points_global + $subduction_right_points_global )" | bc )
		# echo "Subduction length from profile check is $subduction_zone_global_length_test km"


		# For plotting - isolate points that are intersecting continental crust
		awk '{ if ( $1 == ">") print $0 ; else if ($5 == 1) print $0 }' ${scenario}km_feature_L_halfxprofiles.gmt | gmt select -Z0.9/1.1+c4 > ${scenario}km_feature_L_halfxprofiles_continent.gmt
		awk '{ if ( $1 == ">") print $0 ; else if ($5 == 1) print $0 }' ${scenario}km_feature_R_halfxprofiles.gmt | gmt select -Z0.9/1.1+c4 > ${scenario}km_feature_R_halfxprofiles_continent.gmt

		# For plotting - isolate subduction zone points that interact with continental crust
		awk '{ if ( $1 == ">") print $0  }' ${scenario}km_feature_L_halfxprofiles_continent.gmt | awk '{print $7}' | awk -F/ '{print $1, $2}'  > ${scenario}km_feature_L_halfxprofiles_SZcontinent.gmt
		awk '{ if ( $1 == ">") print $0  }' ${scenario}km_feature_R_halfxprofiles_continent.gmt | awk '{print $7}' | awk -F/ '{print $1, $2}'  > ${scenario}km_feature_R_halfxprofiles_SZcontinent.gmt

		subduction_left_points_continental=$( wc -l ${scenario}km_feature_L_halfxprofiles_SZcontinent.gmt | awk '{print $1}' )
		subduction_right_points_continental=$( wc -l ${scenario}km_feature_R_halfxprofiles_SZcontinent.gmt | awk '{print $1}' )
		
		# echo $subduction_left_points_continental $subduction_right_points_continental

		subduction_continental_arc_total_number_of_points=$( echo "$subduction_left_points_continental + $subduction_right_points_continental" | bc )

		# echo $subduction_continental_arc_total_number_of_points $subduction_global_total_number_of_points

		continental_arc_portion=$( echo "$subduction_continental_arc_total_number_of_points / $subduction_global_total_number_of_points" | bc -l )
		continental_arc_length=$( echo "$continental_arc_portion * $subduction_length_total" | bc -l | awk '{ print int($1) }')
		
		# echo $continental_arc_portion $continental_arc_length 

		echo $age $continental_arc_portion >> continental_arc_portion_${scenario}km.txt
		echo $age $continental_arc_length >> continental_arc_length_${scenario}km.txt

		# Return value
		echo "Continental arc length is $continental_arc_length km and is $continental_arc_portion of global subduction length ${subduction_length_total} km."

		psfile=ContinentalArcLength_${scenario}km_${age}Ma.ps
		
		gmt grdimage -P -J${proj} -R${region} -V -K -Y5c $continental_grid -t50 -Ccontinents.cpt  > $psfile

		gmt psxy $coastlines -W0.1p,black -J -R -K -O -V >> $psfile

		gmt psxy -R -J -W1.0p,100 -K -O ${topologies}  -V >> $psfile
		gmt psxy -R -J -W2.0p,black -Sf8p/1.5plt -K -O ${subduction_left} -Gred -V >> $psfile
		gmt psxy -R -J -W2.0p,black -Sf8p/1.5prt -K -O ${subduction_right} -Gred -V >> $psfile

		gmt psxy -R -J -Sc2.0p ${scenario}km_feature_L_halfxprofiles_SZcontinent.gmt -Gmagenta -K -O -V >> $psfile
		gmt psxy -R -J -Sc2.0p ${scenario}km_feature_R_halfxprofiles_SZcontinent.gmt -Gmagenta -K -O -V >> $psfile

		gmt psxy -R -J -Sc0.1p ${scenario}km_feature_L_halfxprofiles.gmt -K -O -V >> $psfile
		gmt psxy -R -J -Sc0.1p ${scenario}km_feature_R_halfxprofiles.gmt -K -O -V >> $psfile

		gmt psxy -R -J -Sc0.2p ${scenario}km_feature_L_halfxprofiles_continent.gmt -Gyellow -K -O -V >> $psfile
		gmt psxy -R -J -Sc0.2p ${scenario}km_feature_R_halfxprofiles_continent.gmt -Gyellow -K -O -V >> $psfile

		gmt psxy -R -J -Sc1.5p ${scenario}km_feature_L_halfxprofiles_SZcontinent.gmt -Gmagenta -K -O -V >> $psfile
		gmt psxy -R -J -Sc1.5p ${scenario}km_feature_R_halfxprofiles_SZcontinent.gmt -Gmagenta -K -O -V >> $psfile

		echo "11 -0.7 40 0 1 5 $age Ma" | gmt pstext -R0/${width}/0/1 -Jx1 -N -O >> $psfile
		 
		gmt ps2raster -Tj -A -E400 $psfile


		age=$(($age + 1))
	done


done

rm *.gmt *.ps