frameSizeAdjRange = 0.05;

function getAdjRange(adjType)
	-- *** DEFINE ADJUSTMENT RANGE ***
	-- *** Click on surface > get vertex/point coordinates ***
	objAdjRange = Ips.getGeometrySelection();
	filenameWRL = scriptPath.."/tempObjAdjRange.wrl"; -- Exports a temporary VRML/WRL file to read vertex points from.
	--filenameWRL = "Data/IMMA/VDtemp/objAdjRange.wrl"; -- Specific VDtemp folder that needs to be writeable!
	if (objAdjRange) then
		objAdjRange:exportToVRML(filenameWRL);
		-- Read the WRL file again and extracts vertex points of the geometry
		lines = {};
		notEnd = 0;
		adjRangePoints = {};
		startP = 0;
		lineNr = 0;
		translationAdjRange = {n=3}; translationAdjRange[1] = 0; translationAdjRange[2] = 0; translationAdjRange[3] = 0;
		for line in io.lines(filenameWRL) do 
			lines[#lines + 1] = line;
			if string.match(line,"translation") then
				translation = {n=3};
				translation.x, translation.y, translation.z = line:match("(%S+) (%S+) (%S+)");
				translationAdjRange[1] = tonumber(translation.x);
				translationAdjRange[2] = tonumber(translation.y);
				translationAdjRange[3] = tonumber(translation.z);
				print("Translation: X "..tostring(translationAdjRange[1])..", Y "..tostring(translationAdjRange[2])..", Z "..tostring(translationAdjRange[3]));
			elseif (line == "point [") then
				startP = #lines;
			elseif (#lines > startP) and (startP ~= 0) and (line ~= "]") and (notEnd == 0) then
				lineNr = #lines - startP;
				adjRangeCoord = {n=3};
				adjRangeCoord.x, adjRangeCoord.y, adjRangeCoord.z = line:match("(%S+) (%S+) (%S[^,]+)");
				adjRangePoints[lineNr] = {n=3};
				adjRangePoints[lineNr][1] = tonumber(adjRangeCoord.x);
				adjRangePoints[lineNr][2] = tonumber(adjRangeCoord.y);
				adjRangePoints[lineNr][3] = tonumber(adjRangeCoord.z);
				print("Point: X "..tostring(adjRangePoints[lineNr][1])..", Y "..tostring(adjRangePoints[lineNr][2])..", Z "..tostring(adjRangePoints[lineNr][3]));
			elseif (#lines > startP) and (line == "]") then
				notEnd = 1;
			end
		end
		-- Fix translation for all points
		tSize = table.getn(adjRangePoints);
		for i=1,tSize do 
			adjRangePoints[i][1] = adjRangePoints[i][1] + translationAdjRange[1];
			adjRangePoints[i][2] = adjRangePoints[i][2] + translationAdjRange[2];
			adjRangePoints[i][3] = adjRangePoints[i][3] + translationAdjRange[3];
		end
		
		-- *** Identify mid-point, corner points are min-max in each quadrant ***
		-- Calculates midpoint of the adjustment range
		midPointAdjRange = {n=3}; midPointAdjRange[1] = 0; midPointAdjRange[2] = 0; midPointAdjRange[3] = 0;
		for i=1,tSize do 
			midPointAdjRange[1] = midPointAdjRange[1] + adjRangePoints[i][1];
			midPointAdjRange[2] = midPointAdjRange[2] + adjRangePoints[i][2];
			midPointAdjRange[3] = midPointAdjRange[3] + adjRangePoints[i][3];
		end
		midPointAdjRange[1] = midPointAdjRange[1]/tSize;
		midPointAdjRange[2] = midPointAdjRange[2]/tSize;
		midPointAdjRange[3] = midPointAdjRange[3]/tSize;
		--print("MidPoint: X."..tostring(midPointAdjRange[1])..", Y."..tostring(midPointAdjRange[2])..", Z."..tostring(midPointAdjRange[3])); -- First instance but will changed when only calculated with corner points.

		quadPoints = {n=4};
		for i=1,4 do 
			quadPoints[i] = {n=3};
			quadPoints[i][1] = midPointAdjRange[1];
			quadPoints[i][2] = midPointAdjRange[2];
			quadPoints[i][3] = midPointAdjRange[3];
		end
		for i=1,tSize do 
			if (adjRangePoints[i][1] > midPointAdjRange[1]) and (adjRangePoints[i][3] > midPointAdjRange[3]) then -- Quadrant 1
				if (adjRangePoints[i][3] > quadPoints[1][3]) then
					quadPoints[1][1] = adjRangePoints[i][1];
					quadPoints[1][3] = adjRangePoints[i][3];
				end
			elseif (adjRangePoints[i][1] > midPointAdjRange[1]) and (adjRangePoints[i][3] < midPointAdjRange[3]) then -- Quadrant 2
				if (adjRangePoints[i][3] < quadPoints[2][3]) then
					quadPoints[2][1] = adjRangePoints[i][1];
					quadPoints[2][3] = adjRangePoints[i][3];
				end
			elseif (adjRangePoints[i][1] < midPointAdjRange[1]) and (adjRangePoints[i][3] < midPointAdjRange[3]) then -- Quadrant 3
				if (adjRangePoints[i][3] < quadPoints[3][3]) then
					quadPoints[3][1] = adjRangePoints[i][1];
					quadPoints[3][3] = adjRangePoints[i][3];
				end
			elseif (adjRangePoints[i][1] < midPointAdjRange[1]) and (adjRangePoints[i][3] > midPointAdjRange[3]) then -- Quadrant 4
				if (adjRangePoints[i][3] > quadPoints[4][3]) then
					quadPoints[4][1] = adjRangePoints[i][1];
					quadPoints[4][3] = adjRangePoints[i][3];
				end
			end
		end
		-- Recalculate midpoint with corner points only.
		midPointAdjRange[1] = (quadPoints[1][1]+quadPoints[2][1]+quadPoints[3][1]+quadPoints[4][1])/4; 
		midPointAdjRange[3] = (quadPoints[1][3]+quadPoints[2][3]+quadPoints[3][3]+quadPoints[4][3])/4;
		print("MidPoint: X."..tostring(midPointAdjRange[1])..", Y."..tostring(midPointAdjRange[2])..", Z."..tostring(midPointAdjRange[3]));
		
		if (adjType == "SW") then
			print("Steering wheel adjustment range is recorded and corner points saved for furher use.");
		else
			print("Seat adjustment range is recorded and corner points saved for furher use.");
		end
		print("QUAD POINTS")
		print(quadPoints[1][1])--point1 X
		print(quadPoints[1][2])--point1 Y
		print(quadPoints[1][3])--point1 Z
		
		print(quadPoints[2][1])--point2 X
		print(quadPoints[2][2])--point2 Y
		print(quadPoints[2][3])--point2 Z
		
		print(quadPoints[3][1])--point3 X
		print(quadPoints[3][2])--point3 Y
		print(quadPoints[3][3])--point3 Z
		return quadPoints;
	else
		Ips.alert("No geometry selected"); -- Error message and break script
	end
end

function setSWrange(quadPoints) -- Search if the specific grip exist, if not then create and add positional and size adjustment.
	yAngle = math.deg(math.atan((quadPoints[1][3]-quadPoints[2][3])/(quadPoints[1][1]-quadPoints[2][1])));
	print("yAngle: "..tostring(yAngle));
	lengthAR = math.sqrt((quadPoints[1][1] - quadPoints[4][1])^2 + (quadPoints[1][3] - quadPoints[4][3])^2);
	heightAR = math.sqrt((quadPoints[1][1] - quadPoints[2][1])^2 + (quadPoints[1][3] - quadPoints[2][3])^2);
	print("Length: "..tostring(lengthAR).."; Height: "..tostring(heightAR));
	
	attachMidPoint = {n=3};
	attachMidPoint[1] = (quadPoints[1][1]+quadPoints[2][1]+quadPoints[3][1]+quadPoints[4][1])/4;
	attachMidPoint[2] = quadPoints[1][2];
	attachMidPoint[3] = (quadPoints[1][3]+quadPoints[2][3]+quadPoints[3][3]+quadPoints[4][3])/4;
		
	root = Ips.getActiveObjectsRoot();
	--We will just name the root as object, since we will iterate through objects
	obj = root;
	gripFound = nil;
	simController = ManikinSimulationController();
	--We will now iterate looking for grip, and not leave until we find the right one
	while (not(obj == nil) and (gripFound == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "GripPoint") and (obj:getLabel() == "DPP_rSWGrip") then
			print("Found a grip point");
			gripFound = 1;
			gripVis = obj:toGripPointVisualization();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end
	if gripFound == nil then -- Need to create the grip first
		rSwGP = simController:createGripPoint(); -- Right Steering Wheel Grip Point
		-- rSwGP:setGripConfiguration("Diagonal Power Grip"); Can´t be used due to rotational offset
		--rSwGP:setHand(1);
		rSwGPVis = rSwGP:getVisualization();
		rSwGPVis:setLabel("DPP_rSWGrip");
		rSwGP:setGripClosure(0.55);		
		rSwGP:setSymmetricRotationTolerances(0.785398163,0.785398163,0.785398163);
		rSwGP:setSymmetricTranslationTolerances(heightAR/2,0,lengthAR/2);
		trans = rSwGPVis:getTControl();
		trans["tx"] = attachMidPoint[1];
		trans["ty"] = attachMidPoint[2];
		trans["tz"] = attachMidPoint[3];
		-- Rotate the right grip Steering wheel angle + 180 degrees.
		set(trans, 'R.r1', Vector3d(math.cos(math.rad(yAngle)), 0, math.sin(math.rad(yAngle))));
		set(trans, 'R.r2', Vector3d(0, -1, 0));
		set(trans, 'R.r3', Vector3d(math.sin(math.rad(yAngle)), 0, -math.cos(math.rad(yAngle))));
		rSwGPVis:setTControl(trans);
	else
		trans = gripVis:getTControl();
		trans["tx"] = attachMidPoint[1];
		trans["tz"] = attachMidPoint[3];
		-- Rotate the right grip Steering wheel angle + 180 degrees.
		set(trans, 'R.r1', Vector3d(math.cos(math.rad(yAngle)), 0, math.sin(math.rad(yAngle))));
		set(trans, 'R.r2', Vector3d(0, -1, 0));
		set(trans, 'R.r3', Vector3d(math.sin(math.rad(yAngle)), 0, -math.cos(math.rad(yAngle))));
		gripVis:setTControl(trans);
		rSwGP = gripVis:getGripPoint();
		rSwGP:setSymmetricTranslationTolerances(heightAR/2,0,lengthAR/2);
	end
			
	--We will just name the root as object, since we will iterate through objects
	obj = root;
	gripFound = nil;
	--We will now iterate looking for grip, and not leave until we find the right one
	while (not(obj == nil) and (gripFound == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "GripPoint") and (obj:getLabel() == "DPP_lSWGrip") then
			print("Found a grip point");
			gripFound = 1;
			gripVis = obj:toGripPointVisualization();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end
	if gripFound == nil then -- Need to create the grip first
		lSwGP = simController:createGripPoint(); -- Left Steering Wheel Grip Point
		-- lSwGP:setGripConfiguration("Diagonal Power Grip"); Can´t be used due to rotational offset
		lSwGP:setHand(0);
		lSwGPVis = lSwGP:getVisualization();
		lSwGPVis:setLabel("DPP_lSWGrip");
		lSwGP:setGripClosure(0.55);	
		lSwGP:setSymmetricRotationTolerances(0.785398163,0.785398163,0.785398163);
		lSwGP:setSymmetricTranslationTolerances(heightAR/2,0,lengthAR/2);
		trans = lSwGPVis:getTControl();
		trans["tx"] = attachMidPoint[1];
		trans["ty"] = attachMidPoint[2];
		trans["tz"] = attachMidPoint[3];
		-- Rotate the left grip Steering wheel angle.
		set(trans, 'R.r1', Vector3d(-math.cos(math.rad(yAngle)), 0, math.sin(math.rad(yAngle))));
		set(trans, 'R.r2', Vector3d(0, 1, 0));
		set(trans, 'R.r3', Vector3d(-math.sin(math.rad(yAngle)), 0, -math.cos(math.rad(yAngle))));
		lSwGPVis:setTControl(trans);		
	else
		trans = gripVis:getTControl();
		trans["tx"] = attachMidPoint[1];
		trans["tz"] = attachMidPoint[3];
		-- Rotate the left grip Steering wheel angle.
		set(trans, 'R.r1', Vector3d(-math.cos(math.rad(yAngle)), 0, math.sin(math.rad(yAngle))));
		set(trans, 'R.r2', Vector3d(0, 1, 0));
		set(trans, 'R.r3', Vector3d(-math.sin(math.rad(yAngle)), 0, -math.cos(math.rad(yAngle))));
		gripVis:setTControl(trans);
		--rotateActiveObjectOnOneAxis(gripVis, true, true, true, -180, yAngle, -180);  --- ROTATEFIX
		lSwGP = gripVis:getGripPoint();
		lSwGP:setSymmetricTranslationTolerances(heightAR/2,0,lengthAR/2);
	end
end

function getGeoSize()
	swThickness = 30;
	-- *** DEFINE ADJUSTMENT RANGE ***
	-- *** Click on surface > get vertex/point coordinates ***
	objSelected = Ips.getGeometrySelection();
	--filenameWRL = "tempObjAdjRange.wrl"; -- Exports a temporary VRML/WRL file to read vertex points from.
	--filenameWRL = "Data/IMMA/VDtemp/objAdjRange.wrl"; -- Specific VDtemp folder that needs to be writeable!
	if (objSelected) then
		local geoBoundingBox = objSelected:getBoundingBox();
		local transSelected = objSelected:getTControl();
				
		--5- get length, width, height, 
		-- local length = swBoundingBox.xmax-swBoundingBox.xmin
		local geoWidth = geoBoundingBox.ymax-geoBoundingBox.ymin;
		local yMidPoint = (geoBoundingBox.ymax+geoBoundingBox.ymin)/2;
		local xMidPoint = (geoBoundingBox.xmax+geoBoundingBox.xmin)/2;
		local zMidPoint = (geoBoundingBox.zmax+geoBoundingBox.zmin)/2;
		print("Geometry width: "..tostring(geoWidth)); 
		print("Y mid point: "..tostring(yMidPoint)); 		
		
		root = Ips.getActiveObjectsRoot();
		--We will just name the root as object, since we will iterate through objects
		obj = root;
		gripFound = nil;
		simController = ManikinSimulationController();
		--We will now iterate looking for grip, and not leave until we find the right one
		while (not(obj == nil) and (gripFound == nil)) do
			--If the object we are looking at now is a attachment group then let's read it	
			if (obj:getType() == "GripPoint") and (obj:getLabel() == "DPP_rSWGrip") then
				print("Found a grip point");
				gripFound = 1;
				gripVis = obj:toGripPointVisualization();
			end
			--In case we didn't find it, we go to the object below and continue searching
			obj = obj:getObjectBelow();
		end
		if gripFound == nil then -- Need to create the grip first
			rSwGP = simController:createGripPoint(); -- Right Steering Wheel Grip Point
			--rSwGP:setGripConfiguration("Diagonal Power Grip"); Can´t be used due to rotational offset
			--rSwGP:setHand(1);
			rSwGPVis = rSwGP:getVisualization();
			rSwGPVis:setLabel("DPP_rSWGrip");
			rSwGP:setGripClosure(0.55);
			rSwGP:setSymmetricRotationTolerances(0.785398163,0.785398163,0.785398163);
			trans = rSwGPVis:getTControl();
			trans["tx"] = xMidPoint;
			trans["ty"] = yMidPoint + geoWidth/2 - (swThickness/1000)/2;
			trans["tz"] = zMidPoint;
			-- Rotate the right grip Steering wheel angle + 180 degrees.
			set(trans, 'R.r1', Vector3d(get(transSelected, 'R.r1.x'), 0, -1*get(transSelected, 'R.r1.z')));
			set(trans, 'R.r2', Vector3d(0, -1, 0));
			set(trans, 'R.r3', Vector3d(get(transSelected, 'R.r3.x'), 0, -1*get(transSelected, 'R.r3.z')));
			rSwGPVis:setTControl(trans);
		else
			trans = gripVis:getTControl();
			trans["ty"] = yMidPoint + geoWidth/2 - (swThickness/1000)/2;
			gripVis:setTControl(trans);
		end
				
		--We will just name the root as object, since we will iterate through objects
		obj = root;
		gripFound = nil;
		--We will now iterate looking for grip, and not leave until we find the right one
		while (not(obj == nil) and (gripFound == nil)) do
			--If the object we are looking at now is a attachment group then let's read it	
			if (obj:getType() == "GripPoint") and (obj:getLabel() == "DPP_lSWGrip") then
				print("Found a grip point");
				gripFound = 1;
				gripVis = obj:toGripPointVisualization();
			end
			--In case we didn't find it, we go to the object below and continue searching
			obj = obj:getObjectBelow();
		end
		if gripFound == nil then -- Need to create the grip first
			lSwGP = simController:createGripPoint(); -- Left Steering Wheel Grip Point
			--lSwGP:setGripConfiguration("Diagonal Power Grip"); Can´t be used due to rotational offset
			lSwGP:setHand(0);
			lSwGPVis = lSwGP:getVisualization();
			lSwGPVis:setLabel("DPP_lSWGrip");
			lSwGP:setGripClosure(0.55);
			lSwGP:setSymmetricRotationTolerances(0.785398163,0.785398163,0.785398163);
			trans = lSwGPVis:getTControl();
			trans["tx"] = xMidPoint;
			trans["ty"] = yMidPoint - geoWidth/2 + (swThickness/1000)/2;
			trans["tz"] = zMidPoint;
			-- Rotate the left grip Steering wheel angle.
			set(trans, 'R.r1', Vector3d(-1*get(transSelected, 'R.r1.x'), 0, -1*get(transSelected, 'R.r1.z')));
			set(trans, 'R.r2', Vector3d(0, 1, 0));
			set(trans, 'R.r3', Vector3d(-1*get(transSelected, 'R.r3.x'), 0, -1*get(transSelected, 'R.r3.z')));		
			lSwGPVis:setTControl(trans);
		else
			trans = gripVis:getTControl();
			trans["ty"] = yMidPoint - geoWidth/2 + (swThickness/1000)/2;
			gripVis:setTControl(trans);
		end
	else
		Ips.alert("No geometry selected"); -- Error message and break script
	end
end

function setAPSettings(quadPoints)
	--Call the simulation controller and save it in simController to use it faster
	simController = ManikinSimulationController();
	
	seatAttachName = "DPP_DriverSeat";
	simController:createAttachGroupFromPrototype(seatAttachName, "Driving Seat");
	--simController:createAttachPointFromPrototype(seatAttachName, "Hip-Centre Seated");
	
	root = Ips.getActiveObjectsRoot();
	--We will just name the root as object, since we will iterate through objects
	obj = root;
	--Let's create a variable to store our seat attachment group
	seatGroup = nil;
	--We will now iterate looking for attachment groups, and not leave until we find the right one
	while (not(obj == nil) and (seatGroup == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "AttachGroup") and (obj:getLabel() == seatAttachName) then
			print("Found an attachment group");
			seatGroup = 1;
			posSeatObj = obj:toPositionedTreeObject();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end
	xDeltaAvg = 21; -- Millimeter avg difference between H-point and Mid-hip joint
	zDeltaAvg = -1; -- Millimeter avg difference between H-point and Mid-hip joint
	
	
	trans = posSeatObj:getTWorld();
	attachMidPoint = {n=3};
	attachMidPoint[1] = (quadPoints[1][1]+quadPoints[2][1]+quadPoints[3][1]+quadPoints[4][1])/4;
	attachMidPoint[2] = quadPoints[1][2];
	attachMidPoint[3] = (quadPoints[1][3]+quadPoints[2][3]+quadPoints[3][3]+quadPoints[4][3])/4;
	trans["tx"] = tonumber(string.format("%.3f", attachMidPoint[1]-xDeltaAvg/1000));
	trans["ty"] = attachMidPoint[2];
	trans["tz"] = tonumber(string.format("%.3f", attachMidPoint[3]-zDeltaAvg/1000));
	yAngle = math.deg(math.atan((quadPoints[1][3]-quadPoints[4][3])/(quadPoints[1][1]-quadPoints[4][1])));
	print("yAngle: "..tostring(yAngle));
	set(trans, 'R.r1', Vector3d(-math.cos(math.rad(yAngle)), 0, -math.sin(math.rad(yAngle))));
	set(trans, 'R.r2', Vector3d(0, -1, 0));
	set(trans, 'R.r3', Vector3d(-math.sin(math.rad(yAngle)), 0, math.cos(math.rad(yAngle))));
	posSeatObj:setTWorld(trans);
	
	mAR = (quadPoints[4][3]-quadPoints[1][3])/(quadPoints[4][1]-quadPoints[1][1]); -- y = mx + c;
	cAR = quadPoints[1][3] - mAR*quadPoints[1][1]; -- y = mx + c; Could be adjusted with a specific compression ratio calculated from BMI "+(compressRatio*BMI)"
	perAngle = yAngle+90; -- Perpendicular angle to the buttock line.
	mARP = math.tan(math.rad(perAngle)); -- y = mx + c;
	cARP = quadPoints[2][3] - mARP*quadPoints[2][1]; -- y = mx + c; Could be adjusted with a specific compression ratio calculated from BMI "+(compressRatio*BMI)" Maybe also add seat characteristics
	x0 = (cARP-cAR)/(mAR-mARP); -- X coordinate for intersection point
	z0 = (cAR*mARP-cARP*mAR)/(mARP-mAR); -- Z coordinate for intersection point
	print("x0: "..tostring(x0).."; z0: "..tostring(z0));
	lengthAR = math.sqrt((x0 - quadPoints[4][1])^2 + (z0 - quadPoints[4][3])^2);
	heightAR = math.sqrt((x0 - quadPoints[2][1])^2 + (z0 - quadPoints[2][3])^2);
	print("Length: "..tostring(lengthAR).."; Height: "..tostring(heightAR));
	hipCentre = obj;
	xDeltaRange = 29; -- Millimeter max-min difference between H-point and Mid-hip joint
	zDeltaRange = 13; -- Millimeter max-min difference between H-point and Mid-hip joint
	--print(hipCentre:getType());
	if (hipCentre:isAttachPointVisualization()) then
		--Move to visualization
		local attachPointVis = obj:toAttachPointVisualization();
		hipCentreAP = attachPointVis:getAttachPoint();
		hipCentreAP:setSymmetricTranslationTolerances(tonumber(string.format("%.3f", lengthAR/2+xDeltaRange/2000)),0,tonumber(string.format("%.3f", heightAR/2+zDeltaRange/2000)));
		
		obj = obj:getObjectBelow(); obj = obj:getObjectBelow(); -- Goes down two steps in tree structure. Should be fixed to a more robust solution. 
		if (obj:isAttachPointVisualization()) then
			posTreeObj = obj:toPositionedTreeObject();
			trans = posTreeObj:getTWorld();
			set(trans, 'R.r1', Vector3d(-math.cos(math.rad(yAngle+90)), 0, -math.sin(math.rad(yAngle+90))));
			set(trans, 'R.r2', Vector3d(0, -1, 0));
			set(trans, 'R.r3', Vector3d(-math.sin(math.rad(yAngle+90)), 0, math.cos(math.rad(yAngle+90))));
			posTreeObj:setTWorld(trans);
		end
	end
end

function getFloorGeo()
		-- *** Click on surface > get vertex/point coordinates ***
	objSelected = Ips.getGeometrySelection();
		
	if (objSelected) then --More simple way and relative robust if the floor is in one flat piece
		local geoBoundingBox = objSelected:getBoundingBox();
		--5- get length, width, height, 
		-- local length = swBoundingBox.xmax-swBoundingBox.xmin
		geoMidPoint = {n=3}; 
		geoMidPoint[1] = (geoBoundingBox.xmax+geoBoundingBox.xmin)/2;
		geoMidPoint[2] = (geoBoundingBox.ymax+geoBoundingBox.ymin)/2;
		geoMidPoint[3] = (geoBoundingBox.zmax+geoBoundingBox.zmin)/2;
		return geoMidPoint;	
	else
		Ips.alert("No geometry selected"); -- Error message and break script
	end
end

function setFloor(geoMidPoint)
	--Call the simulation controller and save it in simController to use it faster
	simController = ManikinSimulationController();
	
	seatAttachName = "DPP_DriverFeet";
	simController:createAttachGroupFromPrototype(seatAttachName, "Driving Feet");
	--simController:createAttachPointFromPrototype(seatAttachName, "Hip-Centre Seated");
	
	root = Ips.getActiveObjectsRoot();
	--We will just name the root as object, since we will iterate through objects
	obj = root;
	--Let's create a variable to store our seat attachment group
	feetGroup = nil;
	--We will now iterate looking for attachment groups, and not leave until we find the right one
	while (not(obj == nil) and (feetGroup == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "AttachGroup") and (obj:getLabel() == seatAttachName) then
			print("Found an attachment group");
			feetGroup = 1;
			posObj_Feet = obj:toPositionedTreeObject();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end
		-- Set transformation
	T1 = Transf3.newIdentity();
	set(T1, 't', Vector3d(geoMidPoint[1], geoMidPoint[2], geoMidPoint[3]));
	set(T1, 'R.r1', Vector3d(-1, 0, 0));
	set(T1, 'R.r2', Vector3d(0, -1, 0));
	set(T1, 'R.r3', Vector3d(0, 0, 1));
	posObj_Feet:setTWorld(T1);
	
	feetBOFAngle = 30;
	obj = obj:getObjectBelow(); obj = obj:getObjectBelow(); -- Goes down two steps in tree structure. Should be fixed to a more robust solution. 
	if (obj:isAttachPointVisualization()) then
		posTreeObj = obj:toPositionedTreeObject();
		trans = posTreeObj:getTWorld();
		set(trans, 'R.r1', Vector3d(-math.cos(math.rad(feetBOFAngle-90)), 0, -math.sin(math.rad(feetBOFAngle-90))));
		set(trans, 'R.r2', Vector3d(0, -1, 0));
		set(trans, 'R.r3', Vector3d(-math.sin(math.rad(feetBOFAngle-90)), 0, math.cos(math.rad(feetBOFAngle-90))));
		posTreeObj:setTWorld(trans);
	end
	obj = obj:getObjectBelow(); obj = obj:getObjectBelow(); obj = obj:getObjectBelow(); -- Goes down three steps in tree structure. Should be fixed to a more robust solution. 
	if (obj:isAttachPointVisualization()) then
		posTreeObj = obj:toPositionedTreeObject();
		trans = posTreeObj:getTWorld();
		set(trans, 'R.r1', Vector3d(-math.cos(math.rad(feetBOFAngle-90)), 0, -math.sin(math.rad(feetBOFAngle-90))));
		set(trans, 'R.r2', Vector3d(0, -1, 0));
		set(trans, 'R.r3', Vector3d(-math.sin(math.rad(feetBOFAngle-90)), 0, math.cos(math.rad(feetBOFAngle-90))));
		posTreeObj:setTWorld(trans);
	end
end



