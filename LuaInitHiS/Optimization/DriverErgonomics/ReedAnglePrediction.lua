
--RMSE definitions by Reed
femaleRMSE = NumberVector();
femaleRMSE:push_back(4.1*nrRMSE);
femaleRMSE:push_back(5.3*nrRMSE);
femaleRMSE:push_back(5.7*nrRMSE);
femaleRMSE:push_back(7*nrRMSE);
femaleRMSE:push_back(9.4*nrRMSE);
femaleRMSE:push_back(13.9*nrRMSE);
femaleRMSE:push_back(4.5*nrRMSE);
femaleRMSE:push_back(8.7*nrRMSE);

maleRMSE = NumberVector();
maleRMSE:push_back(3.3*nrRMSE);
maleRMSE:push_back(5*nrRMSE);
maleRMSE:push_back(6.5*nrRMSE);
maleRMSE:push_back(4.3*nrRMSE);
maleRMSE:push_back(11.4*nrRMSE);
maleRMSE:push_back(13.2*nrRMSE);
maleRMSE:push_back(4.4*nrRMSE);
maleRMSE:push_back(8.9*nrRMSE);


--Reed posture prediction equations
function evaDriverHiptoEyeAngleFunction(iMani, iManiName) -- Right/LeftHip to Eyeside (mid-hip to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	
-- Manikin anthro measures 
	local stature = fam:getMeasure(iMani,anthroMeasVec[1]); -- !!! Here check the order in the anthroMeasVec
	local weight = fam:getMeasure(iMani,anthroMeasVec[0]);
	local sitheight = fam:getMeasure(iMani,anthroMeasVec[12]);
	local bmi = weight/(stature/1000 * stature/1000); 
	local shs = sitheight/stature;
	local gender = getGender(iManiName);
	local evaHip2eyeAngle = 0;
-- Joint-angle-prediciton model
	if (gender == "Female") then
		--print("Female calculation");
		evaHip2eyeAngle = 0.32 + (0.214 * bmi); 
	elseif (gender == "Male") then
		--print("Male calculation");
		evaHip2eyeAngle = -36.8 + (86 * shs) - (8.43 * 10^-3 * h30); 
	end 
	return evaHip2eyeAngle; 
end 

function evaDriverHeadAngleFunction(iMani, iManiName) -- AtlantoAxial to Eyeside (Tragion to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	
-- Manikin anthro measures 
	local stature = fam:getMeasure(iMani,anthroMeasVec[1]); -- !!! Here check the order in the anthroMeasVec
	local weight = fam:getMeasure(iMani,anthroMeasVec[0]);
	local sitheight = fam:getMeasure(iMani,anthroMeasVec[12]);
	local bmi = weight/(stature/1000 * stature/1000); 
	local shs = sitheight/stature;
	local gender = getGender(iManiName);
	local evaHeadAngle = 0;
-- Joint-angle-prediciton model
	if (gender == "Female") then
		--print("Female calculation");
		evaHeadAngle = 72.3 - (1.83 * 10^-2 * stature) - (81.8 * shs) + (0.267 * bmi); 
	elseif (gender == "Male") then
		--print("Male calculation");
		evaHeadAngle = -90.8 + (162 * shs) + (0.327 * bmi) + (1.65 * age) - (3.11 * shs * age);
	end 
	return evaHeadAngle; 
end 

function evaDriverNeckAngleFunction(iMani, iManiName) -- AtlantoAxial to Eyeside (Tragion to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	
-- Manikin anthro measures 
	local stature = fam:getMeasure(iMani,anthroMeasVec[1]); -- !!! Here check the order in the anthroMeasVec
	local gender = getGender(iManiName);
	
	local evaNeckAngle = 0;
-- Joint-angle-prediciton model
	if (gender == "Female") then
		--print("Female calculation");
		evaNeckAngle = 111 - (7.36*10^-2 * stature) - (2.15 * age) - (1.24*10^-2 * h30) + (1.37*10^-3 * stature * age); 
	elseif (gender == "Male") then
		--print("Male calculation");
		evaNeckAngle = -7.83 - (5.24*10^-2 * age);
	end 
	return evaNeckAngle; 
end 

function evaDriverThoraxAngleFunction(iMani, iManiName) -- AtlantoAxial to Eyeside (Tragion to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	
-- Manikin anthro measures 
	local stature = fam:getMeasure(iMani,anthroMeasVec[1]); -- !!! Here check the order in the anthroMeasVec
	local sitheight = fam:getMeasure(iMani,anthroMeasVec[12]);
	local shs = sitheight/stature;
	local gender = getGender(iManiName);
	local evaThoraxAngle = 0;
-- Joint-angle-prediciton model
	if (gender == "Female") then
		--print("Female calculation");
		evaThoraxAngle =  -39.73 + (81.29 * shs); 
	elseif (gender == "Male") then
		--print("Male calculation");
		evaThoraxAngle = -49 + (109 * shs) - (6.71*10^-2 * age) - (9.46*10^-3 * h30);
	end 
	return evaThoraxAngle; 
end 

function evaDriverAbdomenAngleFunction(iMani, iManiName) -- AtlantoAxial to Eyeside (Tragion to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	
-- Manikin anthro measures 
	local stature = fam:getMeasure(iMani,anthroMeasVec[1]); -- !!! Here check the order in the anthroMeasVec
	local sitheight = fam:getMeasure(iMani,anthroMeasVec[12]);
	local weight = fam:getMeasure(iMani,anthroMeasVec[0]);
	local shs = sitheight/stature;
	local bmi = weight/(stature/1000 * stature/1000); 
	local gender = getGender(iManiName);
	local evaAbdomenAngle = 0;
-- Joint-angle-prediciton model
	if (gender == "Female") then
		--print("Female calculation");
		evaAbdomenAngle =  5.093 + (0.8034 * bmi); 
	elseif (gender == "Male") then
		--print("Male calculation");
		evaAbdomenAngle = -71.6 + (140 * shs) + (1.11 * bmi);
	end 
	return evaAbdomenAngle; 
end 

function evaDriverPelvisAngleFunction(iMani, iManiName) -- AtlantoAxial to Eyeside (Tragion to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	
-- Manikin anthro measures 
	local stature = fam:getMeasure(iMani,anthroMeasVec[1]); -- !!! Here check the order in the anthroMeasVec
	local weight = fam:getMeasure(iMani,anthroMeasVec[0]);
	local bmi = weight/(stature/1000 * stature/1000); 
	local gender = getGender(iManiName);
	local evaPelvisAngle = 0;
-- Joint-angle-prediciton model
	if (gender == "Female") then
		--print("Female calculation");
		evaPelvisAngle =  129 - ((4.54*10^-2) * stature) - (0.204 * age); 
	elseif (gender == "Male") then
		--print("Male calculation");
		evaPelvisAngle = -124 + (0.12 * stature) - (1.5 * bmi) + (3.31 * age) - (1.89*10^-3 * stature * age);
	end 
	return evaPelvisAngle; 
end 

function evaDriverThighAngleFunction(iMani, iManiName) -- AtlantoAxial to Eyeside (Tragion to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	
-- Manikin anthro measures 
	local stature = fam:getMeasure(iMani,anthroMeasVec[1]); -- !!! Here check the order in the anthroMeasVec
	local sitheight = fam:getMeasure(iMani,anthroMeasVec[12]);
	local weight = fam:getMeasure(iMani,anthroMeasVec[0]);
	local shs = sitheight/stature;
	--local age = 40; -- !!! Age is not a thing yet in IPS IMMA
	local bmi = weight/(stature/1000 * stature/1000); 
	--local h30 = 256; -- !!! Esto tengo que definirlo 
	--local l6re = -37; 
	local gender = getGender(iManiName);
	local evaThighAngle = 0;
-- Joint-angle-prediciton model
	if (gender == "Female") then
		--print("Female calculation");
		evaThighAngle = -93.2 + (228 * shs) + (7.06 * bmi) - (2.62*10^-2 * h30) - (3.58*10^-2 * l6re) - (13.9 * shs * bmi); 
	elseif (gender == "Male") then
		--print("Male calculation");
		evaThighAngle = 35.2 + (1.9*10^-2 * stature) - (72.5 * shs) - (0.162 * bmi) - (3.04*10^-2 * h30) - (4.36*10^-2 * l6re);
	end 
	return evaThighAngle; 
end 

function evaDriverKneeAngleFunction(iMani, iManiName) -- AtlantoAxial to Eyeside (Tragion to center eye in Reed)
	local root = Ips.getActiveObjectsRoot();
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	
-- Manikin anthro measures 
	local stature = fam:getMeasure(iMani,anthroMeasVec[1]); -- !!! Here check the order in the anthroMeasVec
	local sitheight = fam:getMeasure(iMani,anthroMeasVec[12]);
	local weight = fam:getMeasure(iMani,anthroMeasVec[0]);
	local shs = sitheight/stature;
	local bmi = weight/(stature/1000 * stature/1000); 
	local gender = getGender(iManiName);
	local evaKneeAngle = 0;
-- Joint-angle-prediciton model
	if (gender == "Female") then
		--print("Female calculation");
		evaKneeAngle = 372 - (449 * shs) - (12.9 * bmi) + (7.41*10^-2 * age) - (0.102 * h30) + (8.19*10^-2 * l6re) + (25.5 * shs * bmi); 
	elseif (gender == "Male") then
		--print("Male calculation");
		evaKneeAngle = 204 - (3.48*10^-2 * stature) - (8.57*10^-2 * h30) + (9.33*10^-2 * l6re);
	end 
	return evaKneeAngle; 
end 

