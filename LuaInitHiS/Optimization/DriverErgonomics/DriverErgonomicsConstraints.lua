
function getRoofDistanceCheck(iMani)
	local measuresRoot = Ips.getMeasuresRoot();
	local str = "roof_distance_"..tostring(iMani+1);
	local measure = measuresRoot:findFirstExactMatch(str):toDistanceMeasure();
	local result = 100;
	if ( measure:getDistance()*1000 > roofDistanceLimit) then
		result = 0;
	else
		result = 1;
	end
	return result;
end

function getKneeDistanceCheck(iMani)
	local measuresRoot = Ips.getMeasuresRoot();
	local str = "knee_distance_"..tostring(iMani+1);
	local measure = measuresRoot:findFirstExactMatch(str):toDistanceMeasure();
	local result = 100;
	if ( measure:getDistance()*1000 > kneeDistanceLimit) then
		result = 0;
	else
		result = 1;
	end
	return result;
end

function getThighDistanceCheck(iMani)
	local measuresRoot = Ips.getMeasuresRoot();
	local str = "thigh_distance_"..tostring(iMani+1);
	local measure = measuresRoot:findFirstExactMatch(str):toDistanceMeasure();
	local result = 100;
	if ( measure:getDistance()*1000 > thighDistanceLimit) then
		result = 0;
	else
		result = 1;
	end
	return result;
end

function getDriverDownViewAngleFunction(iMani) -- Right/LeftHip to Eyeside (mid-hip to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	local EyesideTrans = fam:getJointTransformationForManikin(iMani,"Eyeside");
	local topSW = root:findFirstExactMatch(steeringVisionObjectNameInScene):toPositionedTreeObject():getTControl();
	--Translate into vectors to be able to make an operation after obtaining translation vectors
	local topSWVec = topSW["t"];
	local EyesideVec = EyesideTrans["t"];
	local vec = topSWVec-EyesideVec;
	--Calculate vectors
	local downViewAngle = math.deg(math.atan(vec[2]/vec[0]));
	local result = 100;
	if ( downViewAngle > downViewAngleLimit) then
		result = 0;
	else
		result = 1;
	end
	return result;
end

function getAllDriverContraintCheck(iMani)
	local result = getRoofDistanceCheck(iMani) + getKneeDistanceCheck(iMani) + getThighDistanceCheck(iMani) + getDriverDownViewAngleFunction(iMani);
	return result;
end
