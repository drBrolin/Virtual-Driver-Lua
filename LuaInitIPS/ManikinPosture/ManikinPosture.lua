function math.sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

function getStartPosture(fam, jointFilenameCSV)
	jointAngleExportfile = io.open(jointFilenameCSV, "w");
	jointAngleExportfile:write("ManikinId,");
	
	-- Save all necessary variables 
	jointAngleExportfile:write("HeadAxisRotationY,");
	jointAngleExportfile:write("TorsoAxisRotationY,");
	jointAngleExportfile:write("PelvisAxisRotationY,");
	jointAngleExportfile:write("AnklePlantarDorsiFlexionRight,");
	jointAngleExportfile:write("AnklePlantarDorsiFlexionLeft,");
	jointAngleExportfile:write("\n");
	
	local jointAngle = NumberVector(); -- Initiate the jointAngle variable.
	
	-- Get manikins
	mannames = fam:getManikinNames();
	-- For each manikin
	for i = 0, mannames:size() - 1 do
		jointAngleExportfile:write("Manikin "..tostring(i+1)..": "..mannames[i]..",");
		
		--- JOINT POSITIONS ---
		local RightHipTrans = fam:getJointTransformationForManikin(i,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(i,"LeftHip");
		local L5S1Trans = fam:getJointTransformationForManikin(i,"L5S1");
		local T6T7Trans = fam:getJointTransformationForManikin(i,"T6T7");
		local T1T2Trans = fam:getJointTransformationForManikin(i,"T1T2");
		local C6C7Trans = fam:getJointTransformationForManikin(i,"C6C7");
		local AtlantoAxialTrans = fam:getJointTransformationForManikin(i,"AtlantoAxial");
		local EyesideTrans = fam:getJointTransformationForManikin(i,"Eyeside");
		local RightShoulderTrans = fam:getJointTransformationForManikin(i,"RightGH"); -- Or RightAC?
		local RightElbowTrans = fam:getJointTransformationForManikin(i,"RightElbow");
		local LeftShoulderTrans = fam:getJointTransformationForManikin(i,"LeftGH"); -- Or LeftAC?
		local LeftElbowTrans = fam:getJointTransformationForManikin(i,"LeftElbow");
		
		--- EXTRA POSITIONS ---
		local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2; --Set the middle point between hip joints
		local C7T1 = (T1T2Trans["t"] + C6C7Trans["t"])/2;
		local midShoulder = (RightShoulderTrans["t"] + LeftShoulderTrans["t"])/2; --Set the middle point between shoulder joints
		
		--- LOCAL AXIS SYSTEMS ---
		local tHAS = AtlantoAxialTrans; -- Head Axis System
		local HeadAxisRotationY = math.atan2(tHAS.r1z, tHAS.r3z) 
		-- print("HeadAxisRotationY: "..math.deg(tostring(HeadAxisRotationY)));
						
		local tTAS = T1T2Trans; -- Torso Axis System
		local TorsoAxisRotationY = math.atan2(tTAS.r1z, tTAS.r3z) 
		-- print("TorsoAxisRotationY: "..math.deg(tostring(TorsoAxisRotationY)));
		
		local tPAS = getPelvisAxisSystem(LeftHipTrans, RightHipTrans, L5S1Trans); -- Pelvis Axis System
		local PelvisAxisRotationY = math.atan2(tPAS.r1z, tPAS.r3z) 
		-- print("PelvisAxisRotationY: "..math.deg(tostring(PelvisAxisRotationY)));
						
		--- Ankle plantar flexion/dorsiflexion
		jointAngle = fam:getJointAngleForManikin(i, "RightAnkle"); local RightAnklePlantarDorsiFlexion = math.deg(jointAngle[0]);
		jointAngle = fam:getJointAngleForManikin(i, "LeftAnkle"); local LeftAnklePlantarDorsiFlexion = math.deg(jointAngle[0]);
	
		jointAngleExportfile:write(tostring(HeadAxisRotationY)..",");
		jointAngleExportfile:write(tostring(TorsoAxisRotationY)..",");
		jointAngleExportfile:write(tostring(PelvisAxisRotationY)..",");
		jointAngleExportfile:write(tostring(RightAnklePlantarDorsiFlexion)..",");
		jointAngleExportfile:write(tostring(LeftAnklePlantarDorsiFlexion)..",");
		jointAngleExportfile:write("\n");
	end
	jointAngleExportfile:close();
end

function getShoulderAxisSystem(LeftShoulderTrans, RightShoulderTrans, C7T1, L5S1Trans)
	-- A shoulder axis system (SAS) was created using the following steps: 
	-- 1) define the lateral/medial (LM) axis as the unit vector of the line from the Left to Right shoulder, 
	-- 2) define the anterior/posterior axis (AP) as the unit vector of the cross-product between the vector from L5/SI to C7/T1 and the LM axis, and 
	-- 3) define the superior/inferior axis as the cross product of the LM and AP axes
	
	-- References:
	-- La Delfa, N., Potvin, J., 2016. Multi-directional manual arm strength and its relationship with resultant shoulder moment and arm posture. Ergonomics. http://dx.doi.org/10.1080/00140139.2016.1157628.
	-- La Delfa, N., Freeman, C., Petruzzi, C., Potvin, J., 2014. Equations to predict female manual arm strength based on hand location relative to the shoulder. Ergonomics 57 (2), 254-261.

	-- LM vector --
	local vLM = LeftShoulderTrans["t"] - RightShoulderTrans["t"];
	local uvLM = vLM/vLM:length();
	
	-- AP vector --
	local vTorso = C7T1 - L5S1Trans["t"];
	local uvTorso = vTorso/vTorso:length();
	local uvAP = -1*uvTorso:cross(uvLM);
	--print("uvAP length: " ..tostring(uvAP:length()));
	
	-- SI vector --
	local uvSI = -1*uvLM:cross(uvAP);
	
	local transSAS = Transf3.newIdentity(); -- Shoulder Axis System
	set(transSAS, 't', (L5S1Trans["t"] + C7T1 +  RightShoulderTrans["t"] + LeftShoulderTrans["t"])/4); -- (L5S1Trans["t"] + C7T1)/2)
	set(transSAS, 'R.r1', Vector3d(uvAP[0], uvLM[0], uvSI[0]));
	set(transSAS, 'R.r2', Vector3d(uvAP[1], uvLM[1], uvSI[1]));
	set(transSAS, 'R.r3', Vector3d(uvAP[2], uvLM[2], uvSI[2]));
	return transSAS;
end

function getPelvisAxisSystem(LeftHipTrans, RightHipTrans, L5S1Trans)
	-- A pelvis axis system (PAS) is created using the following steps: 
	-- 1) define the lateral/medial (LM) axis as the unit vector of the line from the Left to Right hip, 
	-- 2) define the superior/inferior axis as the unit vector of the line from the midhip to L5S1 joint, and
	-- 3) define the anterior/posterior axis (AP) as the cross product of the LM and SI axes

	-- References (simplified for current version of manikin model):
	-- Wu G, van der Helm FC, Veeger HE, Makhsous M, Van Roy P, Anglin C, Nagels J, Karduna AR, McQuade K, Wang X, Werner FW, Buchholz B; International Society of Biomechanics. ISB recommendation on definitions of joint coordinate systems of various joints for the reporting of human joint motion--Part II: shoulder, elbow, wrist and hand. J Biomech. 2005 May;38(5):981-992. doi: 10.1016/j.jbiomech.2004.05.042. PMID: 15844264.

	-- LM vector --
	local vLM = LeftHipTrans["t"] - RightHipTrans["t"];
	local uvLM = vLM/vLM:length();
	
	-- SI vector --
	local vSI = L5S1Trans["t"]-(LeftHipTrans["t"] + RightHipTrans["t"])/2;
	local uvSI = vSI/vSI:length();
	
	-- AP vector --
	local uvAP = uvLM:cross(uvSI);
	
	local transPAS = Transf3.newIdentity(); -- Pelvis Axis System
	set(transPAS, 't', (L5S1Trans["t"] +  RightHipTrans["t"] + LeftHipTrans["t"])/3);
	set(transPAS, 'R.r1', Vector3d(uvAP[0], uvLM[0], uvSI[0]));
	set(transPAS, 'R.r2', Vector3d(uvAP[1], uvLM[1], uvSI[1]));
	set(transPAS, 'R.r3', Vector3d(uvAP[2], uvLM[2], uvSI[2]));
	return transPAS;
end

function vectorAngleToZ(point1, point2)
	local lineVec = point2 - point1;
	local xyProject = math.sqrt((lineVec[0]^2) + (lineVec[1]^2));	
	local lineAngle = math.deg(math.atan(xyProject/lineVec[2]));
	return lineAngle;
end

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

function currentPosture(fam, jointFilenameCSV)
	local famvis = fam:getVisualization();
	local neutralJointFile = scriptPath.."/neutralJointData_"..famvis:getLabel()..".csv";
	print("neutralJointFile: " ..scriptPath.."/neutralJointData_"..famvis:getLabel()..".csv");
	local lines = lines_from(neutralJointFile);
	
	-- Save all necessary neutral variable values
	-- Vectors index starts at zero [0].
	local neutralManikinId = StringVector();
	local neutralHeadAxisRotationY = NumberVector();
	local neutralTorsoAxisRotationY = NumberVector();
	local neutralPelvisAxisRotationY = NumberVector();
	local neutralAnklePlantarDorsiFlexionRight = NumberVector();
	local neutralAnklePlantarDorsiFlexionLeft = NumberVector();
	
	local jointAngle = NumberVector(); -- Initiate the jointAngle variable.
	
	-- print all line numbers and their contents
	for k,strLine in pairs(lines) do
		local iData = {};
		for iCells in (strLine .. ","):gmatch("([^,]*),") do 
			table.insert(iData, iCells);
		end
		--print(k,strLine);
		print("iData[1]: "..tostring(iData[1]));
		if not(tostring(iData[1]) == "ManikinId") then -- Not first row
			neutralManikinId:push_back(tostring(iData[1]));
			neutralHeadAxisRotationY:push_back(tonumber(iData[2]));
			neutralTorsoAxisRotationY:push_back(tonumber(iData[3]));
			neutralPelvisAxisRotationY:push_back(tonumber(iData[4]));	
			neutralAnklePlantarDorsiFlexionRight:push_back(tonumber(iData[5]));
			neutralAnklePlantarDorsiFlexionLeft:push_back(tonumber(iData[6]));
			print("Push back loop.");
		end
	end	
	
	jointAngleExportfile = io.open(jointFilenameCSV, "w");
	jointAngleExportfile:write("ManikinId,");
	
	-- ASSESMENT ANGLES FOR OCCUPANT PACKAGING --
	jointAngleExportfile:write("HeadFlexion,");
	jointAngleExportfile:write("HeadLateral,");
	jointAngleExportfile:write("HeadRotation,");
	jointAngleExportfile:write("UpperArmflexionRT,");
	jointAngleExportfile:write("UpperArmflexionLT,");
	jointAngleExportfile:write("UpperArmElevationRT,");
	jointAngleExportfile:write("UpperArmElevationLT,");
	jointAngleExportfile:write("HumeralRotationRT,");
	jointAngleExportfile:write("HumeralRotationLT,");
	jointAngleExportfile:write("ElbowincludedRT,");
	jointAngleExportfile:write("ElbowincludedLT,");
	jointAngleExportfile:write("ForearmTwistRT,");
	jointAngleExportfile:write("ForearmTwistLT,");
	jointAngleExportfile:write("WristUlnarDeviationRT,");
	jointAngleExportfile:write("WristUlnarDeviationLT,");
	jointAngleExportfile:write("WristFlexionRT,");
	jointAngleExportfile:write("WristFlexionLT,");
	jointAngleExportfile:write("TorsoRecline,");
	jointAngleExportfile:write("TrunkThighRT,");
	jointAngleExportfile:write("TrunkThighLT,");
	jointAngleExportfile:write("LegSplayRT,");
	jointAngleExportfile:write("LegSplayLT,");
	jointAngleExportfile:write("ThighRotationRT,");
	jointAngleExportfile:write("ThighRotationLT,");
	jointAngleExportfile:write("KneeincludedRT,");
	jointAngleExportfile:write("KneeincludedLT,");
	jointAngleExportfile:write("FootCalfincludedRT,");
	jointAngleExportfile:write("FootCalfincludedLT,");
	
	jointAngleExportfile:write("\n");
	
	-- Get manikins
	mannames = fam:getManikinNames();
	-- For each manikin
	for i = 0, mannames:size() - 1 do
		jointAngleExportfile:write("Manikin "..tostring(i+1)..": "..mannames[i]..",");
		
		--- JOINT POSITIONS ---
		local RightHipTrans = fam:getJointTransformationForManikin(i,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(i,"LeftHip");
		local L5S1Trans = fam:getJointTransformationForManikin(i,"L5S1");
		local T6T7Trans = fam:getJointTransformationForManikin(i,"T6T7");
		local T1T2Trans = fam:getJointTransformationForManikin(i,"T1T2");
		local C6C7Trans = fam:getJointTransformationForManikin(i,"C6C7");
		local AtlantoAxialTrans = fam:getJointTransformationForManikin(i,"AtlantoAxial");
		local EyesideTrans = fam:getJointTransformationForManikin(i,"Eyeside");
		local RightShoulderTrans = fam:getJointTransformationForManikin(i,"RightGH"); -- Or AC?
		local RightElbowTrans = fam:getJointTransformationForManikin(i,"RightElbow");
		local LeftShoulderTrans = fam:getJointTransformationForManikin(i,"LeftGH"); -- Or AC?
		local LeftElbowTrans = fam:getJointTransformationForManikin(i,"LeftElbow");
		local RightKneeTrans = fam:getJointTransformationForManikin(i,"RightKnee");
		local LeftKneeTrans = fam:getJointTransformationForManikin(i,"LeftKnee");
		local RightACTrans = fam:getJointTransformationForManikin(i,"RightAC");
		local LeftACTrans = fam:getJointTransformationForManikin(i,"LeftAC");
		
		--- EXTRA POSITIONS ---
		local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2; --Set the middle point between hip joints
		local C7T1 = (T1T2Trans["t"] + C6C7Trans["t"])/2;
		local midShoulder = (RightShoulderTrans["t"] + LeftShoulderTrans["t"])/2; --Set the middle point between shoulder joints
		
		--- LOCAL AXIS SYSTEMS ---
		local tHAS = AtlantoAxialTrans; -- Head Axis System
		local tetAngle = neutralHeadAxisRotationY[i]; -- Adjust Axis System to neutral posture
		local c = math.cos(tetAngle);
		local s = math.sin(tetAngle);
		local rotHAS = Transf3.newIdentity();
		set(rotHAS, 'R', Rot3(Vector3d(c,0,s), Vector3d(0,1,0), Vector3d(-s,0,c)));
		set(tHAS, 'r1', rotHAS:rotate(tHAS["r1"]));
		set(tHAS, 'r2', rotHAS:rotate(tHAS["r2"]));
		set(tHAS, 'r3', rotHAS:rotate(tHAS["r3"]));
		
		-- -- CREATE FRAME FOR HAS --
		-- local hasFrame = Frame();
		-- hasFrame:setSize(0.5);
		-- hasFrame:setTWorld(tHAS);
		-- hasFrame:setLabel("HeadAxisSystem");
					
		local tTAS = T1T2Trans; -- Torso Axis System
		local tetAngle = neutralTorsoAxisRotationY[i]; -- Adjust Axis System to neutral posture
		local c = math.cos(tetAngle);
		local s = math.sin(tetAngle);
		local rotTAS = Transf3.newIdentity();
		set(rotTAS, 'R', Rot3(Vector3d(c,0,s), Vector3d(0,1,0), Vector3d(-s,0,c)));
		set(tTAS, 'r1', rotTAS:rotate(tTAS["r1"]));
		set(tTAS, 'r2', rotTAS:rotate(tTAS["r2"]));
		set(tTAS, 'r3', rotTAS:rotate(tTAS["r3"]));
		
		-- -- CREATE FRAME FOR TAS --
		-- local tasFrame = Frame();
		-- tasFrame:setSize(0.5);
		-- tasFrame:setTWorld(tTAS);
		-- tasFrame:setLabel("TorsoAxisSystem");
	
		local tPAS = getPelvisAxisSystem(LeftHipTrans, RightHipTrans, L5S1Trans); -- Pelvis Axis System
		local tetAngle = neutralPelvisAxisRotationY[i]; -- Adjust Axis System to neutral posture
		local c = math.cos(tetAngle);
		local s = math.sin(tetAngle);
		local rotPAS = Transf3.newIdentity();
		set(rotPAS, 'R', Rot3(Vector3d(c,0,s), Vector3d(0,1,0), Vector3d(-s,0,c)));
		set(tPAS, 'r1', rotPAS:rotate(tPAS["r1"]));
		set(tPAS, 'r2', rotPAS:rotate(tPAS["r2"]));
		set(tPAS, 'r3', rotPAS:rotate(tPAS["r3"]));
		
		-- -- CREATE FRAME FOR PAS --
		-- local pasFrame = Frame();
		-- pasFrame:setSize(0.5);
		-- pasFrame:setTWorld(tPAS);
		-- pasFrame:setLabel("PelvisAxisSystem");	
		
		-- local tSAS = getShoulderAxisSystem(LeftShoulderTrans, RightShoulderTrans, C7T1, L5S1Trans);

		local tHASinv = tHAS;
		tHASinv["R"] = tHAS["R"]:inverse();
		local tTASinv = tTAS;
		tTASinv["R"] = tTAS["R"]:inverse();
		local tPASinv = tPAS;
		tPASinv["R"] = tPAS["R"]:inverse();
			
		--- HEAD ---	
		local headFlexion = math.deg(math.atan(tTASinv["r1"]:dot(tHASinv["r3"])/tTASinv["r3"]:dot(tHASinv["r3"]))); -- Forward is positive.
		local headLatFlexion = math.deg(math.atan(tTASinv["r3"]:dot(tHASinv["r2"])/tTASinv["r2"]:dot(tHASinv["r2"]))); -- Right is positive.
		local headRotation = math.deg(math.atan(tTASinv["r2"]:dot(tHASinv["r1"])/tTASinv["r1"]:dot(tHASinv["r1"])))*-1; -- Right is positive.
		
		local headInclination = math.deg(math.acos(Vector3d(0,0,1):dot(tHASinv["r3"])));
		
		--- TRUNK ---	
		local trunkFlexion = math.deg(math.atan(tPASinv["r1"]:dot(tTASinv["r3"])/tPASinv["r3"]:dot(tTASinv["r3"]))); -- Forward is positive.
		local trunkLateralFlexion = math.deg(math.atan(tPASinv["r3"]:dot(tTASinv["r2"])/tPASinv["r2"]:dot(tTASinv["r2"]))); -- Right is positive.
		local trunkAxialRotation = math.deg(math.atan(tPASinv["r2"]:dot(tTASinv["r1"])/tPASinv["r1"]:dot(tTASinv["r1"])))*-1; -- Right is positive.
		local trunkInclination = math.deg(math.acos(Vector3d(0,0,1):dot(tTASinv["r3"])));
		
		local neckFlexionExtension = headInclination - trunkInclination;

		--- UPPER ARM FLEXION --- --- Should check if the distance in plane is small relative to length. Then it is straight out of plane.
		local vUpperArmRT = RightElbowTrans["t"] - RightShoulderTrans["t"];
		local uvUpperArmRT = vUpperArmRT/vUpperArmRT:length();
		local UpperArmAntPostRT = math.deg(math.atan(tTASinv["r1"]:dot(uvUpperArmRT)/tTASinv["r2"]:dot(uvUpperArmRT)));  -- Forward is positive. -- Abduction
		local flexionRatioRT = 0;
		local elevationRatioRT = 0;
		local AntPostRatioRT = 0.5 * math.sin(math.rad(4*UpperArmAntPostRT-90)) + 0.5;
		if (math.cos(math.rad(2*UpperArmAntPostRT)) < 0) then
			flexionRatioRT = 1;
			elevationRatioRT = AntPostRatioRT;
		else 
			flexionRatioRT = AntPostRatioRT;
			elevationRatioRT = 1;
		end
		local UpperArmFlexionRT = flexionRatioRT * math.deg(math.atan(tTASinv["r1"]:dot(uvUpperArmRT)/tTASinv["r3"]:dot(uvUpperArmRT)))*-1; -- Forward is positive.
		local UpperArmElevationRT = elevationRatioRT * math.deg(math.atan(tTASinv["r2"]:dot(uvUpperArmRT)/tTASinv["r3"]:dot(uvUpperArmRT)));  -- Outward is positive. -- Abduction
		
		local vUpperArmLT = LeftElbowTrans["t"] - LeftShoulderTrans["t"];
		local uvUpperArmLT = vUpperArmLT/vUpperArmLT:length();
		local UpperArmAntPostLT = math.deg(math.atan(tTASinv["r1"]:dot(uvUpperArmLT)/tTASinv["r2"]:dot(uvUpperArmLT)));  -- Forward is positive. 
		local flexionRatioLT = 0;
		local elevationRatioLT = 0;
		local AntPostRatioLT = 0.5 * math.sin(math.rad(4*UpperArmAntPostLT-90)) + 0.5;
		if (math.cos(math.rad(2*UpperArmAntPostLT)) < 0) then
			flexionRatioLT = 1;
			elevationRatioLT = AntPostRatioLT;
		else 
			flexionRatioLT = AntPostRatioLT;
			elevationRatioLT = 1;
		end	
		local UpperArmFlexionLT = flexionRatioLT * math.deg(math.atan(tTASinv["r1"]:dot(uvUpperArmLT)/tTASinv["r3"]:dot(uvUpperArmLT)))*-1; -- Forward is positive.
		local UpperArmElevationLT = elevationRatioLT * math.deg(math.atan(tTASinv["r2"]:dot(uvUpperArmLT)/tTASinv["r3"]:dot(uvUpperArmLT)))*-1;  -- Outward is positive. -- Abduction
		
		--- UPPER ARM EXTERNAL ROTATION --- 
		-- Equivalent to Right/LeftShoulderRotation
		-- However that is set to (-)15.3 in start posture and only goes to (-)35 at maximum external rotation. Should be +30 from start position.
		local neutralUpperArmExternalRotation = 15.3;
		jointAngle = fam:getJointAngleForManikin(i, "RightShoulderRotation"); 
		local RightUpperArmExternalRot = math.deg(jointAngle[0]) - neutralUpperArmExternalRotation;
		jointAngle = fam:getJointAngleForManikin(i, "LeftShoulderRotation"); 
		local LeftUpperArmExternalRot = (math.deg(jointAngle[0]) + neutralUpperArmExternalRotation)*-1; -- Should be minus if the neutral LeftShoulderRotation is used, which is negative.
		
		--- Elbow flexion/extension
		jointAngle = fam:getJointAngleForManikin(i, "RightElbow"); 
			local RightElbowFlexion = 180 - math.deg(jointAngle[0]);
		jointAngle = fam:getJointAngleForManikin(i, "LeftElbow"); 
			local LeftElbowFlexion = 180 - math.deg(jointAngle[0]);

		--- Forearm pronation/supination -- (Neutral = 0.2 degrees)
		jointAngle = fam:getJointAngleForManikin(i, "RightWristRotation"); 
			local RightForeArmRotation = math.deg(jointAngle[0])*-1;
		jointAngle = fam:getJointAngleForManikin(i, "LeftWristRotation"); 
			local LeftForeArmRotation = math.deg(jointAngle[0]);
		
		--- Wrist flexion/extension & Wrist ulnar/radial abduction, bent from midline
		local neutralWristFlexionExtension = -2.4;
		--local neutralWristUlnarRadialAbductionRight = 0.5;
		jointAngle = fam:getJointAngleForManikin(i, "RightWrist"); 
			local RightWristFlexion = math.deg(jointAngle[0]) - neutralWristFlexionExtension; 
			local RightWristAbduction = math.deg(jointAngle[1]);
		jointAngle = fam:getJointAngleForManikin(i, "LeftWrist"); 
			local LeftWristFlexion = math.deg(jointAngle[0]) - neutralWristFlexionExtension; 
			local LeftWristAbduction = math.deg(jointAngle[1])*-1;		
			
		local torsoRecline = vectorAngleToZ(midHip, midShoulder);
		
		--- Trunk-thigh angle ---
		local vTrunkRT = RightACTrans["t"] - RightHipTrans["t"];
		local uvTrunkRT = vTrunkRT/vTrunkRT:length();
		local vFemurRT = RightKneeTrans["t"] - RightHipTrans["t"];
		local uvFemurRT = vFemurRT/vFemurRT:length();
		local trunkThighRT = math.deg(math.acos(uvTrunkRT:dot(uvFemurRT))); -- Angle between vectors
		
		local vTrunkLT = LeftACTrans["t"] - LeftHipTrans["t"];
		local uvTrunkLT = vTrunkLT/vTrunkLT:length();
		local vFemurLT = LeftKneeTrans["t"] - LeftHipTrans["t"];
		local uvFemurLT = vFemurLT/vFemurLT:length();
		local trunkThighLT = math.deg(math.acos(uvTrunkLT:dot(uvFemurLT))); -- Angle between vectors	
		
		--- Leg splay ---
		-- Pelvis LM vector --
		local vLM = LeftHipTrans["t"] - RightHipTrans["t"];
		local uvLM = vLM/vLM:length();
		-- SI vector --
		local uvSI = Vector3d(0, 0, 1);
		-- AP vector --
		local uvAP = uvLM:cross(uvSI);
			
		local legSplayRT = math.deg(math.atan(uvLM:dot(uvFemurRT)/uvAP:dot(uvFemurRT)))*-1;
		local legSplayLT = math.deg(math.atan(uvLM:dot(uvFemurLT)/uvAP:dot(uvFemurLT)));
		
		local neutralThighRotation = 0; -- 2 in StandingPropertiesV2.xml
		jointAngle = fam:getJointAngleForManikin(i, "RightHip"); 
		local thighRotRT = math.deg(jointAngle[2]) - neutralThighRotation;
		jointAngle = fam:getJointAngleForManikin(i, "LeftHip"); 
		local thighRotLT = (math.deg(jointAngle[2]) + neutralThighRotation)*-1; -- Left neutralThighRotation is negative.
		
		--- Knee flexion
		jointAngle = fam:getJointAngleForManikin(i, "RightKnee"); 
			local RightKneeFlexion = 180 - math.deg(jointAngle[0]); -- 180 degrees = the upper leg in line with the lower leg
		jointAngle = fam:getJointAngleForManikin(i, "LeftKnee"); 
			local LeftKneeFlexion = 180 - math.deg(jointAngle[0]);
		
		--- Ankle plantar flexion/dorsiflexion
		jointAngle = fam:getJointAngleForManikin(i, "RightAnkle"); 
			local RightAnklePlantarDorsiFlexion = 90-(neutralAnklePlantarDorsiFlexionRight[i] - math.deg(jointAngle[0]));
		jointAngle = fam:getJointAngleForManikin(i, "LeftAnkle"); 
			local LeftAnklePlantarDorsiFlexion = 90-(neutralAnklePlantarDorsiFlexionLeft[i] - math.deg(jointAngle[0]));
			
		--- PRINT CALCULATED ANGLE VALUES --- (Un/comment with --)
		-- print("headFlexion: "..tostring(headFlexion));
		-- print("headLatFlexion: "..tostring(headLatFlexion));
		-- print("headRotation: "..tostring(headRotation));
		-- print("headInclination: "..tostring(headInclination));
		-- print("trunkFlexion: "..tostring(trunkFlexion));
		-- print("trunkLateralFlexion: "..tostring(trunkLateralFlexion));
		-- print("trunkAxialRotation: "..tostring(trunkAxialRotation));
		-- print("trunkInclination: "..tostring(trunkInclination));
		-- print("neckFlexionExtension: "..tostring(neckFlexionExtension));
		-- print("torsoRecline: "..tostring(torsoRecline));
		-- print("UpperArmAntPostRT: "..tostring(UpperArmAntPostRT)..". flexionRatioRT: "..tostring(flexionRatioRT)..". elevationRatioRT: "..tostring(elevationRatioRT));
		-- print("UpperArmFlexionRT: "..tostring(UpperArmFlexionRT));
		-- print("UpperArmElevationRT: "..tostring(UpperArmElevationRT));
		-- print("UpperArmAntPostLT: "..tostring(UpperArmAntPostLT)..". flexionRatioLT: "..tostring(flexionRatioLT)..". elevationRatioLT: "..tostring(elevationRatioLT));
		-- print("UpperArmFlexionLT: "..tostring(UpperArmFlexionLT)); 
		-- print("UpperArmElevationLT: "..tostring(UpperArmElevationLT));
		-- print("RightUpperArmExternalRot: "..tostring(RightUpperArmExternalRot)..". LeftUpperArmExternalRot: "..tostring(LeftUpperArmExternalRot));
		-- print("RightElbowFlexion: "..tostring(RightElbowFlexion)..". LeftElbowFlexion: "..tostring(LeftElbowFlexion));
		-- print("RightForeArmRotation: "..tostring(RightForeArmRotation)..". LeftForeArmRotation: "..tostring(LeftForeArmRotation));
		-- print("RightWristFlexion: "..tostring(RightWristFlexion)..". LeftWristFlexion: "..tostring(LeftWristFlexion));
		-- print("RightWristAbduction: "..tostring(RightWristAbduction)..". LeftWristAbduction: "..tostring(LeftWristAbduction));
		-- print("trunkThighRT: "..tostring(trunkThighRT));
		-- print("trunkThighLT: "..tostring(trunkThighLT));
		-- print("legSplayRT: "..tostring(legSplayRT)..". legSplayLT: "..tostring(legSplayLT));
		-- print("thighRotRT: "..tostring(thighRotRT)..". thighRotLT: "..tostring(thighRotLT));
		-- print("RightKneeFlexion: "..tostring(RightKneeFlexion)..". LeftKneeFlexion: "..tostring(LeftKneeFlexion));
		-- print("RightAnklePlantarDorsiFlexion: "..tostring(RightAnklePlantarDorsiFlexion)..". LeftAnklePlantarDorsiFlexion: "..tostring(LeftAnklePlantarDorsiFlexion));
		
		jointAngleExportfile:write(tostring(headFlexion)..",");
		jointAngleExportfile:write(tostring(headLatFlexion)..",");
		jointAngleExportfile:write(tostring(headRotation)..",");
		jointAngleExportfile:write(tostring(UpperArmFlexionRT)..",");
		jointAngleExportfile:write(tostring(UpperArmElevationRT)..",");
		jointAngleExportfile:write(tostring(UpperArmFlexionLT)..",");
		jointAngleExportfile:write(tostring(UpperArmElevationLT)..",");
		jointAngleExportfile:write(tostring(RightUpperArmExternalRot)..",");
		jointAngleExportfile:write(tostring(LeftUpperArmExternalRot)..",");
		jointAngleExportfile:write(tostring(RightElbowFlexion)..",");
		jointAngleExportfile:write(tostring(LeftElbowFlexion)..",");
		jointAngleExportfile:write(tostring(RightForeArmRotation)..",");
		jointAngleExportfile:write(tostring(LeftForeArmRotation)..",");
		jointAngleExportfile:write(tostring(RightWristAbduction)..",");
		jointAngleExportfile:write(tostring(LeftWristAbduction)..",");
		jointAngleExportfile:write(tostring(RightWristFlexion)..",");
		jointAngleExportfile:write(tostring(LeftWristFlexion)..",");
		jointAngleExportfile:write(tostring(torsoRecline)..",");
		jointAngleExportfile:write(tostring(trunkThighRT)..",");
		jointAngleExportfile:write(tostring(trunkThighLT)..",");
		jointAngleExportfile:write(tostring(legSplayRT)..",");
		jointAngleExportfile:write(tostring(legSplayLT)..",");
		jointAngleExportfile:write(tostring(thighRotRT)..",");
		jointAngleExportfile:write(tostring(thighRotLT)..",");
		jointAngleExportfile:write(tostring(RightKneeFlexion)..",");
		jointAngleExportfile:write(tostring(LeftKneeFlexion)..",");
		jointAngleExportfile:write(tostring(RightAnklePlantarDorsiFlexion)..",");
		jointAngleExportfile:write(tostring(LeftAnklePlantarDorsiFlexion)..",");

		jointAngleExportfile:write("\n");
		print("Joint angle written to export file for manikin "..tostring(i));

	end
	jointAngleExportfile:close();
	
end

function displayAxisSystems(fam)
	local famvis = fam:getVisualization();
	local neutralJointFile = scriptPath.."/neutralJointData_"..famvis:getLabel()..".csv";
	print("neutralJointFile: " ..scriptPath.."/neutralJointData_"..famvis:getLabel()..".csv");
	local lines = lines_from(neutralJointFile);
	
	-- Save all necessary neutral variable values
	-- Vectors index starts at zero [0].
	local neutralManikinId = StringVector();
	local neutralHeadAxisRotationY = NumberVector();
	local neutralTorsoAxisRotationY = NumberVector();
	local neutralPelvisAxisRotationY = NumberVector();
	local neutralAnklePlantarDorsiFlexionRight = NumberVector();
	local neutralAnklePlantarDorsiFlexionLeft = NumberVector();
	
	local jointAngle = NumberVector(); -- Initiate the jointAngle variable.
	
	-- print all line numbers and their contents
	for k,strLine in pairs(lines) do
		local iData = {};
		for iCells in (strLine .. ","):gmatch("([^,]*),") do 
			table.insert(iData, iCells);
		end
		--print(k,strLine);
		print("iData[1]: "..tostring(iData[1]));
		if not(tostring(iData[1]) == "ManikinId") then -- Not first row
			neutralManikinId:push_back(tostring(iData[1]));
			neutralHeadAxisRotationY:push_back(tonumber(iData[2]));
			neutralTorsoAxisRotationY:push_back(tonumber(iData[3]));
			neutralPelvisAxisRotationY:push_back(tonumber(iData[4]));	
			neutralAnklePlantarDorsiFlexionRight:push_back(tonumber(iData[5]));
			neutralAnklePlantarDorsiFlexionLeft:push_back(tonumber(iData[6]));
			print("Push back loop.");
		end
	end	
		
	-- Get manikins
	mannames = fam:getManikinNames();
	-- For each manikin
	for i = 0, mannames:size() - 1 do
		
		--- JOINT POSITIONS ---
		local RightHipTrans = fam:getJointTransformationForManikin(i,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(i,"LeftHip");
		local L5S1Trans = fam:getJointTransformationForManikin(i,"L5S1");
		local T1T2Trans = fam:getJointTransformationForManikin(i,"T1T2");
		local C6C7Trans = fam:getJointTransformationForManikin(i,"C6C7");
		local AtlantoAxialTrans = fam:getJointTransformationForManikin(i,"AtlantoAxial");
		local RightShoulderTrans = fam:getJointTransformationForManikin(i,"RightGH"); -- Or AC?
		local LeftShoulderTrans = fam:getJointTransformationForManikin(i,"LeftGH"); -- Or AC?
		
		--- EXTRA POSITIONS ---
		local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2; --Set the middle point between hip joints
		local C7T1 = (T1T2Trans["t"] + C6C7Trans["t"])/2;
		local midShoulder = (RightShoulderTrans["t"] + LeftShoulderTrans["t"])/2; --Set the middle point between shoulder joints
		
		--- LOCAL AXIS SYSTEMS ---
		local tHAS = AtlantoAxialTrans; -- Head Axis System
		local tetAngle = neutralHeadAxisRotationY[i]; -- Adjust Axis System to neutral posture
		local c = math.cos(tetAngle);
		local s = math.sin(tetAngle);
		local rotHAS = Transf3.newIdentity();
		set(rotHAS, 'R', Rot3(Vector3d(c,0,s), Vector3d(0,1,0), Vector3d(-s,0,c)));
		set(tHAS, 'r1', rotHAS:rotate(tHAS["r1"]));
		set(tHAS, 'r2', rotHAS:rotate(tHAS["r2"]));
		set(tHAS, 'r3', rotHAS:rotate(tHAS["r3"]));
		
		-- CREATE FRAME FOR HAS --
		local hasFrame = Frame();
		hasFrame:setSize(0.5);
		hasFrame:setTWorld(tHAS);
		hasFrame:setLabel("HeadAxisSystem");
					
		local tTAS = T1T2Trans; -- Torso Axis System
		local tetAngle = neutralTorsoAxisRotationY[i]; -- Adjust Axis System to neutral posture
		local c = math.cos(tetAngle);
		local s = math.sin(tetAngle);
		local rotTAS = Transf3.newIdentity();
		set(rotTAS, 'R', Rot3(Vector3d(c,0,s), Vector3d(0,1,0), Vector3d(-s,0,c)));
		set(tTAS, 'r1', rotTAS:rotate(tTAS["r1"]));
		set(tTAS, 'r2', rotTAS:rotate(tTAS["r2"]));
		set(tTAS, 'r3', rotTAS:rotate(tTAS["r3"]));
		
		-- CREATE FRAME FOR TAS --
		local tasFrame = Frame();
		tasFrame:setSize(0.5);
		tasFrame:setTWorld(tTAS);
		tasFrame:setLabel("TorsoAxisSystem");
	
		local tPAS = getPelvisAxisSystem(LeftHipTrans, RightHipTrans, L5S1Trans); -- Pelvis Axis System
		local tetAngle = neutralPelvisAxisRotationY[i]; -- Adjust Axis System to neutral posture
		local c = math.cos(tetAngle);
		local s = math.sin(tetAngle);
		local rotPAS = Transf3.newIdentity();
		set(rotPAS, 'R', Rot3(Vector3d(c,0,s), Vector3d(0,1,0), Vector3d(-s,0,c)));
		set(tPAS, 'r1', rotPAS:rotate(tPAS["r1"]));
		set(tPAS, 'r2', rotPAS:rotate(tPAS["r2"]));
		set(tPAS, 'r3', rotPAS:rotate(tPAS["r3"]));
		
		-- CREATE FRAME FOR PAS --
		local pasFrame = Frame();
		pasFrame:setSize(0.5);
		pasFrame:setTWorld(tPAS);
		pasFrame:setLabel("PelvisAxisSystem");

	end

	
end