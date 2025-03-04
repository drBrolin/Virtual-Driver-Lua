frameSizeAdjRange = 0.05;

function getAdjRange(adjType)
	-- *** DEFINE ADJUSTMENT RANGE ***
	-- *** Click on surface > get vertex/point coordinates ***
	objAdjRange = Ips.getGeometrySelection();
	filenameWRL = "tempObjAdjRange.wrl"; -- Exports a temporary VRML/WRL file to read vertex points from.
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
			print("Steering wheel adjustment range is recorded and control frames generated");
		else
			print("Seat adjustment range is recorded and control frames generated");
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


function rotateActiveObjectOnOneAxis(posTreeObj, rxrot, ryrot, rzrot, valuerx, valuery, valuerz) --PositionedTreeObject | true/false true/false true/false | value in Euler for x, y, z

	--Get that object and the TControl of it. Change if TWorld is needed, or TParent. Change lower down in function also when it gets set
	local objectsRoot = Ips.getActiveObjectsRoot();
	local objTControl = posTreeObj:getTControl();
	
	--Magic to convert rotation matrix into euler angles
	local r1x = objTControl["r1x"];
	local r2x = objTControl["r2x"];
	local r3x = objTControl["r3x"];
	local r1y = objTControl["r1y"];
	local r2y = objTControl["r2y"];
	local r3y = objTControl["r3y"];
	local r1z = objTControl["r1z"];
	local r2z = objTControl["r2z"];
	local r3z = objTControl["r3z"];
	local pi= 3.14159265359;
	local yaw, pitch, roll
	local rotation_matrix = {{r1x, r1y, r1z}, {r2x, r2y, r2z}, {r3x, r3y, r3z}}
	if rotation_matrix[3][1] ~= 1 and rotation_matrix[3][1] ~= -1 then
	pitch = -math.asin(rotation_matrix[3][1])
	yaw = math.atan2(rotation_matrix[3][2] / math.cos(pitch), rotation_matrix[3][3] / math.cos(pitch))
	roll = math.atan2(rotation_matrix[2][1] / math.cos(pitch), rotation_matrix[1][1] / math.cos(pitch))
	else
	roll = 0
	if rotation_matrix[3][1] == -1 then
	  pitch = math.pi / 2
	  yaw = roll + math.atan2(rotation_matrix[1][2], rotation_matrix[1][3])
	else
	  pitch = -math.pi / 2
	  yaw = -roll + math.atan2(-rotation_matrix[1][2], -rotation_matrix[1][3])
	end
	end
	local rx = roll;
	local ry = pitch;
	local rz = yaw;


	--Rotate the object
	if(rxrot) then
		rx = math.rad(valuerx);
	end
	if(ryrot) then
		ry = math.rad(valuery);
	end
	if(rzrot) then
		rz = math.rad(valuerz);
	end

	--Get back the rotation matrix
	local c1 = math.cos(rx)
	local s1 = math.sin(rx)
	local c2 = math.cos(ry)
	local s2 = math.sin(ry)
	local c3 = math.cos(rz)
	local s3 = math.sin(rz)
	local r1x = c2 * c3
	local r1y = -c2 * s3
	local r1z = s2
	local r2x = c1 * s3 + c3 * s1 * s2
	local r2y = c1 * c3 - s1 * s2 * s3
	local r2z = -c2 * s1
	local r3x = s1 * s3 - c1 * c3 * s2
	local r3y = c3 * s1 + c1 * s2 * s3
	local r3z = c1 * c2
	objTControl["r1x"] = r1x;
	objTControl["r2x"] = r2x;
	objTControl["r3x"] = r3x;
	objTControl["r1y"] = r1y;
	objTControl["r2y"] = r2y;
	objTControl["r3y"] = r3y;
	objTControl["r1z"] = r1z;
	objTControl["r2z"] = r2z;
	objTControl["r3z"] = r3z;

	posTreeObj:setTControl(objTControl);
end


function setSWrange(quadPoints) -- Search if the specific grip exist, if not then create and add positional and size adjustment.
	
	simController = ManikinSimulationController();
	--Simple creation of grip point, and storing it in a var
	rSwGP = simController:createGripPoint(); -- Right Steering Wheel Grip Point
	rSwGP:setGripConfiguration("Diagonal Power Grip");
	rSwGP:setSymmetricRotationTolerances(0.785398163,0.785398163,0.785398163);
	rSwGPVis = rSwGP:getVisualization();
	rSwGPVis:setLabel("DPP_rSWGrip");
	
	trans = rSwGPVis:getTWorld();
	attachMidPoint = {n=3};
	attachMidPoint[1] = (quadPoints[1][1]+quadPoints[2][1]+quadPoints[3][1]+quadPoints[4][1])/4;
	attachMidPoint[2] = quadPoints[1][2];
	attachMidPoint[3] = (quadPoints[1][3]+quadPoints[2][3]+quadPoints[3][3]+quadPoints[4][3])/4;
	trans["tx"] = attachMidPoint[1];
	trans["ty"] = attachMidPoint[2]-0.03;
	trans["tz"] = attachMidPoint[3]-0.07;
	rSwGPVis:setTWorld(trans);
	
	yAngle = math.deg(math.atan((quadPoints[1][3]-quadPoints[2][3])/(quadPoints[1][1]-quadPoints[2][1])));
	print("yAngle: "..tostring(yAngle));
	rotateActiveObjectOnOneAxis(rSwGPVis, true, true, true, -180, yAngle, 0);
	lengthAR = math.sqrt((quadPoints[1][1] - quadPoints[4][1])^2 + (quadPoints[1][3] - quadPoints[4][3])^2);
	heightAR = math.sqrt((quadPoints[1][1] - quadPoints[2][1])^2 + (quadPoints[1][3] - quadPoints[2][3])^2);
	print("Length: "..tostring(lengthAR).."; Height: "..tostring(heightAR));
	rSwGP:setSymmetricTranslationTolerances(heightAR/2,0,lengthAR/2);
	
	lSwGP = simController:createGripPoint(); -- Left Steering Wheel Grip Point
	lSwGP:setGripConfiguration("Diagonal Power Grip");
	lSwGP:setHand(0);
	lSwGP:setSymmetricRotationTolerances(0.785398163,0.785398163,0.785398163);
	lSwGPVis = lSwGP:getVisualization();
	lSwGPVis:setLabel("DPP_lSWGrip");
	
	trans = lSwGPVis:getTWorld();
	trans["tx"] = attachMidPoint[1];
	trans["ty"] = attachMidPoint[2]-0.03;
	trans["tz"] = attachMidPoint[3]-0.07;
	lSwGPVis:setTWorld(trans);
	
	yAngle = math.deg(math.atan((quadPoints[1][3]-quadPoints[2][3])/(quadPoints[1][1]-quadPoints[2][1])));
	print("yAngle: "..tostring(yAngle));
	rotateActiveObjectOnOneAxis(lSwGPVis, true, true, true, -180, yAngle, -180);
	print("Length: "..tostring(lengthAR).."; Height: "..tostring(heightAR));
	lSwGP:setSymmetricTranslationTolerances(heightAR/2,0,lengthAR/2);
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
		--5- get length, width, height, 
		-- local length = swBoundingBox.xmax-swBoundingBox.xmin
		local geoWidth = geoBoundingBox.ymax-geoBoundingBox.ymin;
		local yMidPoint = (geoBoundingBox.ymax+geoBoundingBox.ymin)/2
		print("Geometry width: "..tostring(geoWidth)); 
		print("Y mid point: "..tostring(yMidPoint)); 
		--Ips.alert("Geometry width calculated"); -- Error message and break script

		root = Ips.getActiveObjectsRoot();
		--We will just name the root as object, since we will iterate through objects
		obj = root;
		--Let's create a variable to store our seat attachment group
		gripFound = nil;
		--We will now iterate looking for attachment groups, and not leave until we find the right one
		while (not(obj == nil) and (gripFound == nil)) do
			--If the object we are looking at now is a attachment group then let's read it	
			if (obj:getType() == "GripPoint") and (obj:getLabel() == "DPP_rSWGrip") then
				print("Found a grip point");
				gripFound = 1;
				posTreeObj = obj:toPositionedTreeObject();
			end
			--In case we didn't find it, we go to the object below and continue searching
			obj = obj:getObjectBelow();
		end
		trans = posTreeObj:getTWorld();
		trans["ty"] = yMidPoint + geoWidth/2 - (swThickness/1000)/2+0.03;
		print("Width: "..tostring(yMidPoint + geoWidth/2-(swThickness/1000)/2));
		posTreeObj:setTWorld(trans);
		
		--We will just name the root as object, since we will iterate through objects
		obj = root;
		--Let's create a variable to store our seat attachment group
		gripFound = nil;
		--We will now iterate looking for attachment groups, and not leave until we find the right one
		while (not(obj == nil) and (gripFound == nil)) do
			--If the object we are looking at now is a attachment group then let's read it	
			if (obj:getType() == "GripPoint") and (obj:getLabel() == "DPP_lSWGrip") then
				print("Found a grip point");
				gripFound = 1;
				posTreeObj = obj:toPositionedTreeObject();
			end
			--In case we didn't find it, we go to the object below and continue searching
			obj = obj:getObjectBelow();
		end
		trans = posTreeObj:getTWorld();
		trans["ty"] = yMidPoint - geoWidth/2 + (swThickness/1000)/2-0.03;
		print("Width: "..tostring(yMidPoint + geoWidth/2-(swThickness/1000)/2));
		posTreeObj:setTWorld(trans);
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
			posTreeObj = obj:toPositionedTreeObject();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end
	xDeltaAvg = 21; -- Millimeter avg difference between H-point and Mid-hip joint
	zDeltaAvg = -1; -- Millimeter avg difference between H-point and Mid-hip joint
	
	
	trans = posTreeObj:getTWorld();
	attachMidPoint = {n=3};
	attachMidPoint[1] = (quadPoints[1][1]+quadPoints[2][1]+quadPoints[3][1]+quadPoints[4][1])/4;
	attachMidPoint[2] = quadPoints[1][2];
	attachMidPoint[3] = (quadPoints[1][3]+quadPoints[2][3]+quadPoints[3][3]+quadPoints[4][3])/4;
	trans["tx"] = tonumber(string.format("%.3f", attachMidPoint[1]-xDeltaAvg/1000));
	trans["ty"] = attachMidPoint[2];
	trans["tz"] = tonumber(string.format("%.3f", attachMidPoint[3]-zDeltaAvg/1000));


	posTreeObj:setTWorld(trans);
	yAngle = math.deg(math.atan((quadPoints[1][3]-quadPoints[4][3])/(quadPoints[1][1]-quadPoints[4][1])));
	print("yAngle: "..tostring(yAngle));
	rotateActiveObjectOnOneAxis(posTreeObj, false, true, true, 0, -1*yAngle, 180);
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
	print(hipCentre:getType());
	if (hipCentre:isAttachPointVisualization()) then
		--Move to visualization
		local attachPointVis = obj:toAttachPointVisualization();
		hipCentreAP = attachPointVis:getAttachPoint();
		hipCentreAP:setSymmetricTranslationTolerances(tonumber(string.format("%.3f", lengthAR/2+xDeltaRange/2000)),0,tonumber(string.format("%.3f", heightAR/2+zDeltaRange/2000)));
	end
end

function getFloorGeo()
		-- *** Click on surface > get vertex/point coordinates ***

	objSelected = Ips.getGeometrySelection();
	-- filenameWRL = "tempObjAdjRange.wrl"; -- Exports a temporary VRML/WRL file to read vertex points from.
	-- --filenameWRL = "Data/IMMA/VDtemp/objAdjRange.wrl"; -- Specific VDtemp folder that needs to be writeable!
	-- if (objSelected) then
		-- objSelected:exportToVRML(filenameWRL);
		-- -- Read the WRL file again and extracts vertex points of the geometry
		-- lines = {};
		-- notEnd = 0;
		-- geoPoints = {};
		-- startP = 0;
		-- lineNr = 0;
		-- geoTranslation = {n=3}; geoTranslation[1] = 0; geoTranslation[2] = 0; geoTranslation[3] = 0;
		-- for line in io.lines(filenameWRL) do 
			-- lines[#lines + 1] = line;
			-- if string.match(line,"translation") then
				-- translation = {n=3};
				-- translation.x, translation.y, translation.z = line:match("(%S+) (%S+) (%S+)");
				-- geoTranslation[1] = tonumber(translation.x);
				-- geoTranslation[2] = tonumber(translation.y);
				-- geoTranslation[3] = tonumber(translation.z);
				-- print("Translation: X "..tostring(geoTranslation[1])..", Y "..tostring(geoTranslation[2])..", Z "..tostring(geoTranslation[3]));
			-- elseif (line == "point [") then
				-- startP = #lines;
			-- elseif (#lines > startP) and (startP ~= 0) and (line ~= "]") and (notEnd == 0) then
				-- lineNr = #lines - startP;
				-- geoCoord = {n=3};
				-- geoCoord.x, geoCoord.y, geoCoord.z = line:match("(%S+) (%S+) (%S[^,]+)");
				-- geoPoints[lineNr] = {n=3};
				-- geoPoints[lineNr][1] = tonumber(geoCoord.x);
				-- geoPoints[lineNr][2] = tonumber(geoCoord.y);
				-- geoPoints[lineNr][3] = tonumber(geoCoord.z);
				-- print("Point: X "..tostring(geoPoints[lineNr][1])..", Y "..tostring(geoPoints[lineNr][2])..", Z "..tostring(geoPoints[lineNr][3]));
			-- elseif (#lines > startP) and (line == "]") then
				-- notEnd = 1;
			-- end
		-- end
		-- -- Fix translation for all points
		-- tSize = table.getn(geoPoints);
		-- for i=1,tSize do 
			-- geoPoints[i][1] = geoPoints[i][1] + geoTranslation[1];
			-- geoPoints[i][2] = geoPoints[i][2] + geoTranslation[2];
			-- geoPoints[i][3] = geoPoints[i][3] + geoTranslation[3];
		-- end
		
		-- -- *** Identify mid-point, corner points are min-max in each quadrant ***
		-- -- Calculates midpoint of the adjustment range
		-- geoMidPoint = {n=3}; geoMidPoint[1] = 0; geoMidPoint[2] = 0; geoMidPoint[3] = 0;
		-- for i=1,tSize do 
			-- geoMidPoint[1] = geoMidPoint[1] + geoPoints[i][1];
			-- geoMidPoint[2] = geoMidPoint[2] + geoPoints[i][2];
			-- geoMidPoint[3] = geoMidPoint[3] + geoPoints[i][3];
		-- end
		-- geoMidPoint[1] = geoMidPoint[1]/tSize;
		-- geoMidPoint[2] = geoMidPoint[2]/tSize;
		-- geoMidPoint[3] = geoMidPoint[3]/tSize;
		
		-- return geoMidPoint;	
		
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
	seatGroup = nil;
	--We will now iterate looking for attachment groups, and not leave until we find the right one
	while (not(obj == nil) and (seatGroup == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "AttachGroup") and (obj:getLabel() == seatAttachName) then
			print("Found an attachment group");
			seatGroup = 1;
			posTreeObj = obj:toPositionedTreeObject();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end
	
	trans = posTreeObj:getTWorld();

	trans["tx"] = geoMidPoint[1];
	trans["ty"] = geoMidPoint[2];
	trans["tz"] = geoMidPoint[3];

	posTreeObj:setTWorld(trans);
	rotateActiveObjectOnOneAxis(posTreeObj, false, false, true, 0, 0, 180);
end



