#include "cl_controlpoint.qh"

.vector colormod;
.float alpha;
.int count;
.float pain_finished;

.bool iscaptured;

.vector cp_origin, cp_bob_origin;
.float cp_bob_spd;

.float cp_bob_dmg_z;

.vector punchangle;

.float max_health;

.entity icon_realmodel;

void cpicon_draw(entity this)
{
	if(time < this.move_time) { return; }

	if(this.cp_bob_dmg_z > 0)
		this.cp_bob_dmg_z = this.cp_bob_dmg_z - 3 * frametime;
	else
		this.cp_bob_dmg_z = 0;
	this.cp_bob_origin_z = 4 * PI * (1 - cos(this.cp_bob_spd));
	this.cp_bob_spd = this.cp_bob_spd + 1.875 * frametime;
	this.colormod = '1 1 1' * (2 - bound(0, (this.pain_finished - time) / 10, 1));

	if(!this.iscaptured) this.alpha = GetResource(this, RES_HEALTH) / this.max_health;

	if(this.iscaptured)
	{
		if (this.punchangle_x > 0)
		{
			this.punchangle_x = this.punchangle_x - 60 * frametime;
			if (this.punchangle_x < 0)
				this.punchangle_x = 0;
		}
		else if (this.punchangle_x < 0)
		{
			this.punchangle_x = this.punchangle_x + 60 * frametime;
			if (this.punchangle_x > 0)
				this.punchangle_x = 0;
		}

		if (this.punchangle_y > 0)
		{
			this.punchangle_y = this.punchangle_y - 60 * frametime;
			if (this.punchangle_y < 0)
				this.punchangle_y = 0;
		}
		else if (this.punchangle_y < 0)
		{
			this.punchangle_y = this.punchangle_y + 60 * frametime;
			if (this.punchangle_y > 0)
				this.punchangle_y = 0;
		}

		if (this.punchangle_z > 0)
		{
			this.punchangle_z = this.punchangle_z - 60 * frametime;
			if (this.punchangle_z < 0)
				this.punchangle_z = 0;
		}
		else if (this.punchangle_z < 0)
		{
			this.punchangle_z = this.punchangle_z + 60 * frametime;
			if (this.punchangle_z > 0)
				this.punchangle_z = 0;
		}

		this.angles_x = this.punchangle_x;
		this.angles_y = this.punchangle_y + this.angles_y;
		this.angles_z = this.punchangle_z;
		this.angles_y = this.angles_y + 45 * frametime;
	}

	setorigin(this, this.cp_origin + this.cp_bob_origin + eZ * this.cp_bob_dmg_z);
}

void cpicon_damage(entity this, float hp)
{
	if(!this.iscaptured) { return; }

	if(hp < this.max_health * 0.25)
		setmodel(this, MDL_ONS_CP3);
	else if(hp < this.max_health * 0.50)
		setmodel(this, MDL_ONS_CP2);
	else if(hp < this.max_health * 0.75)
		setmodel(this, MDL_ONS_CP1);
	else if(hp <= this.max_health || hp >= this.max_health)
		setmodel(this, MDL_ONS_CP);

	this.punchangle = (2 * randomvec() - '1 1 1') * 45;

	this.cp_bob_dmg_z = (2 * random() - 1) * 15;
	this.pain_finished = time + 1;
	this.colormod = '2 2 2';

	setsize(this, CPICON_MIN, CPICON_MAX);
}

void cpicon_construct(entity this, bool isnew)
{
	this.netname = "Control Point Icon";

	setmodel(this, MDL_ONS_CP);
	setsize(this, CPICON_MIN, CPICON_MAX);

	if(this.icon_realmodel == NULL)
	{
		this.icon_realmodel = new(cpicon_model);
		setmodel(this.icon_realmodel, MDL_Null);
		setorigin(this.icon_realmodel, this.origin);
		setsize(this.icon_realmodel, CPICON_MIN, CPICON_MAX);
		set_movetype(this.icon_realmodel, MOVETYPE_NOCLIP);
		this.icon_realmodel.solid = SOLID_NOT;
	}

	if(this.iscaptured) { this.icon_realmodel.solid = SOLID_BBOX; }

	set_movetype(this, MOVETYPE_NOCLIP);
	this.solid			= SOLID_NOT;
	set_movetype(this, MOVETYPE_NOCLIP);
	this.move_time		= time;
	this.drawmask		= MASK_NORMAL;
	this.alpha			= 1;
	this.draw			= cpicon_draw;
	this.cp_origin		= this.origin;
	this.cp_bob_origin 	= '0 0 0.1';
	this.cp_bob_spd 	= 0;

	if(isnew)
		IL_PUSH(g_drawables, this);
}

.vector glowmod;
void cpicon_changeteam(entity this)
{
	if(this.team)
	{
		this.glowmod = Team_ColorRGB(this.team - 1);
		this.teamradar_color = Team_ColorRGB(this.team - 1);
		this.colormap = 1024 + (this.team - 1) * 17;
	}
	else
	{
		this.colormap = 1024;
		this.glowmod = '1 1 0';
		this.teamradar_color = '1 1 0';
	}
}

NET_HANDLE(ENT_CLIENT_CONTROLPOINT_ICON, bool isnew)
{
	return = true;
	int sf = ReadByte();

	if(sf & CPSF_SETUP)
	{
		this.origin = ReadVector();
		setorigin(this, this.origin);

		SetResourceExplicit(this, RES_HEALTH, ReadByte());
		this.max_health = ReadByte();
		this.count = ReadByte();
		this.team = ReadByte();
		this.iscaptured = ReadByte();

		if(!this.count)
			this.count = (GetResource(this, RES_HEALTH) - this.max_health) * frametime;

		cpicon_changeteam(this);
		cpicon_construct(this, isnew);
	}

	if(sf & CPSF_STATUS)
	{
		int _tmp = ReadByte();
		if(_tmp != this.team)
		{
			this.team = _tmp;
			cpicon_changeteam(this);
		}

		_tmp = ReadByte();

		if(_tmp != GetResource(this, RES_HEALTH))
			cpicon_damage(this, _tmp);

		SetResourceExplicit(this, RES_HEALTH, _tmp);
	}
}
