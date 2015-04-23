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
	if(self.solid && (self.mins != '0 0 0' || self.maxs != '0 0 0'))
		sf |= 0x20;
	if(self.colormap != 0)
		sf |= 0x40;
	if(self.lodmodelindex1)
		sf |= 0x80;

	WriteByte(MSG_ENTITY, ENT_CLIENT_ANTIWALL);
	WriteByte(MSG_ENTITY, sf);

    if (self.inactive) {
        self.solid = SOLID_NOT;
    } else {
        self.solid = SOLID_BSP;
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
		WriteString(MSG_ENTITY, self.bgmscript);
		if(self.bgmscript != "")
		{
			WriteByte(MSG_ENTITY, floor(self.bgmscriptattack * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptdecay * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptsustain * 255));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptrelease * 64));
			WriteCoord(MSG_ENTITY, self.movedir_x);
			WriteCoord(MSG_ENTITY, self.movedir_y);
			WriteCoord(MSG_ENTITY, self.movedir_z);
			WriteByte(MSG_ENTITY, floor(self.lip * 255));
		}
        WriteShort(MSG_ENTITY, self.fade_start);
        WriteShort(MSG_ENTITY, self.fade_end);
        WriteShort(MSG_ENTITY, self.alpha_max);
        WriteShort(MSG_ENTITY, self.inactive);
        WriteByte(MSG_ENTITY, self.solid);
        /*printf("called\n");*/
	}

	return TRUE;
}

#define ANTIWALL_INIT(sol) \
	if(self.geomtype) if(autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")) self.movetype = MOVETYPE_PHYSICS; \
	if(!self.scale) self.scale = self.modelscale; \
	SetBrushEntityModel(); \
	self.use = antiwall_setcolormaptoactivator; \
	InitializeEntity(self, antiwall_dropbyspawnflags, INITPRIO_DROPTOFLOOR); \
	if(!self.solid) self.solid = (sol); else if(self.solid < 0) self.solid = SOLID_NOT; \
	if(!self.bgmscriptsustain) self.bgmscriptsustain = 1; else if(self.bgmscriptsustain < 0) self.bgmscriptsustain = 0; \
	Net_LinkEntity(self, TRUE, 0, antiwall_genericsendentity);

void spawnfunc_func_antiwall() { ANTIWALL_INIT(SOLID_BSP) } // Solid dynamic entity
void spawnfunc_func_antiillusion() { ANTIWALL_INIT(SOLID_NOT) } // Non-solid dynamic entity
void spawnfunc_aw() { ANTIWALL_INIT(SOLID_BSP) } // Solid dynamic entity
