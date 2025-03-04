
function createSpheres()
	root = Ips.getActiveObjectsRoot();
	if( root:findFirstExactMatch("Front-top") == nil) then
		local sphere = PrimitiveShape.createSphere(0.01,10,10)
		sphere:setLabel("Front-top")
		local rbSphere = Ips.createRigidBodyObject(sphere)
	end
	if( root:findFirstExactMatch("Front-bottom") == nil) then
		local sphere = PrimitiveShape.createSphere(0.01,10,10)
		sphere:setLabel("Front-bottom")
		local rbSphere = Ips.createRigidBodyObject(sphere)
	end
	if( root:findFirstExactMatch("Back-top") == nil) then
		local sphere = PrimitiveShape.createSphere(0.01,10,10)
		sphere:setLabel("Back-top")
		local rbSphere = Ips.createRigidBodyObject(sphere)
	end
end

