dofile(scriptPath.."/DriverErgonomicsManikinPosture.lua");

--LIMITATIONS!
--Gymbal locks not considered, just a user friendly function
--Issues if object is not well centered, child of a constraining parent... many things can go wrong

function rotateActiveObjectOnOneAxis(posTreeObj, axis, value) --PositionedTreeObject | "rx", "ry" or "rz" to rotate | value in Euler

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
	if( axis == "rx") then
		rx = math.rad(value);
	end
	if( axis == "ry") then
		ry = math.rad(value);
	end
	if(axis == "rz") then
		rz = math.rad(value);
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

-- DRIVER ANGLES -- Start
function getPelvisAngleFunction(fam,manID)
	
	-- TODO: Get the representative or a drop down of manikins
	if not(fam == nil) then
		local RightHipTrans = fam:getJointTransformationForManikin(manID,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(manID,"LeftHip");
		local L5S1Trans = fam:getJointTransformationForManikin(manID,"L5S1");
		
		--Set the middle point between hip joints
		local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
		
		--Translate L5S1 into vector to be able to make an operation after obtaining translation vectors
		local L5S1Vec = L5S1Trans["t"];

		--Calculate vectors from midHip to L5S1
		local midHip2L5S1Vec = L5S1Vec - midHip;
		
		pelvisAngle = math.deg(math.atan(midHip2L5S1Vec[0]/midHip2L5S1Vec[2]));
		print("Pelvis angle: " ..tostring(pelvisAngle));
		-- Ips.alert("Pelvis angle: " ..tostring(pelvisAngle));
		
	else
		Ips.alert("You need to select a family first.");
	end
end

function getTorsoAngleFunction(fam,manID)

	if not(fam == nil) then
		local RightHipTrans = fam:getJointTransformationForManikin(manID,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(manID,"LeftHip");
		local RightShoulderTrans = fam:getJointTransformationForManikin(manID,"RightGH");
		local LeftShoulderTrans = fam:getJointTransformationForManikin(manID,"LeftGH");
		
		--Set the middle point between hip and shoulder joints
		local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
		local midShoulder = (RightShoulderTrans["t"] + LeftShoulderTrans["t"])/2;
		
		--Calculate vectors from midHip to L5S1
		local midHip2midShoulderVec = midShoulder - midHip;
		
		torsoAngle = math.deg(math.atan(midHip2midShoulderVec[0]/midHip2midShoulderVec[2]));
		print("Torso angle: " ..tostring(torsoAngle));
		--Ips.alert("Torso angle: " ..tostring(torsoAngle));		
		
	else
		Ips.alert("You need to select a family first.");
	end
end

function getHipAngleFunction(fam,manID)

	if not(fam == nil) then
		local RightHipTrans = fam:getJointTransformationForManikin(manID,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(manID,"LeftHip");
		local RightShoulderTrans = fam:getJointTransformationForManikin(manID,"RightGH");
		local LeftShoulderTrans = fam:getJointTransformationForManikin(manID,"LeftGH");
		local RightKneeTrans = fam:getJointTransformationForManikin(manID,"RightKnee");
		local LeftKneeTrans = fam:getJointTransformationForManikin(manID,"LeftKnee");
		
		--Set the middle point between hip and shoulder joints
		local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
		local midShoulder = (RightShoulderTrans["t"] + LeftShoulderTrans["t"])/2;
		local midKnee = (RightKneeTrans["t"] + LeftKneeTrans["t"])/2;
				
		--midHip2midShoulder = b
		local diffVec = midShoulder - midHip;
		b = math.sqrt ( diffVec[0] * diffVec[0] + diffVec[2] * diffVec[2] );
		--midHip2midKnee = c
		local diffVec = midKnee - midHip;
		c = math.sqrt ( diffVec[0] * diffVec[0] + diffVec[2] * diffVec[2] );
		--midKnee2midShoulder = a
		local diffVec = midShoulder - midKnee;
		a = math.sqrt ( diffVec[0] * diffVec[0] + diffVec[2] * diffVec[2] );
			
		hipAngle1 = math.deg(math.acos((b*b + c*c - a*a) / (2*b*c)));
		print("Hip angle (from torso to thigh): " ..tostring(hipAngle1));
		
		--Calculate vectors from midHip to knee
		local diffVec = midKnee - midHip;
		hipAngle2 = math.deg(math.atan(diffVec[0]/diffVec[2]));
		print("Hip angle (from vertical to thigh): " ..tostring(hipAngle2));
		-- Ips.alert("Hip angle:\nFrom torso to thigh: "..tostring(hipAngle1).."\nFrom vertical to thigh: "..tostring(hipAngle2));
	
	else
		Ips.alert("You need to select a family first.");
	end
end

function getKneeAngleFunction(fam,manID)

	if not(fam == nil) then
		local RightKneeAngle = fam:getJointAngleForManikin(manID,"RightKnee");
		local LeftKneeAngle = fam:getJointAngleForManikin(manID,"LeftKnee");
		
		RightKneeAngDeg = math.deg(RightKneeAngle[0]);
		LeftKneeAngDeg = math.deg(LeftKneeAngle[0]);
		
		print("RightKneeAngle: " ..tostring(RightKneeAngDeg));
		print("LeftKneeAngle: " ..tostring(LeftKneeAngDeg));	
		-- Ips.alert("Knee angle:\nRight knee: "..tostring(RightKneeAngDeg).."\nLeft knee: "..tostring(LeftKneeAngDeg));		
		
	else
		Ips.alert("You need to select a family first.");
	end
end
-- DRIVER ANGLES -- End

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

fam = selectManikinFamily();

local namefam = fam:getVisualization():getLabel();
local groupNr = tonumber(string.sub(namefam, -1));
--print("groupNr: " ..tostring(groupNr));
-- Get list of points (h-point, eye-point, sw-point, sBackDeg)


--Name of geometries in scene. Double check there are not repeated names or the code will take the first one by default
saeHPointEquivalentNameInScene = 'SAE H-point equivalent';
steeringWheelNameInScene = 'SteeringWheel';
seatAdjustmentRangeNameInScene = 'SeatAdjRange';
steeringWheelAdjustmentRangeNameInScene = 'SteeringWheelAdjRange';
torsoNameInScene = "Torso"
buttockNameInScene = "Buttock";
MidEyeNameInScene = "MidEye 1";
opSeqNameInScene = "Operation Sequence "..tostring(groupNr);

local filenameCSV = "Group"..tostring(groupNr).."/testDataGroup"..tostring(groupNr)..".csv"; -- Could be changed to: static string Ips.inputOpenFile( string filter, string directory, string title )
local testDatafile = scriptPath.."/"..filenameCSV;
local lines = lines_from(testDatafile);

local tpSex = StringVector();
local tpId = StringVector();
local hPointX = NumberVector();
local hPointZ = NumberVector();
local eyePointX = NumberVector();
local eyePointZ = NumberVector();
local swPosX = NumberVector();
local swPosZ = NumberVector();
local sBackDeg = NumberVector();

-- print all line numbers and their contents
for k,strLine in pairs(lines) do
	local iData = {};
	for iCells in (strLine .. ","):gmatch("([^,]*),") do 
		table.insert(iData, iCells);
	end
	tpSex:push_back(iData[1]);
	tpId:push_back(iData[2]);
	hPointX:push_back(tonumber(iData[3]));
	hPointZ:push_back(tonumber(iData[4]));
	eyePointX:push_back(tonumber(iData[5]));
	eyePointZ:push_back(tonumber(iData[6]));
	swPosX:push_back(tonumber(iData[7]));
	swPosZ:push_back(tonumber(iData[8]));
	sBackDeg:push_back(tonumber(iData[9]));
end

-- Get manikins
mannames = fam:getManikinNames();
-- For each manikin

local objectsRoot = Ips.getActiveObjectsRoot();

local procRoot = Ips.getProcessRoot();
local opSeq = procRoot:findFirstExactMatch(opSeqNameInScene):toOperationSequence();
local obj = objectsRoot:findFirstExactMatch(saeHPointEquivalentNameInScene):toPositionedTreeObject();


local jointFilenameCSV = scriptPath.."/Group"..tostring(groupNr).."/testDataGroup"..tostring(groupNr).."JointAngles.csv"; -- Could be changed to: static string Ips.inputOpenFile( string filter, string directory, string title )
local jointAngleExportfile = io.open(jointFilenameCSV, "w");
--jointAngleExportfile:write("Manikin,H-pointX,H-pointZ,SWpointX,SWpointZ,EyepointX,EyepointZ\n");
jointAngleExportfile:write("ManikinID,");
--local nameVector = StringVector();
for n = 0, fam:getNumJoints() - 1 do
	local jointName = fam:getJointName(n);
	local jointAngle = fam:getJointAngleForManikin(0, jointName); -- Just take the first manikin to check the nr of joint angles for each joint.
	-- jointStr = jointName..", "..tostring(jointAngle:size());
	-- nameVector:push_back(jointStr);
	-- print(jointStr);
	for j = 0, jointAngle:size() - 1 do
		jointAngleExportfile:write(""..jointName.."_"..tostring(j)..",");
	end
end
jointAngleExportfile:write("HiptoEyeAngle,HeadAngle,NeckAngle,ThoraxAngle,AbdomenAngle,PelvisAngle,ThighAngle,RightKneeAngle,LeftKneeAngle,MidHipX,MidHipZ,MidEyeX,MidEyeZ");
jointAngleExportfile:write("\n");
local x0 = 2221.50;
local y0 = -380;
local z0 = 395;

for i = 0, mannames:size() - 1 do

	local id = i;
	print("Manikin "..tostring(i+1)..": "..mannames[i].."Manikin id: "..tostring(id));
	jointAngleExportfile:write("Manikin"..tostring(i+1).."_"..mannames[i]..",");
	
	-- for j = 0, tpId:size() - 1 do
		-- local sexTpId = tpSex[j].."_"..tpId[j];
		-- if mannames[i] == sexTpId then
			-- id = j;
		-- end
	-- end
	--print("Manikin id: "..tostring(id));
	-- Position and adjust H-point template (X,Z and SB-angle), SW and maybe eye-point (for whole family)

	-- Steering Wheel
	local objectsRootSteeringWheel = objectsRoot:findFirstExactMatch(steeringWheelNameInScene):toPositionedTreeObject(); 
	--local swGlobalCoor = objectsRootSteeringWheel:getTWorld();
	local swControlCoor = objectsRootSteeringWheel:getTControl();

	trans = swControlCoor;
	trans["tx"] = (swPosX[id]+x0)/1000;
	trans["tz"] = (swPosZ[id]+z0)/1000;
	-- print(tostring("SW_X: "..trans["tx"]));
	-- print(tostring("SW_Z: "..trans["tz"]));
	objectsRootSteeringWheel:setTControl(trans);
	
	-- Seat H-point template
	local objectsRootSae = objectsRoot:findFirstExactMatch(saeHPointEquivalentNameInScene):toPositionedTreeObject();
	--local saeGlobalCoor = objectsRootSae:getTWorld();
	local saeControlCoor = objectsRootSae:getTControl(); 
	
	trans = saeControlCoor;
	trans["tx"] = (hPointX[id]+x0)/1000;
	trans["tz"] = (hPointZ[id]+z0)/1000;
	-- print("SAE_X: "..tostring(trans["tx"]));
	-- print("SAE_Z: "..tostring(trans["tz"]));
	objectsRootSae:setTControl(trans);
	
	-- Seat back angle
	local posTreeObjTorso = objectsRoot:findFirstExactMatch(torsoNameInScene):toPositionedTreeObject(); 
	local torsoControlCoor = objectsRootSteeringWheel:getTControl();
	trans = torsoControlCoor;
	rotateActiveObjectOnOneAxis(posTreeObjTorso,"rx",0);
	rotateActiveObjectOnOneAxis(posTreeObjTorso,"rz",0);
	rotateActiveObjectOnOneAxis(posTreeObjTorso,"ry",sBackDeg[id]);

	-- Eyepoint
	local posTreeObjMidEye = objectsRoot:findFirstExactMatch(MidEyeNameInScene):toPositionedTreeObject();
	local eyeControlCoor = posTreeObjMidEye:getTControl(); 
	
	trans = eyeControlCoor;
	trans["tx"] = (eyePointX[id]+x0)/1000;
	trans["tz"] = (eyePointZ[id]+z0)/1000;
	-- print("EyeZ: "..tostring(trans["tz"]));
	print("EyeX: "..tostring(trans["tx"]));
	posTreeObjMidEye:setTControl(trans);
	
	
	--Execute sequence and set last frame when manikins are well attached
	opSeq:executeSequence(); -- It would be nice give a name to each sequence
	local opSeqTreeObj = procRoot:findFirstExactMatch(opSeqNameInScene);
	local timeline = opSeqTreeObj:getLastChild():toTimelineReplay();
	timeline:setTime(timeline:getFinalTime());
	Ips.updateScreen();
					
	-- local RightHipTrans = fam:getJointTransformationForManikin(iMani,"RightHip");
	
	-- Check specific manikin
	-- Export angles and mid-hip joint centre
	-- Raw Joint Angles
	
	-- local nrJoints = fam:getNumJoints();	
	-- print(tostring(nrJoints));
	-- local jointAngles = {nrJoints};
	for n = 0, fam:getNumJoints() - 1 do
		local jointName = fam:getJointName(n);
		local jointAngle = fam:getJointAngleForManikin(i, jointName);
		--print("Joint vector size: " ..tostring(jointAngle:size()));
		for j = 0, jointAngle:size() - 1 do
			jointAngleExportfile:write(tostring(jointAngle[j])..",");
		end
		--jointAngles[n+1] = jointAngle;
	end
		
	-- Driver angles
	-- getPelvisAngleFunction(fam,i);
	-- getTorsoAngleFunction(fam,i);
	-- getHipAngleFunction(fam,i);
	-- getKneeAngleFunction(fam,i);
	local HiptoEyeAngle = getDriverHiptoEyeAngleFunction(fam,i);
	local HeadAngle = getDriverHeadAngleFunction(fam,i);
	local NeckAngle = getDriverNeckAngleFunction(fam,i);
	local ThoraxAngle = getDriverThoraxAngleFunction(fam,i);
	local AbdomenAngle = getDriverAbdomenAngleFunction(fam,i);
	local PelvisAngle = getDriverPelvisAngleFunction(fam,i);
	local ThighAngle = getDriverThighAngleFunction(fam,i);
	local RightKneeAngle = getDriverRightKneeAngleFunction(fam,i);
	local LeftKneeAngle = getDriverLeftKneeAngleFunction(fam,i);
	
	-- getDriverNeckAngleFunction(i)
		
	-- Mid-hip Joint Centre
	local rightHipTrans = fam:getJointTransformationForManikin(i,"RightHip");
	local leftHipTrans = fam:getJointTransformationForManikin(i,"LeftHip");
	
	--Set the middle point between hip joints
	local midHip = (rightHipTrans["t"] + leftHipTrans["t"])/2;
	local MidHipX = midHip[0];
	local MidHipZ = midHip[2];
	
	-- Eyeside Joint Centre
	local EyesideTrans = fam:getJointTransformationForManikin(i,"Eyeside");
	local MidEyeX = EyesideTrans["tx"];
	local MidEyeZ = EyesideTrans["tz"];
	-- Additional output?
	
	-- print(tostring(midHip));
	jointAngleExportfile:write(tostring(HiptoEyeAngle)..","..tostring(HeadAngle)..","..tostring(NeckAngle)..","..tostring(ThoraxAngle)..","..tostring(AbdomenAngle)..","..tostring(PelvisAngle)..","..tostring(ThighAngle)..","..tostring(RightKneeAngle)..","..tostring(LeftKneeAngle)..","..tostring(MidHipX)..","..tostring(MidHipZ)..","..tostring(MidEyeX)..","..tostring(MidEyeZ));
	--print(tostring(jointAngles[15][1]));
	jointAngleExportfile:write("\n");
	--Ips.alert("Manikin "..tostring(i+1)..": "..mannames[i].." with id "..tostring(id).." positioned.\nRightKneeAngle: "..tostring(RightKneeAngle)..", LeftKneeAngle: "..tostring(LeftKneeAngle));

	print("Manikin "..tostring(i+1)..": "..mannames[i].." with id "..tostring(id).." positioned.\nRightKneeAngle: "..tostring(RightKneeAngle)..", LeftKneeAngle: "..tostring(LeftKneeAngle)..", MidEyeX: "..tostring(MidEyeX));
end

jointAngleExportfile:close();

-- Save to CSV-file
-- Results should statistically analyse to generate new strategy-files and comfort evaluation model

