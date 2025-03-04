
function createMeasures()
	dofile(scriptPath.."/DriverErgonomics/DriverErgonomicsUserInput.lua");
	local root = Ips.getActiveObjectsRoot();
	local famObject = root:findFirstExactMatch(familyNameInScene);
	local fam = ManikinSimulationController():getManikinFamily(ManikinSimulationController():getManikinFamilyIDs()[0]);
	local manikinObject = TreeObjectVector();
	local man = famObject:getFirstChild();
	manikinObject:push_back(man);
	
	local roofObject = TreeObjectVector();
	roofObject:push_back(root:findFirstExactMatch(roofNameInScene));
	local consoleObject = TreeObjectVector();
	consoleObject:push_back(root:findFirstExactMatch(consoleNameInScene));
	local steeringCollisionObject = TreeObjectVector();
	steeringCollisionObject:push_back(root:findFirstExactMatch(steeringCollisionObjectNameInScene));

	
	for i = 0, fam:getNumManikins() - 1 do
		local measure1 = Ips.createDistanceMeasure(manikinObject, roofObject);
		measure1:setLabel("roof_distance_"..tostring(i+1))
		local measure2 = Ips.createDistanceMeasure(manikinObject, consoleObject);
		measure2:setLabel("knee_distance_"..tostring(i+1))
		local measure3 = Ips.createDistanceMeasure(manikinObject, steeringCollisionObject);
		measure3:setLabel("thigh_distance_"..tostring(i+1))

		man = man:getNextSibling();
		manikinObject[0] = man;
	end


	
end

