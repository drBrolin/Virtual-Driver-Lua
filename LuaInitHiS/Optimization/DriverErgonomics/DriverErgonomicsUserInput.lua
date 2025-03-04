--Age of all manikins 
age = 40;

--Family name
familyNameInScene = 'Family 1';

numHeatmapPoints = 300 --It will create some additional points to fill the gaps and make it squared
heatmapPointSize = Vector3d(0.01,0.001,0.01)

--Name of geometries in scene. Double check there are not repeated names or the code will take the first one by default
saeHPointEquivalentNameInScene = 'SAE H-point equivalent';
steeringWheelNameInScene = 'SteeringWheel-car';
seatAdjustmentRangeNameInScene = 'SeatAdjRange';
steeringWheelAdjustmentRangeNameInScene = 'SteeringWheelAdjRange';
torsoNameInScene = "Torso"
buttockNameInScene = 'Buttock';
opSeqNameInScene = 'Operation Sequence 1';
ahpNameInScene = "ahp";
prpNameInScene = "prp";

--constraint objects
steeringCollisionObjectNameInScene = "zBottomSW";
steeringVisionObjectNameInScene = "zTopSW";
consoleNameInScene = "zConsole";
roofNameInScene = 'zRoof';

--constraint limits (minimum)
roofDistanceLimit = 50; --(mm)
kneeDistanceLimit = 50;	--(mm)
thighDistanceLimit = 50; --(mm)
downViewAngleLimit = 13; -- (degrees)

--limits for colors in NOT OK
greenColorLimit = 3; --Maximum number for that color
yellowColorLimit = 5; --Maximum number for that color. Must be bigger than green

--Nümber of RMSE admitted to be okay
nrRMSE = 1; --Default is 1 RMSE defined by Reed. More allows more variation of posture

--Torso angle adjustments

allpointsAngleSeat = NumberVector();
--allpointsAngleSeat:push_back(0);
allpointsAngleSeat:push_back(5);
allpointsAngleSeat:push_back(12); --Add another line to check more angles. The angle is defined from the vertical
allpointsAngleSeat:push_back(20);
allpointsAngleSeat:push_back(25);
allpointsAngleSeat:push_back(30);

--Adjustments for manikin difference (modify if defined family does not match)

offsetHip2Eye = {1.90,5.30,4.16,7.31,2.12,5.50,3.92,6.68,-0.44,3.10,1.60,4.99,0.14,3.79,1.83,5.20};

offsetHead = {-29.69,-26.12,-27.06,-24.28,-29.09,-25.64,-27.14,-24.17,-32.51,-28.45,-30.45,-26.74,-31.43,-28.02,-29.72,-26.24}

offsetNeck = {-14.57,-7.27,-11.43,-3.26,-14.04,-7.64,-10.99,-3.70,-17.87,-11.25,-15.27,-6.97,-17.80,-10.86,-14.59,-7.36}

offsetThorax = {-0.97,5.58,4.21,9.89,-0.52,6.01,1.95,7.71,-5.36,1.30,-1.47,5.03,-4.15,2.88,-1.05,5.48}

offsetAbdomen = {3.73,1.36,-0.36,-2.22,4.92,2.30,4.32,0.57,1.33,4.27,2.39,0.40,4.09,2.92,3.64,1.26}

offsetPelvis = {6.08,12.48,8.10,14.04,6.68,12.87,7.78,13.63,4.22,10.47,5.42,11.94,4.44,10.61,5.87,12.34}

offsetThigh = {0.71,3.20,2.79,5.25,0.82,2.71,0.86,2.83,-1.06,0.87,0.99,3.67,0.81,2.57,0.71,3.10}

offsetKnee = {-6.60,-10.77,-8.59,-10.63,-6.27,-9.64,-7.48,-7.94,-3.59,-9.10,-7.33,-11.68,-5.78,-11.92,-6.56,-10.86}

--Heatmap point size definition
heatmapSquareSizeVec = Vector3d(0.01,0.001,0.01) --XYZ sizes of the squares


--Additional settings of constants of driver. Read Reed-s prediction article to define them
function setConstantsDriver()
	--1. Slope 
	slope = -0.55556;

	--2. H30 Simulation
	-- We read this value from the scene in every new iteration
	-- H30 = vertical distance from the AHP to the H-point, hte centre of the seat adj range
	--abs(seatAdjRange tz - ahp static geometry tz) 
	h30 = math.abs(getTControlOfActiveObjectByName(seatAdjustmentRangeNameInScene)["tz"] - getTControlOfStaticGeometryByName(ahpNameInScene)["tz"])*1000;

	--3. MidL6
	MidL6 = slope * h30 + 700;

	--4. L6sim
	-- We read this value from the scene in every new iteration
	-- L6sim = horizontal distance from SW center to PRP (pedal ref point)
	--abs(SteeringWheelAdjRange txty -prp static geometry txty)

	L6sim = math.abs(getTControlOfActiveObjectByName(steeringWheelAdjustmentRangeNameInScene)["tx"] - getTControlOfStaticGeometryByName(prpNameInScene)["tx"])*1000; 

	--5. L6re
	l6re = L6sim - MidL6; 
end


	