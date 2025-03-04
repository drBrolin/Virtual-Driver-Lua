frameSizeAdjRange = 0.05;
frameSizeRefPoint = 0.05;

function createSeatTravelFrames()
	-- Frame creation
	STframe1 = Frame();
	STframe2 = Frame();
	STframe3 = Frame();
	STframe4 = Frame();
	
	-- Frame labeling
	STframe1:setLabel("SeatTravelFrame1");
	STframe2:setLabel("SeatTravelFrame2");
	STframe3:setLabel("SeatTravelFrame3");
	STframe4:setLabel("SeatTravelFrame4");
	
	-- Frame resizing
	STframe1:setSize(frameSizeAdjRange);
	STframe2:setSize(frameSizeAdjRange);
	STframe3:setSize(frameSizeAdjRange);
	STframe4:setSize(frameSizeAdjRange);
	
	-- Frame positioning
	trans1 = STframe1:getTWorld();
	transNew = trans1;
	transNew["tx"] =  trans1.t.x - 60/1000;
	transNew["tz"] =  trans1.t.z + 70/1000;
	STframe2:setTWorld(transNew);
	transNew = trans1;
	transNew["tx"] =  trans1.t.x + 260/1000;
	transNew["tz"] =  trans1.t.z - 30/1000;
	STframe3:setTWorld(transNew);
	transNew = trans1;
	transNew["tx"] =  trans1.t.x + 60/1000;
	transNew["tz"] =  trans1.t.z - 70/1000;
	STframe4:setTWorld(transNew);

end

function createReferenceFrames()
	-- Frame creation
	SgRP = Frame();
	AHP = Frame();
	PRP = Frame();
	
	-- Frame labeling
	SgRP:setLabel("SgRP");
	AHP:setLabel("AHP");
	PRP:setLabel("PRP");
	
	-- Frame resizing
	SgRP:setSize(frameSizeRefPoint);
	AHP:setSize(frameSizeRefPoint);
	PRP:setSize(frameSizeRefPoint);
	
	-- Frame positioning
	transSgRP = SgRP:getTWorld();
	transSgRP["tx"] =  transSgRP.t.x + 100/1000;
	transSgRP["tz"] =  transSgRP.t.z + 20/1000;
	SgRP:setTWorld(transSgRP);
end

function createSteeringWheelFrames()
	-- Frame creation
	SWframe1 = Frame();
	SWframe2 = Frame();
	SWframe3 = Frame();
	SWframe4 = Frame();
	
	-- Frame labeling
	SWframe1:setLabel("SteeringWheelFrame1");
	SWframe2:setLabel("SteeringWheelFrame2");
	SWframe3:setLabel("SteeringWheelFrame3");
	SWframe4:setLabel("SteeringWheelFrame4");
	
	-- Frame resizing
	SWframe1:setSize(frameSizeAdjRange);
	SWframe2:setSize(frameSizeAdjRange);
	SWframe3:setSize(frameSizeAdjRange);
	SWframe4:setSize(frameSizeAdjRange);
	
	-- Frame positioning
	trans1 = SWframe1:getTWorld();
	transNew = trans1;
	transNew["tx"] =  trans1.t.x + 15/1000;
	transNew["tz"] =  trans1.t.z - 40/1000;
	SWframe2:setTWorld(transNew);
	transNew["tx"] =  trans1.t.x + 45/1000;
	transNew["tz"] =  trans1.t.z + 20/1000;
	SWframe3:setTWorld(transNew);
	transNew["tx"] =  trans1.t.x - 10/1000;
	transNew["tz"] =  trans1.t.z + 40/1000;
	SWframe4:setTWorld(transNew);
end