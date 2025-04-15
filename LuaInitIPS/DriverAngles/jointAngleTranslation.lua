function getPelvisAngle(fam, iMani)
	if not(fam == nil) then
		local RightHipTrans = fam:getJointTransformationForManikin(iMani,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(iMani,"LeftHip");
		local L5S1Trans = fam:getJointTransformationForManikin(iMani,"L5S1");
		
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
	return pelvisAngle;
end

function getTorsoAngle(fam, iMani)
	if not(fam == nil) then
		local RightHipTrans = fam:getJointTransformationForManikin(iMani,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(iMani,"LeftHip");
		local RightShoulderTrans = fam:getJointTransformationForManikin(iMani,"RightGH");
		local LeftShoulderTrans = fam:getJointTransformationForManikin(iMani,"LeftGH");
		
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
	return torsoAngle;
end

function getHipAngle(fam, iMani)
	if not(fam == nil) then
		local RightHipTrans = fam:getJointTransformationForManikin(iMani,"RightHip");
		local LeftHipTrans = fam:getJointTransformationForManikin(iMani,"LeftHip");
		local RightShoulderTrans = fam:getJointTransformationForManikin(iMani,"RightGH");
		local LeftShoulderTrans = fam:getJointTransformationForManikin(iMani,"LeftGH");
		local RightKneeTrans = fam:getJointTransformationForManikin(iMani,"RightKnee");
		local LeftKneeTrans = fam:getJointTransformationForManikin(iMani,"LeftKnee");
		
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
	return hipAngle1;
end

function getKneeAngle(fam, iMani)
	if not(fam == nil) then
		local RightKneeAngle = fam:getJointAngleForManikin(iMani,"RightKnee");
		local LeftKneeAngle = fam:getJointAngleForManikin(iMani,"LeftKnee");
		
		RightKneeAngDeg = math.deg(RightKneeAngle[0]);
		LeftKneeAngDeg = math.deg(LeftKneeAngle[0]);
		
		print("RightKneeAngle: " ..tostring(RightKneeAngDeg));
		print("LeftKneeAngle: " ..tostring(LeftKneeAngDeg));	
		-- Ips.alert("Knee angle:\nRight knee: "..tostring(RightKneeAngDeg).."\nLeft knee: "..tostring(LeftKneeAngDeg));		
		
	else
		Ips.alert("You need to select a family first.");
	end
end

function getNeckAngle(fam, iMani)
	if not(fam == nil) then
		local T1T2Trans = fam:getJointTransformationForManikin(iMani,"T1T2");  -- T1T2 to AtlantoAxial (C7T1 to Tragion in Reed)
		local C6C7Trans = fam:getJointTransformationForManikin(iMani,"C6C7");
		local AATrans = fam:getJointTransformationForManikin(iMani,"AtlantoAxial");
		
		local C7T1Vec = (C6C7Trans["t"] + T1T2Trans["t"])/2;
		--Translate into vectors to be able to make an operation after obtaining translation vectors
		--local T1T2Vec = T1T2Trans["t"];
		local AAVec = AATrans["t"];

		--Calculate vectors
		local C7T12AAVec = AAVec - C7T1Vec;
		local signVec =  math.abs(C7T12AAVec[0])/C7T12AAVec[0];	
		local xyProject = math.sqrt((C7T12AAVec[0]^2) + (C7T12AAVec[1]^2))*signVec;
		local neckAngle = math.deg(math.atan(xyProject/C7T12AAVec[2]));
		
		print("Neck angle: " ..tostring(neckAngle));
	else
		Ips.alert("You need to select a family first.");
	end
	return neckAngle;
end