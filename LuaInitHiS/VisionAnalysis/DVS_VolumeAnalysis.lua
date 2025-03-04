--Set up the manual input of the user
function selectManikinFamily()
	local root = Ips.getActiveObjectsRoot();
	local belowRoot = root:getNextSibling();
	local obj = root;
	familyvector = TreeObjectVector();
	while (not(obj == nil) and not(obj:equals(belowRoot))) do
		if (obj:isManikinFamilyVisualization()) then
			familyvector:push_back(obj); -- Push family in to familyvector
		end
		obj = obj:getObjectBelow();
	end
	
	familynames = StringVector();
	for i = 0, familyvector:size() - 1 do
		namefam = tostring(familyvector[i]:getLabel());
		familynames:push_back(namefam);
	end
	if (familyvector:size() == 1) then -- Checks if a selection of manikin family is needed.
		famvis = familyvector[0]:toManikinFamilyVisualization();
	elseif (familyvector:size() == 0) then
		Ips.alert("No manikin families exist in tree!");
		return; -- How is this inserted?
	else
		familySelection = Ips.inputDropDownList("Family selection", "Select the manikin family", familynames);
		if (familySelection == -1) then -- Hanterar fel
			Ips.alert("Error in input!");
			--return; -- How is this inserted?
		end
		famvis = familyvector[familySelection]:toManikinFamilyVisualization();
	end
	fam = famvis:getManikinFamily(); -- Get selected family.
	return fam;
end


fam = selectManikinFamily();
-- Get manikins
mannames = fam:getManikinNames();

-- Set up scene with positioned manikins and box to check direct vision requirements

-- Get box and move view point to each point (nr of points defined by resolution within box).
---> Step 1: Get Box Coordinates
--1- goes to the root of active objects, gives it the name objectsRoot
local objectsRoot = Ips.getActiveObjectsRoot();
--2- find the first exact match, look for the name of the object
local treeObj = objectsRoot:findFirstExactMatch('DVS_VA_BoxA');
-- Error handling if DVS_VA_Box is not rendered or found!

--3- once we have the treeObject we can convert it to a positionedTreeObjectOfBox
local positionedTreeObjectOfBox = treeObj:toPositionedTreeObject()
--4- from the positionedTreeObject we can get the boundary box
local globalBoundingBox = positionedTreeObjectOfBox:getBoundingBox();

--5- get length, width, height, 
local length = globalBoundingBox.xmax-globalBoundingBox.xmin
local width = globalBoundingBox.ymax-globalBoundingBox.ymin
local height = globalBoundingBox.zmax-globalBoundingBox.zmin

---> Step 2: Create points in increments
--We added the use of Vector3dVector which is a vector of 3d vectors which in turn contains coordinates of a 3d point. 
-- input by user: points
resDist = Ips.inputNumberWithDefault("Set the distance/resolution between points [mm]", 100); -- Should be checked.
if (resDist == nil) then -- Handle error
	 Ips.alert("Error in input!");
end
resDist = resDist/1000; -- convert to meter.

-- for each side
nLength = math.ceil(length/resDist)+1;
nWidth = math.ceil(width/resDist)+1;
nHeight = math.ceil(height/resDist)+1;

allpoints = Vector3dVector(); -- Creates a vector of 3d vector
x=globalBoundingBox.xmin;
y=globalBoundingBox.ymin;
z=globalBoundingBox.zmax;
-- Z first instead and zmax going down
for i = 0,nHeight-1 do
	z=globalBoundingBox.zmax-i*resDist;
	if ((i*resDist) > height) then
		z = globalBoundingBox.zmin;
	end
	for k = 0,nLength-1 do
		x=globalBoundingBox.xmin+k*resDist;
		if ((k*resDist) > length) then
			x = globalBoundingBox.xmin + length;
		end
		for j = 0,nWidth-1 do
			y=globalBoundingBox.ymin+j*resDist;
			if ((j*resDist) > width) then
				y = globalBoundingBox.ymin + width;
			end
			--print("Point "..tostring(x)..", "..tostring(y)..", "..tostring(z)..". ");
			point = Vector3d(x,y,z); -- A 3d vector contains coordinates for 3 dimensions
			allpoints:push_back(point); -- Puts the point at the end of the vectors
		end
	end
end
numberOfPoints = allpoints:size();
Ips.alert("Number of points " ..tostring(numberOfPoints).. "."); --> it needs a cancel button

-- Find Box B
local treeObj = objectsRoot:findFirstExactMatch('DVS_VA_BoxB');
local positionedTreeObjectOfBox = treeObj:toPositionedTreeObject()
local globalBoundingBox = positionedTreeObjectOfBox:getBoundingBox();

-- get max and min for x and y. 
local boxB_xMin = globalBoundingBox.xmin;
local boxB_yMax = globalBoundingBox.ymax;
local boxB_yMin = globalBoundingBox.ymin;
		
----> Select view point points to check.
local treeObjViewPoint = objectsRoot:findFirstExactMatch('View Point 1');
local viewPoint = treeObjViewPoint:toPositionedTreeObject();
local viewPointVis = treeObjViewPoint:toViewPointVisualization();
local transViewPoint = viewPoint:getTWorld(); -- gets the coordinates of the view point
local transViewPointOrigin = transViewPoint; -- Saving the original position to reset it to after the simulation.

local manSimController = ManikinSimulationController();
local manViewPoints = manSimController:getViewPointIDs();
-- for n = 0, manViewPoints:size() - 1 do
	-- print("Viewpoint "..tostring(n+1)..": "..manViewPoints[n]);
-- end
local manViewPoint = manSimController:getViewPoint(manViewPoints[0]);

local timeString = os.date("%Y-%m-%dT%H%M");
local fileName = "VisionAnalysis_"..timeString;
testedPoints = 0;
visiblePoints = 0;
local visionPointCloudfileVisible = io.open(scriptPath.."/"..fileName.."_Visible.xyz", "w");
local visionPointCloudfileBlocked = io.open(scriptPath.."/"..fileName.."_Blocked.xyz", "w");
for i = 0,numberOfPoints-1 do 	
	-- For each z-plane (every x*y point) check if any points on previous plane was visible. 
	-- -	Otherwise mark all as blocked.
	point = allpoints[i];
	if point[0] > boxB_xMin and point[1] < boxB_yMax and point[1] > boxB_yMin then
		-- Inside box B.
		print("P"..tostring(i+1).." is inside Box B."); -- naming the sphere
	else
		----> Step 3: Move grip to point including offset
		transViewPoint["tx"] = point[0];
		transViewPoint["ty"] = point[1]; 
		transViewPoint["tz"] = point[2];
		viewPoint:setTWorld(transViewPoint);
		
		Ips.updateScreen();	
		-- For each point check if if line of sight is blocked for the specified member of the specified family	
				
		-- For each manikin
		for j = 0, mannames:size() - 1 do
			--print("Manikin "..tostring(j+1)..": "..mannames[j]);
				-- bool ManikinViewPoint.isViewBlockedForFamilyMember( ManikinFamily family, int memberIndex )
				-- Returns true if line of sight is blocked for the specified member of the specified family.
				-- Arguments:
				-- family: The manikin family.
				-- memberIndex: Member in the family.
				
			----> Step 5: If true create a green spere in the position	
			-- sphere = PrimitiveShape.createSphere(0.03,10,10); -- creates the sphere
			-- sphere:setTWorld(transViewPoint); -- position the sphere 
			local blockedView = manViewPoint:isViewBlockedForFamilyMember(fam,j);
			if blockedView then
				-- sphere:setColor(1,0,0); -- red
				-- sphere:setLabel("P"..tostring(i+1).."_Blocked_"..mannames[j]); -- naming the sphere
				print("P"..tostring(i+1).."_Blocked_"..mannames[j]); -- naming the sphere
				visionPointCloudfileBlocked:write(""..tostring(point[0]).." "..tostring(point[1]).." "..tostring(point[2]).." 255 0 0\n");
			else
				-- sphere:setColor(0,1,0); -- green
				-- sphere:setLabel("P"..tostring(i+1).."_Visible_"..mannames[j]); -- naming the sphere
				print("P"..tostring(i+1).."_Visible_"..mannames[j]); -- naming the sphere
				visionPointCloudfileVisible:write(""..tostring(point[0]).." "..tostring(point[1]).." "..tostring(point[2]).." 0 255 0\n");
				visiblePoints = visiblePoints + 1;
			end
			-- local groupGeometry = staticRoot:findFirstExactMatch(geoGroupLabel);
			-- Ips.moveTreeObject(sphere, groupGeometry)
			-- groupGeometry:setExpanded(false);
		end
		testedPoints = testedPoints + 1;
	end
end	
print("Tested points: "..tostring(testedPoints)..", Visible points: "..tostring(visiblePoints)..", Percent visible: "..tostring(visiblePoints/testedPoints*100)); -- naming the sphere

visionPointCloudfileVisible:close();
visionPointCloudfileBlocked:close();
viewPoint:setTWorld(transViewPointOrigin); -- positions the view point in the saved original position
--Ips.inputOpenFile('*.xyz', scriptPath, fileName);
Ips.loadGeometry(scriptPath.."/"..fileName.."_Visible.xyz");
Ips.loadGeometry(scriptPath.."/"..fileName.."_Blocked.xyz");



	


			

