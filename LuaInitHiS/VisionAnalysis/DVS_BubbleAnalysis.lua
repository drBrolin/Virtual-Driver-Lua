function visionAnalysisSphere(sphereName,manViewPoint,viewPoint,geoGroupLabel)
	local objectsRoot = Ips.getActiveObjectsRoot();
	local staticRoot = Ips.getGeometryRoot();
	--2- find the first exact match, look for the name of the object
	local treeObj = objectsRoot:findFirstExactMatch(sphereName);
	
	--3- once we have the treeObject we can convert it to a positionedTreeObjectOfBox
	local sphereObject = treeObj:toPositionedTreeObject();
	local transSphere = sphereObject:getTWorld(); 
	-- void ManikinViewPoint.setTarget(Transf3 target)
				-- Sets the transformation of the view point.
				-- Argument:
				-- target: The view point transformation in world coordinates.
	--manViewPoint:setTarget(transSphere);
	viewPoint:setTWorld(transSphere);
			
	Ips.updateScreen();
				
	-- For each point check if if line of sight is blocked for the specified member of the specified family
				
	-- For each manikin
	local blockedFam = false;
	for j = 0, mannames:size() - 1 do
		print("Manikin "..tostring(j+1)..": "..mannames[j]);
			-- bool ManikinViewPoint.isViewBlockedForFamilyMember( ManikinFamily family, int memberIndex )
			-- Returns true if line of sight is blocked for the specified member of the specified family.
			-- Arguments:
			-- family: The manikin family.
			-- memberIndex: Member in the family.
			
		----> Step 5: If true create a green spere in the position	
		sphere = PrimitiveShape.createSphere(0.03,10,10); -- creates the sphere

		sphere:setTWorld(transSphere); -- position the sphere 
		local blockedView = manViewPoint:isViewBlockedForFamilyMember(fam,j);
		if blockedView then
			sphere:setColor(1,0,0);
			sphere:setLabel(sphereName.."_Blocked_"..mannames[j]); -- naming the sphere
			blockedFam = true;
		else
			sphere:setColor(0,1,0);
			sphere:setLabel(sphereName.."_Visible_"..mannames[j]); -- naming the sphere
		end
		local groupGeometry = staticRoot:findFirstExactMatch(geoGroupLabel);
		Ips.moveTreeObject(sphere, groupGeometry)
		groupGeometry:setExpanded(false);
	end
	if blockedFam then
		sphereObject:setColor(1,0,0);
	else
		sphereObject:setColor(0,1,0);
	end
end

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
local objectsRoot = Ips.getActiveObjectsRoot();
----> Select view point points to check.
local treeObjViewPoint = objectsRoot:findFirstExactMatch('View Point 1');
local viewPoint = treeObjViewPoint:toPositionedTreeObject();
local transViewPointOrigin = transViewPoint; -- Saving the original position to reset it to after the simulation.

local manSimController = ManikinSimulationController();
local manViewPoints = manSimController:getViewPointIDs();
-- for n = 0, manViewPoints:size() - 1 do
	-- print("Viewpoint "..tostring(n+1)..": "..manViewPoints[n]);
-- end
local manViewPoint = manSimController:getViewPoint(manViewPoints[0]);

local geoGroup = Ips.createGeometryGroup(nil);
local timeString = os.date("%Y-%m-%dT%H:%M");
local geoGroupLabel = 'DVS-Analysis_'..timeString;
geoGroup:setLabel(geoGroupLabel);
-- Get box and move view point to each point (nr of points defined by resolution within box).
---> Step 1: Get Box Coordinates
--1- goes to the root of active objects, gives it the name objectsRoot
sphereName = 'SphereD';
visionAnalysisSphere(sphereName,manViewPoint,viewPoint,geoGroupLabel);
sphereName = 'SphereC';
visionAnalysisSphere(sphereName,manViewPoint,viewPoint,geoGroupLabel);
sphereName = 'SphereB';
visionAnalysisSphere(sphereName,manViewPoint,viewPoint,geoGroupLabel);

--viewPoint:setTWorld(transViewPointOrigin); -- positions the hand grip in the saved original position




			

