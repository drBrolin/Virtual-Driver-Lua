-- Returns { vertices = {{x,y,z},...}, faces = {{i,j,k},...} } for an icosphere.
-- resolution: 0=12, 1=42, 2=162, 3=642, 4=2562 vertices. Faces use 1-based indices.
function generateIcosphere(resolution, radius)
	local phi = (1.0 + math.sqrt(5.0)) / 2.0

	local function normalize(v)
		local len = math.sqrt(v[1]*v[1] + v[2]*v[2] + v[3]*v[3])
		return {v[1]/len, v[2]/len, v[3]/len}
	end

	local vertices = {}
	for _, v in ipairs({
		{-1,  phi,  0}, { 1,  phi,  0}, {-1, -phi,  0}, { 1, -phi,  0},
		{ 0, -1,  phi}, { 0,  1,  phi}, { 0, -1, -phi}, { 0,  1, -phi},
		{ phi,  0, -1}, { phi,  0,  1}, {-phi,  0, -1}, {-phi,  0,  1}
	}) do
		table.insert(vertices, normalize(v))
	end

	local faces = {
		{1,12,6}, {1,6,2}, {1,2,8}, {1,8,11}, {1,11,12},
		{2,6,10}, {6,12,5}, {12,11,3}, {11,8,7}, {8,2,9},
		{4,10,5}, {4,5,3}, {4,3,7}, {4,7,9}, {4,9,10},
		{5,10,6}, {3,5,12}, {7,3,11}, {9,7,8}, {10,9,2}
	}

	local midCache = {}
	local function midpoint(i1, i2)
		local lo, hi = math.min(i1, i2), math.max(i1, i2)
		local key = lo .. "_" .. hi
		if midCache[key] then return midCache[key] end
		local v1, v2 = vertices[i1], vertices[i2]
		table.insert(vertices, normalize({
			(v1[1]+v2[1])/2, (v1[2]+v2[2])/2, (v1[3]+v2[3])/2
		}))
		midCache[key] = #vertices
		return #vertices
	end

	for _ = 1, resolution do
		local newFaces = {}
		for _, f in ipairs(faces) do
			local a = midpoint(f[1], f[2])
			local b = midpoint(f[2], f[3])
			local c = midpoint(f[3], f[1])
			table.insert(newFaces, {f[1], a, c})
			table.insert(newFaces, {f[2], b, a})
			table.insert(newFaces, {f[3], c, b})
			table.insert(newFaces, {a, b, c})
		end
		faces = newFaces
	end

	local points = {}
	for _, v in ipairs(vertices) do
		table.insert(points, {v[1]*radius, v[2]*radius, v[3]*radius})
	end
	return { vertices = points, faces = faces }
end

-- Returns { vertices = {{x,y,z},...}, faces = {{i,j,k},...} } for a UV (lat/lon) sphere.
-- stacks: latitude divisions pole-to-pole (>=2); slices: longitude segments (>=3).
-- Total vertices: 2 + (stacks-1)*slices. Poles at +Z and -Z. Faces use 1-based indices.
function generateUVSphere(stacks, slices, radius)
	local vertices = {}
	local faces = {}

	-- Top pole (+Z)
	table.insert(vertices, {0, 0, radius})

	-- Ring vertices (stacks-1 rings between poles)
	for i = 1, stacks - 1 do
		local phi = math.pi * i / stacks     -- 0 (top) → π (bottom)
		for j = 0, slices - 1 do
			local theta = 2 * math.pi * j / slices
			table.insert(vertices, {
				radius * math.sin(phi) * math.cos(theta),
				radius * math.sin(phi) * math.sin(theta),
				radius * math.cos(phi)
			})
		end
	end

	-- Bottom pole (-Z)
	table.insert(vertices, {0, 0, -radius})

	local topPole    = 1
	local bottomPole = #vertices

	-- Top cap: topPole → first ring
	for j = 0, slices - 1 do
		table.insert(faces, {topPole,
		                      2 + j,
		                      2 + (j + 1) % slices})
	end

	-- Middle bands: connect adjacent rings
	for i = 0, stacks - 3 do
		local r1 = 2 + i * slices
		local r2 = 2 + (i + 1) * slices
		for j = 0, slices - 1 do
			local a = r1 + j
			local b = r1 + (j + 1) % slices
			local c = r2 + (j + 1) % slices
			local d = r2 + j
			table.insert(faces, {a, b, c})
			table.insert(faces, {a, c, d})
		end
	end

	-- Bottom cap: last ring → bottomPole
	local lrs = 2 + (stacks - 2) * slices
	for j = 0, slices - 1 do
		table.insert(faces, {lrs + j,
		                      bottomPole,
		                      lrs + (j + 1) % slices})
	end

	return { vertices = vertices, faces = faces }
end

-- Creates icosphere Frame objects in the static geometry tree, tagged for reach analysis.
-- Frame objects are self-visualizing and directly usable by ReachFrameAnalysis via toFrame().
function CreateIcospherePoints()
	local resInput = Ips.inputNumberWithDefault(
		"Icosphere resolution  (0=12 pts | 1=42 pts | 2=162 pts | 3=642 pts | 4=2562 pts)", 2)
	if resInput == nil then
		Ips.alert("Error in input!")
		return
	end
	local resolution = math.max(0, math.min(4, math.floor(resInput)))
	local radius = 2.0

	local points = generateIcosphere(resolution, radius).vertices
	print("Icosphere r"..tostring(resolution)..": "..tostring(#points).." points, radius "..tostring(radius).."m")
	for i, p in ipairs(points) do
		print("  P"..tostring(i)..": x="..tostring(p[1])..", y="..tostring(p[2])..", z="..tostring(p[3]))
	end

	local staticRoot = Ips.getGeometryRoot()
	local geoGroup = Ips.createGeometryGroup(nil)
	local timeString = os.date("%Y-%m-%dT%H%M")
	local groupLabel = "IcospherePoints_r"..tostring(resolution).."_"..timeString
	geoGroup:setLabel(groupLabel)

	for i, p in ipairs(points) do
		local frame = Frame()
		local trans = Transf3.newIdentity()
		trans.tx = p[1]
		trans.ty = p[2]
		trans.tz = p[3]
		frame:setTWorld(trans)
		frame:setSize(0.05)
		frame:setLabel("IcoP_"..tostring(i))
		frame:setPublicAttributeValue("VD_reachAnalysis", "True")
		local group = staticRoot:findFirstExactMatch(groupLabel)
		Ips.moveTreeObject(frame, group)
	end

	local group = staticRoot:findFirstExactMatch(groupLabel)
	if group then group:setExpanded(false) end

	Ips.alert("Created "..tostring(#points).." icosphere frames (resolution "..tostring(resolution).."). Ready for reach analysis.")
	return points
end

function getReachPoints(reachPoints)
	local staticRoot = Ips.getGeometryRoot();
	local belowRoot = staticRoot:getNextSibling();
	local obj = staticRoot;

	while (not(obj == nil) and not(obj:equals(belowRoot))) do
		-- Get attributes and check if VD_reachAnalysis is true
		if (obj:getPublicAttributeValue("VD_reachAnalysis") == "True") then
			print("VD_reach found");
			reachPoints:push_back(obj);
		end
		obj = obj:getObjectBelow();
	end
	return reachPoints;
end

function getReachGrip()
	local activeRoot = Ips.getActiveObjectsRoot();
	local belowRoot = activeRoot:getNextSibling();
	local obj = activeRoot;
	local reachGrips = TreeObjectVector();
	while (not(obj == nil) and not(obj:equals(belowRoot))) do
		-- Get attributes and check if VD_reachAnalysisGrip is true
		if (obj:getPublicAttributeValue("VD_reachAnalysisGrip") == "True") then
			print("VD_reach found");
			reachGrips:push_back(obj);
		end
		obj = obj:getObjectBelow();
	end
	gripLabels = StringVector();
	for i = 0, reachGrips:size() - 1 do
		nameGrip = tostring(reachGrips[i]:getLabel());
		gripLabels:push_back(nameGrip);
	end
	selectedReachGrip = reachGrips[0];
	if (reachGrips:size() == 1) then -- Checks if a selection of grip is needed.
		selectedReachGrip = reachGrips[0];
	elseif (reachGrips:size() == 0) then
		Ips.alert("No grips exist in tree!");
		return; -- How is this inserted?
	else
		gripSelection = Ips.inputDropDownList("Grip selection", "Select which reach grip that should be used in analysis.", gripLabels);
		if (gripSelection == -1) then -- Hanterar fel
			Ips.alert("Error in input!");
			--return; -- How is this inserted?
		end
		selectedReachGrip = reachGrips[gripSelection];
	end
	selectedReachGripVisualization = selectedReachGrip:toGripPointVisualization();
	return selectedReachGripVisualization;
end

-- TODO: Reach analysis using similar approach. 
-- 1. Select frames to be inlcuded in reach analysis, add Attribute VD_reachAnalysis - true
function ReachFrameSelect()
	objSelected = Ips.getSelections();
	print("Selected frames: "..tostring(objSelected:size()));
	if (objSelected) then
		for i = 0,objSelected:size()-1 do
			objSelected[i]:setPublicAttributeValue("VD_reachAnalysis","True");
		end
	else
		Ips.alert("No geometry selected"); -- Error message and break script
	end
	
end
-- Highlight selected frames that will be included. -- Not possible

-- 2. Exclude selected frames from reach analaysis
function ReachFrameDeselect()
	objSelected = Ips.getSelections();
	print("Selected frames: "..tostring(objSelected:size()));
	if (objSelected) then
		for i = 0,objSelected:size()-1 do
			objSelected[i]:setPublicAttributeValue("VD_reachAnalysis","False");
		end
	else
		Ips.alert("No geometry selected"); -- Error message and break script
	end
end

-- 3. Create reach grip
function CreateReachGrip()
	local simController = ManikinSimulationController();

	reachGrip = simController:createGripPoint();
	reachGrip:setSymmetricRotationTolerances(1.7976931348623157e+308,1.7976931348623157e+308,1.7976931348623157e+308);
	-- reachGrip:setSoftTranslation();
	reachGripVis = reachGrip:getVisualization();
	reachGripVis:setPublicAttributeValue("VD_reachAnalysisGrip","True");
	
	inputAlternatives = StringVector(); inputAlternatives:push_back("Right"); inputAlternatives:push_back("Left");
	handness = Ips.inputDropDownList("Hand selection", "What hand grip should be created? Right or Left?", inputAlternatives); 
	
	if (handness == 0) then -- Right
		reachGripVis:setLabel("VDrightReachGrip");
	elseif (handness == 1) then -- Left
		reachGripVis:setLabel("VDleftReachGrip");
		reachGrip:setHand(0);
	end
	Ips.alert("Reach grip created, attach to manikin(s) for further analysis.");
end

-- 4. Perform reach analysis, test each point:
function ReachFrameAnalysis(fam)
	mannames = fam:getManikinNames();
	reachGripVisualization = getReachGrip();
	--check for left or right
	reachGripPoint = reachGripVisualization:getGripPoint();
	handness = reachGripPoint:getHand();
	handName = "Right Hand";
	if handness == 0 then -- Left
		handName = "Left Hand";
	end
	ctrlPoints = fam:getControlPoints();
	for i = 0,ctrlPoints:size()-1 do
		if ctrlPoints[i]:getName() == handName then
			handPoint = ctrlPoints[i];
		end
	end
	
	transHand = handPoint:getTarget(); -- gets the coordinates of the hand grip
	transGripOrigin = transHand; -- Saving the original position to reset it to after the simulation.
	
	local reachPoints = TreeObjectVector();
	reachPoints = getReachPoints(reachPoints);
	print("Selected frames: "..tostring(reachPoints:size()));
	
	local gripOffset = reachGripPoint:getOffset();
	okDiff = math.sqrt((gripOffset[0]-0)^2+(gripOffset[1]-0)^2+(gripOffset[2]-0.07)^2)+0.02;
	--okDiff = 0.04; -- 40 mm diff is ok.	
	print("OK diff: " ..tostring(okDiff));
	testedPoints = 0;
	reachedPoints = 0;
	
	----> Select view point points to check.
	local staticRoot = Ips.getGeometryRoot();
	local geoGroup = Ips.createGeometryGroup(nil);
	local timeString = os.date("%Y-%m-%dT%H%M");
	local geoGroupLabel = "ReachAnalysis_"..timeString;
	geoGroup:setLabel(geoGroupLabel);

	for i = 0,reachPoints:size()-1 do
		reachGripVisualization:setTControl(transGripOrigin); -- positions the hand grip in the saved original position
		Ips.updateScreen();
		frameSel = reachPoints[i]:toFrame();
		----> Step 3: Move grip to point including offset
		transGrip = frameSel:getTWorld(); -- gets the coordinates of the frame
		reachGripVisualization:setTControl(transGrip); -- positions the hand grip in the coordinates. Does not handle collision avoidance in a good way! 
		-- Would be better to create grip points in all positions and then grasp release between all of them.
		Ips.updateScreen();
		----> Step 4: Get coordinates for hand and compare to coordinates of the evaluated grip point 
		--- TODO: Select family and select hand in family. For each manikin make representative and then check position. setRepresentative(int)
		local notReachedBy = 0;
		for j = 0, mannames:size() - 1 do
			if mannames:size() > 1 then
				fam:setRepresentative(j);
			end
			transHand = handPoint:getTarget(); -- gets the coordinates of the hand grip

			xDiff = transHand["tx"]-transGrip["tx"];
			yDiff = transHand["ty"]-transGrip["ty"];
			zDiff = transHand["tz"]-transGrip["tz"];
			testDiff = math.sqrt(xDiff^2+yDiff^2+zDiff^2);
			
			if testDiff < okDiff then
				print("Point " ..tostring(i+1).. " reached by "..mannames[j]);
			else
				notReachedBy = notReachedBy + 1;
				print("Point " ..tostring(i+1).. " not reached by "..mannames[j]);
			end
		end
		--print("\nPoint " ..tostring(i+1).. "\nPointcoordinates, " ..tostring(transGrip["tx"]).. ", " ..tostring(transGrip["ty"]).. ", " ..tostring(transGrip["tz"]).. "\nHandcoordinates, " ..tostring(transHand["tx"]).. ", " ..tostring(transHand["ty"]).. ", " ..tostring(transHand["tz"]).. "\nDifferences, " ..tostring(xDiff).. ", " ..tostring(yDiff).. ", " ..tostring(zDiff));
		
		-- index=i+1;
		-- ----> Step 5: If true create a green spere in the position	
		-- sphere = PrimitiveShape.createSphere(0.01,10,10); -- creates the sphere
		-- sphere:setLabel("Point: "..tostring(index)); -- naming the sphere
		-- transPoint = transGrip; -- Create a new TWorld.
		-- --transPoint["ty"] = point[1]; -- Change back the offset
		-- --transPoint["tz"] = point[2]; -- Change back the offset
		-- sphere:setTWorld(transPoint); -- position the sphere 
		
		
		-- if xDiff < okDiff and yDiff < okDiff and zDiff < okDiff then
			-- sphere:setColor(0,1,0);
			-- --Ips.alert("Reached point " ..tostring(index).. "!");
		-- else
			-- sphere:setColor(1,0,0);
			-- --Ips.alert("Did not reach point " ..tostring(index).. "!");
		-- end
		
		local percReached = (mannames:size()-notReachedBy)/mannames:size();
		local stepNr = math.floor(percReached*510+1 + 0.5);
		local gCol = stepNr - 1;
		local rCol = 255*2 - stepNr + 1;
		if rCol > 255 then
			rCol = 255;
		end
		if gCol > 255 then
			gCol = 255;
		end
		if percReached > 0.5 then
			reachedPoints = reachedPoints + 1;
		end
		-- Connect percReached to colour of point
		sphere = PrimitiveShape.createSphere(0.01,10,10); -- creates the sphere
		sphere:setTWorld(transGrip); -- position the sphere
		sphere:setColor(rCol/255,gCol/255,0); 
		sphere:setLabel("P"..tostring(i+1).."_ReachedPerc_"..tostring(percReached)); -- naming the sphere
		local groupGeometry = staticRoot:findFirstExactMatch(geoGroupLabel);
		Ips.moveTreeObject(sphere, groupGeometry);
		groupGeometry:setExpanded(false);
	end	
	reachGripVisualization:setTControl(transGripOrigin); -- positions the hand grip in the saved original position
	Ips.updateScreen();
end

function ReachFrameNr(fam)
	mannames = fam:getManikinNames();
	reachGripVisualization = getReachGrip();
	--check for left or right
	reachGripPoint = reachGripVisualization:getGripPoint();
	handness = reachGripPoint:getHand();
	handName = "Right Hand";
	if handness == 0 then -- Left
		handName = "Left Hand";
	end
	ctrlPoints = fam:getControlPoints();
	for i = 0,ctrlPoints:size()-1 do
		if ctrlPoints[i]:getName() == handName then
			handPoint = ctrlPoints[i];
		end
	end

	transHand = handPoint:getTarget(); -- gets the coordinates of the hand grip
	transGripOrigin = transHand; -- Saving the original position to reset it to after the simulation.
	
	local reachPoints = TreeObjectVector();
	reachPoints = getReachPoints(reachPoints);
	print("Selected frames: "..tostring(reachPoints:size()));
	reachPointList = StringVector();
	for i = 0, reachPoints:size() - 1 do
		frame = tostring(reachPoints[i]:toFrame():getLabel());
		reachPointList:push_back(frame);
	end
	reachPointNr = 0;
	if (reachPoints:size() == 1) then -- Checks if a selection of manikin family is needed.
		
	elseif (reachPoints:size() == 0) then
		Ips.alert("No reach points exist in tree!");
		return; -- How is this inserted?
	else
		reachPointSelection = Ips.inputDropDownList("Point/frame selection", "Select the point/frame you want to analyse", reachPointList);
		if (reachPointSelection == -1) then -- Hanterar fel
			Ips.alert("Error in input!");
			--return; -- How is this inserted?
		end
		reachPointNr = reachPointSelection;
	end
	
	local gripOffset = reachGripPoint:getOffset();
	okDiff = math.sqrt((gripOffset[0]-0)^2+(gripOffset[1]-0)^2+(gripOffset[2]-0.07)^2)+0.02;
	--okDiff = 0.04; -- 40 mm diff is ok.	
	print("OK diff: " ..tostring(okDiff));
	testedPoints = 0;
	reachedPoints = 0;
	

	frameSel = reachPoints[reachPointNr]:toFrame();
	----> Step 3: Move grip to point including offset
	transGrip = frameSel:getTWorld(); -- gets the coordinates of the frame
	reachGripVisualization:setTControl(transGrip); -- positions the hand grip in the coordinates. Does not handle collision avoidance in a good way! 
	-- Would be better to create grip points in all positions and then grasp release between all of them.
	Ips.updateScreen();
	----> Step 4: Get coordinates for hand and compare to coordinates of the evaluated grip point 
	--- TODO: Select family and select hand in family. For each manikin make representative and then check position. setRepresentative(int)
	print("Point " ..tostring(reachPointNr+1).. ": x: "..tostring(transGrip["tx"])..", y: "..tostring(transGrip["ty"])..", z:"..tostring(transGrip["tz"])..".");
	local notReachedBy = 0;
	for j = 0, mannames:size() - 1 do
		if mannames:size() > 1 then
			fam:setRepresentative(j);
		end
		transHand = handPoint:getTarget(); -- gets the coordinates of the hand grip
		--print("transHand: x: "..tostring(transHand["tx"])..", y: "..tostring(transHand["ty"])..", z:"..tostring(transHand["tz"])..".");
			
		xDiff = transHand["tx"]-transGrip["tx"];
		yDiff = transHand["ty"]-transGrip["ty"];
		zDiff = transHand["tz"]-transGrip["tz"];
		testDiff = math.sqrt(xDiff^2+yDiff^2+zDiff^2);
			
		if testDiff < okDiff then
			print("Point " ..tostring(reachPointNr+1).. " reached by "..mannames[j]..". Diff: "..tostring(testDiff)..".");
		else
			notReachedBy = notReachedBy + 1;
			print("Point " ..tostring(reachPointNr+1).. " not reached by "..mannames[j]..". Diff: "..tostring(testDiff)..".");
		end
	end
	
	local percReached = (mannames:size()-notReachedBy)/mannames:size();
	print("Reached by " ..tostring(percReached*100).. " %.");
	-- Connect percReached to colour of point

	-- reachGripVisualization:setTControl(transGripOrigin); -- positions the hand grip in the saved original position
	-- Ips.updateScreen();
end

-- Filters a sphere table to the forward hemisphere (local z >= 0, which aligns with the
-- L5S1 X direction after the R_y90 remapping). Returns filteredVertices, filteredFaces.
function filterSphereHalf(sphere)
	local remap, filtVerts, filtFaces = {}, {}, {}
	for i, v in ipairs(sphere.vertices) do
		if v[3] >= 0 then
			filtVerts[#filtVerts + 1] = v
			remap[i] = #filtVerts
		end
	end
	for _, f in ipairs(sphere.faces) do
		if remap[f[1]] and remap[f[2]] and remap[f[3]] then
			filtFaces[#filtFaces + 1] = {remap[f[1]], remap[f[2]], remap[f[3]]}
		end
	end
	return filtVerts, filtFaces
end

-- Moves the grip to each icosphere vertex, records actual hand position per manikin,
-- and builds a coloured triangle-mesh reach envelope (one per manikin) via VRML.
-- Sphere is centred on the L5S1 joint and oriented so the +Z pole aligns with the L5S1 X-axis.
-- Vertex colour: red = short reach, green = full reach (normalised to sphere radius).
function ReachEnvelopeAnalysisIco(fam)
	local resInput = Ips.inputNumberWithDefault(
		"Icosphere resolution  (0=12 pts | 1=42 pts | 2=162 pts | 3=642 pts | 4=2562 pts)", 2)
	if resInput == nil then
		Ips.alert("Error in input!")
		return
	end
	local resolution = math.max(0, math.min(4, math.floor(resInput)))
	local radius = 2.0

	local ico = generateIcosphere(resolution, radius)
	print("Icosphere r"..tostring(resolution)..": "..tostring(#ico.vertices).." vertices, "..tostring(#ico.faces).." faces")

	local extentOpts = StringVector()
	extentOpts:push_back("Full sphere")
	extentOpts:push_back("Forward half  (L5S1 X direction)")
	local extentSel = Ips.inputDropDownList("Sphere extent",
		"Test the full sphere or only the forward hemisphere (L5S1 X direction)?", extentOpts)
	if extentSel == -1 then Ips.alert("Error in input!") return end

	local testVerts, testFaces
	if extentSel == 1 then
		testVerts, testFaces = filterSphereHalf(ico)
		print(string.format("Forward half selected: %d vertices, %d faces", #testVerts, #testFaces))
	else
		testVerts, testFaces = ico.vertices, ico.faces
		print("Full sphere selected.")
	end

	local reachGripVisualization = getReachGrip()
	local reachGripPoint = reachGripVisualization:getGripPoint()
	local handName = "Right Hand"
	if reachGripPoint:getHand() == 0 then handName = "Left Hand" end

	local ctrlPoints = fam:getControlPoints()
	local handPoint
	for i = 0, ctrlPoints:size() - 1 do
		if ctrlPoints[i]:getName() == handName then
			handPoint = ctrlPoints[i]
		end
	end
	if handPoint == nil then
		Ips.alert("Could not find "..handName.." control point.")
		return
	end

	local transGripOrigin = handPoint:getTarget()
	local mannames = fam:getManikinNames()
	local nManikins = mannames:size()
	local staticRoot = Ips.getGeometryRoot()
	local timeString = os.date("%Y-%m-%dT%H%M")

	-- Collect L5S1 transforms for all manikins upfront; manikin 0 sets sphere centre/orientation
	local L5S1Transforms = {}
	for j = 0, nManikins - 1 do
		L5S1Transforms[j] = fam:getJointTransformationForManikin(j, "L5S1")
		local L = L5S1Transforms[j]
		print(string.format("  Manikin %d (%s) L5S1: pos=(%.3f, %.3f, %.3f)  X-axis=(%.3f, %.3f, %.3f)",
			j+1, tostring(mannames[j]), L.tx, L.ty, L.tz, L.r1x, L.r2x, L.r3x))
	end
	local L5S1Trans = L5S1Transforms[0]   -- reference transform for sphere placement

	-- Initialise per-manikin hand-position tables: handPos[j][vertexIndex]
	local handPos = {}
	for j = 0, nManikins - 1 do
		handPos[j] = {}
	end

	-- Simulate: move grip once per vertex; IPS runs all manikins simultaneously.
	-- After each updateScreen, read each manikin's result via setRepresentative.
	print(string.format("Simulating %d vertices for %d manikin(s)...", #testVerts, nManikins))
	for i, target in ipairs(testVerts) do
		local vWorld = L5S1Trans:transform(Vector3d(target[3], target[2], -target[1]))
		local transGrip = Transf3.newIdentity()
		transGrip.tx = vWorld[0]
		transGrip.ty = vWorld[1]
		transGrip.tz = vWorld[2]
		reachGripVisualization:setTControl(transGrip)
		Ips.updateScreen()
		for j = 0, nManikins - 1 do
			if nManikins > 1 then fam:setRepresentative(j) end
			local th = handPoint:getTarget()
			handPos[j][i] = {th.tx, th.ty, th.tz}
		end
	end

	-- Build one coloured VRML envelope per manikin from collected hand positions
	for j = 0, nManikins - 1 do
		local manName = tostring(mannames[j])
		local L5S1j = L5S1Transforms[j]
		local cX, cY, cZ = L5S1j.tx, L5S1j.ty, L5S1j.tz

		local wrlPath = scriptPath.."/tempReachEnvelope.wrl"
		local wrlFile = io.open(wrlPath, "w")
		if wrlFile == nil then
			Ips.alert("Cannot write temporary file: "..wrlPath)
			break
		end
		wrlFile:write("#VRML V2.0 utf8\nShape {\n  geometry IndexedFaceSet {\n")
		wrlFile:write("    coord Coordinate { point [\n")
		for _, hp in ipairs(handPos[j]) do
			wrlFile:write(string.format("      %.6f %.6f %.6f,\n", hp[1], hp[2], hp[3]))
		end
		wrlFile:write("    ] }\n    color Color { color [\n")
		for _, hp in ipairs(handPos[j]) do
			local dx, dy, dz = hp[1] - cX, hp[2] - cY, hp[3] - cZ
			local normDist = math.min(1.0, math.sqrt(dx*dx + dy*dy + dz*dz) / radius)
			wrlFile:write(string.format("      %.4f %.4f 0.0,\n", 1.0 - normDist, normDist))
		end
		wrlFile:write("    ] }\n    colorPerVertex TRUE\n    coordIndex [\n")
		for _, face in ipairs(testFaces) do
			wrlFile:write(string.format("      %d %d %d -1\n", face[1]-1, face[2]-1, face[3]-1))
		end
		wrlFile:write("    ]\n  }\n}\n")
		wrlFile:close()

		local groupLabel = "ReachEnvelope_"..manName.."_"..timeString
		local geoGroup = Ips.createGeometryGroup(nil)
		geoGroup:setLabel(groupLabel)
		local geom = Ips.loadGeometry(wrlPath)
		if geom ~= nil then
			geom:setLabel("Envelope_"..manName)
			local group = staticRoot:findFirstExactMatch(groupLabel)
			Ips.moveTreeObject(geom, group)
			group:setExpanded(false)
		else
			Ips.alert("Failed to load envelope mesh for "..manName)
		end
	end

	reachGripVisualization:setTControl(transGripOrigin)
	Ips.updateScreen()
	Ips.alert("Reach envelope complete. "..tostring(nManikins).." envelope(s) created.")
end

-- UV-sphere variant of ReachEnvelopeAnalysis.
-- Uses a lat/lon (stacks × slices) sphere centred on the L5S1 joint, oriented so the
-- +Z pole aligns with the L5S1 X-axis.
-- Vertex colour: red = short reach, green = full reach (normalised to sphere radius).
function ReachEnvelopeAnalysisUV(fam)
	local stacksInput = Ips.inputNumberWithDefault(
		"UV sphere stacks (latitude bands)  (10 ≈ 146 pts | 18 ≈ 410 pts | 36 ≈ 1226 pts)", 10)
	if stacksInput == nil then Ips.alert("Error in input!") return end
	local slicesInput = Ips.inputNumberWithDefault(
		"UV sphere slices (longitude segments)  (e.g. 16 | 24 | 32)", 16)
	if slicesInput == nil then Ips.alert("Error in input!") return end

	local stacks = math.max(2, math.floor(stacksInput))
	local slices = math.max(3, math.floor(slicesInput))
	local radius = 2.0

	local uv = generateUVSphere(stacks, slices, radius)
	print(string.format("UV sphere %d stacks × %d slices: %d vertices, %d faces",
		stacks, slices, #uv.vertices, #uv.faces))

	local extentOpts = StringVector()
	extentOpts:push_back("Full sphere")
	extentOpts:push_back("Forward half  (L5S1 X direction)")
	local extentSel = Ips.inputDropDownList("Sphere extent",
		"Test the full sphere or only the forward hemisphere (L5S1 X direction)?", extentOpts)
	if extentSel == -1 then Ips.alert("Error in input!") return end

	local testVerts, testFaces
	if extentSel == 1 then
		testVerts, testFaces = filterSphereHalf(uv)
		print(string.format("Forward half selected: %d vertices, %d faces", #testVerts, #testFaces))
	else
		testVerts, testFaces = uv.vertices, uv.faces
		print("Full sphere selected.")
	end

	local reachGripVisualization = getReachGrip()
	local reachGripPoint = reachGripVisualization:getGripPoint()
	local handName = "Right Hand"
	if reachGripPoint:getHand() == 0 then handName = "Left Hand" end

	local ctrlPoints = fam:getControlPoints()
	local handPoint
	for i = 0, ctrlPoints:size() - 1 do
		if ctrlPoints[i]:getName() == handName then
			handPoint = ctrlPoints[i]
		end
	end
	if handPoint == nil then
		Ips.alert("Could not find "..handName.." control point.")
		return
	end

	local transGripOrigin = handPoint:getTarget()
	local mannames = fam:getManikinNames()
	local nManikins = mannames:size()
	local staticRoot = Ips.getGeometryRoot()
	local timeString = os.date("%Y-%m-%dT%H%M")

	-- Collect L5S1 transforms for all manikins upfront; manikin 0 sets sphere centre/orientation
	local L5S1Transforms = {}
	for j = 0, nManikins - 1 do
		L5S1Transforms[j] = fam:getJointTransformationForManikin(j, "L5S1")
		local L = L5S1Transforms[j]
		print(string.format("  Manikin %d (%s) L5S1: pos=(%.3f, %.3f, %.3f)  X-axis=(%.3f, %.3f, %.3f)",
			j+1, tostring(mannames[j]), L.tx, L.ty, L.tz, L.r1x, L.r2x, L.r3x))
	end
	local L5S1Trans = L5S1Transforms[0]   -- reference transform for sphere placement

	-- Initialise per-manikin hand-position tables: handPos[j][vertexIndex]
	local handPos = {}
	for j = 0, nManikins - 1 do
		handPos[j] = {}
	end

	-- Simulate: move grip once per vertex; IPS runs all manikins simultaneously.
	-- After each updateScreen, read each manikin's result via setRepresentative.
	print(string.format("Simulating %d vertices for %d manikin(s)...", #testVerts, nManikins))
	for i, target in ipairs(testVerts) do
		local vWorld = L5S1Trans:transform(Vector3d(target[3], target[2], -target[1]))
		local transGrip = Transf3.newIdentity()
		transGrip.tx = vWorld[0]
		transGrip.ty = vWorld[1]
		transGrip.tz = vWorld[2]
		reachGripVisualization:setTControl(transGrip)
		Ips.updateScreen()
		for j = 0, nManikins - 1 do
			if nManikins > 1 then fam:setRepresentative(j) end
			local th = handPoint:getTarget()
			handPos[j][i] = {th.tx, th.ty, th.tz}
		end
	end

	-- Build one coloured VRML envelope per manikin from collected hand positions
	for j = 0, nManikins - 1 do
		local manName = tostring(mannames[j])
		local L5S1j = L5S1Transforms[j]
		local cX, cY, cZ = L5S1j.tx, L5S1j.ty, L5S1j.tz

		local wrlPath = scriptPath.."/tempReachEnvelope.wrl"
		local wrlFile = io.open(wrlPath, "w")
		if wrlFile == nil then
			Ips.alert("Cannot write temporary file: "..wrlPath)
			break
		end
		wrlFile:write("#VRML V2.0 utf8\nShape {\n  geometry IndexedFaceSet {\n    solid FALSE\n")
		wrlFile:write("    coord Coordinate { point [\n")
		for _, hp in ipairs(handPos[j]) do
			wrlFile:write(string.format("      %.6f %.6f %.6f,\n", hp[1], hp[2], hp[3]))
		end
		wrlFile:write("    ] }\n    color Color { color [\n")
		for _, hp in ipairs(handPos[j]) do
			local dx, dy, dz = hp[1] - cX, hp[2] - cY, hp[3] - cZ
			local normDist = math.min(1.0, math.sqrt(dx*dx + dy*dy + dz*dz) / radius)
			wrlFile:write(string.format("      %.4f %.4f 0.0,\n", 1.0 - normDist, normDist))
		end
		wrlFile:write("    ] }\n    colorPerVertex TRUE\n    coordIndex [\n")
		for _, face in ipairs(testFaces) do
			wrlFile:write(string.format("      %d %d %d -1\n", face[1]-1, face[2]-1, face[3]-1))
		end
		wrlFile:write("    ]\n  }\n}\n")
		wrlFile:close()

		local groupLabel = "ReachEnvelope2_"..manName.."_"..timeString
		local geoGroup = Ips.createGeometryGroup(nil)
		geoGroup:setLabel(groupLabel)
		local geom = Ips.loadGeometry(wrlPath)
		if geom ~= nil then
			geom:setLabel("Envelope2_"..manName)
			local group = staticRoot:findFirstExactMatch(groupLabel)
			Ips.moveTreeObject(geom, group)
			group:setExpanded(false)
		else
			Ips.alert("Failed to load envelope mesh for "..manName)
		end
	end

	reachGripVisualization:setTControl(transGripOrigin)
	Ips.updateScreen()
	Ips.alert("Reach envelope 2 complete. "..tostring(nManikins).." envelope(s) created.")
end