/*
 Copyright (C) 2015 Micah Talkiewicz.

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

vector vec_bias(vector v, float f)
{
	vector c;
	c_x = v_x + f;
	c_y = v_y + f;
	c_z = v_z + f;
	return c;
}
vector vec_to_min(vector a, vector b)
{
	vector c;
	c_x = min(a_x, b_x);
	c_y = min(a_y, b_y);
	c_z = min(a_z, b_z);
	return c;
}

vector vec_to_max(vector a, vector b)
{
	vector c;
	c_x = max(a_x, b_x);
	c_y = max(a_y, b_y);
	c_z = max(a_z, b_z);
	return c;
}

// there may already be a function for bounding a vector in this manner, however my very quick search did not reveal one -- Player_2
vector vec_bounds_in(vector point, vector a, vector b)
{
	vector c, d, e;

	d = vec_to_min(a, b);
	e = vec_to_max(a, b);

	c = vec_to_max(point, d);
	c = vec_to_min(c, e);

	return c;
}

vector vec_bounds_out(vector point, vector a, vector b)
{
	vector c, d, e;

	d = vec_to_max(a, b);
	e = vec_to_min(a, b);

	c = vec_to_max(point, d);
	c = vec_to_min(c, e);

	return c;
}

float angle_snap_f(float f, float increment)
{
	float i;
	for (i = 0; i <= 360; )
	{
		if (f <= i - increment) return i - increment;
		i = i + increment;
	}

	return 0;
}

vector angle_snap_vec(vector v,  float increment)
{
	vector c;
	c_x = angle_snap_f(v_x, increment);
	c_y = angle_snap_f(v_y, increment);
	c_z = angle_snap_f(v_z, increment);
	return c;
}

vector aim_vec(vector origin, vector target)
{
	vector v;
	// we float around x and y, but rotate around z
	v_x = target_x - origin_x;
	v_y = target_y - origin_y;
	v_z = origin_z - target_z;
	// get the angles actual
	return vectoangles(normalize(v));
}
