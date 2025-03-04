function classBPred() -- No specific batch prediction is necessary for trucks since the prediction model does not include age.
	swMidPointXReAHP = midPointSW[1] - AHP_X;
	swMidPointZReAHP = midPointSW[2] - AHP_Z;
	mSWPrefHt = 524 + 0.1613 * Stature + 175 * 0.559; -- [mm]
	kSWPrefHt = -0.559; -- where x is the distance aft of AHP
	kInvSWPrefHt = -1/kSWPrefHt;
	mInvSWPrefHt = swMidPointZReAHP*1000 - kInvSWPrefHt*swMidPointXReAHP*1000;
	swNewPoint = {}; -- create the matrix
	swNewPoint[1] = (mSWPrefHt-mInvSWPrefHt)/(kInvSWPrefHt-kSWPrefHt); -- x-coordinate for the intersection point
	swNewPoint[2] = kSWPrefHt*swNewPoint[1]+mSWPrefHt; -- z-coordinate for the intersection point
	swNewPoint[1] = swNewPoint[1] / 1000 + AHP_X;
	swNewPoint[2] = swNewPoint[2] / 1000 + AHP_Z;
	--Ips.alert("swNewPoint: X. "..tostring(swNewPoint[1])..", Z. "..tostring(swNewPoint[2]));		
	if (checkPosition(seqOrderSW, swPoints, swNewPoint) == 0) then -- outside adjustment range
		swNewPoint = getClosestSWPoint(seqOrderSW, midPointSW, anglePointsSW, swPoints, swNewPoint, kInvSWPrefHt, mInvSWPrefHt);
		Ips.alert("SW-point outside adjustment area!");
	end
	swDiff = positionClassBSW(SWCF_X, SWCF_Z, swNewPoint);
	Ips.alert("swNewPoint: X. "..tostring(swNewPoint[1])..", Z. "..tostring(swNewPoint[2]));
	L11 = (swNewPoint[1] - AHP_X)*1000;
	H17 = (swNewPoint[2] - AHP_Z)*1000;
	Ips.alert("L11: "..tostring(L11)..", H17: "..tostring(H17));
	-- HpointX = -53.6 + 0.6081 * L11 - 0.3343 * H17 + 0.6394 * SSH + 89.07 * math.log(BMI) + AHP_X*1000; -- in relation to AHP which is added
	-- HpointZ = -200.3 + 0.8545 * H17 + AHP_Z*1000; -- in relation to AHP which is added
	HpointX = 78.3+0.6244*SSH+3.3391*BMI+0.6448*L11-0.283*H17 + AHP_X*1000; -- in relation to AHP which is added
	HpointZ = -249.7+0.0855*SSH-0.679*BMI+0.8507*H17 + AHP_Z*1000; -- in relation to AHP which is added
	Hpoint[1] = HpointX/1000;
	Hpoint[2] = HpointZ/1000;
	if (checkPosition(seatSeqOrder, ST_points, Hpoint) == 0) then
		Hpoint = getClosestPoint(seatSeqOrder, seatMidPoint, seatAnglePoints, ST_points, Hpoint);
		Ips.alert("H-point outside adjustment area!");
	end
	HpointX = Hpoint[1]*1000;
	HpointZ = Hpoint[2]*1000;
	MidHipX = HpointX + (90.2 - 5.27 * BMI); -- From PRELIMINARY DRIVER POSTURE PREDICTION MODELS FOR TRUCKS AND BUSES (2001)
	MidHipZ = HpointZ + (-109.9 + 1.51 * BMI + 0.0813 * SittingHeight); -- From PRELIMINARY DRIVER POSTURE PREDICTION MODELS FOR TRUCKS AND BUSES (2001)
	-- MidHipX = HpointX + ((90.2 - 5.27 * BMI) + (-334 + 0.0809 * L11 + 1142 * SHS - 87.98 * math.log(BMI)) - (0.7262*SittingHeight*math.sin(math.rad(-38+0.297*BMI+67.6*SHS-2.5))))/2; 
	-- MidHipZ = HpointZ + ((-109.9 + 1.51 * BMI + 0.0813 * SittingHeight) + (-47.3 + 0.7812 * SittingHeight) - (0.7262*SittingHeight*math.cos(math.rad(-38+0.297*BMI+67.6*SHS-2.5))))/2; 
	EyeX = HpointX -334 + 0.0809 * L11 + 1142 * SHS - 87.98 * math.log(BMI);
	EyeZ = HpointZ -47.3 + 0.7812 * SittingHeight;
	-- MidHipX = HpointX + (90.2 - 5.27 * BMI); 
	-- MidHipZ = HpointZ + (-109.9 + 1.51 * BMI + 0.0813 * SittingHeight); 
	-- EyeX = MidHipX + 0.7262*SittingHeight*math.sin(math.rad(-38+0.297*BMI+67.6*SHS-2.5));
	-- EyeZ = MidHipZ + 0.7262*SittingHeight*math.cos(math.rad(-38+0.297*BMI+67.6*SHS-2.5));
end