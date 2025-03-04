function vdeStatModel(fam)
	local mannames = fam:getManikinNames();
	if (mannames:size() ~= 1) then
		Ips.alert("Manikin family size too large (can only have one manikin currently).\nNumber of manikins in family: "..tostring(mannames:size()));
		return; -- How is this inserted?
	end

	gender = getGender(mannames);
	
	Stature = fam:getMeasure(0,"Stature (body height)");
	SittingHeight = fam:getMeasure(0,"Sitting height (erect)");
	Weight = fam:getMeasure(0,"Body mass (weight)");
	SHS =  SittingHeight/Stature;
	BMI = Weight/(Stature/1000*Stature/1000);
	SSH = Stature-SittingHeight;
	
	AttachmentPointVector = nil;
	AttachmentPointNameVector = nil;
	createAttachmentPointVector();
	
	MidHipX = -1; MidHipZ = -1; EyeX = -1; EyeZ = -1; 
	MidHip = ""; CenterEye = "";
	getAttachmentPoints();
	
	-- Get geometry locations
	SWCF_X = 0; SWCF_Z = 0; -- Steering Wheel Control Frame
	objectvector = TreeObjectVector();
	objectSelection = -1;
	getSWcoordinates();
	swFramesPoints = TreeObjectVector();
	--getSWFrames();
	swFrames = {"SteeringWheelFrame1", "SteeringWheelFrame2", "SteeringWheelFrame3", "SteeringWheelFrame4"};
	numFrames = 4;
	getControlFrames(swFrames, swFramesPoints, numFrames);

	swPoints = {}; -- create the matrix
	for i = 0, swFramesPoints:size() - 1 do
		swPoints[i] = {};     -- create a new row
		FrameVis = swFramesPoints[i]:toPositionedTreeObject();
		trans = FrameVis:getTWorld();
		swPoints[i][1] = trans.t.x;
		swPoints[i][2] = trans.t.z;
	end
	SW_max_X = swPoints[0][1];
	SW_min_X = swPoints[0][1];
	SW_min_xid = 0;
	SW_max_xid = 0;
	for i = 1, 3 do
		if (swPoints[i][1] > SW_max_X) then
			SW_max_X = swPoints[i][1];
			SW_max_xid = i;
		end
		if (swPoints[i][1] < SW_min_X) then
			SW_min_X = swPoints[i][1];
			SW_min_xid = i;
		end
	end
			
	refFramesPoints = TreeObjectVector();
	--getReferenceFrames();
	ReferenceFrames = {"SgRP", "AHP", "PRP"};
	numFrames = 3;
	getControlFrames(ReferenceFrames, refFramesPoints, numFrames);
	
	ref_points = {};          -- create the matrix
	for i = 0, refFramesPoints:size() - 1 do
		ref_points[i] = {};     -- create a new row
		FrameVis = refFramesPoints[i]:toPositionedTreeObject();
		trans = FrameVis:getTWorld();
		ref_points[i][1] = trans.t.x;
		ref_points[i][2] = trans.t.z;
	end
	
	-- Seat adjustment
	adjFramesPoints = TreeObjectVector();
	AdjustmentFrames = {"SeatTravelFrame1", "SeatTravelFrame2", "SeatTravelFrame3", "SeatTravelFrame4"};
	--getAdjustmentFrames();
	numFrames = 4;
	getControlFrames(AdjustmentFrames, adjFramesPoints, numFrames);

	ST_points = {};          -- create the matrix
	for i = 0, adjFramesPoints:size() - 1 do
		ST_points[i] = {};     -- create a new row
		FrameVis = adjFramesPoints[i]:toPositionedTreeObject();
		trans = FrameVis:getTWorld();
		ST_points[i][1] = trans.t.x;
		ST_points[i][2] = trans.t.z;
	end
	
	SgRP_Z = ref_points[0][2];
	AHP_X = ref_points[1][1];
	AHP_Z = ref_points[1][2];
	PRP_X = ref_points[2][1];
	-- SW_X = (swPoints[0][1]+swPoints[1][1]+swPoints[2][1]+swPoints[3][1])/4;
	-- SW_Z = (swPoints[0][2]+swPoints[1][2]+swPoints[2][2]+swPoints[3][2])/4;
	H30 = (SgRP_Z - AHP_Z)*1000;
	
	-- L6 = (SW_X - PRP_X)*1000;
	-- L6re = L6-600;
	
	-- L11 = (SW_X - AHP_X)*1000;
	-- H17 = (SW_Z - AHP_Z)*1000;
	
	HpointX = 0;
	HpointZ = 0;
	
	Hpoint = {}; -- create the matrix
	seatMidPoint = getMidPoint(ST_points);
	seatAnglePoints = getAnglePoints(ST_points, seatMidPoint);
	seatSeqOrder = getSeqOrder(seatAnglePoints);
	
	midPointSW = getMidPoint(swPoints);
	anglePointsSW = getAnglePoints(swPoints, midPointSW);
	seqOrderSW = getSeqOrder(anglePointsSW);
	
	-- H30
	-- Class A Vehicles (passenger cars) - 125-405 mm
	-- Class B Vehicles (trucks and buses) - 405-530 mm
	if (H30 < 405) then
		Ips.alert("Statistical model: Cars\nH30 = "..tostring(H30).." mm");
		-- Asking user to provide the age of the manikin
		age = Ips.inputNumberWithDefault("Set the age of the manikin (in years)", 50); -- Should be checked.
		if (age == nil) then -- Hanterar fel
			Ips.alert("Error in input!");
			--return; -- How is this inserted?
		end
		-- if age isnotinteger 
			-- Age need to be set in years!
		-- elseif notbetween 18-65
			-- Age should be between 18-65 for best results.
		-- end
		classAPred();
	else
		Ips.alert("Statistical model: Trucks\nH30 = "..tostring(H30).." mm");
		classBPred();
	end
	Ips.alert("Output data:\nHpointX: "..tostring(HpointX)..", HpointZ: "..tostring(HpointZ).."\nMidHipX: "..tostring(MidHipX)..", MidHipZ: "..tostring(MidHipZ).."\nEyeX: "..tostring(EyeX)..", EyeZ: "..tostring(EyeZ));
	
	setSWPosition(objectvector[objectSelection]:toPositionedTreeObject(), swDiff);
	setAttachmentPoint(MidHip, MidHipX, MidHipZ, HpointX, HpointZ, CenterEye, EyeX, EyeZ, mannames);
end