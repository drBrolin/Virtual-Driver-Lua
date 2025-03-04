function Round(num, dp)
    local mult = 10^(dp or 0)
    return math.floor(num * mult + 0.5)/mult
end

function evaluateDrivers()

	dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsUtils.lua");
	dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsUserInput.lua");
	dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsManikinPosture.lua");
	dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsConstraints.lua");
	dofile(scriptPath.."/DriverErgonomics/ReedAnglePrediction.lua");
	dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsEvaluation.lua");
	dofile(scriptPath.."/DriverErgonomics/Anthropometrics.lua");
	
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	local maniNamesVec = fam:getManikinNames(); 
	
	local notOKs = NumberVector()
	local constraints = NumberVector()
	
	for i = 0, fam:getNumManikins() -1 do
		setConstantsDriver();
		local iMani = i;
		print("-------------------------------------------------------");
		print("RESULTS FOR MANIKIN "..tostring(i).." WITH NAME: "..maniNamesVec[i]);
		print("-------------------------------------------------------");
		
		--Hip to eye angle
		local idealHipToEyeAngle = Round(evaDriverHiptoEyeAngleFunction(i,maniNamesVec[i]),2);
		local hipToEyeAngle = Round(getDriverHiptoEyeAngleFunction(i),2)
		local hipToEyeAngleRMSE = 0;
		if(getGender(maniNamesVec[i]) == "Female") then
			hipToEyeAngleRMSE = femaleRMSE[0]
		else
			hipToEyeAngleRMSE = maleRMSE[0]
		end
		local hipToEyeAngleOK = ""
		if (eval(maniNamesVec[i], hipToEyeAngle, idealHipToEyeAngle, 0) == 1) then
			hipToEyeAngleOK = "NOT OK";
		else
			hipToEyeAngleOK = "OK";
		end
		local hipToEyeAngleAcceptableLowRange = idealHipToEyeAngle - hipToEyeAngleRMSE;
		local hipToEyeAngleAcceptableHighRange = idealHipToEyeAngle + hipToEyeAngleRMSE;
		print("["..hipToEyeAngleOK.."] Hip to eye angle. Value: "..tostring(hipToEyeAngle)..". Ideal range ["..tostring(hipToEyeAngleAcceptableLowRange)..", "..tostring(hipToEyeAngleAcceptableHighRange).."]");
		
		
		-- --Head angle
		local idealHeadAngle = Round(evaDriverHeadAngleFunction(i,maniNamesVec[i]),2);
		local headAngle = Round(getDriverHeadAngleFunction(i),2)
		local headAngleRMSE = 0;
		if(getGender(maniNamesVec[i]) == "Female") then
			headAngleRMSE = femaleRMSE[1]
		else
			headAngleRMSE = maleRMSE[1]
		end
		local headAngleOK = ""
		if (eval(maniNamesVec[i], headAngle, idealHeadAngle, 1) == 1) then
			headAngleOK = "NOT OK";
		else
			headAngleOK = "OK";
		end
		local headAngleAcceptableLowRange = idealHeadAngle - headAngleRMSE;
		local headAngleAcceptableHighRange = idealHeadAngle + headAngleRMSE;
		print("["..headAngleOK.."] Head angle. Value: "..tostring(headAngle)..". Ideal range ["..tostring(headAngleAcceptableLowRange)..", "..tostring(headAngleAcceptableHighRange).."]");
		

		-- --Neck
		local idealNeckAngle = Round(evaDriverNeckAngleFunction(i,maniNamesVec[i]),2);
		local neckAngle = Round(getDriverNeckAngleFunction(i),2)
		local neckAngleRMSE = 0;
		if(getGender(maniNamesVec[i]) == "Female") then
			neckAngleRMSE = femaleRMSE[2]
		else
			neckAngleRMSE = maleRMSE[2]
		end
		local neckAngleOK = ""
		if (eval(maniNamesVec[i], neckAngle, idealNeckAngle, 2) == 1) then
			neckAngleOK = "NOT OK";
		else
			neckAngleOK = "OK";
		end
		local neckAngleAcceptableLowRange = idealNeckAngle - neckAngleRMSE;
		local neckAngleAcceptableHighRange = idealNeckAngle + neckAngleRMSE;
		print("["..neckAngleOK.."] Neck angle. Value: "..tostring(neckAngle)..". Ideal range ["..tostring(neckAngleAcceptableLowRange)..", "..tostring(neckAngleAcceptableHighRange).."]");
		
		
		-- --Thorax angle
		local idealThoraxAngle = Round(evaDriverThoraxAngleFunction(i,maniNamesVec[i]),2);
		local thoraxAngle = Round(getDriverThoraxAngleFunction(i),2)
		local thoraxAngleRMSE = 0;
		if(getGender(maniNamesVec[i]) == "Female") then
			thoraxAngleRMSE = femaleRMSE[3]
		else
			thoraxAngleRMSE = maleRMSE[3]
		end
		local thoraxAngleOK = ""
		if (eval(maniNamesVec[i], thoraxAngle, idealThoraxAngle, 3) == 1) then
			thoraxAngleOK = "NOT OK";
		else
			thoraxAngleOK = "OK";
		end
		local thoraxAngleAcceptableLowRange = idealThoraxAngle - thoraxAngleRMSE;
		local thoraxAngleAcceptableHighRange = idealThoraxAngle + thoraxAngleRMSE;
		print("["..thoraxAngleOK.."] Thorax angle. Value: "..tostring(thoraxAngle)..". Ideal range ["..tostring(thoraxAngleAcceptableLowRange)..", "..tostring(thoraxAngleAcceptableHighRange).."]");
		
		
		-- --Abdomen angle
		local idealAbdomenAngle = Round(evaDriverAbdomenAngleFunction(i,maniNamesVec[i]),2);
		local abdomenAngle = Round(getDriverAbdomenAngleFunction(i),2)
		local abdomenAngleRMSE = 0;
		if(getGender(maniNamesVec[i]) == "Female") then
			abdomenAngleRMSE = femaleRMSE[4]
		else
			abdomenAngleRMSE = maleRMSE[4]
		end
		local abdomenAngleOK = ""
		if (eval(maniNamesVec[i], abdomenAngle, idealAbdomenAngle, 4) == 1) then
			abdomenAngleOK = "NOT OK";
		else
			abdomenAngleOK = "OK";
		end
		local abdomenAngleAcceptableLowRange = idealAbdomenAngle - abdomenAngleRMSE;
		local abdomenAngleAcceptableHighRange = idealAbdomenAngle + abdomenAngleRMSE;
		print("["..abdomenAngleOK.."] Abdomen angle. Value: "..tostring(abdomenAngle)..". Ideal range ["..tostring(abdomenAngleAcceptableLowRange)..", "..tostring(abdomenAngleAcceptableHighRange).."]");
		
		
		-- --Pelvis angle
		local idealPelvisAngle = Round(evaDriverPelvisAngleFunction(i,maniNamesVec[i]),2);
		local pelvisAngle = Round(getDriverPelvisAngleFunction(i),2)
		local pelvisAngleRMSE = 0;
		if(getGender(maniNamesVec[i]) == "Female") then
			pelvisAngleRMSE = femaleRMSE[5]
		else
			pelvisAngleRMSE = maleRMSE[5]
		end
		local pelvisAngleOK = ""
		if (eval(maniNamesVec[i], pelvisAngle, idealPelvisAngle, 5) == 1) then
			pelvisAngleOK = "NOT OK";
		else
			pelvisAngleOK = "OK";
		end
		local pelvisAngleAcceptableLowRange = idealPelvisAngle - pelvisAngleRMSE;
		local pelvisAngleAcceptableHighRange = idealPelvisAngle + pelvisAngleRMSE;
		print("["..pelvisAngleOK.."] Pelvis angle. Value: "..tostring(pelvisAngle)..". Ideal range ["..tostring(pelvisAngleAcceptableLowRange)..", "..tostring(pelvisAngleAcceptableHighRange).."]");
		
		
		-- --Thigh angle
		local idealThighAngle = Round(evaDriverThighAngleFunction(i,maniNamesVec[i]),2);
		local thighAngle = Round(getDriverThighAngleFunction(i),2)
		local thighAngleRMSE = 0;
		if(getGender(maniNamesVec[i]) == "Female") then
			thighAngleRMSE = femaleRMSE[6]
		else
			thighAngleRMSE = maleRMSE[6]
		end
		local thighAngleOK = ""
		if (eval(maniNamesVec[i], thighAngle, idealThighAngle, 6) == 1) then
			thighAngleOK = "NOT OK";
		else
			thighAngleOK = "OK";
		end
		local thighAngleAcceptableLowRange = idealThighAngle - thighAngleRMSE;
		local thighAngleAcceptableHighRange = idealThighAngle + thighAngleRMSE;
		print("["..thighAngleOK.."] Thigh angle. Value: "..tostring(thighAngle)..". Ideal range ["..tostring(thighAngleAcceptableLowRange)..", "..tostring(thighAngleAcceptableHighRange).."]");
		
		
		-- --Knee angle
		local idealKneeAngle = Round(evaDriverKneeAngleFunction(i,maniNamesVec[i]),2);
		local kneeAngle = Round(getDriverRightKneeAngleFunction(i),2)
		local kneeAngleRMSE = 0;
		if(getGender(maniNamesVec[i]) == "Female") then
			kneeAngleRMSE = femaleRMSE[7]
		else
			kneeAngleRMSE = maleRMSE[7]
		end
		local kneeAngleOK = ""
		if (eval(maniNamesVec[i], kneeAngle, idealKneeAngle, 7) == 1) then
			kneeAngleOK = "NOT OK";
		else
			kneeAngleOK = "OK";
		end
		local kneeAngleAcceptableLowRange = idealKneeAngle - kneeAngleRMSE;
		local kneeAngleAcceptableHighRange = idealKneeAngle + kneeAngleRMSE;
		print("["..kneeAngleOK.."] Knee angle. Value: "..tostring(kneeAngle)..". Ideal range ["..tostring(kneeAngleAcceptableLowRange)..", "..tostring(kneeAngleAcceptableHighRange).."]");
		
		local totalNotOK = 
		
		print("++++++++++++++++++++")
		
		if(getRoofDistanceCheck(i) == 1) then
			print("[Violated] Roof distance") 
		else
			print("[Ok] Roof distance") 
		end
		
		if(getKneeDistanceCheck(i) == 1) then
			print("[Violated] Knee distance") 
		else
			print("[Ok] Knee distance") 
		end
		
		if(getThighDistanceCheck(i) == 1) then
			print("[Violated] Thigh distance") 
		else
			print("[Ok] Thigh distance") 
		end
		
		if(getDriverDownViewAngleFunction(i) == 1) then
			print("[Violated] Down view angle") 
		else
			print("[Ok] Down view angle") 
		end

	end
	
end