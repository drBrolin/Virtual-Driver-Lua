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