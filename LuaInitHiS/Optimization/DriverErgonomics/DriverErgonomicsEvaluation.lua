dofile(scriptPath.."/Geometry_creation.lua");

dofile(scriptPath.."/DriverErgonomics/Anthropometrics.lua");
dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsUtils.lua");
dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsUserInput.lua");
dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsManikinPosture.lua");
dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsConstraints.lua");
dofile(scriptPath.."/DriverErgonomics/ReedAnglePrediction.lua");


function eval(name, value, acceptable, iMeasure) --manikin name, that measure evaluation, that measure okay value, that measure index in RMSE array
	if(getGender(name) == "Female") then
		if ((value > (acceptable + femaleRMSE[iMeasure])) or (value < (acceptable - femaleRMSE[iMeasure]))) then
			return 1; --Not ok
		else
			return 0; --ok
		end
	else
		if ((value > (acceptable + maleRMSE[iMeasure])) or (value < (acceptable - maleRMSE[iMeasure]))) then
			return 1; --Not ok
		else
			return 0; --ok
		end
	end
end




function addDriverEvaluationsToJSON()
	local objectsRoot = Ips.getActiveObjectsRoot();
	local objectsRootSae = objectsRoot:findFirstExactMatch(saeHPointEquivalentNameInScene):toPositionedTreeObject();
	local saeGlobalCoor = objectsRootSae:getTWorld();
	local saeControlCoor = objectsRootSae:getTControl(); 
	--print("The SAE machine is: " ..tostring(saeControlCoor));

	-- Steering Wheel car
	local objectsRootSteeringWheel = objectsRoot:findFirstExactMatch(steeringWheelNameInScene):toPositionedTreeObject(); 
	local swGlobalCoor = objectsRootSteeringWheel:getTWorld();
	local swControlCoor = objectsRootSteeringWheel:getTControl();
	--print("The steering wheel car is: " ..tostring(swControlCoor));

	--------------------------------------------------------------------------------------------

	---> Step 2: Access the SeatAdjRange and place it where the SAE machine is (the previous coordenates)
	---  		 Access the SteeringWheelAdjRange and place it where the SteeringWheel-car is
	-- SeatAdjRange
	local objectsRootHpointEnv = objectsRoot:findFirstExactMatch(seatAdjustmentRangeNameInScene):toPositionedTreeObject();
	local h_EnvCoor = objectsRootHpointEnv:getTControl();
	--print("\n");
	--print("The h-point envelope was: " ..tostring(h_EnvCoor));

	h_EnvCoor["tx"] = saeControlCoor["tx"];
	h_EnvCoor["ty"] = saeControlCoor["ty"];
	h_EnvCoor["tz"] = saeControlCoor["tz"];

	objectsRootHpointEnv:setTControl(h_EnvCoor);
	h_EnvCoor = objectsRootHpointEnv:getTControl();
	--print("The h-point envelope has been moved to: " ..tostring(h_EnvCoor));

	-- SteeringWheelAdjRange
	local objectsRootSteWheelAdjRan = objectsRoot:findFirstExactMatch(steeringWheelAdjustmentRangeNameInScene):toPositionedTreeObject();
	local swarCoor = objectsRootSteWheelAdjRan:getTControl();
	--print("\n");
	--print("The SteeringWheelAdjRange was: " ..tostring(h_EnvCoor)); 
	 
	swarCoor["tx"] = swControlCoor["tx"]; 
	swarCoor["ty"] = swControlCoor["ty"]; 
	swarCoor["tz"] = swControlCoor["tz"]; 

	objectsRootSteWheelAdjRan:setTControl(swarCoor);
	swarCoor = objectsRootSteWheelAdjRan:getTControl();
	--print('The SteeringWheelAdjRange has been moved to: '..tostring(swarCoor));
	-- local checkpointsSeat = 8; 
	-- local checkpointsSteeringWheel = 4;

	--Fix buttock location
	local objectsButtock = objectsRoot:findFirstExactMatch(buttockNameInScene):toPositionedTreeObject();
	local buttockTrans = objectsButtock:getTControl();
	buttockTrans["tx"] = saeControlCoor["tx"]; 
	buttockTrans["ty"] = saeControlCoor["ty"]; 
	buttockTrans["tz"] = saeControlCoor["tz"]; 
	objectsButtock:setTControl(buttockTrans);
	
	--Create locations
	

	local allpointsSeat = Vector3dVector(); -- Creates a vector of 3d vector
	local sphere1 = objectsRoot:findFirstExactMatch("Front-top"):toPositionedTreeObject();
	local sphere2 = objectsRoot:findFirstExactMatch("Back-top"):toPositionedTreeObject();
	local sphere3 = objectsRoot:findFirstExactMatch("Front-bottom"):toPositionedTreeObject();

	local point1 = sphere1:getTWorld()['t'];
	local point2 = sphere2:getTWorld()['t'];
	local point3 = sphere3:getTWorld()['t'];
	
	-- local point1 = h_EnvCoor['t'] + Vector3d(-0.191,0,0.059);
	-- local point2 = h_EnvCoor['t'] + Vector3d(0.122,0,0.026);
	-- local point3 = h_EnvCoor['t'] + Vector3d(-0.123,0,-0.026);
	allpointsSeat = createPointsInSquare(point1, point2, point3, numHeatmapPoints)

	local allpointsSteeringWheel = Vector3dVector(); 
	-- allpointsSteeringWheel:push_back(swarCoor['t'] + Vector3d(0,0,0)); 			--Point 0
	-- allpointsSteeringWheel:push_back(swarCoor['t'] + Vector3d(0.06,0,0.026)); 	--Point 1 
	allpointsSteeringWheel:push_back(swarCoor['t'] + Vector3d(0.038,0,-0.013)); --Point 2 (origin)
	-- allpointsSteeringWheel:push_back(swarCoor['t'] + Vector3d(0.018,0,-0.048)); --Point 3
	-- allpointsSteeringWheel:push_back(swarCoor['t'] + Vector3d(0.08,0,-0.028));	--Point 4
	
	-- local allpointsAngleSeat = NumberVector();
	-- --allpointsAngleSeat:push_back(0);
	-- allpointsAngleSeat:push_back(15);
	-- -- allpointsAngleSeat:push_back(30);
	
	local procRoot = Ips.getProcessRoot();
	local opSeq = procRoot:findFirstExactMatch(opSeqNameInScene):toOperationSequence();
	local obj = objectsRoot:findFirstExactMatch(saeHPointEquivalentNameInScene):toPositionedTreeObject();

	--print("\n");
	--print(allpointsSteeringWheel);
	local transfSae = saeControlCoor:clone(); 
	local transfSW = swControlCoor:clone();
	
	
	
	setConstantsDriver();
	-------------------------------------------------------------------------
	local hipToEyeAngleVec = NumberVector();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);

	local measNames = StringVector();
	measNames:push_back("hipToEyeAngle");
	measNames:push_back("headAngle");
	measNames:push_back("neckAngle");
	measNames:push_back("thoraxAngle");
	measNames:push_back("abdomenAngle");
	measNames:push_back("pelvisAngle");
	measNames:push_back("thighAngle");
	measNames:push_back("rightKneeAngle");
	measNames:push_back("leftKneeAngle");
	measNames:push_back("rightElbowAngle");
	measNames:push_back("leftElbowAngle");
	
	
	local anthroMeasNamesVec = fam:getMeasureNames();
	local maniNamesVec = fam:getManikinNames(); 
	
	
	for i = 0, fam:getNumManikins()-1 do

		local idealAngles = NumberVector();
		
		idealAngles:push_back(evaDriverHiptoEyeAngleFunction(i,maniNamesVec[i])); 
		idealAngles:push_back(evaDriverHeadAngleFunction(i,maniNamesVec[i]));
		idealAngles:push_back(evaDriverNeckAngleFunction(i,maniNamesVec[i]));
		idealAngles:push_back(evaDriverThoraxAngleFunction(i,maniNamesVec[i]));
		idealAngles:push_back(evaDriverAbdomenAngleFunction(i,maniNamesVec[i]));
		idealAngles:push_back(evaDriverPelvisAngleFunction(i,maniNamesVec[i]));
		idealAngles:push_back(evaDriverThighAngleFunction(i,maniNamesVec[i]));
		idealAngles:push_back(evaDriverKneeAngleFunction(i,maniNamesVec[i]));
	end			
	
	local idealHipToEye = NumberVector();
	local idealHeadAngle = NumberVector();
	local idealNeckAngle = NumberVector();
	local idealThoraxAngle = NumberVector();
	local idealAbdomenAngle = NumberVector();
	local idealPelvisAngle = NumberVector();
	local idealThighAngle = NumberVector();
	local idealKneeAngle = NumberVector();
	
	for i = 0, fam:getNumManikins()-1 do
		idealHipToEye:push_back(evaDriverHiptoEyeAngleFunction(i,maniNamesVec[i]));
		idealHeadAngle:push_back(evaDriverHeadAngleFunction(i,maniNamesVec[i]));
		idealNeckAngle:push_back(evaDriverNeckAngleFunction(i,maniNamesVec[i]));
		idealThoraxAngle:push_back(evaDriverThoraxAngleFunction(i,maniNamesVec[i]));
		idealAbdomenAngle:push_back(evaDriverAbdomenAngleFunction(i,maniNamesVec[i]));
		idealPelvisAngle:push_back(evaDriverPelvisAngleFunction(i,maniNamesVec[i]));
		idealThighAngle:push_back(evaDriverThighAngleFunction(i,maniNamesVec[i]));
		idealKneeAngle:push_back(evaDriverKneeAngleFunction(i,maniNamesVec[i]));
	end

	--For all checkpoints of steering wheel
	local staticRoot = Ips.getGeometryRoot();
	for i = 0, fam:getNumManikins()-1 do
		local geoGroup = Ips.createGeometryGroup(nil);
		geoGroup:setLabel('Manikin_'..tostring(i+1))
	end
	for i = 0, allpointsSteeringWheel:size()-1 do
		--Set the new steering wheel position
		-- transfSW['t'] = allpointsSteeringWheel[i];
		-- objectsRootSteeringWheel:setTControl(transfSW);
		
		--For all checkpoints of seat
		for j = 0, allpointsSeat:size()-1 do
			--Set the new seat position
			transfSae['t'] = allpointsSeat[j];
			objectsRootSae:setTControl(transfSae);
			--Ips.updateScreen();
			
				local matrixResults = {}
				for l = 0, allpointsAngleSeat:size()-1 do
				
					local posTreeObjTorso = objectsRoot:findFirstExactMatch(torsoNameInScene):toPositionedTreeObject(); 
					rotateActiveObjectOnOneAxis(posTreeObjTorso,"rx",0);
					rotateActiveObjectOnOneAxis(posTreeObjTorso,"rz",0);
					rotateActiveObjectOnOneAxis(posTreeObjTorso,"ry",allpointsAngleSeat[l]);

					--Execute sequence and set last frame when manikins are well attached
					opSeq:executeSequence(); -- It would be nice give a name to each sequence
					local opSeqTreeObj = procRoot:findFirstExactMatch('Operation Sequence 1');
					local timeline = opSeqTreeObj:getLastChild():toTimelineReplay();
					timeline:setTime(timeline:getFinalTime());
					Ips.updateScreen();
			
			--local beforeManikins = os.clock();
				--Manikin loop
					for k = 0, fam:getNumManikins()-1 do

						
						--local beforeGetAngles = os.clock();
						--Get angles from the manikins
						local angleValues = NumberVector();
						
						angleValues:push_back(getDriverHiptoEyeAngleFunction(k)); --0
						angleValues:push_back(getDriverHeadAngleFunction(k)); --1
						angleValues:push_back(getDriverNeckAngleFunction(k)); --2
						angleValues:push_back(getDriverThoraxAngleFunction(k)); --3
						angleValues:push_back(getDriverAbdomenAngleFunction(k)); --4
						angleValues:push_back(getDriverPelvisAngleFunction(k)); --5
						angleValues:push_back(getDriverThighAngleFunction(k)); --6
						angleValues:push_back(getDriverRightKneeAngleFunction(k)); --7	
						--local getAnglesTime = os.clock();
						--print(string.format("elapsed time getting angles: %.2f\n", getAnglesTime - beforeGetAngles));
				
						--Get evaluation of the angles against ideal and RMSE
						--local beforeEvaluatingAngles = os.clock();
						local notOkVec = NumberVector();
						notOkVec:push_back(eval(maniNamesVec[k], angleValues[0], idealHipToEye[k], 0));
						notOkVec:push_back(eval(maniNamesVec[k], angleValues[1], idealHeadAngle[k], 1));
						notOkVec:push_back(eval(maniNamesVec[k], angleValues[2], idealNeckAngle[k], 2));
						notOkVec:push_back(eval(maniNamesVec[k], angleValues[3], idealThoraxAngle[k], 3));
						notOkVec:push_back(eval(maniNamesVec[k], angleValues[4], idealAbdomenAngle[k], 4));
						notOkVec:push_back(eval(maniNamesVec[k], angleValues[5], idealPelvisAngle[k], 5));
						notOkVec:push_back(eval(maniNamesVec[k], angleValues[6], idealThighAngle[k], 6));
						notOkVec:push_back(eval(maniNamesVec[k], angleValues[7], idealKneeAngle[k], 7));
						--local evaluatingAnglesTime = os.clock();
						--print(string.format("elapsed time evaluating angles: %.2f\n", evaluatingAnglesTime - beforeEvaluatingAngles));
						
						--Calculate how many not okays there are for each manikin
						local notOkCount = 0;
						for iNotOkVec = 0, notOkVec:size()-1 do
							notOkCount = notOkCount + notOkVec[iNotOkVec];
						end
						local constraintCount = getAllDriverContraintCheck(k)
						local constraintAndNotOK = {constraintCount,notOkCount}
						
						print("Manikin "..tostring(k))
						
						if(l==0) then --if it is the first angle, it is the best result until now
							table.insert(matrixResults,constraintAndNotOK)
						else --If it is not, we start checking
							print("RESULT BEFORE. Constraint: "..tostring(matrixResults[k+1][1])..". Not OK: "..tostring(matrixResults[k+1][2]))
							if(constraintAndNotOK[1] < matrixResults[k+1][1]) then--if the new position violates less constraints, we take it
								matrixResults[k+1][1] = constraintAndNotOK[1];
								matrixResults[k+1][2] = constraintAndNotOK[2];
								print("Less constraints!");
							elseif((constraintAndNotOK[1] == matrixResults[k+1][1]) and (constraintAndNotOK[2] < matrixResults[k+1][2])) then --if the constraints are the same but the notOK-s are less, we take it
								matrixResults[k+1][1] = constraintAndNotOK[1];
								matrixResults[k+1][2] = constraintAndNotOK[2];
								print("Same constraints and less NOT OK!");
							end
						end
						
						
						print("Constraint: "..tostring(constraintAndNotOK[1])..". Not OK: "..tostring(constraintAndNotOK[2]))
						
						print("RESULT NOW. Constraint: "..tostring(matrixResults[k+1][1])..". Not OK: "..tostring(matrixResults[k+1][2]))

					end
					deleteRestOfTimelines();
				end
				--Create heatmap for all manikins pixel
				for k = 0, fam:getNumManikins()-1 do
					local groupGeometry = staticRoot:findFirstExactMatch('Manikin_'..tostring(k+1));
					local square = createEvaluatedSquare(transfSae, heatmapPointSize, matrixResults[k+1][2], matrixResults[k+1][1])
					Ips.moveTreeObject(square, groupGeometry)
					groupGeometry:setExpanded(false);
				end
			deleteRestOfTimelines();
		end
	end
	
	--Reset the position to the center one for better representation
	objectsRootSteeringWheel:setTControl(swControlCoor);
	objectsRootSae:setTControl(saeControlCoor);
	deleteRestOfTimelines();
	opSeq:executeSequence(); -- It would be nice give a name to each sequence
	local opSeqTreeObj = procRoot:findFirstExactMatch(opSeqNameInScene);
	local timeline = opSeqTreeObj:getLastChild():toTimelineReplay();
	timeline:setTime(timeline:getFinalTime());
	Ips.updateScreen();
	
	return str;
end