function getMidPoint(pointsT)
	pointsTMid = {};
	pointsTMid[1] = (pointsT[0][1] + pointsT[1][1] + pointsT[2][1] + pointsT[3][1]) / 4;
	pointsTMid[2] = (pointsT[0][2] + pointsT[1][2] + pointsT[2][2] + pointsT[3][2]) / 4;
	return pointsTMid;
end

function getAnglePoints(pointsT, pointsTMid)
	radiusPointsT = {};
	for i = 1, 4 do
		radiusPointsT[i] = math.sqrt ((pointsT[i-1][1]-pointsTMid[1])^2 + (pointsT[i-1][2]-pointsTMid[2])^2);
	end
	
	anglePointsT = {};
	for i = 1, 4 do
		if ((pointsT[i-1][2]-pointsTMid[2]) >= 0) then
			anglePointsT[i] = math.acos((pointsT[i-1][1]-pointsTMid[1])/radiusPointsT[i]);
		elseif ((pointsT[i-1][2]-pointsTMid[2]) < 0) then
			anglePointsT[i] = -1 * math.acos((pointsT[i-1][1]-pointsTMid[1])/radiusPointsT[i]) + 2 * math.pi;
		end
	end
	return anglePointsT;
end

function getSeqOrder(anglePointsT)
	len = 4;
	array = {};
	for i = 1, len do
		array[i] = anglePointsT[i];
	end
	for j = 2, len do
        key = array[j]
        i = j - 1
        while i > 0 and array[i] > key do
            array[i + 1] = array[i]
            i = i - 1
        end
        array[i + 1] = key
    end
	seqOrder = {};
	for i = 1, len do
		for j = 1, len do
			if (array[i] == anglePointsT[j]) then
				seqOrder[i] = j;
			end
		end
	end
    --Ips.alert("seqOrder: 1. "..tostring(seqOrder[1])..", 2. "..tostring(seqOrder[2])..", 3. "..tostring(seqOrder[3])..", 4. "..tostring(seqOrder[4]).."\nanglePointsT: 1. "..tostring(anglePointsT[1])..", 2. "..tostring(anglePointsT[2])..", 3. "..tostring(anglePointsT[3])..", 4. "..tostring(anglePointsT[4]));
	return seqOrder;
end

-- Outside check
function checkPosition(seqOrder, pointsT, ref_point)
	-- Area of Quadrilateral
	x = {};
	x[1] = seqOrder[1]-1;
	x[2] = seqOrder[2]-1; 
	x[3] = seqOrder[3]-1;
	x[4] = seqOrder[4]-1;
	
	side = {}; -- Distance between corner points
	for i = 1, 4 do
		j = i+1;
		if (i == 4) then
			j = 1;
		end
		side[i] = math.sqrt ((pointsT[x[j]][1]-pointsT[x[i]][1])^2+(pointsT[x[j]][2]-pointsT[x[i]][2])^2);
	end
	diag = math.sqrt ((pointsT[x[3]][1]-pointsT[x[1]][1])^2+(pointsT[x[3]][2]-pointsT[x[1]][2])^2); -- Diagonal of quadrilateral
	S1 = (side[1] + side[2] + diag)/2; -- Semiperimeter of triangle 1
	S2 = (side[3] + side[4] + diag)/2; -- Semiperimeter of triangle 2
	A1 = math.sqrt  (S1*(S1-side[1])*(S1-side[2])*(S1-diag)); -- Area of triangle 1
	A2 = math.sqrt  (S2*(S2-side[3])*(S2-side[4])*(S2-diag)); -- Area of triangle 2
	AreaQuad = A1 + A2;

	-- Area of point to adjustment area
	L = {}; -- Distance from ref point to corner points of quadrilateral
	for i = 1, 4 do
		L[i] = math.sqrt ((pointsT[x[i]][1]-ref_point[1])^2+(pointsT[x[i]][2]-ref_point[2])^2);
	end
	
	St = {}; -- Semiperimeter of each triangle to ref point 
	for i = 1, 4 do
		j = i+1;
		if (i == 4) then
			j = 1;
		end
		St[i] = (L[i] + L[j] + side[i])/2;
	end
	
	At = {}; -- Area of each triangle to ref point 
	for i = 1, 4 do
		j = i+1;
		if (i == 4) then
			j = 1;
		end
		At[i] = math.sqrt  (St[i]*(St[i]-L[i])*(St[i]-L[j])*(St[i]-side[i]));
		if (St[i]*(St[i]-L[i])*(St[i]-L[j])*(St[i]-side[i]) < 0) then
			At[i] = 0;
		end
	end
	
	AreaToRP = At[1] + At[2] + At[3] + At[4];
	if (AreaQuad + 0.0000001 >= AreaToRP) then
		--Ips.alert("RefPoint inside adjustment area! AreaQuad: "..tostring(AreaQuad).."\nAreaToRP: "..tostring(AreaToRP));
		sidecheck = 1; -- inside
	else
		--Ips.alert("RefPoint outside adjustment area! AreaQuad: "..tostring(AreaQuad).."\nAreaToRP: "..tostring(AreaToRP));
		sidecheck = 0; -- outside
	end
	--Ips.alert("side: 1. "..tostring(side[1])..", 2. "..tostring(side[2])..", 3. "..tostring(side[3])..", 4. "..tostring(side[4]).."\nL: 1. "..tostring(L[1])..", 2. "..tostring(L[2])..", 3. "..tostring(L[3])..", 4. "..tostring(L[4]).."\n St: 1. "..tostring(St[1])..", 2. "..tostring(St[2])..", 3. "..tostring(St[3])..", 4. "..tostring(St[4]).."\n At: 1. "..tostring(At[1])..", 2. "..tostring(At[2])..", 3. "..tostring(At[3])..", 4. "..tostring(At[4]));
	return sidecheck;
end

function getClosestPoint(seqOrder, pointsTMid, anglePointsT, pointsT, ref_point) 
	x = {};
	x[1] = seqOrder[1]-1;
	x[2] = seqOrder[2]-1; 
	x[3] = seqOrder[3]-1;
	x[4] = seqOrder[4]-1;
	
	radiusRefPoints = math.sqrt ((ref_point[1]-pointsTMid[1])^2 + (ref_point[2]-pointsTMid[2])^2);
	angleRefPoint = 0;
	if ((ref_point[2]-pointsTMid[2]) >= 0) then
		angleRefPoint = math.acos((ref_point[1]-pointsTMid[1])/radiusRefPoints);
	elseif ((ref_point[2]-pointsTMid[2]) < 0) then
		angleRefPoint = -1 * math.acos((ref_point[1]-pointsTMid[1])/radiusRefPoints) + 2 * math.pi;
	end
	
	i = 1;
	while (anglePointsT[seqOrder[i]] < angleRefPoint) do
		i = i + 1;
		if (i == 5) then
			break;
		end
	end
	closestSide = i-1;
	if (i == 5) or (i == 1) then
		closestSide = 4;
	end
	--Ips.alert("closestSide: "..tostring(closestSide));
	if (closestSide ~= 4) then
		slopeClsstLine = (pointsT[seqOrder[closestSide]-1][2]-pointsT[seqOrder[closestSide+1]-1][2])/(pointsT[seqOrder[closestSide]-1][1]-pointsT[seqOrder[closestSide+1]-1][1]);
	elseif (closestSide == 4) then
		slopeClsstLine = (pointsT[seqOrder[4]-1][2]-pointsT[seqOrder[1]-1][2])/(pointsT[seqOrder[4]-1][1]-pointsT[seqOrder[1]-1][1]);
	end
	intsctClsstLine = pointsT[seqOrder[closestSide]-1][2] - slopeClsstLine*pointsT[seqOrder[closestSide]-1][1];
	slopeToLine = -1/slopeClsstLine;
	intsctToLine = ref_point[2] - slopeToLine*ref_point[1];
	
	--Ips.alert("slopeClsstLine: "..tostring(slopeClsstLine)..", intsctClsstLine: "..tostring(intsctClsstLine).."\n slopeToLine: "..tostring(slopeToLine)..", intsctToLine: "..tostring(intsctToLine));
	newRefPoint = {}; -- create the matrix
	newRefPoint[1] = (intsctClsstLine-intsctToLine)/(slopeToLine-slopeClsstLine); -- x-coordinate for the closest point
	newRefPoint[2] = slopeClsstLine*newRefPoint[1]+intsctClsstLine; -- y-coordinate for the closest point
	if (checkPosition(seqOrder, pointsT, newRefPoint) == 0) then -- Check if the new ref point is still outside ("corner quadrant").
		-- Distance of point to adjustment area corners
		distanceT = {};
		for i = 1, 4 do
			distanceT[i] = math.sqrt ((pointsT[x[i]][1]-ref_point[1])^2+(pointsT[x[i]][2]-ref_point[2])^2);
		end
		distanceMin = distanceT[1];
		distanceMinId = 1;
		for i = 2, 4 do
			if (distanceT[i] < distanceMin) then
				distanceMin = distanceT[i];
				distanceMinId = i;
			end
		end
		newRefPoint[1] = pointsT[x[distanceMinId]][1];
		newRefPoint[2] = pointsT[x[distanceMinId]][2];
	end
	return newRefPoint;
end

function getClosestSWPoint(seqOrder, pointsTMid, anglePointsT, pointsT, ref_point, kPointToMid, mPointToMid) 
	x = {};
	x[1] = seqOrder[1]-1;
	x[2] = seqOrder[2]-1; 
	x[3] = seqOrder[3]-1;
	x[4] = seqOrder[4]-1;
	
	radiusRefPoints = math.sqrt ((ref_point[1]-pointsTMid[1])^2 + (ref_point[2]-pointsTMid[2])^2);
	angleRefPoint = 0;
	if ((ref_point[2]-pointsTMid[2]) >= 0) then
		angleRefPoint = math.acos((ref_point[1]-pointsTMid[1])/radiusRefPoints);
	elseif ((ref_point[2]-pointsTMid[2]) < 0) then
		angleRefPoint = -1 * math.acos((ref_point[1]-pointsTMid[1])/radiusRefPoints) + 2 * math.pi;
	end
	
	i = 1;
	while (anglePointsT[seqOrder[i]] < angleRefPoint) do
		i = i + 1;
		if (i == 5) then
			break;
		end
	end
	closestSide = i-1;
	if (i == 5) or (i == 1) then
		closestSide = 4;
	end
	--Ips.alert("closestSide: "..tostring(closestSide));
	if (closestSide ~= 4) then
		slopeClsstLine = (pointsT[seqOrder[closestSide]-1][2]-pointsT[seqOrder[closestSide+1]-1][2])/(pointsT[seqOrder[closestSide]-1][1]-pointsT[seqOrder[closestSide+1]-1][1]);
	elseif (closestSide == 4) then
		slopeClsstLine = (pointsT[seqOrder[4]-1][2]-pointsT[seqOrder[1]-1][2])/(pointsT[seqOrder[4]-1][1]-pointsT[seqOrder[1]-1][1]);
	end

	intsctClsstLine = pointsT[seqOrder[closestSide]-1][2] - slopeClsstLine*pointsT[seqOrder[closestSide]-1][1];	
	newRefPoint = {}; -- create the matrix
	newRefPoint[1] = (intsctClsstLine-mPointToMid)/(kPointToMid-slopeClsstLine); -- x-coordinate for the closest point
	newRefPoint[2] = slopeClsstLine*newRefPoint[1]+intsctClsstLine; -- y-coordinate for the closest point
	if (checkPosition(seqOrder, pointsT, newRefPoint) == 0) then -- Check if the new ref point is still outside ("corner quadrant").
		-- Distance of point to adjustment area corners
		distanceT = {};
		for i = 1, 4 do
			distanceT[i] = math.sqrt ((pointsT[x[i]][1]-ref_point[1])^2+(pointsT[x[i]][2]-ref_point[2])^2);
		end
		distanceMin = distanceT[1];
		distanceMinId = 1;
		for i = 2, 4 do
			if (distanceT[i] < distanceMin) then
				distanceMin = distanceT[i];
				distanceMinId = i;
			end
		end
		newRefPoint[1] = pointsT[x[distanceMinId]][1];
		newRefPoint[2] = pointsT[x[distanceMinId]][2];
	end
	return newRefPoint;
end

function getSWmidline(seqOrder, pointsT)
	-- Corners of Quadrilateral
	x1 = seqOrder[1]-1;
	x2 = seqOrder[2]-1; 
	x3 = seqOrder[3]-1;
	x4 = seqOrder[4]-1;
	
	MidpointT = {}; -- create the matrix
	MidpointT[0] = {}; -- create a new row
	MidpointT[0][1] = (pointsT[x2][1] + pointsT[x1][1])/2;
	MidpointT[0][2] = (pointsT[x2][2] + pointsT[x1][2])/2;
	MidpointT[1] = {}; -- create a new row
	MidpointT[1][1] = (pointsT[x3][1] + pointsT[x2][1])/2;
	MidpointT[1][2] = (pointsT[x3][2] + pointsT[x2][2])/2;
	MidpointT[2] = {}; -- create a new row
	MidpointT[2][1] = (pointsT[x4][1] + pointsT[x3][1])/2;
	MidpointT[2][2] = (pointsT[x4][2] + pointsT[x3][2])/2;
	MidpointT[3] = {}; -- create a new row
	MidpointT[3][1] = (pointsT[x1][1] + pointsT[x4][1])/2;
	MidpointT[3][2] = (pointsT[x1][2] + pointsT[x4][2])/2;
	
	k1 = (MidpointT[2][2]-MidpointT[0][2])/(MidpointT[2][1]-MidpointT[0][1]);
	k2 = (MidpointT[3][2]-MidpointT[1][2])/(MidpointT[3][1]-MidpointT[1][1]);
	
	SWMidLine = {}; -- create the matrix
	SWMidLine[0] = {}; -- create a new row
	SWMidLine[1] = {}; -- create a new row	
	if (k1 > 0) then
		SWMidLine[0][1] = MidpointT[0][1];
		SWMidLine[0][2] = MidpointT[0][2];
		SWMidLine[1][1] = MidpointT[2][1];
		SWMidLine[1][2] = MidpointT[2][2];
		return SWMidLine;
	elseif (k2 > 0) then
		SWMidLine[0][1] = MidpointT[1][1];
		SWMidLine[0][2] = MidpointT[1][2];
		SWMidLine[1][1] = MidpointT[3][1];
		SWMidLine[1][2] = MidpointT[3][2];
		return SWMidLine;
	else
		Ips.alert("Error, could not find slope of steering wheel midline.\nk1: "..tostring(k1)..", k2: "..tostring(k2));
	end
end

function positionClassASW(SW_points, SW_min_xid, SW_max_xid, SWCF_X, SWCF_Z, SWMidLine, PRP_X, L6)
	swDiff = {}; -- Difference of current position of steering wheel to new predicted L6 
	if (SW_Pos == 1) then -- Smaller than adj range
		swDiff[1] =  SW_points[SW_min_xid][1] - SWCF_X;
		swDiff[2] =  SW_points[SW_min_xid][2] - SWCF_Z;
	elseif (SW_Pos == 5) then -- Bigger than adj range
		swDiff[1] =  SW_points[SW_max_xid][1] - SWCF_X;
		swDiff[2] =  SW_points[SW_max_xid][2] - SWCF_Z;
	elseif (SW_Pos == 3) then
		SWMidLine_order = {};
		SWMidLine_order[1] = 0;
		SWMidLine_order[2] = 1;
		if (SWMidLine[1][1] < SWMidLine[0][1]) then -- Check order of midline-points
			SWMidLine_order[1] = 1;
			SWMidLine_order[2] = 0;
		end
		k = 0; m = 0; -- Input for 
		if (L6 <= (SWMidLine[SWMidLine_order[1]][1] - PRP_X)*1000) then
			--Ips.alert("L6 smaller than SWMidLine_X bottom");
			-- Calculate SW_Z
			SW_Pos = 2;
			k = (SW_points[SW_min_xid][2]-SWMidLine[SWMidLine_order[1]][2])/(SW_points[SW_min_xid][1]-SWMidLine[SWMidLine_order[1]][1]);
			m = SW_points[SW_min_xid][2] - k*SW_points[SW_min_xid][1];
		elseif (L6 >= (SWMidLine[SWMidLine_order[2]][1] - PRP_X)*1000) then
			--Ips.alert("L6 bigger than SWMidLine_X top");
			-- Calculate SW_Z
			SW_Pos = 4;
			k = (SW_points[SW_max_xid][2]-SWMidLine[SWMidLine_order[2]][2])/(SW_points[SW_max_xid][1]-SWMidLine[SWMidLine_order[2]][1]);
			m = SW_points[SW_max_xid][2] - k*SW_points[SW_max_xid][1];
		else
			--Ips.alert("L6 within midline points, L6 + PRP_X = "..tostring(L6).." + "..tostring(PRP_X*1000).." = "..tostring(L6+PRP_X*1000)..". Compared to SWCF_X: "..tostring(SWCF_X));
			-- Calculate SW_Z
			k = (SWMidLine[1][2]-SWMidLine[0][2])/(SWMidLine[1][1]-SWMidLine[0][1]);
			m = SWMidLine[1][2] - k*SWMidLine[1][1];
		end
		SW_Z = k*(L6/1000+PRP_X) + m;
		swDiff[1] = (L6/1000+PRP_X) - SWCF_X;
		swDiff[2] = SW_Z - SWCF_Z;
		--Ips.alert("swDiff[1]: "..tostring(swDiff[1])..". swDiff[2]: "..tostring(swDiff[2]));
	end
	return swDiff;
end

function positionClassBSW(SWCF_X, SWCF_Z, swNewPoint)
	swDiff = {}; -- Difference of current position of steering wheel to new predicted L6 
	swDiff[1] = swNewPoint[1] - SWCF_X;
	swDiff[2] = swNewPoint[2] - SWCF_Z;
	return swDiff;
end
	
function setSWPosition(SWObjectVis, swDiff)
	SWObjectVis = objectvector[objectSelection]:toPositionedTreeObject(); -- Should be deleted?
	trans = SWObjectVis:getTWorld();
	trans["tx"] = swDiff[1];
	trans["tz"] = swDiff[2];
	SWObjectVis:setTWorld(trans);
end

function setAttachmentPoint(MidHip, MidHipX, MidHipZ, HpointX, HpointZ, CenterEye, EyeX, EyeZ, mannames)
	local root = Ips.getActiveObjectsRoot();
	local obj = root:getObjectBelow();
	while (not(obj == nil)) do
		if (obj:getType() == "AttachPoint") then
			local name = (tostring(obj:getLabel()));
			if (name == MidHip) then
				AttachPointVis = obj:toPositionedTreeObject();
				trans = AttachPointVis:getTWorld();
				trans["tx"] = MidHipX/1000;
				trans["tz"] = MidHipZ/1000;
				AttachPointVis:setTWorld(trans);
				sphere = PrimitiveShape.createSphere(0.01,10,10);
				sphere:setLabel("H-point: "..tostring(mannames[0]));
				trans["tx"] = HpointX/1000;
				trans["tz"] = HpointZ/1000;
				sphere:setTWorld(trans);
				sphere:setColor(1,0,0);
			end
			if (name == CenterEye) then
				AttachPointVis = obj:toPositionedTreeObject();
				trans = AttachPointVis:getTWorld();
				trans["tx"] = EyeX/1000;
				trans["tz"] = EyeZ/1000;
				AttachPointVis:setTWorld(trans);
			end
		end
		obj = obj:getNextSibling();
	end
end
	
function createReferencePoints(MidHip, MidHipX, MidHipZ, HpointX, HpointZ, CenterEye, EyeX, EyeZ, manName, swDiff, SWCF_X, SWCF_Z)
	sphSize = 0.005;
	local root = Ips.getActiveObjectsRoot();
	local obj = root:getObjectBelow();
	while (not(obj == nil)) do
		if (obj:getType() == "AttachPoint") then
			local name = (tostring(obj:getLabel()));
			if (name == MidHip) then
				AttachPointVis = obj:toPositionedTreeObject();
				trans = AttachPointVis:getTWorld();
				sphere = PrimitiveShape.createSphere(sphSize,10,10);
				sphere:setLabel("Mid-hip: "..tostring(manName));
				trans["tx"] = MidHipX/1000;
				trans["tz"] = MidHipZ/1000;
				sphere:setTWorld(trans);
				sphere:setColor(0,1,0);
				sphere = PrimitiveShape.createSphere(sphSize,10,10);
				sphere:setLabel("H-point: "..tostring(manName));
				trans["tx"] = HpointX/1000;
				trans["tz"] = HpointZ/1000;
				sphere:setTWorld(trans);
				sphere:setColor(1,0,0);
			end
			if (name == CenterEye) then
				AttachPointVis = obj:toPositionedTreeObject();
				trans = AttachPointVis:getTWorld();
				sphere = PrimitiveShape.createSphere(sphSize,10,10);
				sphere:setLabel("Centre-eye: "..tostring(manName));
				trans["tx"] = EyeX/1000;
				trans["tz"] = EyeZ/1000;
				sphere:setTWorld(trans);
				sphere:setColor(0,0,1);
				sphere = PrimitiveShape.createSphere(sphSize,10,10);
				sphere:setLabel("SW-centre: "..tostring(manName));
				trans["tx"] = swDiff[1] + SWCF_X;
				trans["tz"] = swDiff[2] + SWCF_Z;
				sphere:setTWorld(trans);
				sphere:setColor(1,0,1);
			end
		end
		obj = obj:getNextSibling();
	end
end

function createReferencePoints2(refFramesPoints, MidHipX, MidHipZ, HpointX, HpointZ, EyeX, EyeZ, manName, swDiff, SWCF_X, SWCF_Z)
	sphSize = 0.005;
	FrameVis = refFramesPoints[0]:toPositionedTreeObject();
	trans = FrameVis:getTWorld();
	
	sphere = PrimitiveShape.createSphere(sphSize,10,10);
	sphere:setLabel("Mid-hip: "..tostring(manName));
	trans["tx"] = MidHipX/1000;
	trans["tz"] = MidHipZ/1000;
	sphere:setTWorld(trans);
	sphere:setColor(0,1,0);
	
	sphere = PrimitiveShape.createSphere(sphSize,10,10);
	sphere:setLabel("H-point: "..tostring(manName));
	trans["tx"] = HpointX/1000;
	trans["tz"] = HpointZ/1000;
	sphere:setTWorld(trans);
	sphere:setColor(1,0,0);
	
	sphere = PrimitiveShape.createSphere(sphSize,10,10);
	sphere:setLabel("Centre-eye: "..tostring(manName));
	trans["tx"] = EyeX/1000;
	trans["tz"] = EyeZ/1000;
	sphere:setTWorld(trans);
	sphere:setColor(0,0,1);
	
	sphere = PrimitiveShape.createSphere(sphSize,10,10);
	sphere:setLabel("SW-centre: "..tostring(manName));
	trans["tx"] = swDiff[1] + SWCF_X;
	trans["tz"] = swDiff[2] + SWCF_Z;
	sphere:setTWorld(trans);
	sphere:setColor(1,0,1);
end