function selectViewPoint()
	local root = Ips.getActiveObjectsRoot();
	local belowRoot = root:getNextSibling();
	local obj = root;
	viewPointvector = TreeObjectVector();
	while (not(obj == nil) and not(obj:equals(belowRoot))) do
		if (obj:isViewPointVisualization()) then 
			viewPointvector:push_back(obj); -- Push view point in to viewPointvector
		end
		obj = obj:getObjectBelow();
	end
	viewPointnames = StringVector();
	for i = 0, viewPointvector:size() - 1 do
		namefam = tostring(viewPointvector[i]:getLabel());
		viewPointnames:push_back(namefam);
	end
	if (viewPointvector:size() == 1) then -- Checks if a selection of view points is needed.
		vPvis = viewPointvector[0]:toViewPointVisualization();
	elseif (viewPointvector:size() == 0) then
		Ips.alert("No view points exist in tree!");
		return; -- How is this inserted?
	else
		viewPointSelection = Ips.inputDropDownList("View point selection", "Select the view point", viewPointnames);
		if (viewPointSelection == -1) then -- Hanterar fel
			Ips.alert("Error in input!");
			--return; -- How is this inserted?
		end
		vPvis = viewPointvector[viewPointSelection]:toViewPointVisualization();
	end
	local viewP = vPvis:getViewPoint(); -- Get selected view point. .getViewPoint()
	return viewP;
end

function axisAngleToMatrix(axis, angle)
	local x, y, z = axis[1], axis[2], axis[3];
	local cos_theta = math.cos(angle);
	local sin_theta = math.sin(angle);
	local one_minus_cos = 1 - cos_theta;

	-- Ensure the axis is normalized
	local length = math.sqrt(x * x + y * y + z * z);
	x, y, z = x / length, y / length, z / length;

	-- Compute the rotation matrix
	local matrix = {
		{
			cos_theta + x * x * one_minus_cos,
			x * y * one_minus_cos - z * sin_theta,
			x * z * one_minus_cos + y * sin_theta;
		},
		{
			y * x * one_minus_cos + z * sin_theta,
			cos_theta + y * y * one_minus_cos,
			y * z * one_minus_cos - x * sin_theta;
		},
		{
			z * x * one_minus_cos - y * sin_theta,
			z * y * one_minus_cos + x * sin_theta,
			cos_theta + z * z * one_minus_cos;
		}
	}
	return matrix;
end

-- Function to multiply a 3x3 matrix with a 3D vector
function rotatePoint(rotationMatrix, point)
    local x = point[1]
    local y = point[2]
    local z = point[3]

    -- Matrix-vector multiplication
    local rx = rotationMatrix[1][1] * x + rotationMatrix[1][2] * y + rotationMatrix[1][3] * z
    local ry = rotationMatrix[2][1] * x + rotationMatrix[2][2] * y + rotationMatrix[2][3] * z
    local rz = rotationMatrix[3][1] * x + rotationMatrix[3][2] * y + rotationMatrix[3][3] * z

    return {rx, ry, rz}
end

function visionObstructionFunction(fam)
	mannames = fam:getManikinNames();
	-- Set up scene with positioned manikins and area to check direct vision requirements
	-- -- Get area and move view point to each point (nr of points defined by resolution within box).
	-- ---> Step 1: Get area Coordinates
	-- *** DEFINE OBJECT POSITION, ROTATION AND SIZE ***
	-- *** Click on surface > get vertex/point coordinates ***
	objAdjRange = Ips.getGeometrySelection();
	filenameWRL = "tempObj.wrl"; -- Exports a temporary VRML/WRL file to read vertex points from.
	--filenameWRL = "Data/IMMA/VDtemp/objAdjRange.wrl"; -- Specific VDtemp folder that needs to be writeable!
	if (objAdjRange) then
		local positionedTreeObjectOfSelection = objAdjRange:toPositionedTreeObject();
		local selObject	= positionedTreeObjectOfSelection:toPositionedTreeObject();
		transSelObject = selObject:getTWorld(); -- gets the coordinates of the selected object
		objAdjRange:exportToVRML(filenameWRL);
		-- Read the WRL file again and extracts vertex points of the geometry
		lines = {};
		notEnd = 0;
		objPoints = {};
		startP = 0;
		lineNr = 0;
		translationObj = {n=3}; translationObj[1] = 0; translationObj[2] = 0; translationObj[3] = 0;
		rotationObj = {n=3}; rotationObj[1] = 0; rotationObj[2] = 0; rotationObj[3] = 0; rotationObj[4] = 0;
		for line in io.lines(filenameWRL) do 
			lines[#lines + 1] = line;
			if string.match(line,"translation") then
				translation = {n=3};
				translation.x, translation.y, translation.z = line:match("(%S+) (%S+) (%S+)");
				translationObj[1] = tonumber(translation.x);
				translationObj[2] = tonumber(translation.y);
				translationObj[3] = tonumber(translation.z);
				--print("Translation: X "..tostring(translationObj[1])..", Y "..tostring(translationObj[2])..", Z "..tostring(translationObj[3]));
			elseif string.match(line,"rotation") then
				rotation = {n=4};
				rotation.x, rotation.y, rotation.z, rotation.angle = line:match("(%S+) (%S+) (%S+) (%S+)");
				rotationObj[1] = tonumber(rotation.x);
				rotationObj[2] = tonumber(rotation.y);
				rotationObj[3] = tonumber(rotation.z);
				rotationObj[4] = tonumber(rotation.angle);
				--print("Rotation: X "..tostring(rotationObj[1])..", Y "..tostring(rotationObj[2])..", Z "..tostring(rotationObj[3])..", Angle "..tostring(rotationObj[4]));
			elseif (line == "point [") then
				startP = #lines;
			elseif (#lines > startP) and (startP ~= 0) and (line ~= "]") and (notEnd == 0) then
				lineNr = #lines - startP;
				objCoord = {n=3};
				objCoord.x, objCoord.y, objCoord.z = line:match("(%S+) (%S+) (%S[^,]+)");
				objPoints[lineNr] = {n=3};
				objPoints[lineNr][1] = tonumber(objCoord.x);
				objPoints[lineNr][2] = tonumber(objCoord.y);
				objPoints[lineNr][3] = tonumber(objCoord.z);
				--print("Point: X "..tostring(objPoints[lineNr][1])..", Y "..tostring(objPoints[lineNr][2])..", Z "..tostring(objPoints[lineNr][3]));
			elseif (#lines > startP) and (line == "]") then
				notEnd = 1;
			end
		end
	else
		Ips.alert("No geometry selected"); -- Error message and break script
	end
	-- Get rotation matrix:
	local axis = {rotationObj[1], rotationObj[2], rotationObj[3]}; -- Rotate around the X-axis
	local angle = rotationObj[4];
	-- Rotation matrix as identity matrix to not get errors if not rotated.
	local rotationMatrix = {
		{1,0,0;},
		{0,1,0;},
		{0,0,1;}
	}
	-- print("Axis: "..tostring(axis[1])..", "..tostring(axis[2])..", "..tostring(axis[3])..". ");
	-- print("Angle: "..tostring(angle));
	if not(axis[1] == 0  and axis[2] == 0 and axis[3] == 0 and angle == 0)  then
		rotationMatrix = axisAngleToMatrix(axis, angle);
		--print("Rotation matrix calculation");
	end
	
	-- Get number of points
	tSize = table.getn(objPoints);
	-- print("tSize: "..tostring(tSize));
	if tSize > 4 then
		print("Point cloud object, tSize: "..tostring(tSize)); -- Not handled by current script!
	else
		print("Rectangle object, tSize: "..tostring(tSize));
	end
		
	---> Step 2: Create points in increments 
	-- input by user: points
	resDist = Ips.inputNumberWithDefault("Set the distance/resolution between points [mm]", 100); -- Should be checked.
	if (resDist == nil) then -- Handle error
		 Ips.alert("Error in input!");
	end
	resDist = resDist/1000; -- convert to meter.

	objLength = math.max(objPoints[1][1], objPoints[2][1], objPoints[3][1], objPoints[4][1]) - math.min(objPoints[1][1], objPoints[2][1], objPoints[3][1], objPoints[4][1]);
	objWidth = math.max(objPoints[1][2], objPoints[2][2], objPoints[3][2], objPoints[4][2]) - math.min(objPoints[1][2], objPoints[2][2], objPoints[3][2], objPoints[4][2]);
	objHeight = math.max(objPoints[1][3], objPoints[2][3], objPoints[3][3], objPoints[4][3]) - math.min(objPoints[1][3], objPoints[2][3], objPoints[3][3], objPoints[4][3]);
	print("objLength: X "..tostring(objLength)..", objWidth "..tostring(objWidth)..", objHeight "..tostring(objHeight));
		
	nLength = math.ceil(objLength/resDist)+1;
	nWidth = math.ceil(objWidth/resDist)+1;
	nHeight = math.ceil(objHeight/resDist)+1;
	print("nLength: X "..tostring(nLength)..", nWidth "..tostring(nWidth)..", nHeight "..tostring(nHeight));

	allpoints = Vector3dVector(); -- Creates a vector of 3d vector
	x=math.min(objPoints[1][1], objPoints[2][1], objPoints[3][1], objPoints[4][1]);
	y=math.min(objPoints[1][2], objPoints[2][2], objPoints[3][2], objPoints[4][2]);
	z=math.min(objPoints[1][3], objPoints[2][3], objPoints[3][3], objPoints[4][3]);
	xMin = x;
	yMin = y;
	zMin = z;
	for i = 0,nHeight-1 do
		z=zMin+i*resDist;
		if ((i*resDist) > objHeight) then
			z = zMin + objHeight;
		end
		for k = 0,nLength-1 do
			x=xMin+k*resDist;
			if ((k*resDist) > objLength) then
				x = xMin + objLength;
			end
			for j = 0,nWidth-1 do
				y=yMin+j*resDist;
				if ((j*resDist) > objWidth) then
					y = yMin + objWidth;
				end
				--print("Point "..tostring(x)..", "..tostring(y)..", "..tostring(z)..". ");
				point = Vector3d(x,y,z); -- A 3d vector contains coordinates for 3 dimensions
				allpoints:push_back(point); -- Puts the point at the end of the vectors
			end
		end
	end
	numberOfPoints = allpoints:size();
	Ips.alert("Number of points " ..tostring(numberOfPoints).. "."); --> it needs a cancel button

	rotatedPoints = allpoints;
	for i = 0,numberOfPoints-1 do
		point = {allpoints[i][0],allpoints[i][1],allpoints[i][2]};
		rotatedPoint = rotatePoint(rotationMatrix, point);
		--print("rotatedPoint "..tostring(i)..": "..tostring(rotatedPoint[1])..", "..tostring(rotatedPoint[2])..", "..tostring(rotatedPoint[3])..". ");
		rotatedPoints[i] = Vector3d(rotatedPoint[1],rotatedPoint[2],rotatedPoint[3]);
		--print("rotatedPoint "..tostring(i)..": "..tostring(rotatedPoints[i][0])..", "..tostring(rotatedPoints[i][1])..", "..tostring(rotatedPoints[i][2])..". ");
	end

	checkPoints = rotatedPoints;
	for i = 0,numberOfPoints-1 do
		checkPoints[i] = Vector3d(rotatedPoints[i][0]+translationObj[1],rotatedPoints[i][1]+translationObj[2],rotatedPoints[i][2]+translationObj[3]);
		--print("checkPoint "..tostring(i)..": "..tostring(checkPoints[i][0])..", "..tostring(checkPoints[i][1])..", "..tostring(checkPoints[i][2])..". ");
	end

	----> Select view point points to check.
	local staticRoot = Ips.getGeometryRoot();
	local geoGroup = Ips.createGeometryGroup(nil);
	local timeString = os.date("%Y-%m-%dT%H%M");
	local geoGroupLabel = "VisionAnalysis_"..timeString;
	geoGroup:setLabel(geoGroupLabel);

	-- Find View Point --
	--local treeObjViewPoint = objectsRoot:findFirstExactMatch('ViewPoint');
	local viewPoint = selectViewPoint();
	local transViewPoint = viewPoint:getTarget(); -- gets the coordinates of the view point
	local transViewPointOrigin = transViewPoint; -- Saving the original position to reset it to after the simulation.

	local manViewPoint = viewPoint;

	testedPoints = 0;
	visiblePoints = 0;
	
	transDisc = transSelObject;
	
	-- TODO: Create a CSV file to write to.
	-- Write first row with "Pnr" and then all manikin´s labels.
	for i = 0,numberOfPoints-1 do 	
		-- For each z-plane (every x*y point) check if any points on previous plane was visible. 
		-- -	Otherwise mark all as blocked.
		point = checkPoints[i];
		
		-- TODO: Write pointnumber to CSV file.

		----> Step 3: Move to point including offset
		transViewPoint["tx"] = point[0];
		transViewPoint["ty"] = point[1]; 
		transViewPoint["tz"] = point[2];
		viewPoint:setTarget(transViewPoint);
		
		--Ips.updateScreen();	
		-- For each point check if if line of sight is blocked for the specified member of the specified family	
		local blockedFor = 0;
		for j = 0, mannames:size() - 1 do
			local blockedView = manViewPoint:isViewBlockedForFamilyMember(fam,j);
			if blockedView then
				blockedFor = blockedFor + 1;
				-- TODO: Write "Blocked" or 0 for specific manikin "..mannames[j])".
			-- else
				-- TODO: Write "Visible" or 1 for specific manikin "..mannames[j])".
			end
		end
		local percVision = (mannames:size()-blockedFor)/mannames:size();
		local stepNr = math.floor(percVision*510+1 + 0.5);
		local gCol = stepNr - 1;
		local rCol = 255*2 - stepNr + 1;
		if rCol > 255 then
			rCol = 255;
		end
		if gCol > 255 then
			gCol = 255;
		end
		if percVision > 0.5 then
			visiblePoints = visiblePoints + 1;
		end
		-- Connect percVision to colour of point
		-- visionPointCloudfile:write(""..tostring(point[0]).." "..tostring(point[1]).." "..tostring(point[2]).." "..tostring(rCol).." "..tostring(gCol).." 0\n");
		disc = PrimitiveShape.createDisc(0,resDist/2,10,10); -- creates the disc
	
		transDisc["tx"] = transViewPoint["tx"];
		transDisc["ty"] = transViewPoint["ty"];
		transDisc["tz"] = transViewPoint["tz"];
		disc:setTWorld(transDisc); -- position the disc 
		disc:setColor(rCol/255,gCol/255,0); 
		disc:setLabel("P"..tostring(i+1).."_VisionPerc_"..tostring(percVision)); -- naming the disc
		local groupGeometry = staticRoot:findFirstExactMatch(geoGroupLabel);
		Ips.moveTreeObject(disc, groupGeometry);
		groupGeometry:setExpanded(false);
		
		-- TODO: Wrtite VisionPerc_"..tostring(percVision) to CSV file.
		-- TODO: Write color code for point on the last columns in CSV file.
		-- TODO: Add new row.
		
		testedPoints = testedPoints + 1;
		print("Tested point: "..tostring(testedPoints));
	end	
	print("Tested points: "..tostring(testedPoints)..", Visible points: "..tostring(visiblePoints)..", Percent visible: "..tostring(visiblePoints/testedPoints*100)); -- naming the sphere

	--visionPointCloudfileVisible:close();
	--visionPointCloudfileBlocked:close();
	viewPoint:setTarget(transSelObject); -- positions the view point in the saved original position
	--Ips.inputOpenFile('*.xyz', scriptPath, fileName);
	-- Ips.loadGeometry(scriptPath.."/"..fileName.."_Visible.xyz");
	-- Ips.loadGeometry(scriptPath.."/"..fileName.."_Blocked.xyz");
end