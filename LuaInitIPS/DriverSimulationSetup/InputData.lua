function createAttachmentPointVector() -- Fix this part that reads active objects, needs to find all attachment points
	local root = Ips.getActiveObjectsRoot();
	local obj = root;
	
	AttachmentPointVector = TreeObjectVector();
	AttachmentPointNameVector = StringVector();
	while (not(obj == nil)) do
		if (obj:getType() == "AttachPoint") then
			local name = (tostring(obj:getLabel()));
			AttachmentPointVector:push_back(obj);
			AttachmentPointNameVector:push_back(name);
		end
		obj = obj:getObjectBelow();
	end
end

function getAttachmentPoints()
	-- Below code is used when MidHip and CenterEye should be selected
	AttachmentPointId = Ips.inputDropDownList("Cascade modelling", "Select mid-hip point.", AttachmentPointNameVector);
	if (AttachmentPointId == -1) then -- Hanterar fel
		Ips.alert("Error in input!");
	else
		MidHip = AttachmentPointNameVector[AttachmentPointId]; 
		AttachPointVis = AttachmentPointVector[AttachmentPointId]:toPositionedTreeObject();
		trans = AttachPointVis:getTWorld();
		MidHipX = trans.t.x;
		MidHipZ = trans.t.z;
	end
	-- 4
	AttachmentPointId = Ips.inputDropDownList("Cascade modelling", "Select centre eye.", AttachmentPointNameVector);
	if (AttachmentPointId == -1) then -- Hanterar fel
		Ips.alert("Error in input!");
	else
		CenterEye = AttachmentPointNameVector[AttachmentPointId]; 
		AttachPointVis = AttachmentPointVector[AttachmentPointId]:toPositionedTreeObject();
		trans = AttachPointVis:getTWorld();
		EyeX = trans.t.x;
		EyeZ = trans.t.z;
	end
	
	-- Below code could be used instead if MidHip and CenterEye always have a specific name.
	-- local length = AttachmentPointVector:size();
	-- MidHip = "Hip-Centre Seated";
	-- CenterEye = "Centre-Eye";
	-- for i = 0, length -1 do
		-- AttachPointVis = AttachmentPointVector[i]:toPositionedTreeObject();
		-- trans = AttachPointVis:getTWorld();
		-- if (AttachmentPointNameVector[i] == MidHip) then
			-- MidHipX = trans.t.x;
			-- MidHipZ = trans.t.z;
		-- end
		-- if (AttachmentPointNameVector[i] == CenterEye) then
			-- EyeX = trans.t.x;
			-- EyeZ = trans.t.z;
		-- end
	-- end
end

function getSWcoordinates()
	local root = Ips.getActiveObjectsRoot();
	local obj = root:getObjectBelow();
	while (not(obj == nil)) do
		if (obj:getType() == "RigidBodyObject") then
			objectvector:push_back(obj);
		end
		obj = obj:getNextSibling();
	end
	objectnames = StringVector();
	for i = 0, objectvector:size() - 1 do
		nameobj = tostring(objectvector[i]:getLabel());
		objectnames:push_back(nameobj);
	end
	if (objectvector:size() == 0) then
		Ips.alert("No objects exist in tree!");
		--return; -- How is this inserted?
	else
		objectSelection = Ips.inputDropDownList("Object selection", "Select the steering wheel object", objectnames);
		if (objectSelection == -1) then -- Hanterar fel
			Ips.alert("Error in input!");
			--return; -- How is this inserted?
		end
		-- Hantera fel! Ips.alert("objectSelection = "..tostring(objectSelection));
		SWObjectVis = objectvector[objectSelection]:toPositionedTreeObject(); -- Set steering wheel geometry to zero position.
		trans = SWObjectVis:getTWorld();
		trans["tx"] = 0;
		trans["tz"] = 0;
		SWObjectVis:setTWorld(trans);
		local anchorF = objectvector[objectSelection]:getObjectBelow();
		AnchorFrameVis = anchorF:toPositionedTreeObject();
		trans = AnchorFrameVis:getTWorld();
		SWCF_X = trans.t.x;
		SWCF_Z = trans.t.z;
	end
end

function getControlFrames(nameVector, frameObjectVector, numFrames)
	local root = Ips.getGeometryRoot();
	local obj = root:getObjectBelow();
	i = 1;
	while (not(obj == nil)) and (numFrames >= i) do
		if (obj:getType() == "Frame") then
			local name = (tostring(obj:getLabel()));
			if (name == nameVector[i]) then
				frameObjectVector:push_back(obj);
				i = i + 1;
			end
		end
		obj = obj:getNextSibling();
	end
end