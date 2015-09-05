void _Movetype_Physics_Follow() // SV_Physics_Follow
{SELFPARAM();
	entity e = self.move_aiment; // TODO: networking?

	// LordHavoc: implemented rotation on MOVETYPE_FOLLOW objects
	if(self.move_angles == self.move_punchangle)
	{
		self.move_origin = e.move_origin + self.view_ofs;
	}
	else
	{
		vector ang, v;
		ang_x = -self.move_punchangle_x;
		ang_y = self.move_punchangle_y;
		ang_z = self.move_punchangle_z;
		makevectors(ang);
		v_x = self.view_ofs_x * v_forward_x + self.view_ofs_y * v_right_x + self.view_ofs_z * v_up_x;
		v_y = self.view_ofs_x * v_forward_y + self.view_ofs_y * v_right_y + self.view_ofs_z * v_up_y;
		v_z = self.view_ofs_x * v_forward_z + self.view_ofs_y * v_right_z + self.view_ofs_z * v_up_z;
		ang_x = -e.move_angles_x;
		ang_y = e.move_angles_y;
		ang_z = e.move_angles_z;
		makevectors(ang);
		self.move_origin_x = v_x * v_forward_x + v_y * v_forward_y + v_z * v_forward_z + e.move_origin_x;
		self.move_origin_x = v_x * v_right_x + v_y * v_right_y + v_z * v_right_z + e.move_origin_y;
		self.move_origin_x = v_x * v_up_x + v_y * v_up_y + v_z * v_up_z + e.move_origin_z;
	}

	self.move_angles = e.move_angles + self.v_angle;
	_Movetype_LinkEdict(false);
}
