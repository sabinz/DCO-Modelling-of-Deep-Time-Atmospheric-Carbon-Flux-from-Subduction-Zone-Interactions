# SubductionZoneLength_ContinentalArcLength
Measures subduction zone length and continental arc length from GPlates

Dr Sabin Zahirovic (sabin.zahirovic@sydney.edu.au)

Citation:
Zahirovic, S., Eleish, A., Doss, S., Pall, J., Cannon, J., Pistone, M., and Fox, P., Submitted, Subduction kinematics and carbonate platform interactions: Geoscience Data Journal.


### Example use case

Load the Muller et al. (2019) v2 model into GPlates 2.3. Muller et al. (2019) v2 model is here:
https://www.earthbyte.org/webdav/ftp/Data_Collections/Muller_etal_2019_Tectonics/Muller_etal_2019_PlateMotionModel/Muller_etal_2019_PlateMotionModel_v2.0_Tectonics.zip 

Export the topologies into folder “GPlates_Export” using the options in the screenshot attached (gplates_export.png). 

STEP 1 – Make continental grids using the continental masking features 
•	This step generates the continental grids. You only need to do this ONCE, any time your plate motion model changes the position of continental terranes. 
•	I have made this into a batched process, so it is faster than before.
•	“cd” into directory using Terminal
	(first time do “chmod +rwx *” to give the scripts execute permissions)
	launch using "./STEP1-LaunchBatchContinentalGridding.sh" (check on single timestep first, such as 110 Ma)

STEP 2 – Analysis
•	Easiest is to just change the “scenario” which is the distance from the trench into the continent (in km, provide as integer)
•	Run on a single time step to check 
		-Launch the script using “./STEP2-ContinentalArcLengths.sh”
•	Launch for entire model timeframe (0-250 Ma)

The script will plot the reconstructions (see attached example from 125 Ma). Continental subduction zones are plotted as magenta segments. The “whiskers” (with multiple checking points along them) are plotted as black. Where they intersect continental crust, they are plotted as yellow. 

You will get three files:
total_sz_length.txt – AGE LENGTH(km)
continental_arc_portion_${scenario}km.txt – AGE PORTION(0-1)
continental_arc_length_${scenario}km.txt – AGE CONTINENT_ARC_LENGTH(km)

Some notes:
•	You will need GMT5 or GMT6 installed (and dependencies - “brew install gmt” is your friend). You will also need pygplates installed and running properly. 
•	For this example, I used a trench-arc distance of 281 km. This is the MEDIAN distance we found from our global analysis at the present-day (Pall et al. 2018). https://www.earthbyte.org/calculating-arc-trench-distances-using-the-smithsonian-global-volcanism-project-database/ 
