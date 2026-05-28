dofile(scriptPath.."/../DriverPositionAndEvaluation/geometryImport.lua");

function math.sign(x)
  return x>0 and 1 or x<0 and -1 or 0
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

function readStartPosture(fam)
	local famvis = fam:getVisualization();
	local neutralJointFile = scriptPath.."/../ManikinPosture/neutralJointData_"..famvis:getLabel()..".csv";
	print("neutralJointFile: " ..scriptPath.."/../ManikinPosture/neutralJointData_"..famvis:getLabel()..".csv");
	local lines = lines_from(neutralJointFile);
	
	-- Save all neutral variable values in ISO11226:2000 - Ergonomics — Evaluation of static working postures
	-- Vectors index starts at zero [0].
	local neutralManikinId = StringVector();
	local neutralHeadAxisRotationY = NumberVector();
	local neutralTorsoAxisRotationY = NumberVector();
	local neutralPelvisAxisRotationY = NumberVector();
	local neutralAnklePlantarDorsiFlexionRight = NumberVector();
	local neutralAnklePlantarDorsiFlexionLeft = NumberVector();
	
	--local jointAngle = NumberVector(); -- Initiate the jointAngle variable.
	
	-- print all line numbers and their contents
	for k,strLine in pairs(lines) do
		local iData = {};
		for iCells in (strLine .. ","):gmatch("([^,]*),") do 
			table.insert(iData, iCells);
		end
		--print(k,strLine);
		--print("iData[1]: "..tostring(iData[1]));
		if not(tostring(iData[1]) == "ManikinId") then -- Not first row
			neutralManikinId:push_back(tostring(iData[1]));
			neutralHeadAxisRotationY:push_back(tonumber(iData[2]));
			neutralTorsoAxisRotationY:push_back(tonumber(iData[3]));
			neutralPelvisAxisRotationY:push_back(tonumber(iData[4]));	
			neutralAnklePlantarDorsiFlexionRight:push_back(tonumber(iData[5]));
			neutralAnklePlantarDorsiFlexionLeft:push_back(tonumber(iData[6]));
			--print("Push back loop.");
		end
	end
	neutralData = {};
	for i = 0, neutralManikinId:size() - 1 do
		neutralData[i] = {neutralHeadAxisRotationY[i], neutralTorsoAxisRotationY[i], neutralPelvisAxisRotationY[i], neutralAnklePlantarDorsiFlexionRight[i], neutralAnklePlantarDorsiFlexionLeft[i]}; 
	end
	
	return neutralData;
end
	

function assessPosture(fam, manikin, neutralHeadAxisRotationY, neutralTorsoAxisRotationY, neutralPelvisAxisRotationY, neutralAnklePlantarDorsiFlexionRight, neutralAnklePlantarDorsiFlexionLeft)	

	-- ASSESMENT ANGLES FOR OCCUPANT PACKAGING --
		
	--- JOINT POSITIONS ---
	local RightHipTrans = fam:getJointTransformationForManikin(manikin,"RightHip");
	local LeftHipTrans = fam:getJointTransformationForManikin(manikin,"LeftHip");
	local L5S1Trans = fam:getJointTransformationForManikin(manikin,"L5S1");
	local T6T7Trans = fam:getJointTransformationForManikin(manikin,"T6T7");
	local T1T2Trans = fam:getJointTransformationForManikin(manikin,"T1T2");
	local C6C7Trans = fam:getJointTransformationForManikin(manikin,"C6C7");
	local AtlantoAxialTrans = fam:getJointTransformationForManikin(manikin,"AtlantoAxial");
	local EyesideTrans = fam:getJointTransformationForManikin(manikin,"Eyeside");
	local RightShoulderTrans = fam:getJointTransformationForManikin(manikin,"RightGH"); -- Or AC?
	local RightElbowTrans = fam:getJointTransformationForManikin(manikin,"RightElbow");
	local LeftShoulderTrans = fam:getJointTransformationForManikin(manikin,"LeftGH"); -- Or AC?
	local LeftElbowTrans = fam:getJointTransformationForManikin(manikin,"LeftElbow");
	local RightKneeTrans = fam:getJointTransformationForManikin(manikin,"RightKnee");
	local LeftKneeTrans = fam:getJointTransformationForManikin(manikin,"LeftKnee");
	local RightACTrans = fam:getJointTransformationForManikin(manikin,"RightAC");
	local LeftACTrans = fam:getJointTransformationForManikin(manikin,"LeftAC");
	
	--- EXTRA POSITIONS ---
	local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2; --Set the middle point between hip joints
	local C7T1 = (T1T2Trans["t"] + C6C7Trans["t"])/2;
	local midShoulder = (RightShoulderTrans["t"] + LeftShoulderTrans["t"])/2; --Set the middle point between shoulder joints
	
	--- LOCAL AXIS SYSTEMS ---
	local tHAS = AtlantoAxialTrans; -- Head Axis System
	local tetAngle = neutralHeadAxisRotationY; -- Adjust Axis System to neutral posture
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
	local tetAngle = neutralTorsoAxisRotationY; -- Adjust Axis System to neutral posture
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
	local tetAngle = neutralPelvisAxisRotationY; -- Adjust Axis System to neutral posture
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
	-- local headLatFlexion = math.deg(math.atan(tTASinv["r3"]:dot(tHASinv["r2"])/tTASinv["r2"]:dot(tHASinv["r2"]))); -- Right is positive.
	-- local headRotation = math.deg(math.atan(tTASinv["r2"]:dot(tHASinv["r1"])/tTASinv["r1"]:dot(tHASinv["r1"])))*-1; -- Right is positive.
	
	-- local headInclination = math.deg(math.acos(Vector3d(0,0,1):dot(tHASinv["r3"])));
	
	-- --- TRUNK ---	
	-- local trunkFlexion = math.deg(math.atan(tPASinv["r1"]:dot(tTASinv["r3"])/tPASinv["r3"]:dot(tTASinv["r3"]))); -- Forward is positive.
	-- local trunkLateralFlexion = math.deg(math.atan(tPASinv["r3"]:dot(tTASinv["r2"])/tPASinv["r2"]:dot(tTASinv["r2"]))); -- Right is positive.
	-- local trunkAxialRotation = math.deg(math.atan(tPASinv["r2"]:dot(tTASinv["r1"])/tPASinv["r1"]:dot(tTASinv["r1"])))*-1; -- Right is positive.
	-- local trunkInclination = math.deg(math.acos(Vector3d(0,0,1):dot(tTASinv["r3"])));
	
	-- local neckFlexionExtension = headInclination - trunkInclination;

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
	
	-- --- UPPER ARM EXTERNAL ROTATION --- 
	-- -- Equivalent to Right/LeftShoulderRotation
	-- -- However that is set to (-)15.3 in start posture and only goes to (-)35 at maximum external rotation. Should be +30 from start position.
	-- local neutralUpperArmExternalRotation = 15.3;
	-- jointAngle = fam:getJointAngleForManikin(manikin, "RightShoulderRotation"); 
	-- local RightUpperArmExternalRot = math.deg(jointAngle[0]) - neutralUpperArmExternalRotation;
	-- jointAngle = fam:getJointAngleForManikin(manikin, "LeftShoulderRotation"); 
	-- local LeftUpperArmExternalRot = (math.deg(jointAngle[0]) + neutralUpperArmExternalRotation)*-1; -- Should be minus if the neutral LeftShoulderRotation is used, which is negative.
	
	--- Elbow flexion/extension
	jointAngle = fam:getJointAngleForManikin(manikin, "RightElbow"); 
		local RightElbowFlexion = 170 - math.deg(jointAngle[0]);
	jointAngle = fam:getJointAngleForManikin(manikin, "LeftElbow"); 
		local LeftElbowFlexion = 170 - math.deg(jointAngle[0]);

	-- --- Forearm pronation/supination -- (Neutral = 0.2 degrees)
	-- jointAngle = fam:getJointAngleForManikin(manikin, "RightWristRotation"); 
		-- local RightForeArmRotation = math.deg(jointAngle[0])*-1;
	-- jointAngle = fam:getJointAngleForManikin(manikin, "LeftWristRotation"); 
		-- local LeftForeArmRotation = math.deg(jointAngle[0]);
	
	-- --- Wrist flexion/extension & Wrist ulnar/radial abduction, bent from midline
	-- local neutralWristFlexionExtension = -2.4;
	-- --local neutralWristUlnarRadialAbductionRight = 0.5;
	-- jointAngle = fam:getJointAngleForManikin(manikin, "RightWrist"); 
		-- local RightWristFlexion = math.deg(jointAngle[0]) - neutralWristFlexionExtension; 
		-- local RightWristAbduction = math.deg(jointAngle[1]);
	-- jointAngle = fam:getJointAngleForManikin(manikin, "LeftWrist"); 
		-- local LeftWristFlexion = math.deg(jointAngle[0]) - neutralWristFlexionExtension; 
		-- local LeftWristAbduction = math.deg(jointAngle[1])*-1;		
		
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
	
	-- --- Leg splay ---
	-- -- Pelvis LM vector --
	-- local vLM = LeftHipTrans["t"] - RightHipTrans["t"];
	-- local uvLM = vLM/vLM:length();
	-- -- SI vector --
	-- local uvSI = Vector3d(0, 0, 1);
	-- -- AP vector --
	-- local uvAP = uvLM:cross(uvSI);
		
	-- local legSplayRT = math.deg(math.atan(uvLM:dot(uvFemurRT)/uvAP:dot(uvFemurRT)))*-1;
	-- local legSplayLT = math.deg(math.atan(uvLM:dot(uvFemurLT)/uvAP:dot(uvFemurLT)));
	
	-- local neutralThighRotation = 0; -- 2 in StandingPropertiesV2.xml
	-- jointAngle = fam:getJointAngleForManikin(manikin, "RightHip"); 
	-- local thighRotRT = math.deg(jointAngle[2]) - neutralThighRotation;
	-- jointAngle = fam:getJointAngleForManikin(manikin, "LeftHip"); 
	-- local thighRotLT = (math.deg(jointAngle[2]) + neutralThighRotation)*-1; -- Left neutralThighRotation is negative.
	
	--- Knee flexion
	jointAngle = fam:getJointAngleForManikin(manikin, "RightKnee"); 
		local RightKneeFlexion = 180 - math.deg(jointAngle[0]); -- 180 degrees = the upper leg in line with the lower leg
	jointAngle = fam:getJointAngleForManikin(manikin, "LeftKnee"); 
		local LeftKneeFlexion = 180 - math.deg(jointAngle[0]);
	
	--- Ankle plantar flexion/dorsiflexion
	jointAngle = fam:getJointAngleForManikin(manikin, "RightAnkle"); 
		local RightAnklePlantarDorsiFlexion = 90-(neutralAnklePlantarDorsiFlexionRight - math.deg(jointAngle[0]));
	jointAngle = fam:getJointAngleForManikin(manikin, "LeftAnkle"); 
		local LeftAnklePlantarDorsiFlexion = 90-(neutralAnklePlantarDorsiFlexionLeft - math.deg(jointAngle[0]));
		
	--- PRINT CALCULATED ANGLE VALUES --- (Un/comment with --)
	-- comfortAngles = {
		-- headFlexion,
		-- headLatFlexion,
		-- headRotation,
		-- UpperArmFlexionRT,
		-- UpperArmElevationRT,
		-- UpperArmFlexionLT,
		-- UpperArmElevationLT,
		-- RightUpperArmExternalRot,
		-- LeftUpperArmExternalRot,
		-- RightElbowFlexion,
		-- LeftElbowFlexion,
		-- RightForeArmRotation,
		-- LeftForeArmRotation,
		-- RightWristAbduction,
		-- LeftWristAbduction,
		-- RightWristFlexion,
		-- LeftWristFlexion,
		-- torsoRecline,
		-- trunkThighRT,
		-- trunkThighLT,
		-- legSplayRT,
		-- legSplayLT,
		-- thighRotRT,
		-- thighRotLT,
		-- RightKneeFlexion,
		-- LeftKneeFlexion,
		-- RightAnklePlantarDorsiFlexion,
		-- LeftAnklePlantarDorsiFlexion};	
		
	local comfortAngles = {
		UpperArmFlexionRT,
		UpperArmFlexionLT,
		RightElbowFlexion,
		LeftElbowFlexion,
		torsoRecline,
		trunkThighRT,
		trunkThighLT,
		RightKneeFlexion,
		LeftKneeFlexion,
		RightAnklePlantarDorsiFlexion,
		LeftAnklePlantarDorsiFlexion};	
	
	-- -- Joint angle ranges
	-- --- From Porter and Gyi (1998)
	-- neckRange = {30,66}; -- Does not match headFlexion, needs to be checked.
	-- --- From Wolf et. al, 2022. The effects of stature, age, gender, and posture preferences on preferred joint angles after real driving.
	-- ankleRange = {85,113};
	-- kneeRange = {93,137};
	-- trunkThighRange = {78,118};
	-- shoulderRange = {5,45};
	-- elbowRange = {77,155};
	-- trunkToVertRange = {5,34}; -- torsoRecline
	-- ankleHipInclination = {11,22};
	return comfortAngles;
end

function createSagittalPlane(TsagPl, planeName, R, G, B)
	sagittalPlane = PrimitiveShape.createRectangle(2, 1, 10, 10); -- creates a rectangel 2x1 m.
	-- Rotates the plane to align with the "side view" that the sagittal plane tries to visualise.
	set(TsagPl, 'R.r1', Vector3d(TsagPl['r1z'], -1*TsagPl['r1x'], -1*TsagPl['r1y']));
	set(TsagPl, 'R.r2', Vector3d(TsagPl['r2z'], -1*TsagPl['r2x'], -1*TsagPl['r2y']));
	set(TsagPl, 'R.r3', Vector3d(TsagPl['r3z'], -1*TsagPl['r3x'], -1*TsagPl['r3y']));
	sagittalPlane:setTWorld(TsagPl); -- position the sagittal plane.
	sagittalPlane:setColor(R,G,B); 
	sagittalPlane:setLabel("sagittalPlane_"..planeName); -- naming the sphere
end

function findAttachmentControlPairs(attachmentPoints, controlPoints)
	local acPair = {};
	for ap = 0, attachmentPoints:size() - 1 do
		local apTest = attachmentPoints[ap]:toAttachPointVisualization():getAttachPoint();
		local apTestName = apTest:getName();
		-- print("apTestName: "..apTest:getName());
		local sameString = 0;
		local cp = 0;
		while sameString == 0 and cp < controlPoints:size() do
			local cpTestName = controlPoints[cp]:getName();
			-- print("cpTestName: "..cpTest:getName());
			local len_ap = #apTestName;
			local len_cp = #cpTestName;
			local min_len = math.min(len_ap, len_cp); -- Determine comparison length
			sameString = 1;
			-- Compare character by character
			for i = 1, min_len do
				if apTestName:sub(i, i) ~= cpTestName:sub(i, i) then
					sameString = 0;  -- mismatch position
				end
			end
			if sameString == 1 then  -- equal up to shortest length
				acPair[ap+1] = cp;
				print(tostring(ap+1)..". apTestName: "..apTest:getName()..". cpTestName: "..tostring(cp+1)..". "..cpTestName);
			end
			cp = cp + 1
		end
	end
	return acPair;
end

function getTestPositions(width_points, height_points, spacing, row_shift, angle_deg, objectName)
	local posTable = {};
	local posObj = getPositionObject(objectName):toPositionedTreeObject():getTControl();	
	
	local theta = math.rad(angle_deg);
	local cos_t = math.cos(theta);
	local sin_t = math.sin(theta);
	
	local x = -(width_points-1)/2 * spacing;
	local z = (height_points-1)/2 * spacing;

	-- Row-dependent shift (skew)
	x = x - (height_points-1)/2 * row_shift;

	-- Rotation around Y-axis
	local xr = x * cos_t - z * sin_t;
	local zr = x * sin_t + z * cos_t;
	local startPoint = {posObj["tx"]+xr, posObj["ty"], posObj["tz"]+zr};

	for j = 0, height_points - 1 do      -- rows (Z direction)
		posTable[j+1] = {};
		for i = 0, width_points - 1 do   -- columns (X direction)

			-- Base grid
			x = i * spacing;
			z = -j * spacing;

			-- Row-dependent shift (skew)
			x = x + j * row_shift;

			-- Rotation around Y-axis
			xr = x * cos_t - z * sin_t;
			zr = x * sin_t + z * cos_t;
			
			posTable[j+1][i+1] = {startPoint[1]+xr, startPoint[2], startPoint[3]+zr};		
		end
	end
	return posTable;
end

function getSWgrips(swGrips)
	local activeRoot = Ips.getActiveObjectsRoot();
	local belowRoot = activeRoot:getNextSibling();
	local obj = activeRoot;
	while (not(obj == nil) and not(obj:equals(belowRoot))) do
		-- Get attributes and check if VD_swGrip is true
		if (obj:getPublicAttributeValue("VD_swGrip") == "True") then
			print("VD SW Grip found");
			swGrips:push_back(obj);
		end
		obj = obj:getObjectBelow();
	end
	return swGrips;
end

function rotateObjectY(activeObject, rotY)
	local posObj = activeObject:toPositionedTreeObject();
	local trans = posObj:getTControl();

	local theta = math.rad(rotY);  -- convert to radians
    local c = math.cos(theta);
    local s = math.sin(theta);

	set(trans, 'R.r1', Vector3d(c, 0, s));
	set(trans, 'R.r2', Vector3d(0, 1, 0));
	set(trans, 'R.r3', Vector3d(-s, 0, c));
	posObj:setTControl(trans);
end