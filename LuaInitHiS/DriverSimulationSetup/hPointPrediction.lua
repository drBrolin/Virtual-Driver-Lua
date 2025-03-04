function hPointPredFamily(fam)
	mannames = fam:getManikinNames();

	for i = 0, mannames:size() - 1 do
		print("Manikin "..tostring(i+1)..": "..mannames[i]);
		gender = getGender(mannames); -- Female = 0, Male = 1
		RightHipTrans = fam:getJointTransformationForManikin(i,"RightHip");
		LeftHipTrans = fam:getJointTransformationForManikin(i,"LeftHip");
		
		--Set the middle point between hip joints
		midHip = (RightHipTrans["t"] + LeftHipTrans["t"])/2;
		manBodyWeight = fam:getMeasure(i, "Body mass (weight)");
		manStature = fam:getMeasure(i, "Stature (body height)");
		manBMI = manBodyWeight/((manStature/1000)^2);
		print("BMI: "..tostring(manBMI));
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
	end
end

function swPointPredFamily(fam)
	mannames = fam:getManikinNames();

	for i = 0, mannames:size() - 1 do
		print("Manikin "..tostring(i+1)..": "..mannames[i]);
		gender = getGender(mannames); -- Female = 0, Male = 1
		RightHandTrans = fam:getJointTransformationForManikin(i,"Right_MiddleCarpal");
		LeftHandTrans = fam:getJointTransformationForManikin(i,"Left_MiddleCarpal");
		
		--Set the middle point between hip joints
		midHand = (RightHandTrans["t"] + LeftHandTrans["t"])/2;
		
		print("midHand: "..tostring(midHand[0]..","..tostring(midHand[1])));
		
		
		sphSize = 0.005;
		sphere = PrimitiveShape.createSphere(sphSize,10,10);
		sphere:setLabel("SW-point_"..(mannames[i]));
		trans = sphere:getTWorld();
		trans["tx"] = midHand[0];
		trans["ty"] = midHand[1];
		trans["tz"] = midHand[2];
		sphere:setTWorld(trans);
		sphere:setColor(0,1,0);	
	end
end

function eyePointPredFamily(fam)
	mannames = fam:getManikinNames();

	for i = 0, mannames:size() - 1 do
		print("Manikin "..tostring(i+1)..": "..mannames[i]);
		gender = getGender(mannames); -- Female = 0, Male = 1
		eyePointTrans = fam:getJointTransformationForManikin(i,"Eyeside");
		
		print("eyePoint: "..tostring(eyePointTrans[0]..","..tostring(eyePointTrans[1])));
		
		sphSize = 0.005;
		sphere = PrimitiveShape.createSphere(sphSize,10,10);
		sphere:setLabel("Eye-point_"..(mannames[i]));
		trans = sphere:getTWorld();
		trans["tx"] = eyePointTrans[0];
		trans["ty"] = eyePointTrans[1];
		trans["tz"] = eyePointTrans[2];
		sphere:setTWorld(trans);
		sphere:setColor(0,0,1);	
	end
end