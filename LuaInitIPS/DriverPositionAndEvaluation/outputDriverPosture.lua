function math.sign(x)
  return x>0 and 1 or x<0 and -1 or 0
end

--- Functions below can and should be updated based on definitions that will be added in upcoming revisions.

function getDriverHiptoEyeAngleFunction(fam,iMani) -- Right/LeftHip to Eyeside (mid-hip to center eye in Reed)
	local RightHipTrans = fam:getJointTransformationForManikin(iMani,"RightHip");
	local LeftHipTrans = fam:getJointTransformationForManikin(iMani,"LeftHip");
	local EyesideTrans = fam:getJointTransformationForManikin(iMani,"Eyeside");
	
	--Translate into vectors to be able to make an operation after obtaining translation vectors
	local midHipVec = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
	local EyesideVec = EyesideTrans["t"];
	
	--print(tostring(EyesideVec[0]));
	--Calculate vectors
	local midHip2EyesideVec = EyesideVec - midHipVec;
	local xyProject = math.sqrt((midHip2EyesideVec[0]^2) + (midHip2EyesideVec[1]^2))*math.sign(midHip2EyesideVec[0]);
	local hip2eyeAngle = math.deg(math.atan(xyProject/midHip2EyesideVec[2]));
	-- local hip2eyeAngle = math.deg(math.atan(midHip2EyesideVec[0]/midHip2EyesideVec[2]));
	--print("Hip-to-eye angle: " ..tostring(hip2eyeAngle));

	return hip2eyeAngle;
end

function getDriverHeadAngleFunction(fam,iMani) -- AtlantoAxial to Eyeside (Tragion to center eye in Reed)
	local AATrans = fam:getJointTransformationForManikin(iMani,"AtlantoAxial");
	local EyesideTrans = fam:getJointTransformationForManikin(iMani,"Eyeside");
		
	--Translate into vectors to be able to make an operation after obtaining translation vectors
	local AAVec = AATrans["t"];
	local EyesideVec = EyesideTrans["t"];
		
	--Calculate vectors
	local AA2EyesideVec = EyesideVec - AAVec;
	local xyProject = math.sqrt((AA2EyesideVec[0]^2) + (AA2EyesideVec[1]^2));
	local headAngle = math.deg(math.atan(AA2EyesideVec[2]/xyProject));
	--print("Head angle: " ..tostring(headAngle));

	return headAngle; 
end

function getDriverNeckAngleFunction(fam,iMani) -- T1T2 to AtlantoAxial (C7T1 to Tragion in Reed)
	local T1T2Trans = fam:getJointTransformationForManikin(iMani,"T1T2");
	local C6C7Trans = fam:getJointTransformationForManikin(iMani,"C6C7");
	local AATrans = fam:getJointTransformationForManikin(iMani,"AtlantoAxial");
	
	local C7T1Vec = (C6C7Trans["t"] + T1T2Trans["t"])/2;
	--Translate into vectors to be able to make an operation after obtaining translation vectors
	--local T1T2Vec = T1T2Trans["t"];
	local AAVec = AATrans["t"];

	--Calculate vectors
	local C7T12AAVec = AAVec - C7T1Vec;
	local xyProject = math.sqrt((C7T12AAVec[0]^2) + (C7T12AAVec[1]^2))*math.sign(C7T12AAVec[0]);
	local neckAngle = math.deg(math.atan(xyProject/C7T12AAVec[2]));
	--print("Neck angle: " ..tostring(neckAngle));

	return neckAngle;
end

function getDriverThoraxAngleFunction(fam,iMani) -- (T12L1 to C7T1 in Reed)
	local T12L1Trans = fam:getJointTransformationForManikin(iMani,"T12L1");
	local C6C7Trans = fam:getJointTransformationForManikin(iMani,"C6C7");
	local T1T2Trans = fam:getJointTransformationForManikin(iMani,"T1T2");
	local C7T1Vec = (C6C7Trans["t"] + T1T2Trans["t"])/2;
	
	--Translate into vectors to be able to make an operation after obtaining translation vectors
	local T12L1Vec = T12L1Trans["t"];

	--Calculate vectors
	local T12L1C7T1Vec = C7T1Vec - T12L1Vec;
	local xyProject = math.sqrt((T12L1C7T1Vec[0]^2) + (T12L1C7T1Vec[1]^2))*math.sign(T12L1C7T1Vec[0]);	
	local thoraxAngle = math.deg(math.atan(xyProject/T12L1C7T1Vec[2]));
	--print("Thorax angle: " ..tostring(thoraxAngle));

	return thoraxAngle; 
end

function getDriverAbdomenAngleFunction(fam,iMani) --  (L5S1 to T12L1 in Reed)
	local L5S1Trans = fam:getJointTransformationForManikin(iMani,"L5S1");
	local T12L1Trans = fam:getJointTransformationForManikin(iMani,"T12L1");
	
	--Translate L5S1 into vector to be able to make an operation after obtaining translation vectors
	local L5S1Vec = L5S1Trans["t"];
	local T12L1Vec = T12L1Trans["t"];
	
	--Calculate vectors
	local L5S1toT12L1Vec = T12L1Vec - L5S1Vec;
	local xyProject = math.sqrt((L5S1toT12L1Vec[0]^2) + (L5S1toT12L1Vec[1]^2))*math.sign(L5S1toT12L1Vec[0]);	
	local abdomenAngle = math.deg(math.atan(xyProject/L5S1toT12L1Vec[2]));
	--print("Abdomen angle: " ..tostring(abdomenAngle));

	return abdomenAngle; 
end

function getDriverPelvisAngleFunction(fam,iMani)
	local RightHipTrans = fam:getJointTransformationForManikin(iMani,"RightHip");
	local LeftHipTrans = fam:getJointTransformationForManikin(iMani,"LeftHip");
	local L5S1Trans = fam:getJointTransformationForManikin(iMani,"L5S1");
	
	--Set the middle point between hip joints
	local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
		
	--Translate L5S1 into vector to be able to make an operation after obtaining translation vectors
	local L5S1Vec = L5S1Trans["t"];

	--Calculate vectors from midHip to L5S1
	local midHip2L5S1Vec = L5S1Vec - midHip;
	local xyProject = math.sqrt((midHip2L5S1Vec[0]^2) + (midHip2L5S1Vec[1]^2))*math.sign(midHip2L5S1Vec[0]);	
	local pelvisAngle = math.deg(math.atan(xyProject/midHip2L5S1Vec[2]));
	--print("Pelvis angle: " ..tostring(pelvisAngle));
	
	return pelvisAngle; 	
end

function getDriverTorsoAngleFunction(fam,iMani)
	-- local root = Ips.getActiveObjectsRoot();
	-- local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);

	-- local RightHipTrans = fam:getJointTransformationForManikin(iMani,"RightHip");
	-- local LeftHipTrans = fam:getJointTransformationForManikin(iMani,"LeftHip");
	-- local RightShoulderTrans = fam:getJointTransformationForManikin(iMani,"RightGH");
	-- local LeftShoulderTrans = fam:getJointTransformationForManikin(iMani,"LeftGH");
	
	-- --Set the middle point between hip and shoulder joints
	-- local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
	-- local midShoulder = (RightShoulderTrans["t"] + LeftShoulderTrans["t"])/2;
	
	-- --Calculate vectors from midHip to L5S1
	-- local midHip2midShoulderVec = midShoulder - midHip;
	-- local xyProject = math.sqrt((midHip2midShoulderVec[0]^2) + (midHip2midShoulderVec[1]^2));	
	-- local torsoAngle = math.deg(math.atan(xyProject/midHip2midShoulderVec[2]));
	-- --print("Torso angle: " ..tostring(torsoAngle));
	
	-- return torsoAngle;
end

function getDriverThighAngleFunction(fam,iMani)
	local RightHipTrans = fam:getJointTransformationForManikin(iMani,"RightHip");
	local LeftHipTrans = fam:getJointTransformationForManikin(iMani,"LeftHip");
	local RightKneeTrans = fam:getJointTransformationForManikin(iMani,"RightKnee");
	local LeftKneeTrans = fam:getJointTransformationForManikin(iMani,"LeftKnee");
		
	--Set the middle point between hip and knee joints
	local midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
	local midKnee = (RightKneeTrans["t"] + LeftKneeTrans["t"])/2;
	
	--Calculate vectors from midHip to knee
	local diffVec = midKnee - midHip;
	local xyProject = math.sqrt((diffVec[0]^2) + (diffVec[1]^2));	
	local thighAngle = math.deg(math.atan(diffVec[2]/xyProject));
	--print("Thigh angle (from vertical to thigh): " ..tostring(thighAngle));
	
	return thighAngle; 
end


function getDriverRightKneeAngleFunction(fam,iMani)
	local RightKneeAngle = fam:getJointAngleForManikin(iMani,"RightKnee");
	local RightKneeAngDeg = 180-math.deg(RightKneeAngle[0]);
	--print("RightKneeAngle: " ..tostring(RightKneeAngDeg));
	
	return RightKneeAngDeg; 
end

function getDriverLeftKneeAngleFunction(fam,iMani)
	local LeftKneeAngle = fam:getJointAngleForManikin(iMani,"LeftKnee");
	local LeftKneeAngDeg = 180-math.deg(LeftKneeAngle[0]);
	--print("LeftKneeAngle: " ..tostring(LeftKneeAngDeg));	
	
	return LeftKneeAngDeg;
end

function getDriverRightElbowAngleFunction(fam,iMani)
	-- local root = Ips.getActiveObjectsRoot();
	-- local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);

	-- local RightElbowAngle = fam:getJointAngleForManikin(iMani,"RightElbow");
	-- local RightElbowAngDeg = math.deg(RightElbowAngle[0]);
	-- --print("RightElbowAngle: " ..tostring(RightElbowAngDeg));
	
	-- return RightElbowAngDeg;
end

function getDriverLeftElbowAngleFunction(fam,iMani)
	-- local root = Ips.getActiveObjectsRoot();
	-- local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);

	-- local LeftElbowAngle = fam:getJointAngleForManikin(iMani,"LeftElbow");
	-- local LeftElbowAngDeg = math.deg(LeftElbowAngle[0]);
	-- --print("LeftElbowAngle: " ..tostring(LeftElbowAngDeg));	
	
	-- return LeftElbowAngDeg;
end

function getMidHipFunction(fam,manID)
	-- Mid-hip Joint Centre
	local rightHipTrans = fam:getJointTransformationForManikin(manID,"RightHip");
	local leftHipTrans = fam:getJointTransformationForManikin(manID,"LeftHip");
	
	--Set the middle point between hip joints
	local midHip = (rightHipTrans["t"] + leftHipTrans["t"])/2;
	local MidHipX = midHip[0];
	local MidHipZ = midHip[2];
	
	return {MidHipX, MidHipZ};
end
	
function getEyeSideFunction(fam,manID)
	-- Eyeside Joint Centre
	local EyesideTrans = fam:getJointTransformationForManikin(manID,"Eyeside");
	local MidEyeX = EyesideTrans["tx"];
	local MidEyeZ = EyesideTrans["tz"];
	
	return {MidEyeX, MidEyeZ};
end