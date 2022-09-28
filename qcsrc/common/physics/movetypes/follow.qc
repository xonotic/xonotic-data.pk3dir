#include "follow.qh"

void _Movetype_Physics_Follow(entity this) // SV_Physics_Follow
{
	entity e = this.aiment;

	if(e.angles == this.punchangle)
	{
		this.origin = e.origin + this.view_ofs;
	}
	else
	{
		vector ang, v;
		ang_x = -this.punchangle_x;
		ang_y = this.punchangle_y;
		ang_z = this.punchangle_z;
		makevectors(ang);
		v_x = this.view_ofs_x * v_forward_x + this.view_ofs_y * v_right_x + this.view_ofs_z * v_up_x;
		v_y = this.view_ofs_x * v_forward_y + this.view_ofs_y * v_right_y + this.view_ofs_z * v_up_y;
		v_z = this.view_ofs_x * v_forward_z + this.view_ofs_y * v_right_z + this.view_ofs_z * v_up_z;
		ang = e.angles;
		ang_x = -e.angles_x;
		makevectors(ang);
		this.origin_x = v_x * v_forward_x + v_y * v_forward_y + v_z * v_forward_z + e.origin_x;
		this.origin_y = v_x * v_right_x + v_y * v_right_y + v_z * v_right_z + e.origin_y;
		this.origin_z = v_x * v_up_x + v_y * v_up_y + v_z * v_up_z + e.origin_z;
	}

	this.angles = e.angles + this.v_angle;
	_Movetype_LinkEdict(this, false);
}
