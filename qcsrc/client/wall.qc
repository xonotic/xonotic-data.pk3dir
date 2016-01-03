#include "wall.qh"

#include "bgmscript.qh"


#include "../lib/csqcmodel/interpolate.qh"

.float alpha;
.float scale;
.vector movedir;

void Ent_Wall_PreDraw()
{SELFPARAM();
	if (self.inactive)
	{
		self.alpha = 0;
	}
	else
	{
		vector org = getpropertyvec(VF_ORIGIN);
		if(!checkpvs(org, self))
			self.alpha = 0;
		else if(self.fade_start || self.fade_end) {
			vector offset = '0 0 0';
			offset_z = self.fade_vertical_offset;
			float player_dist = vlen(org - self.origin - 0.5 * (self.mins + self.maxs) + offset);
			if (self.fade_end == self.fade_start)
			{
				if (player_dist >= self.fade_start)
					self.alpha = 0;
				else
					self.alpha = 1;
			}
			else
			{
				self.alpha = (self.alpha_min + self.alpha_max * bound(0,
							   (self.fade_end - player_dist)
							   / (self.fade_end - self.fade_start), 1)) / 100.0;
			}
		}
		else
		{
			self.alpha = 1;
		}
	}
	if(self.alpha <= 0)
		self.drawmask = 0;
	else
		self.drawmask = MASK_NORMAL;
}

void Ent_Wall_Draw(entity this)
{
	float f;
	var .vector fld;

	if(this.bgmscriptangular)
		fld = angles;
	else
		fld = origin;
	this.(fld) = this.saved;

	if(this.lodmodelindex1)
	{
		if(autocvar_cl_modeldetailreduction <= 0)
		{
			if(this.lodmodelindex2 && autocvar_cl_modeldetailreduction <= -2)
				this.modelindex = this.lodmodelindex2;
			else if(autocvar_cl_modeldetailreduction <= -1)
				this.modelindex = this.lodmodelindex1;
			else
				this.modelindex = this.lodmodelindex0;
		}
		else
		{
			float distance = vlen(NearestPointOnBox(this, view_origin) - view_origin);
			f = (distance * current_viewzoom + 100.0) * autocvar_cl_modeldetailreduction;
			f *= 1.0 / bound(0.01, view_quality, 1);
			if(this.lodmodelindex2 && f > this.loddistance2)
				this.modelindex = this.lodmodelindex2;
			else if(f > this.loddistance1)
				this.modelindex = this.lodmodelindex1;
			else
				this.modelindex = this.lodmodelindex0;
		}
	}

	InterpolateOrigin_Do(this);

	this.saved = this.(fld);

	f = doBGMScript(this);
	if(f >= 0)
	{
		if(this.lip < 0) // < 0: alpha goes from 1 to 1-|lip| when toggled (toggling subtracts lip)
			this.alpha = 1 + this.lip * f;
		else // > 0: alpha goes from 1-|lip| to 1 when toggled (toggling adds lip)
			this.alpha = 1 - this.lip * (1 - f);
		this.(fld) = this.(fld) + this.movedir * f;
	}
	else
		this.alpha = 1;

	if(this.alpha >= ALPHA_MIN_VISIBLE)
		this.drawmask = MASK_NORMAL;
	else
		this.drawmask = 0;
}

void Ent_Wall_Remove(entity this)
{
	if(this.bgmscript)
		strunzone(this.bgmscript);
	this.bgmscript = string_null;
}

NET_HANDLE(ENT_CLIENT_WALL, bool isnew)
{
	int f;
	var .vector fld;

	InterpolateOrigin_Undo(this);
	this.iflags = IFLAG_ANGLES | IFLAG_ORIGIN;

	if(this.bgmscriptangular)
		fld = angles;
	else
		fld = origin;
	this.(fld) = this.saved;

	f = ReadByte();

	if(f & 1)
	{
		if(f & 0x40)
			this.colormap = ReadShort();
		else
			this.colormap = 0;
	}

	if(f & 2)
	{
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();
		setorigin(this, this.origin);
	}

	if(f & 4)
	{
		if(f & 0x10)
		{
			this.angles_x = ReadAngle();
			this.angles_y = ReadAngle();
			this.angles_z = ReadAngle();
		}
		else
			this.angles = '0 0 0';
	}

	if(f & 8)
	{
		if(f & 0x80)
		{
			this.lodmodelindex0 = ReadShort();
			this.loddistance1 = ReadShort();
			this.lodmodelindex1 = ReadShort();
			this.loddistance2 = ReadShort();
			this.lodmodelindex2 = ReadShort();
		}
		else
		{
			this.modelindex = ReadShort();
			this.loddistance1 = 0;
			this.loddistance2 = 0;
		}
		this.solid = ReadByte();
		this.scale = ReadShort() / 256.0;
		if(f & 0x20)
		{
			this.mins_x = ReadCoord();
			this.mins_y = ReadCoord();
			this.mins_z = ReadCoord();
			this.maxs_x = ReadCoord();
			this.maxs_y = ReadCoord();
			this.maxs_z = ReadCoord();
		}
		else
			this.mins = this.maxs = '0 0 0';
		setsize(this, this.mins, this.maxs);

		if(this.bgmscript)
			strunzone(this.bgmscript);
		this.bgmscript = ReadString();
		if(substring(this.bgmscript, 0, 1) == "<")
		{
			this.bgmscript = strzone(substring(this.bgmscript, 1, -1));
			this.bgmscriptangular = 1;
		}
		else
		{
			this.bgmscript = strzone(this.bgmscript);
			this.bgmscriptangular = 0;
		}
		if(this.bgmscript != "")
		{
			this.bgmscriptattack = ReadByte() / 64.0;
			this.bgmscriptdecay = ReadByte() / 64.0;
			this.bgmscriptsustain = ReadByte() / 255.0;
			this.bgmscriptrelease = ReadByte() / 64.0;
			this.movedir_x = ReadCoord();
			this.movedir_y = ReadCoord();
			this.movedir_z = ReadCoord();
			this.lip = ReadByte() / 255.0;
		}
		this.fade_start = ReadShort();
		this.fade_end = ReadShort();
		this.alpha_max = ReadShort();
		this.alpha_min = ReadShort();
		this.inactive = ReadShort();
		this.fade_vertical_offset = ReadShort();
		BGMScript_InitEntity(this);
	}

	return = true;

	InterpolateOrigin_Note(this);

	this.saved = this.(fld);

	this.entremove = Ent_Wall_Remove;
	this.draw = Ent_Wall_Draw;
	this.predraw = Ent_Wall_PreDraw;
}
