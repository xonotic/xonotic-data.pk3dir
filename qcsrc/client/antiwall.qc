#include "antiwall.qh"

void Ent_Antiwall_PreDraw()
{
    if (self.inactive) {
        self.alpha = 0;
    } else {
        vector org;
        org = getpropertyvec(VF_ORIGIN);
        if(!checkpvs(org, self))
            self.alpha = 0;
        else if(self.fade_start) {
            self.alpha = self.alpha_max / 100.0 * bound(0,
                               (self.fade_end - vlen(org - self.origin - 0.5 * (self.mins + self.maxs)))
                               / (self.fade_end - self.fade_start), 1);
        } else {
            self.alpha = 1;
        }
    }
    if(self.alpha <= 0)
        self.drawmask = 0;
    else
        self.drawmask = MASK_NORMAL;
}

void Ent_Antiwall_Draw()
{
	float f;

	if(self.lodmodelindex1)
	{
		if(autocvar_cl_modeldetailreduction <= 0)
		{
			if(self.lodmodelindex2 && autocvar_cl_modeldetailreduction <= -2)
				self.modelindex = self.lodmodelindex2;
			else if(autocvar_cl_modeldetailreduction <= -1)
				self.modelindex = self.lodmodelindex1;
			else
				self.modelindex = self.lodmodelindex0;
		}
		else
		{
			float distance = vlen(NearestPointOnBox(self, view_origin) - view_origin);
			f = (distance * current_viewzoom + 100.0) * autocvar_cl_modeldetailreduction;
			f *= 1.0 / bound(0.01, view_quality, 1);
			if(self.lodmodelindex2 && f > self.loddistance2)
				self.modelindex = self.lodmodelindex2;
			else if(f > self.loddistance1)
				self.modelindex = self.lodmodelindex1;
			else
				self.modelindex = self.lodmodelindex0;
		}
	}

	InterpolateOrigin_Do();
}

void Ent_Antiwall_Remove()
{
}

void Ent_Antiwall()
{
	float f;

	InterpolateOrigin_Undo();
	self.iflags = IFLAG_ANGLES | IFLAG_ORIGIN;

	f = ReadByte();

	if(f & 1)
	{
		if(f & 0x40)
			self.colormap = ReadShort();
		else
			self.colormap = 0;
	}

	if(f & 2)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
	}

	if(f & 4)
	{
		if(f & 0x10)
		{
			self.angles_x = ReadAngle();
			self.angles_y = ReadAngle();
			self.angles_z = ReadAngle();
		}
		else
			self.angles = '0 0 0';
	}

	if(f & 8)
	{
		if(f & 0x80)
		{
			self.lodmodelindex0 = ReadShort();
			self.loddistance1 = ReadShort();
			self.lodmodelindex1 = ReadShort();
			self.loddistance2 = ReadShort();
			self.lodmodelindex2 = ReadShort();
		}
		else
		{
			self.modelindex = ReadShort();
			self.loddistance1 = 0;
			self.loddistance2 = 0;
		}
		self.scale = ReadShort() / 256.0;
		if(f & 0x20)
		{
			self.mins_x = ReadCoord();
			self.mins_y = ReadCoord();
			self.mins_z = ReadCoord();
			self.maxs_x = ReadCoord();
			self.maxs_y = ReadCoord();
			self.maxs_z = ReadCoord();
		}
		else
			self.mins = self.maxs = '0 0 0';
		setsize(self, self.mins, self.maxs);

        self.fade_start = ReadShort();
        self.fade_end = ReadShort();
        self.alpha_max = ReadShort();
        self.inactive = ReadShort();
        self.solid = ReadByte();
        self.illusion = ReadShort();
        if (!self.fade_start) {
            self.fade_start = 50;
        }
        if (!self.fade_end) {
            self.fade_end = 150;
        }
        if (!self.alpha_max) {
            self.alpha_max = 1;
        }
	}
	InterpolateOrigin_Note();

	self.entremove = Ent_Antiwall_Remove;
	self.draw = Ent_Antiwall_Draw;
    self.predraw = Ent_Antiwall_PreDraw;
}

