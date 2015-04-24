#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../dpdefs/progsdefs.qh"
    #include "../dpdefs/dpextensions.qh"
    #include "../common/constants.qh"
    #include "autocvars.qh"
    #include "constants.qh"
    #include "defs.qh"
    #include "../csqcmodellib/sv_model.qh"
#endif

void antiwall_setcolormaptoactivator (void)
{
	g_model_setcolormaptoactivator();
	self.SendFlags |= 9;
}

void antiwall_dropbyspawnflags()
{
	vector o0;
	o0 = self.origin;
	g_model_dropbyspawnflags();
	if(self.origin != o0)
		self.SendFlags |= 2;
}

float antiwall_genericsendentity (entity to, float sf)
{
	sf = sf & 0x0F;
	if(self.angles != '0 0 0')
		sf |= 0x10;
	if(self.mins != '0 0 0' || self.maxs != '0 0 0')
		sf |= 0x20;
	if(self.colormap != 0)
		sf |= 0x40;
	if(self.lodmodelindex1)
		sf |= 0x80;

	WriteByte(MSG_ENTITY, ENT_CLIENT_ANTIWALL);
	WriteByte(MSG_ENTITY, sf);

    if (!self.illusion) {
        if (self.inactive) {
            self.solid = SOLID_NOT;
        } else {
            self.solid = SOLID_BSP;
        }
    } else {
        self.solid = SOLID_NOT;
    }

	if(sf & 1)
	{
		if(sf & 0x40)
			WriteShort(MSG_ENTITY, self.colormap);
	}

	if(sf & 2)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}

	if(sf & 4)
	{
		if(sf & 0x10)
		{
			WriteAngle(MSG_ENTITY, self.angles_x);
			WriteAngle(MSG_ENTITY, self.angles_y);
			WriteAngle(MSG_ENTITY, self.angles_z);
		}
	}

	if(sf & 8)
	{
		if(sf & 0x80)
		{
			WriteShort(MSG_ENTITY, self.lodmodelindex0);
			WriteShort(MSG_ENTITY, bound(0, self.loddistance1, 65535));
			WriteShort(MSG_ENTITY, self.lodmodelindex1);
			WriteShort(MSG_ENTITY, bound(0, self.loddistance2, 65535));
			WriteShort(MSG_ENTITY, self.lodmodelindex2);
		} else {
			WriteShort(MSG_ENTITY, self.modelindex);
        }
		WriteShort(MSG_ENTITY, floor(self.scale * 256));
		if(sf & 0x20)
		{
			WriteCoord(MSG_ENTITY, self.mins_x);
			WriteCoord(MSG_ENTITY, self.mins_y);
			WriteCoord(MSG_ENTITY, self.mins_z);
			WriteCoord(MSG_ENTITY, self.maxs_x);
			WriteCoord(MSG_ENTITY, self.maxs_y);
			WriteCoord(MSG_ENTITY, self.maxs_z);
		}
        WriteShort(MSG_ENTITY, self.fade_start);
        WriteShort(MSG_ENTITY, self.fade_end);
        WriteShort(MSG_ENTITY, self.alpha_max);
        WriteShort(MSG_ENTITY, self.inactive);
        WriteByte(MSG_ENTITY, self.solid);
        WriteShort(MSG_ENTITY, self.illusion);
        /*printf("called\n");*/
	}

	return TRUE;
}

void spawnfunc_func_antiwall() {
    if (self.geomtype) {
        if (autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")) {
            self.movetype = MOVETYPE_PHYSICS;
        }
    }
    if (!self.scale) { self.scale = self.modelscale; }
    SetBrushEntityModel();
    self.use = antiwall_setcolormaptoactivator;
    InitializeEntity(self, antiwall_dropbyspawnflags, INITPRIO_DROPTOFLOOR);
    if (self.illusion) {
        self.solid = SOLID_NOT;
    } else {
        self.solid = SOLID_BSP;
    }
    Net_LinkEntity(self, TRUE, 0, antiwall_genericsendentity);
}
