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

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end