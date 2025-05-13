function generateSteeringWheel(simController, attachmentsP, swDiameter, swThickness, swPosition, swAngle)
	-- Steering wheel START --
	-- Diameter, thickness, position, angle
	objectName = "VD_SteeringWheel";
	SteeringWheel = PrimitiveShape.createCylinder( swDiameter/2, swThickness, swThickness, 25, 1, 1, true);
	SteeringWheel:setLabel(objectName);

	-- Set box transformation
	T1 = Transf3.newIdentity();
	set(T1, 'R.r1', Vector3d(0, 0, -1));
	set(T1, 'R.r2', Vector3d(0, 1, 0));
	set(T1, 'R.r3', Vector3d(1, 0, 0));
	SteeringWheel:toPositionedTreeObject():setTWorld(T1);

	swRigidBody = Ips.createRigidBodyObject(SteeringWheel:toPositionedTreeObject());
	--lu.assertNotNil(VD_SW_RB, "Invalid rigid body object");

	-- Find the SteeringWheel as active object
	
	root = Ips.getActiveObjectsRoot();
	activeObject_SW = root:findFirstMatch(objectName);

	--Simple creation of grip point, and storing it in a var
	rightSWgrip = simController:createGripPoint(); -- Right Steering Wheel Grip Point
	rightSWgrip:setGripConfiguration("Diagonal Power Grip");
	rightSWgrip:setSymmetricRotationTolerances(0.34906585,0.785398163,0.34906585);
	
	
	rightSWgripVis = rightSWgrip:getVisualization();
	rightSWgripVis:setLabel("VDrightSWGrip");
	rightSWgripVis:setPublicAttributeValue("VD_attach","True");
	attachmentsP:push_back(rightSWgripVis);
		
	-- Set transformation
	T1 = Transf3.newIdentity();
	set(T1, 't', Vector3d(0.07, swDiameter/2+0.01, 0));
	set(T1, 'R.r1', Vector3d(0, 0, -1));
	set(T1, 'R.r2', Vector3d(0, -1, 0));
	set(T1, 'R.r3', Vector3d(-1, 0, 0));
	rightSWgripVis:setTWorld(T1);
	
	objectName = "VDrightSWGrip";
	activeObject_rightSWgrip = root:findFirstMatch(objectName);
	gripToSW = Ips.moveTreeObject(activeObject_rightSWgrip, activeObject_SW);
	
	leftSWgrip = simController:createGripPoint(); -- Left Steering Wheel Grip Point
	leftSWgrip:setGripConfiguration("Diagonal Power Grip");
	leftSWgrip:setHand(0);
	leftSWgrip:setSymmetricRotationTolerances(0.34906585,0.785398163,0.34906585);
	leftSWgripVis = leftSWgrip:getVisualization();
	leftSWgripVis:setLabel("VDleftSWGrip");
	leftSWgripVis:setPublicAttributeValue("VD_attach","True");
	attachmentsP:push_back(leftSWgripVis);
	
	-- Set transformation
	T1 = Transf3.newIdentity();
	set(T1, 't', Vector3d(0.07, -swDiameter/2-0.01, 0));
	set(T1, 'R.r1', Vector3d(0, 0, -1));
	set(T1, 'R.r2', Vector3d(0, 1, 0));
	set(T1, 'R.r3', Vector3d(1, 0, 0));
	leftSWgripVis:setTWorld(T1);
	
	objectName = "VDleftSWGrip";
	activeObject_leftSWgrip = root:findFirstMatch(objectName);
	gripToSW = Ips.moveTreeObject(activeObject_leftSWgrip, activeObject_SW);
	
	posObj_SW = activeObject_SW:toPositionedTreeObject();
	-- Set transformation
	T1 = Transf3.newIdentity();
	set(T1, 't', Vector3d(swPosition[1], swPosition[2], swPosition[3]));
	set(T1, 'R.r1', Vector3d(-math.cos(math.rad(90-swAngle)), 0, -math.sin(math.rad(90-swAngle))));
	set(T1, 'R.r2', Vector3d(0, 1, 0));
	set(T1, 'R.r3', Vector3d(math.sin(math.rad(90-swAngle)), 0, -math.cos(math.rad(90-swAngle))));
	posObj_SW:setTWorld(T1);
	
	return activeObject_SW;
		
	-- Steering wheel END --
end

function generateSeatHpointTemplate(attachmentsP, seatPosition, buttockAngle, torsoAngle)
	-- Seat --
	-- local seatPosition = {3, -0.380, 0.8};
	-- local buttockAngle = 4;
	-- local torsoAngle = 10;
	
	-- Position, buttock angle, torso angle
	local root = Ips.getActiveObjectsRoot();
	local belowRoot = root:getNextSibling();
	local obj = root;
	saeFound = nil;
	while (not(obj == nil) and not(obj:equals(belowRoot))) do
		if (obj:getPublicAttributeValue("hPointTemplate") == "True") then
			print("hPointTemplate found, no need to create another one.");
			saeFound = 1;
		end
		obj = obj:getObjectBelow();
	end
	if saeFound == nil then -- Need to create the grip first
		Ips.loadScene(scriptPath.."/../LoadDriverScenes/hPointTemplate.ips");
	end
		
	-- Find the H-point template as active object
	objectName = "H-point template";
	root = Ips.getActiveObjectsRoot();
	activeObject_HpointTemplate = root:findFirstMatch(objectName);

	posObj_Seat = activeObject_HpointTemplate:toPositionedTreeObject();
	-- Set transformation
	T1 = Transf3.newIdentity();
	set(T1, 't', Vector3d(seatPosition[1], seatPosition[2], seatPosition[3]));
	set(T1, 'R.r1', Vector3d(-1, 0, 0));
	set(T1, 'R.r2', Vector3d(0, -1, 0));
	set(T1, 'R.r3', Vector3d(0, 0, 1));
	posObj_Seat:setTControl(T1);

	--activeObject_HpointTemplate
	seatChildren = activeObject_HpointTemplate:getNumChildren();
	print("seatChildren: "..tostring(seatChildren));
	-- TreeObject.getFirstChild()
	torsoRigidBodyName = "Torso";
	obj = activeObject_HpointTemplate;
	--Let's create a variable to store our attachment group
	torsoRigidBody = nil;
	--We will now iterate looking for attachment groups, and not leave until we find the right one
	while (not(obj == nil) and (torsoRigidBody == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "RigidBodyObject") and (obj:getLabel() == torsoRigidBodyName) then
			--print("Found an attachment group");
			torsoRigidBody = 1;
			activeObject_Torso = obj;
			posObj_Torso = obj:toPositionedTreeObject();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end

	torsoChildren = activeObject_Torso:getNumChildren();
	print("torsoChildren: "..tostring(torsoChildren));
	obj = activeObject_Torso:getFirstChild();
	for i=1,torsoChildren do 
		print("TorsoChild: "..tostring(i));
		if (obj:getType() == "AttachPoint") then
			print("Found an attachment");
			objVis = obj:toAttachPointVisualization();
			objVis:setPublicAttributeValue("VD_attach","True");
			attachmentsP:push_back(obj);
		end
		obj = obj:getNextSibling();
	end

	-- TreeObject.getFirstChild()
	buttockRigidBodyName = "Buttock";
	obj = activeObject_HpointTemplate;
	--Let's create a variable to store our seat attachment group
	buttockRigidBody = nil;
	--We will now iterate looking for attachment groups, and not leave until we find the right one
	while (not(obj == nil) and (buttockRigidBody == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "RigidBodyObject") and (obj:getLabel() == buttockRigidBodyName) then
			--print("Found an attachment group");
			buttockRigidBody = 1;
			activeObject_Buttock = obj;
			posObj_Buttock = obj:toPositionedTreeObject();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end

	--activeObject_HpointTemplate
	buttockChildren = activeObject_Buttock:getNumChildren();
	print("buttockChildren: "..tostring(buttockChildren));
	obj = activeObject_Buttock:getFirstChild();
	for i=1,buttockChildren do 
		print("ButtockChild: "..tostring(i));
		if (obj:getType() == "AttachPoint") then
			print("Found an attachment");
			objVis = obj:toAttachPointVisualization();
			objVis:setPublicAttributeValue("VD_attach","True");
			attachmentsP:push_back(obj);
		end	
		obj = obj:getNextSibling();
	end
	
	return activeObject_HpointTemplate;
end

function generateFloor(simController, attachmentsP, xBOF, seatY, zAHP, feetBOFAngle)
	-- Position

	-- Pedals
	-- AHP, BOF, Angle
	-- Floor
	-- Z-position (AHP), XY-centre (BOF)
	-- xBOF = 2.25;
	-- zAHP = 0.48;
	yFeet = seatY;
	--Call the simulation controller and save it in simController to use it faster

	feetAttachName = "VDdriverFeet";
	local attachFeet = simController:createAttachGroupFromPrototype(feetAttachName, "Driving Feet");

	attachFeet:getVisualization():setPublicAttributeValue("VD_attach","True");
	attachmentsP:push_back(attachFeet:getVisualization());

	root = Ips.getActiveObjectsRoot();
	--We will just name the root as object, since we will iterate through objects
	obj = root;
	--Let's create a variable to store our seat attachment group
	feetGroup = nil;
	--We will now iterate looking for attachment groups, and not leave until we find the right one
	while (not(obj == nil) and (feetGroup == nil)) do
		--If the object we are looking at now is a attachment group then let's read it	
		if (obj:getType() == "AttachGroup") and (obj:getLabel() == feetAttachName) then
			--print("Found an attachment group");
			feetGroup = 1;
			posObj_Feet = obj:toPositionedTreeObject();
		end
		--In case we didn't find it, we go to the object below and continue searching
		obj = obj:getObjectBelow();
	end
	print("xBOF: "..tostring(xBOF));
	print("yFeet: "..tostring(yFeet));
	print("zAHP: "..tostring(zAHP));
	-- Set transformation
	T1 = Transf3.newIdentity();
	set(T1, 't', Vector3d(xBOF, yFeet, zAHP));
	set(T1, 'R.r1', Vector3d(-1, 0, 0));
	set(T1, 'R.r2', Vector3d(0, -1, 0));
	set(T1, 'R.r3', Vector3d(0, 0, 1));
	posObj_Feet:setTWorld(T1);
	
	obj = obj:getObjectBelow(); obj = obj:getObjectBelow(); -- Goes down two steps in tree structure. Should be fixed to a more robust solution. 
	if (obj:isAttachPointVisualization()) then
		posTreeObj = obj:toPositionedTreeObject();
		trans = posTreeObj:getTWorld();
		set(trans, 'R.r1', Vector3d(-math.cos(math.rad(feetBOFAngle-90)), 0, -math.sin(math.rad(feetBOFAngle-90))));
		set(trans, 'R.r2', Vector3d(0, -1, 0));
		set(trans, 'R.r3', Vector3d(-math.sin(math.rad(feetBOFAngle-90)), 0, math.cos(math.rad(feetBOFAngle-90))));
		posTreeObj:setTWorld(trans);
	end
	obj = obj:getObjectBelow(); obj = obj:getObjectBelow(); obj = obj:getObjectBelow(); -- Goes down three steps in tree structure. Should be fixed to a more robust solution. 
	if (obj:isAttachPointVisualization()) then
		posTreeObj = obj:toPositionedTreeObject();
		trans = posTreeObj:getTWorld();
		set(trans, 'R.r1', Vector3d(-math.cos(math.rad(feetBOFAngle-90)), 0, -math.sin(math.rad(feetBOFAngle-90))));
		set(trans, 'R.r2', Vector3d(0, -1, 0));
		set(trans, 'R.r3', Vector3d(-math.sin(math.rad(feetBOFAngle-90)), 0, math.cos(math.rad(feetBOFAngle-90))));
		posTreeObj:setTWorld(trans);
	end
	
	return posObj_Feet;
end

function generateViewPoint(simController, attachmentsP, viewPoint)
	-- View point
	local viewPointVD = simController:createViewPoint();
	VDviewPointVis = viewPointVD:getVisualization();
	VDviewPointVis:setPublicAttributeValue("VD_attach","True");

	-- Set transformation
	T1 = Transf3.newIdentity();
	set(T1, 't', Vector3d(viewPoint[1], viewPoint[2], viewPoint[3]));
	VDviewPointVis:setTWorld(T1);
	attachmentsP:push_back(VDviewPointVis);
	
	return viewPointVD;
end

function positionSW(activeObject_SW, swPositionX, swPositionY, swPositionZ)
	local posObj_SW = activeObject_SW:toPositionedTreeObject();
	local swControlCoor = posObj_SW:getTControl();

	trans = swControlCoor;
	trans["tx"] = swPositionX
	trans["tz"] = swPositionZ;

	posObj_SW:setTControl(trans);
end

function positionSeat(activeObject_HpointTemplate, seatPositionX, seatPositionY, seatPositionZ)
	-- Seat H-point template
	local posObj_Seat = activeObject_HpointTemplate:toPositionedTreeObject();
	local saeControlCoor = posObj_Seat:getTControl(); 
	
	trans = saeControlCoor;
	trans["tx"] = seatPositionX;
	trans["tz"] = seatPositionZ;
	posObj_Seat:setTControl(trans);
end