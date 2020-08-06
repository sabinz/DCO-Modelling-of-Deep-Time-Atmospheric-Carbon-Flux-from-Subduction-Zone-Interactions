#!/bin/bash

# FILENAME: DCO_Demo_Plot.sh
# DESCRIPTION: Plots of DCO analysis results generated using the Matthews et al. (2016) plate model
# compared with CO2 proxy records from Park & Royer (2011), Royer (2011) and modelled 
# palaeoatmospheric CO2 from Bergman et al. (2004) from 410 Ma to present day. 
# Grids of sediment thickness and CO2-content of the upper oceanic crust generated 
# from the Muller et al. AREPS (2016) age grid from 230 Ma to present day.
#              
# AUTHORS: Sebastiano Doss, Jodie Pall
# START DATE: 30 June 2016
# LAST EDIT: 26 March 2020

# gmt set PAPER_MEDIA A2 COLOR_MODEL RGB MAP_FRAME_TYPE plain FONT_LABEL 18p,Helvetica,black FONT_ANNOT_PRIMARY 12p,Helvetica,black FONT_ANNOT_SECONDARY 8p,Helvetica,black

gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A2 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=14p MAP_FRAME_PEN=thin FONT_LABEL=18p,Helvetica,black PROJ_LENGTH_UNIT=cm


if [ ! -d "Graphs" ]
	then
	mkdir "Graphs"
fi

if [ ! -d "PostScripts" ]
	then
	mkdir "PostScripts"
fi

projection=X-36c/18c

if [ "$1" == "Bergman" ] || [ "$1" == "bergman" ]
	then
	co2_projection=$projection
	model='COPSE model (Bergman et al. 2004)'
	co2_region=0/400/200/3400
	co2_curve=CO2/copse_bergman_400-0Ma.dat
	co2_prefix=Bergman_CO2
	co2_label="Atmospheric CO@-2@- (pCO@-2@-)"
	co2_unit_space=200
	AdditionalFlags=''
elif [ "$1" == "Royer" ] || [ "$1" == "royer" ]
	then
	co2_projection=$projection
	model='CO@-2@- Proxy Record (Royer 2006)'
	co2_region=0/400/200/3400
	co2_curve=CO2/proxy_royer_400-0Ma.dat
	co2_prefix=Royer_CO2
	co2_label="Atmospheric CO@-2@- (ppm)"
	co2_unit_space=200
	AdditionalFlags=''
else
	co2_projection=$projection
	model='CO@-2@- Proxy Record (Park & Royer 2011)'
	co2_region=0/400/0/2500
	co2_curve=CO2/proxy_park_400-0Ma.dat
	co2_prefix=Park_CO2
	co2_label="Atmospheric CO@-2@- (ppm)"
	co2_unit_space=500
	AdditionalFlags="-Ey+20p/2.0p,blue -Sc5p"
fi



sz_curve=Results/global_sz_length_data.dat
sz_region=0/400/50000/100000

carbonate_curve=Results/global_sz_length_carbonate_data.dat
carbonate_region=0/400/0/32000

continentalarc_curve=Results/global_sz_length_continentarc_data.dat
continental_region=0/400/30000/100000

continental_pcent_curve=Results/global_continent_arc_percentage_data.dat
pcent_continental_region=0/400/40/100



# Plot total subduction zones and palaeoatmospheric CO2 levels
echo "Plotting total subduction zone lengths and palaeoatmospheric CO2 levels"
psfile="Total_Subduction_Zones_And_${co2_prefix}.ps"
pngfile="Total_Subduction_Zones_And_${co2_prefix}.png"
gmt psbasemap -R$sz_region -J$projection -B20:"Age (Ma)":S:."Total Subduction Zone Lengths & $model": -K -V > $psfile

gmt psxy -R$sz_region --MAP_DEFAULT_PEN=+orangered --FONT_ANNOT_PRIMARY=12p,Helvetica,orangered  \
--FONT_LABEL=18p,Helvetica,orangered -J$projection -B10000:"Subduction Zone Length (km)":W -W2.5p,orangered $sz_curve -K -O >> $psfile

gmt psxy $co2_curve -R$co2_region -J$co2_projection $AdditionalFlags  --MAP_DEFAULT_PEN=+blue \
--FONT_ANNOT_PRIMARY=12p,Helvetica,blue  --FONT_LABEL=18p,Helvetica,blue \
-B${co2_unit_space}:"$co2_label":E -W2.5p,mediumblue -O -V >> $psfile

gmt psconvert -A2/2/2/2 -V -Tg -P $psfile
mv $psfile PostScripts
mv $pngfile Graphs
# open "Graphs/$pngfile"



# Plot total subduction zones with active carbonate platforms and palaeoatmospheric CO2 levels
echo "Plotting total subduction zone lengths with carbonate platforms and palaeoatmospheric CO2 levels"
psfile="Total_Subduction_Zones_With_Carbonate_And_${co2_prefix}.ps"
pngfile="Total_Subduction_Zones_With_Carbonate_And_${co2_prefix}.png"
gmt psbasemap -R$sz_region -J$projection -B20:"Age (Ma)":S:.\
"Length of Subduction Zones, Interactions with Active Carbonate Platforms & $model": -K -V > $psfile

gmt psxy -R$sz_region --MAP_DEFAULT_PEN=+orangered --FONT_ANNOT_PRIMARY=12p,Helvetica,orangered --FONT_LABEL=\
18p,Helvetica,orangered -J$projection -B10000:"Subduction Zone Length (km)":W -W2.5p,orangered $sz_curve -K -O >> $psfile

gmt psxy -R$carbonate_region -J$projection --MAP_DEFAULT_PEN=+seagreen --FONT_ANNOT_PRIMARY=12p,Helvetica,seagreen  \
--FONT_LABEL=18p,Helvetica,seagreen -B2500:"Subduction Zone Length Intersecting Active Carbonate Platfm(km)":E -W2.5p,seagreen \
$carbonate_curve  -K -O -V >> $psfile

gmt psxy $co2_curve -R$co2_region -J$projection $AdditionalFlags --MAP_DEFAULT_PEN=+blue --FONT_ANNOT_PRIMARY=12p,Helvetica,blue\
 --FONT_LABEL=18p,Helvetica,blue -X3c -D-3c/0c -B${co2_unit_space}:"$co2_label":E -W2.5p,mediumblue $co2_curve -N -O -V >> $psfile
gmt psconvert -A2/2/2/2 -V -Tg -P $psfile
mv $psfile PostScripts
mv $pngfile Graphs
# open "Graphs/$pngfile"



# Plot total continental arc lengths, total subduction zone lengths and palaeoatmospheric CO2 levels
echo "Ploting total continental arc lengths, total subduction zone lengths and palaeoatmospheric CO2 levels"
psfile="Total_ContinentalArc_Subduction_Zones_And_${co2_prefix}.ps"
pngfile="Total_ContinentalArc_Subduction_Zones_And_${co2_prefix}.png"

gmt psbasemap -R$sz_region -J$projection -B20:"Age (Ma)":S:."Total Continental Arc Lengths, Total Subduction & $model": \
-K -V > $psfile

gmt psxy -R$continental_region -J$projection --MAP_DEFAULT_PEN=+black --FONT_ANNOT_PRIMARY=12p,Helvetica,black \
--FONT_LABEL=18p,Helvetica,black -B10000:"Subduction Zone Length (km)":W -W2.5p,orangered $sz_curve -K -O >> $psfile

gmt psxy $continentalarc_curve -R$continental_region -J$projection --MAP_DEFAULT_PEN=+lightblue \
--FONT_ANNOT_PRIMARY=12p,Helvetica,turquoise --FONT_LABEL=18p,Helvetica,lightblue -D-3c/0c -X3c -W2.5p,lightblue \
$continentalarc_curve -K -O -V >> $psfile

gmt psxy $co2_curve -R$co2_region -J$projection $AdditionalFlags --MAP_DEFAULT_PEN=+blue --FONT_ANNOT_PRIMARY=\
12p,Helvetica,blue -X-3c -D0c/0c --FONT_LABEL=18p,Helvetica,blue -B${co2_unit_space}:"$co2_label":E -W2.5p,mediumblue \
$co2_curve -O -V >> $psfile

gmt psconvert -A2/2/2/2 -V -Tg -P $psfile
mv $psfile PostScripts
mv $pngfile Graphs
# open "Graphs/$pngfile"



# Plot proportion of volcanic arcs that are continental arcs and palaeoatmospheric CO2 levels
echo "Plotting continental arcs (%) and palaeoatmospheric CO2 levels"
psfile="Proportion_ContinentalArc_Subduction_Zones_And_${co2_prefix}.ps"
pngfile="Proportion_ContinentalArc_Subduction_Zones_And_${co2_prefix}.png"

gmt psbasemap -R$continental_region -J$projection -Ba20f10:"Age (Ma)":S:."Continental Arcs as Proportion of Global Volcanic Arcs & $model": -K \
-V > $psfile

gmt psxy $continental_pcent_curve -R$pcent_continental_region --MAP_DEFAULT_PEN=+black \
--FONT_ANNOT_PRIMARY=12p,Helvetica,black --FONT_LABEL=18p,Helvetica,black -J$projection \
-B10:"Continental arcs as proportion of global subduction zone lengths (%)":W \
-W2.5p,turquoise $continental_pcent_curve -O -K -V >> $psfile

gmt psxy $co2_curve -R$co2_region -J$projection $AdditionalFlags --MAP_DEFAULT_PEN=+blue \
--FONT_ANNOT_PRIMARY=12p,Helvetica,blue --FONT_LABEL=18p,Helvetica,blue -B${co2_unit_space}:"$co2_label":E \
-W2.5p,mediumblue $co2_curve -O -V >> $psfile

gmt psconvert -A2/2/2/2 -V -Tg -P $psfile
mv $psfile PostScripts
mv $pngfile Graphs
# open "Graphs/$pngfile"


# gmt set PAPER_MEDIA A2 COLOR_MODEL RGB MAP_FRAME_TYPE plain FONT_LABEL 18p,Helvetica,black FONT_ANNOT_PRIMARY 12p,Helvetica,black FONT_ANNOT_SECONDARY 8p,Helvetica,black 

gmt gmtset PS_COLOR_MODEL=RGB PS_MEDIA=A2 MAP_FRAME_TYPE=plain FORMAT_GEO_MAP=ddd:mm:ssF FONT_ANNOT_PRIMARY=14p MAP_FRAME_PEN=thin FONT_LABEL=18p,Helvetica,black PROJ_LENGTH_UNIT=cm


if [ "$1" == "Bergman" ] || [ "$1" == "bergman" ]  
then
	model='COPSE model (Bergman et al. 2004)'
	co2_region=0/200/200/1400
	co2_curve=CO2/copse_bergman_230-0Ma.dat
	co2_prefix=Bergman_CO2
	co2_label="Atmospheric CO@-2@- (pCO@-2@-)"
	co2_unit_space=100
elif [ "$1" == "Royer" ] || [ "$1" == "royer" ]
then	
	model='CO@-2@- Proxy Record (Royer 2006)'
	co2_region=0/200/200/2400
	co2_curve=CO2/proxy_royer_230-0Ma.dat
	co2_prefix=Royer_CO2
	co2_label="Atmospheric CO@-2@- (ppm)"
	co2_unit_space=200
else
	model='CO@-2@- Proxy Record (Park & Royer 2011)'
	co2_region=0/200/0/2500
	co2_curve=CO2/proxy_park_230-0Ma.dat
	co2_prefix=Park_CO2
	co2_label="Atmospheric CO@-2@- (ppm)"
	co2_unit_space=500
	AdditionalFlags="-Ey+20p/2.0p,blue -Sc5p"
fi


age_region=0/200/20/115
crust_co2_region=0/200/2.0/3.4
sed_region=0/200/0/700

co2_stats=Results/global_crust_co2_data.dat
age_stats=Results/global_crust_age_data.dat
sed_stats=Results/global_crust_sed_data.dat
co2_mean=co2_mean.dat
co2_median=co2_median.dat
age_mean=age_mean.dat
age_median=age_median.dat
sed_mean=sed_mean.dat
sed_median=sed_median.dat



echo "Plotting mean & median age of subducting oceanic crust and palaeoatmospheric CO2 levels"
psfile="Subducting_Oceanic_Crust_Age_And_${co2_prefix}.ps"
pngfile="Subducting_Oceanic_Crust_Age_And_${co2_prefix}.png"

awk 'NR > 1{print $1 , $2}' $age_stats > $age_mean
awk 'NR > 1{print $1 , $4}' $age_stats > $age_median

gmt psbasemap -R$age_region -J$projection -B20:"Time (Ma)":S:."Mean & Median Age of Subucting Oceanic Crust & $model": -K -V > $psfile
gmt psxy -R$age_region -J$projection --MAP_DEFAULT_PEN=+orangered --FONT_ANNOT_PRIMARY=12p,Helvetica,orangered \
--FONT_LABEL=18p,Helvetica,orangered -B10:"Crust Age (Ma)":W -W2.5p,orangered $age_mean -K -O -V >> $psfile

gmt psxy $co2_curve -R$co2_region -J$projection $AdditionalFlags --MAP_DEFAULT_PEN=+royalblue \
--FONT_ANNOT_PRIMARY=12p,Helvetica,royalblue  --FONT_LABEL=18p,Helvetica,royalblue -B${co2_unit_space}:"$co2_label":E \
-W2.5p,royalblue $co2_curve -K -O -V >> $psfile

gmt psxy -R$age_region -J$projection --MAP_DEFAULT_PEN=+orangered --FONT_ANNOT_PRIMARY=12p,Helvetica,orangered \
-W1.5p,orangered,- $age_median -V -O >> $psfile

gmt psconvert -A2/2/2/2 -V -Tg -P $psfile
mv $psfile PostScripts
mv $pngfile Graphs
# open "Graphs/$pngfile"



echo "Plotting mean & median CO2 content of subducting oceanic crust and palaeoatmospheric CO2 levels"
psfile="Subducting_Oceanic_Crust_CO2_And_${co2_prefix}.ps"
pngfile="Subducting_Oceanic_Crust_CO2_And_${co2_prefix}.png"

awk 'NR > 1{print $1 , $2}' $co2_stats > $co2_mean
awk 'NR > 1{print $1 , $4}' $co2_stats > $co2_median

gmt psbasemap -R$crust_co2_region -J$projection -B20:"Time (Ma)":S:."Mean & Median CO@-2@- Content of Subucting Oceanic Crust & $model": -K -V > $psfile

gmt psxy -R$crust_co2_region -J$projection --MAP_DEFAULT_PEN=+orangered --FONT_ANNOT_PRIMARY=12p,Helvetica,orangered \
--FONT_LABEL=18p,Helvetica,orangered -B0.1:"CO@-2@- (wt%)":W -W2.5p,orangered $co2_mean -K -O -V >> $psfile

gmt psxy $co2_curve -R$co2_region -J$projection $AdditionalFlags --MAP_DEFAULT_PEN=+royalblue \
--FONT_ANNOT_PRIMARY=12p,Helvetica,royalblue  --FONT_LABEL=18p,Helvetica,royalblue \
-B${co2_unit_space}:"$co2_label":E -W2.5p,royalblue $co2_curve -K -O -V >> $psfile

gmt psxy -R$crust_co2_region -J$projection --MAP_DEFAULT_PEN=+orangered \
--FONT_ANNOT_PRIMARY=12p,Helvetica,orangered -W1.5p,orangered,- $co2_median -V -O >> $psfile

gmt psconvert -A2/2/2/2 -V -Tg -P $psfile
mv $psfile PostScripts
mv $pngfile Graphs
# open "Graphs/$pngfile"



echo "Plotting mean & median seafloor sediment thickness and palaeoatmospheric CO2 levels"
psfile="Subducting_Oceanic_Crust_Sediment_Thickness_And_${co2_prefix}.ps"
pngfile="Subducting_Oceanic_Crust_Sediment_Thickness_And_${co2_prefix}.png"

awk 'NR > 1{print $1 , $2}' $sed_stats > $sed_mean
awk 'NR > 1{print $1 , $4}' $sed_stats > $sed_median

gmt psbasemap -R$sed_region -J$projection -B20:"Time (Ma)":S:."Mean & Median Subducting Slab Sediment Thickness & $model": -K -V > $psfile

gmt psxy -R$sed_region -J$projection --MAP_DEFAULT_PEN=+orangered --FONT_ANNOT_PRIMARY=12p,Helvetica,orangered  \
--FONT_LABEL=18p,Helvetica,orangered -B50:"Sediment Thickness (m)":W -W2.5p,orangered $sed_mean -K -O -V >> $psfile

gmt psxy $co2_curve -R$co2_region -J$projection $AdditionalFlags --MAP_DEFAULT_PEN=+royalblue \
--FONT_ANNOT_PRIMARY=12p,Helvetica,royalblue  --FONT_LABEL=18p,Helvetica,royalblue -B${co2_unit_space}:"$co2_label":E \
-W2.5p,royalblue $co2_curve -K -O -V >> $psfile

gmt psxy -R$sed_region -J$projection --MAP_DEFAULT_PEN=+orangered --FONT_ANNOT_PRIMARY=12p,Helvetica,orangered \
-W1.5p,orangered,- $sed_median -V -O >> $psfile

gmt psconvert -A2/2/2/2 -V -Tg -P $psfile
mv $psfile PostScripts
mv $pngfile Graphs
# open "Graphs/$pngfile"


rm gmt.conf gmt.history *median.dat *mean.dat