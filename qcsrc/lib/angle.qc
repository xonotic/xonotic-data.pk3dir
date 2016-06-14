.vector origin;
.vector angles;

/*
* Return a angle within +/- 360.
*/
float anglemods(float v)
{
	v = v - 360 * floor(v / 360);

	if(v >= 180)
		return v - 360;
	else if(v <= -180)
		return v + 360;
	else
		return v;
}

/*
* Return the short angle
*/
float shortangle_f(float ang1, float ang2)
{
	if(ang1 > ang2)
	{
		if(ang1 > 180)
			return ang1 - 360;
	}
	else
	{
		if(ang1 < -180)
			return ang1 + 360;
	}

	return ang1;
}

vector shortangle_v(vector ang1, vector ang2)
{
	vector vtmp;

	vtmp_x = shortangle_f(ang1_x,ang2_x);
	vtmp_y = shortangle_f(ang1_y,ang2_y);
	vtmp_z = shortangle_f(ang1_z,ang2_z);

	return vtmp;
}

vector shortangle_vxy(vector ang1, vector ang2)
{
	vector vtmp = '0 0 0';

	vtmp_x = shortangle_f(ang1_x,ang2_x);
	vtmp_y = shortangle_f(ang1_y,ang2_y);

	return vtmp;
}

/*
* Return the angle between two enteties
*/
vector angleofs(entity from, entity to)
{
	vector v_res;

	v_res = normalize(to.origin - from.origin);
	v_res = vectoangles(v_res);
	v_res = v_res - from.angles;

	if (v_res_x < 0) 	v_res_x += 360;
	if (v_res_x > 180) 	v_res_x -= 360;

	if (v_res_y < 0) 	v_res_y += 360;
	if (v_res_y > 180) 	v_res_y -= 360;

	return v_res;
}

vector angleofs3(vector from, vector from_a, entity to)
{
	vector v_res;

	v_res = normalize(to.origin - from);
	v_res = vectoangles(v_res);
	v_res = v_res - from_a;

	if (v_res_x < 0) 	v_res_x += 360;
	if (v_res_x > 180) 	v_res_x -= 360;

	if (v_res_y < 0) 	v_res_y += 360;
	if (v_res_y > 180) 	v_res_y -= 360;

	return v_res;
}
