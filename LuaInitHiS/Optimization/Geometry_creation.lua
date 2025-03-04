

-- function recursiveSearchStaticGeometries(obj,posTreeObject)
	-- --obj = obj:getFirstChild();
	-- print(obj:getLabel())
	-- while(not(obj == nil)) do
		-- if(obj:isGeometryGroup()) then
			-- obj = obj:getFirstChild();
			-- recursiveSearchStaticGeometries(obj);
		-- else
			-- print("checking if it is the same")
			-- compObj = obj;
			-- if(compObj == posTreeObject) then
				-- treeObj = obj;
				-- print(found)
				-- break;
			-- end
		-- end
		-- obj = obj:getNextSibling();
		-- print(obj:isPositionedTreeObject())
	-- end
	-- --strGeoSum = table.concat(strGeoSum);
	-- return treeObj;
-- end

-- function retrieveTreeObject(posTreeObject)
	-- --firstObj = staticRoot:getFirstChild()
	-- recursiveSearchStaticGeometries(staticRoot,posTreeObject)
-- end

function createSquare(transf, sizeVec, colorCode)
	local square = PrimitiveShape.createBox(sizeVec[0],sizeVec[1], sizeVec[2],1,1,1,true)
	square:setTWorld(transf)
	square:setColor(colorCode[0],colorCode[1],colorCode[2])
	return square;
end

-- function createSquare(transf, sizeVec, colorCode)
	-- local square = PrimitiveShape.createRectangle(sizeVec[0], sizeVec[1],1,1)
	-- square:setTWorld(transf)
	-- square:setColor(colorCode[0],colorCode[1],colorCode[2])
	-- return square;
-- end

function createEvaluatedSquare(transf, sizeVec, eval, const)
	local colorCode = Vector3d(0,0,0)
	if(const > 0) then
		colorCode[0] = 0
		colorCode[1] = 0
		colorCode[2] = 0
	else
		if(eval < greenColorLimit+1) then
			colorCode[1] = 1;
		else 
			if (eval < yellowColorLimit+1) then
				colorCode[0] = 1
				colorCode[1] = 1
			else
				colorCode[0] = 1
			end
		end
	end
	return createSquare(transf, sizeVec, colorCode)
end

-- 1*********2
-- ***********
-- 3*********4
function createPointsInSquare(point1, point2, point3,numPoints)
	--numPoints = numPoints - 4
	local hVec = point2-point1
	--local lowHVec = point3-point4
	local vVec = point3-point1
	--local rightVVec = point2-point4
	local hLength = hVec:length()
	local vLength = vVec:length()
	local hProportion = hLength/(hLength+vLength) --Point density depending on size
	local vProportion = vLength/(hLength+vLength)
	local vPoints = math.floor(math.sqrt(numPoints*(vProportion/hProportion))+0.5);
	local hPoints = math.floor(((hProportion/vProportion)*vPoints)+0.5);
	-- local hPoints = math.floor(math.sqrt(hProportion*numPoints)+0.5) --Number of points rounded up
	-- local vPoints = math.floor(math.sqrt(vProportion*numPoints)+0.5)
	local hU = hVec/(hPoints) --Unitary vectors
	local vU = vVec/(vPoints)
	
	local allPoints = Vector3dVector()
	for i = 0, vPoints do
		local vPoint = point1 + vU*i
		for j = 0, hPoints do
			local point = vPoint + hU*j
			allPoints:push_back(point)
		end
	end
	print(point1)
	print(point2)
	print(point3)
	print(numPoints)
	print(hPoints)
	print(vPoints)
	print('------')
	print(hProportion)
	print(vProportion)
	return allPoints
end

-- point1 = Vector3d(0,0,2)
-- point2 = Vector3d(2,0,2)
-- point3 = Vector3d(0,0,0)
-- point4 = Vector3d(2,0,0)


-- createPointsInSquare(point1, point2, point3, point4, 100)
-- staticRoot = Ips.getStaticGeometryRoot()
-- size = Vector3d(0.02,0.005,0.02)
-- eval = 6

-- activeRoot = Ips.getActiveObjectsRoot()
-- seatAdj = activeRoot:findFirstExactMatch("SeatAdjRange")
-- seatAdjPos = seatAdj:toPositionedTreeObject():getTControl()

-- createEvaluatedSquare(seatAdjPos, size, eval)
