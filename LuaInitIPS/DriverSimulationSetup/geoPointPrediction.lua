function getAllGeomPoints(fam)
	mannames = fam:getManikinNames();
	local geoPointFilenameCSV = Ips.inputSaveFile("*.csv", scriptPath.."/DriverPrediction", "Select file to save geometric point data to");

	local geoPointfile = io.open(geoPointFilenameCSV, "w");
	--local geoPointfile = io.open(scriptPath.."DriverPrediction/geoPointPredFamily"..fam:getID()..".csv", "w");
	geoPointfile:write("Manikin,H-pointX,H-pointZ,SWpointX,SWpointZ,EyepointX,EyepointZ\n");
	
	local staticRoot = Ips.getGeometryRoot();
	local geoGroup = Ips.createGeometryGroup(nil);
	local timeString = os.date("%Y-%m-%dT%H%M");
	local geoGroupLabel = "GeoPointPrediction_"..timeString;
	geoGroup:setLabel(geoGroupLabel);
	
	for i = 0, mannames:size() - 1 do
		local groupGeometry = staticRoot:findFirstExactMatch(geoGroupLabel);
		print("Manikin "..tostring(i+1)..": "..mannames[i]);
		gender = getGender(mannames); -- Female = 0, Male = 1
		RightHipTrans = fam:getJointTransformationForManikin(i,"RightHip");
		LeftHipTrans = fam:getJointTransformationForManikin(i,"LeftHip");
		
		--Set the middle point between hip joints
		midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
		manBodyWeight = fam:getMeasure(i, "Body mass (weight)");
		manStature = fam:getMeasure(i, "Stature (body height)");
		manBMI = manBodyWeight/((manStature/1000)^2);
		--print("BMI: "..tostring(manBMI));
		if (gender == 0) then -- Female
			midHipToHpointZ = 0.2872*manBMI - 11.583;
		elseif (gender == 1) then -- Male
			midHipToHpointZ  = 0.2921*manBMI - 7.5027;
		end
		midHipToHpointX = 0.4691*manBMI + 6.7786;
		
		sphSize = 0.005;
		sphere = PrimitiveShape.createSphere(sphSize,10,10);
		sphere:setLabel("H-point_"..(mannames[i]));
		trans = sphere:getTWorld();
		trans["tx"] = midHip[0]+midHipToHpointX/1000;
		trans["ty"] = midHip[1];
		trans["tz"] = midHip[2]+midHipToHpointZ/1000;
		sphere:setTWorld(trans);
		sphere:setColor(1,0,0);	
		geoPointfile:write(""..tostring(mannames[i])..","..tostring(trans["tx"])..","..tostring(trans["tz"]));
		Ips.moveTreeObject(sphere, groupGeometry);
		groupGeometry:setExpanded(false);
	
		--print("Manikin "..tostring(i+1)..": "..mannames[i]);
		RightCarpalTrans = fam:getJointTransformationForManikin(i,"Right_MiddleProximal");
		LeftCarpalTrans = fam:getJointTransformationForManikin(i,"Left_MiddleProximal");
		RightHandTrans = fam:getJointTransformationForManikin(i,"RightWrist");
		LeftHandTrans = fam:getJointTransformationForManikin(i,"LeftWrist");
		
		--Set the middle point between joints
		midHand = (RightHandTrans["t"] + LeftHandTrans["t"])/2;
		midCarpal = (RightCarpalTrans["t"] + LeftCarpalTrans["t"])/2;
		
		local dirVec  = {n=3};
		dirVec[0] = midCarpal[0] - midHand[0];
		dirVec[1] = midCarpal[1] - midHand[1];
		dirVec[2] = midCarpal[2] - midHand[2];
		
		local magnitude = math.sqrt(dirVec[0]^2 + dirVec[1]^2 + dirVec[2]^2);
		
		local normalizedDirection = {n=3};
		normalizedDirection[0] = dirVec[0] / magnitude;
		normalizedDirection[1] = dirVec[1] / magnitude;
		normalizedDirection[2] = dirVec[2] / magnitude;
				
		local distance = 0.07;
		local handgrip = {n=3};
		handgrip[0] = midHand[0] + normalizedDirection[0] * distance;
		handgrip[1] = midHand[1] + normalizedDirection[1] * distance;
		handgrip[2] = midHand[2] + normalizedDirection[2] * distance;	
		
		-- print("midHand: "..tostring(midHand[0]..","..tostring(RightHandTrans["R"])));
		sphSize = 0.005;
		sphere = PrimitiveShape.createSphere(sphSize,10,10);
		sphere:setLabel("SW-point_"..(mannames[i]));
		trans = sphere:getTWorld();
		trans["tx"] = handgrip[0];
		trans["ty"] = handgrip[1];
		trans["tz"] = handgrip[2];
		sphere:setTWorld(trans);
		sphere:setColor(0,1,0);	
		geoPointfile:write(","..tostring(trans["tx"])..","..tostring(trans["tz"]));
		Ips.moveTreeObject(sphere, groupGeometry);
		groupGeometry:setExpanded(false);
	
		--print("Manikin "..tostring(i+1)..": "..mannames[i]);
		
		eyePointTrans = fam:getJointTransformationForManikin(i,"Eyeside");
		
		--print("eyePoint: "..tostring(eyePointTrans["tx"]..","..tostring(eyePointTrans["ty"])));
		sphSize = 0.005;
		sphere = PrimitiveShape.createSphere(sphSize,10,10);
		sphere:setLabel("Eye-point_"..(mannames[i]));
		trans = sphere:getTWorld();
		trans["tx"] = eyePointTrans["tx"];
		trans["ty"] = eyePointTrans["ty"];
		trans["tz"] = eyePointTrans["tz"];
		sphere:setTWorld(trans);
		sphere:setColor(0,0,1);
		geoPointfile:write(","..tostring(trans["tx"])..","..tostring(trans["tz"]).."\n");	
		Ips.moveTreeObject(sphere, groupGeometry);
		groupGeometry:setExpanded(false);		
	
	end
	geoPointfile:close();
end