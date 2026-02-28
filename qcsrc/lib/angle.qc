.vector origin;

.vector angles; ///< angles of the player's model (as opposed to their view which uses `.vector v_angle;`) in degrees
// x is pitch: positive means up (unlike .v_angle), usually is 0
// y is yaw: between -180 and 180, increases when turning left
// z is roll: positive means tilted clockwise, usually is 0

/// Return a angle within +/- 360
ERASEABLE
float anglemods(float v)
{
	v -= 360 * floor(v / 360);

	if (v >= 180)
		return v - 360;
	else if (v <= -180)
		return v + 360;
	return v;
}

/// Return the short angle
ERASEABLE
float shortangle_f(float ang1, float ang2)
{
	if (ang1 > ang2)
	{
		if (ang1 > 180)
			return ang1 - 360;
	}
	else
	{
		if (ang1 < -180)
			return ang1 + 360;
	}
	return ang1;
}

ERASEABLE
vector shortangle_v(vector ang1, vector ang2)
{
	vector vtmp;
	vtmp.x = shortangle_f(ang1.x, ang2.x);
	vtmp.y = shortangle_f(ang1.y, ang2.y);
	vtmp.z = shortangle_f(ang1.z, ang2.z);
	return vtmp;
}

ERASEABLE
vector shortangle_vxy(vector ang1, vector ang2)
{
	vector vtmp;
	vtmp.x = shortangle_f(ang1.x, ang2.x);
	vtmp.y = shortangle_f(ang1.y, ang2.y);
	vtmp.z = 0;
	return vtmp;
}

/// Return the angle offset between angle ang and angle of the vector from->to
ERASEABLE
vector angleofs3(vector from, vector ang, vector to)
{
	vector v_res = normalize(to - from);
	v_res = vectoangles(v_res) - ang;

	if (v_res.x < 0) 	v_res.x += 360;
	if (v_res.x > 180) 	v_res.x -= 360;

	if (v_res.y < 0) 	v_res.y += 360;
	if (v_res.y > 180) 	v_res.y -= 360;

	return v_res;
}

#define angleofs(from, to) angleofs3(from.origin, from.angles, to.origin)
