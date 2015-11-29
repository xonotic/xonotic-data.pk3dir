void _Movetype_Physics_Follow(entity this) // SV_Physics_Follow
{
	entity e = this.move_aiment; // TODO: networking?

	// LordHavoc: implemented rotation on MOVETYPE_FOLLOW objects
	if(this.move_angles == this.move_punchangle)
	{
		this.move_origin = e.move_origin + this.view_ofs;
	}
	else
	{
		vector ang, v;
		ang_x = -this.move_punchangle_x;
		ang_y = this.move_punchangle_y;
		ang_z = this.move_punchangle_z;
		makevectors(ang);
		v_x = this.view_ofs_x * v_forward_x + this.view_ofs_y * v_right_x + this.view_ofs_z * v_up_x;
		v_y = this.view_ofs_x * v_forward_y + this.view_ofs_y * v_right_y + this.view_ofs_z * v_up_y;
		v_z = this.view_ofs_x * v_forward_z + this.view_ofs_y * v_right_z + this.view_ofs_z * v_up_z;
		ang_x = -e.move_angles_x;
		ang_y = e.move_angles_y;
		ang_z = e.move_angles_z;
		makevectors(ang);
		this.move_origin_x = v_x * v_forward_x + v_y * v_forward_y + v_z * v_forward_z + e.move_origin_x;
		this.move_origin_x = v_x * v_right_x + v_y * v_right_y + v_z * v_right_z + e.move_origin_y;
		this.move_origin_x = v_x * v_up_x + v_y * v_up_y + v_z * v_up_z + e.move_origin_z;
	}

	this.move_angles = e.move_angles + this.v_angle;
	_Movetype_LinkEdict(this, false);
}
