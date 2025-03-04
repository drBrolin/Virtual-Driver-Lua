--Anthropometric data
anthropometricDataTag = "Anthropometrics";
measurementsTag = "Measurements";
rangesOfMotionTag = "Ranges of motion";

anthroMeasVec = StringVector();
anthroMeasVec:push_back("Body mass (weight)");
anthroMeasVec:push_back("Stature (body height)");
anthroMeasVec:push_back("Eye height");
anthroMeasVec:push_back("Shoulder height");
anthroMeasVec:push_back("Elbow height");
anthroMeasVec:push_back("Iliac spine height, standing");
anthroMeasVec:push_back("Crotch height");
anthroMeasVec:push_back("Tibial height");
anthroMeasVec:push_back("Chest depth, standing");
anthroMeasVec:push_back("Body depth, standing");
anthroMeasVec:push_back("Chest breadth, standing");
anthroMeasVec:push_back("Hip breadth, standing");
anthroMeasVec:push_back("Sitting height (erect)");
anthroMeasVec:push_back("Eye height, sitting");
anthroMeasVec:push_back("Cervicale height, sitting");
anthroMeasVec:push_back("Shoulder height, sitting");
anthroMeasVec:push_back("Elbow height, sitting");
anthroMeasVec:push_back("Shoulder-elbow length");
anthroMeasVec:push_back("Elbow-wrist length");
anthroMeasVec:push_back("Shoulder (biacromial) breadth");
anthroMeasVec:push_back("Shoulder (bideltoid) breadth");
anthroMeasVec:push_back("Elbow-to-elbow breadth");
anthroMeasVec:push_back("Hip breadth, sitting");
anthroMeasVec:push_back("Lower leg length (popliteal height)");
anthroMeasVec:push_back("Thigh clearance");
anthroMeasVec:push_back("Knee height");
anthroMeasVec:push_back("Abdominal depth, sitting");
anthroMeasVec:push_back("Thorax depth at the nipple");
anthroMeasVec:push_back("Buttock-abdomen depth sitting");
anthroMeasVec:push_back("Hand length");
anthroMeasVec:push_back("Palm length perpendicular");
anthroMeasVec:push_back("Hand breadth at metacarpals");
anthroMeasVec:push_back("Index finger length");
anthroMeasVec:push_back("Index finger breadth, distal");
anthroMeasVec:push_back("Foot length");
anthroMeasVec:push_back("Foot breadth");
anthroMeasVec:push_back("Head length");
anthroMeasVec:push_back("Head breadth");
anthroMeasVec:push_back("Face length (nasion-menton)");
anthroMeasVec:push_back("Head circumference");
anthroMeasVec:push_back("Sagittal arc");
anthroMeasVec:push_back("Bitrageon arc");
anthroMeasVec:push_back("Wall-acromion distance");
anthroMeasVec:push_back("Grip reach (forward reach)");
anthroMeasVec:push_back("Elbow-grip length");
anthroMeasVec:push_back("Fist (grip axis) height");
anthroMeasVec:push_back("Forearm-fingertip length");
anthroMeasVec:push_back("Buttock-popliteal length (seat depth)");
anthroMeasVec:push_back("Buttock-knee length");
anthroMeasVec:push_back("Neck circumference");
anthroMeasVec:push_back("Chest circumference");
anthroMeasVec:push_back("Waist circumference");
anthroMeasVec:push_back("Wrist circumference");
anthroMeasVec:push_back("Thigh circumference");
anthroMeasVec:push_back("Calf circumference");

rangesOfMotionVec = StringVector();
rangesOfMotionVec:push_back("None");


-----------------------------------------------------

function addMeasToJSON(str)
	str = addStringVecToJSON("Measurements vector", anthroMeasVec, str);
	str = nextVarJSON(str);
	str = startNamedObjectJSON(str, measurementsTag);
	local fam = getFamily();
	for i = 0, anthroMeasVec:size() - 1 do
		if i > 0 then
			str = nextVarJSON(str);
		end
		local val = fam:getMeasure(manikinSelection,anthroMeasVec[i])
		str = addNumToJSON(anthroMeasVec[i], val, str)
	end
	str = endObjectJSON(str);
	return str;
end

function addRoMToJSON(str)
	str = addStringVecToJSON("Ranges of motion vector", rangesOfMotionVec, str);
	str = nextVarJSON(str);
	str = startNamedObjectJSON(str, rangesOfMotionTag);
	local fam = getFamily();
	for i = 0, rangesOfMotionVec:size() - 1 do
		if i > 0 then
			str = nextVarJSON(str);
		end
		local val = 0;
		str = addNumToJSON(rangesOfMotionVec[i], val, str)
	end
	str = endObjectJSON(str);
	return str;
end
-----------------------------------------------------
--ANTHROPOMETRICS TEXT PROCESS

function addAnthropometricsToJSON(JSONstring)
	JSONstring = nextVarJSON(JSONstring);
	JSONstring = startNamedObjectJSON(JSONstring,anthropometricDataTag);
		--Content
		JSONstring = addMeasToJSON(JSONstring);
		JSONstring = nextVarJSON(JSONstring);
		JSONstring = addRoMToJSON(JSONstring)
	JSONstring = endObjectJSON(JSONstring);
	return JSONstring;
end