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

function getGender(manName)
	LetterOne =  string.sub (manName[0], 1 , 4);
	if (LetterOne == "Fema") then
		gender = 0;
	elseif (LetterOne == "Male") then
		gender = 1;

	else
		genders = StringVector();
		genders:push_back("Female");
		genders:push_back("Male");
		gender = Ips.inputDropDownList("Cascade modelling", "Select gender for the manikin.", genders);
		if (gender == -1) then -- Hanterar fel
			Ips.alert("Error in input!");
			--return; -- How is this inserted?
		end
	end
	return gender;
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
local treeObj = objectsRoot:findFirstExactMatch('VisionBox');

--3- once we have the treeObject we can convert it to a positionedTreeObjectOfBox
local positionedTreeObjectOfBox = treeObj:toPositionedTreeObject()
--4- from the positionedTreeObject we can get the boundary box
local globalBoundingBox = positionedTreeObjectOfBox:getBoundingBox();

--5- get length, width, height, 
local length = globalBoundingBox.xmax-globalBoundingBox.xmin
local width = globalBoundingBox.ymax-globalBoundingBox.ymin
local height = globalBoundingBox.zmax-globalBoundingBox.zmin
-- x,y,z coordinates
local xcoord = (globalBoundingBox.xmax+globalBoundingBox.xmin)/2
local ycoord = (globalBoundingBox.ymax+globalBoundingBox.ymin)/2
local zcoord = (globalBoundingBox.zmax+globalBoundingBox.zmin)/2


---> Step 2: Create points in increments
--We added the use of Vector3dVector which is a vector of 3d vectors which in turn contains coordinates of a 3d point. 
-- input by user: points
checkpoints = Ips.inputNumberWithDefault("Set the number of points on each side to check", 2); -- Should be checked.
if (checkpoints == nil) then -- Handle error
	 Ips.alert("Error in input!");
end

numberOfPoints = (checkpoints+1)^3;
Ips.alert("Number of points " ..tostring(numberOfPoints).. "."); --> it needs a cancel button
allpoints = Vector3dVector(); -- Creates a vector of 3d vector
x=globalBoundingBox.xmin;
y=globalBoundingBox.ymin;
z=globalBoundingBox.zmin;
for k = 0,checkpoints do
	x=globalBoundingBox.xmin+1/checkpoints*k*length; 
	for j = 0,checkpoints do
		y=globalBoundingBox.ymin+1/checkpoints*j*width;
		for i = 0,checkpoints do
			z=globalBoundingBox.zmin+1/checkpoints*i*height;
			point = Vector3d(x,y,z); -- A 3d vector contains coordinates for 3 dimensions
			allpoints:push_back(point); -- Puts the point at the end of the vectors
		end
	end
end

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

local staticRoot = Ips.getGeometryRoot();
local geoGroup = Ips.createGeometryGroup(nil);
local timeString = os.date("%Y-%m-%dT%H:%M");
local geoGroupLabel = 'VisionAnalysis_'..timeString;
geoGroup:setLabel(geoGroupLabel);

for i = 0,numberOfPoints-1 do 
	void ManikinViewPoint.setTarget(Transf3 target)
			Sets the transformation of the view point.
			Argument:
			target: The view point transformation in world coordinates.
			
	move('ViewPoint') to (allpoints[i]) 
	point = allpoints[i];
	----> Step 3: Move grip to point including offset
	transViewPoint["tx"] = point[0];
	transViewPoint["ty"] = point[1]; 
	transViewPoint["tz"] = point[2];
	viewPoint:setTWorld(transViewPoint); -- positions the hand grip in the coordinates
	
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
		sphere:setTWorld(transViewPoint); -- position the sphere 
		sphere = PrimitiveShape.createSphere(0.03,10,10); -- creates the sphere
		local blockedView = manViewPoint:isViewBlockedForFamilyMember(fam,j);
		if blockedView then
			sphere:setColor(1,0,0);
			sphere:setLabel("P"..tostring(i+1).."_Blocked_"..mannames[j]); -- naming the sphere
			print("P"..tostring(i+1).."_Blocked_"..mannames[j]); -- naming the sphere
		else
			sphere:setColor(0,1,0);
			sphere:setLabel("P"..tostring(i+1).."_Visible_"..mannames[j]); -- naming the sphere
			print("P"..tostring(i+1).."_Visible_"..mannames[j]); -- naming the sphere
		end
		local groupGeometry = staticRoot:findFirstExactMatch(geoGroupLabel);
		Ips.moveTreeObject(sphere, groupGeometry)
		groupGeometry:setExpanded(false);
	end
end	

viewPoint:setTWorld(transViewPointOrigin); -- positions the hand grip in the saved original position




			

