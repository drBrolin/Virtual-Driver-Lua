function rotateActiveObjectOnOneAxis(posTreeObj, axis, value) --PositionedTreeObject | "rx", "ry" or "rz" to rotate | value in Euler

	--Get that object and the TControl of it. Change if TWorld is needed, or TParent. Change lower down in function also when it gets set
	local objectsRoot = Ips.getActiveObjectsRoot();
	local objTControl = posTreeObj:getTControl();
	
	--Magic to convert rotation matrix into euler angles
	local r1x = objTControl["r1x"];
	local r2x = objTControl["r2x"];
	local r3x = objTControl["r3x"];
	local r1y = objTControl["r1y"];
	local r2y = objTControl["r2y"];
	local r3y = objTControl["r3y"];
	local r1z = objTControl["r1z"];
	local r2z = objTControl["r2z"];
	local r3z = objTControl["r3z"];
	local pi= 3.14159265359;
	local yaw, pitch, roll
	local rotation_matrix = {{r1x, r1y, r1z}, {r2x, r2y, r2z}, {r3x, r3y, r3z}}
	if rotation_matrix[3][1] ~= 1 and rotation_matrix[3][1] ~= -1 then
	pitch = -math.asin(rotation_matrix[3][1])
	yaw = math.atan2(rotation_matrix[3][2] / math.cos(pitch), rotation_matrix[3][3] / math.cos(pitch))
	roll = math.atan2(rotation_matrix[2][1] / math.cos(pitch), rotation_matrix[1][1] / math.cos(pitch))
	else
	roll = 0
	if rotation_matrix[3][1] == -1 then
	  pitch = math.pi / 2
	  yaw = roll + math.atan2(rotation_matrix[1][2], rotation_matrix[1][3])
	else
	  pitch = -math.pi / 2
	  yaw = -roll + math.atan2(-rotation_matrix[1][2], -rotation_matrix[1][3])
	end
	end
	local rx = roll;
	local ry = pitch;
	local rz = yaw;

	--Rotate the object
	if( axis == "rx") then
		rx = math.rad(value);
	end
	if( axis == "ry") then
		ry = math.rad(value);
	end
	if(axis == "rz") then
		rz = math.rad(value);
	end

	--Get back the rotation matrix
	local c1 = math.cos(rx)
	local s1 = math.sin(rx)
	local c2 = math.cos(ry)
	local s2 = math.sin(ry)
	local c3 = math.cos(rz)
	local s3 = math.sin(rz)
	local r1x = c2 * c3
	local r1y = -c2 * s3
	local r1z = s2
	local r2x = c1 * s3 + c3 * s1 * s2
	local r2y = c1 * c3 - s1 * s2 * s3
	local r2z = -c2 * s1
	local r3x = s1 * s3 - c1 * c3 * s2
	local r3y = c3 * s1 + c1 * s2 * s3
	local r3z = c1 * c2
	objTControl["r1x"] = r1x;
	objTControl["r2x"] = r2x;
	objTControl["r3x"] = r3x;
	objTControl["r1y"] = r1y;
	objTControl["r2y"] = r2y;
	objTControl["r3y"] = r3y;
	objTControl["r1z"] = r1z;
	objTControl["r2z"] = r2z;
	objTControl["r3z"] = r3z;

	posTreeObj:setTControl(objTControl);
end


function setAPSettings()
	--Call the simulation controller and save it in simController to use it faster
	simController = ManikinSimulationController();
	
	seatAttachName = "driverSeat";
	seatGroup = simController:createAttachGroupFromPrototype(seatAttachName, "Driving Car");
	root = Ips.getActiveObjectsRoot()
	--We will just name the root as object, since we will iterate through objects
	obj = root
	--Let's create a variable to store our seat attachment group
	seatGroup = nil
	--We will now iterate looking for attachment groups, and not leave until we find the right one
	while (not(obj == nil) and (seatGroup == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "AttachGroup") then
			print("Found an attachement group");
			posTreeObj = obj:toPositionedTreeObject();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end

	rotateActiveObjectOnOneAxis(posTreeObj, "rz", 180);
end

setAPSettings();