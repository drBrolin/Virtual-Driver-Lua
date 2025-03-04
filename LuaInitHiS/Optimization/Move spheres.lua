frameSizeAdjRange = 0.05;

function moveSpheresToAdjustmentRange()
	-- *** DEFINE ADJUSTMENT RANGE ***
	-- *** Click on surface > get vertex/point coordinates ***
	objAdjRange = Ips.getGeometrySelection();
	filenameWRL = "tempObjAdjRange.wrl"; -- Exports a temporary VRML/WRL file to read vertex points from.
	--filenameWRL = "Data/IMMA/VDtemp/objAdjRange.wrl"; -- Specific VDtemp folder that needs to be writeable!
	if (objAdjRange) then
		objAdjRange:exportToVRML(filenameWRL);
		-- Read the WRL file again and extracts vertex points of the geometry
		lines = {};
		notEnd = 0;
		adjRangePoints = {};
		startP = 0;
		lineNr = 0;
		translationAdjRange = {n=3}; translationAdjRange[1] = 0; translationAdjRange[2] = 0; translationAdjRange[3] = 0;
		for line in io.lines(filenameWRL) do 
			lines[#lines + 1] = line;
			if string.match(line,"translation") then
				translation = {n=3};
				translation.x, translation.y, translation.z = line:match("(%S+) (%S+) (%S+)");
				translationAdjRange[1] = tonumber(translation.x);
				translationAdjRange[2] = tonumber(translation.y);
				translationAdjRange[3] = tonumber(translation.z);
				--print("Translation: X "..tostring(translationAdjRange[1])..", Y "..tostring(translationAdjRange[2])..", Z "..tostring(translationAdjRange[3]));
			elseif (line == "point [") then
				startP = #lines;
			elseif (#lines > startP) and (startP ~= 0) and (line ~= "]") and (notEnd == 0) then
				lineNr = #lines - startP;
				adjRangeCoord = {n=3};
				adjRangeCoord.x, adjRangeCoord.y, adjRangeCoord.z = line:match("(%S+) (%S+) (%S[^,]+)");
				adjRangePoints[lineNr] = {n=3};
				adjRangePoints[lineNr][1] = tonumber(adjRangeCoord.x);
				adjRangePoints[lineNr][2] = tonumber(adjRangeCoord.y);
				adjRangePoints[lineNr][3] = tonumber(adjRangeCoord.z);
				--print("Point: X "..tostring(adjRangePoints[lineNr][1])..", Y "..tostring(adjRangePoints[lineNr][2])..", Z "..tostring(adjRangePoints[lineNr][3]));
			elseif (#lines > startP) and (line == "]") then
				notEnd = 1;
			end
		end
		-- Fix translation for all points
		tSize = table.getn(adjRangePoints);
		for i=1,tSize do 
			adjRangePoints[i][1] = adjRangePoints[i][1] + translationAdjRange[1];
			adjRangePoints[i][2] = adjRangePoints[i][2] + translationAdjRange[2];
			adjRangePoints[i][3] = adjRangePoints[i][3] + translationAdjRange[3];
		end
		
		-- *** Identify mid-point, corner points are min-max in each quadrant ***
		-- Calculates midpoint of the adjustment range
		midPointAdjRange = {n=3}; midPointAdjRange[1] = 0; midPointAdjRange[2] = 0; midPointAdjRange[3] = 0;
		for i=1,tSize do 
			midPointAdjRange[1] = midPointAdjRange[1] + adjRangePoints[i][1];
			midPointAdjRange[2] = midPointAdjRange[2] + adjRangePoints[i][2];
			midPointAdjRange[3] = midPointAdjRange[3] + adjRangePoints[i][3];
		end
		midPointAdjRange[1] = midPointAdjRange[1]/tSize;
		midPointAdjRange[2] = midPointAdjRange[2]/tSize;
		midPointAdjRange[3] = midPointAdjRange[3]/tSize;
		--print("MidPoint: X."..tostring(midPointAdjRange[1])..", Y."..tostring(midPointAdjRange[2])..", Z."..tostring(midPointAdjRange[3])); -- First instance but will changed when only calculated with corner points.

		quadPoints = {n=4};
		for i=1,4 do 
			quadPoints[i] = {n=3};
			quadPoints[i][1] = midPointAdjRange[1];
			quadPoints[i][2] = midPointAdjRange[2];
			quadPoints[i][3] = midPointAdjRange[3];
		end
		for i=1,tSize do 
			if (adjRangePoints[i][1] > midPointAdjRange[1]) and (adjRangePoints[i][3] > midPointAdjRange[3]) then -- Quadrant 1
				if (adjRangePoints[i][3] > quadPoints[1][3]) then
					quadPoints[1][1] = adjRangePoints[i][1];
					quadPoints[1][3] = adjRangePoints[i][3];
				end
			elseif (adjRangePoints[i][1] > midPointAdjRange[1]) and (adjRangePoints[i][3] < midPointAdjRange[3]) then -- Quadrant 2
				if (adjRangePoints[i][3] < quadPoints[2][3]) then
					quadPoints[2][1] = adjRangePoints[i][1];
					quadPoints[2][3] = adjRangePoints[i][3];
				end
			elseif (adjRangePoints[i][1] < midPointAdjRange[1]) and (adjRangePoints[i][3] < midPointAdjRange[3]) then -- Quadrant 3
				if (adjRangePoints[i][3] < quadPoints[3][3]) then
					quadPoints[3][1] = adjRangePoints[i][1];
					quadPoints[3][3] = adjRangePoints[i][3];
				end
			elseif (adjRangePoints[i][1] < midPointAdjRange[1]) and (adjRangePoints[i][3] > midPointAdjRange[3]) then -- Quadrant 4
				if (adjRangePoints[i][3] > quadPoints[4][3]) then
					quadPoints[4][1] = adjRangePoints[i][1];
					quadPoints[4][3] = adjRangePoints[i][3];
				end
			end
		end
		-- Recalculate midpoint with corner points only.
		midPointAdjRange[1] = (quadPoints[1][1]+quadPoints[2][1]+quadPoints[3][1]+quadPoints[4][1])/4; 
		midPointAdjRange[3] = (quadPoints[1][3]+quadPoints[2][3]+quadPoints[3][3]+quadPoints[4][3])/4;
		--print("MidPoint: X."..tostring(midPointAdjRange[1])..", Y."..tostring(midPointAdjRange[2])..", Z."..tostring(midPointAdjRange[3]));
		
		local root = Ips.getActiveObjectsRoot();
		local sphere1 = root:findFirstExactMatch("Front-top"):toPositionedTreeObject();
		local sphere2 = root:findFirstExactMatch("Back-top"):toPositionedTreeObject();
		local sphere3 = root:findFirstExactMatch("Front-bottom"):toPositionedTreeObject();

		local trans1 = sphere1:getTWorld();
		trans1['tx'] = quadPoints[4][1]
		trans1['ty'] = quadPoints[4][2]
		trans1['tz'] = quadPoints[4][3]
		sphere1:setTWorld(trans1)
		
		local trans2 = sphere2:getTWorld();
		trans2['tx'] = quadPoints[1][1]
		trans2['ty'] = quadPoints[1][2]
		trans2['tz'] = quadPoints[1][3]
		sphere2:setTWorld(trans2)
		
		local trans3 = sphere3:getTWorld();
		trans3['tx'] = quadPoints[3][1]
		trans3['ty'] = quadPoints[3][2]
		trans3['tz'] = quadPoints[3][3]
		sphere3:setTWorld(trans3)

		return quadPoints;
	else
		Ips.alert("No geometry selected"); -- Error message and break script
	end
end

