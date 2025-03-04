function classAPred()
	L6 = (4 + 0.003441 * Stature + 0.01854 * H30 - 0.00004958 * H30^2) / 0.021182; -- Reed, M. Driver Preference for Fore-Aft Steering Wheel Location. 4 = just right
	SW_Pos = 0; 
	if (L6 >= (SW_min_X - PRP_X)*1000) and (L6 <= (SW_max_X - PRP_X)*1000) then
		L6re = L6-600;
		SW_Pos = 3;
	elseif (L6 <= (SW_min_X - PRP_X)*1000) then
		Ips.alert("Preferred L6 smaller than steering wheel adjustment area.\nL6 moved to adjustment area.");
		L6re = (SW_min_X - PRP_X)*1000-600; -- Used in calculations
		SW_Pos = 1;
	elseif (L6 >= (SW_max_X - PRP_X)*1000) then
		Ips.alert("Preferred L6 bigger than steering wheel adjustment area.\nL6 moved to adjustment area");
		L6re = (SW_max_X - PRP_X)*1000-600; -- Used in calculations
		SW_Pos = 5;
	end	
	if (gender == 0) then -- female
		HpointX = 678+(0.284*Stature)-(494*SHS)+(2.33*BMI)-(0.388*H30)+(0.426*L6re) + PRP_X*1000; -- in relation to PRP which is added
		HpointZ = 129-(6.2*10^-2*Stature)+(0.909*H30)-(4.65*10^-2*L6re) + AHP_Z*1000; -- in relation to AHP which is added
		-- HpointX = HpointX + adjustment based on H30, stature, etc.;
		-- HpointZ = HpointZ + adjustment based on H30, stature, etc.;
		Hpoint[1] = HpointX/1000;
		Hpoint[2] = HpointZ/1000;
		if (checkPosition(seatSeqOrder, ST_points, Hpoint) == 0) then
			Hpoint = getClosestPoint(seatSeqOrder, seatMidPoint, seatAnglePoints, ST_points, Hpoint);
			Ips.alert("H-point outside adjustment area!");
		end
		HpointX = Hpoint[1]*1000;
		HpointZ = Hpoint[2]*1000;
		MidHipX = HpointX + (-162.3 + (358.3*SHS) - (1.757 *BMI));
		MidHipZ = HpointZ + (2238 -(1.26 *Stature) - (4719 *SHS) + (4.66 *BMI) - (6 *age) - (5.3 *10^-2 *BMI *age) +(13.8 *SHS *age) + (2.54 *Stature*SHS));
		EyeX = HpointX + (-364 + (7.64 *10^-2 *Stature) + (540 *SHS) +(0.124 *L6re));
		EyeZ = HpointZ + (-461 + (0.163 *Stature) + (1445 *SHS) - (15.1 *BMI) + (3.61 *age) + (9.93*10^-3 *Stature *BMI) - (6.54 *SHS *age));
	else -- male
		HpointX = -48+(0.56*Stature)+(1.39*BMI)+(7.53*age)-(0.42*H30)+(0.505*L6re)-(3.98*10^-3*Stature*age) + PRP_X*1000; -- in relation to PRP which is added
		HpointZ = 123.1-(5.864*10^-2*Stature)+(0.945*H30) + AHP_Z*1000; -- in relation to AHP which is added
		Hpoint[1] = HpointX/1000;
		Hpoint[2] = HpointZ/1000;
		if (checkPosition(seatSeqOrder, ST_points, Hpoint) == 0) then
			Hpoint = getClosestPoint(seatSeqOrder, seatMidPoint, seatAnglePoints, ST_points, Hpoint);
			Ips.alert("H-point outside adjustment area!");
		end
		HpointX = Hpoint[1]*1000;
		HpointZ = Hpoint[2]*1000;
		MidHipZ = HpointZ + (2269 -(1.39 *Stature) -(4615 *SHS) + (1.42 *BMI)- (0.222 *age) + (2.78*Stature *SHS));
		MidHipX = HpointX + (196 + (7.38 *10^-2 *Stature) - (552 *SHS) -(2.44 *BMI));
		EyeX = HpointX + (-578 + (0.174 *Stature) + (706 *SHS) - (1.55*BMI) - (6.48*10^-2 *H30));
		EyeZ = HpointZ + (-498 + (0.361 *Stature) + (845 *SHS) + (2.76*BMI) - (0.175 *age));
	end
	SWMidLine = getSWmidline(seqOrderSW, swPoints);
	swDiff = positionClassASW(swPoints, SW_min_xid, SW_max_xid, SWCF_X, SWCF_Z, SWMidLine, PRP_X, L6);
end