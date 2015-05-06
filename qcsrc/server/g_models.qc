#include "_all.qh"

#include "g_subs.qh"
#include "g_triggers.qh"

#include "../common/constants.qh"
#include "../csqcmodellib/sv_model.qh"

.float modelscale;

void g_model_setcolormaptoactivator (void)
{
	if(teamplay)
	{
		if(activator.team)
			self.colormap = (activator.team - 1) * 0x11;
		else
			self.colormap = 0x00;
	}
	else
		self.colormap = floor(random() * 256);
	self.colormap |= 1024; // RENDER_COLORMAPPED
}

void g_clientmodel_setcolormaptoactivator (void)
{
	g_model_setcolormaptoactivator();
	self.SendFlags |= 1;
}

void g_model_dropbyspawnflags()
{
	if((self.spawnflags & 3) == 1) // ALIGN_ORIGIN
	{
		traceline(self.origin, self.origin - '0 0 4096', MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos);
	}
	else if((self.spawnflags & 3) == 2) // ALIGN_BOTTOM
	{
		tracebox(self.origin, self.mins, self.maxs, self.origin - '0 0 4096', MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos);
	}
	else if((self.spawnflags & 3) == 3) // ALIGN_ORIGIN | ALIGN_BOTTOM
	{
		traceline(self.origin, self.origin - '0 0 4096', MOVE_NOMONSTERS, self);
		setorigin(self, trace_endpos - '0 0 1' * self.mins.z);
	}
}

void g_clientmodel_dropbyspawnflags()
{
	vector o0;
	o0 = self.origin;
	g_model_dropbyspawnflags();
	if(self.origin != o0)
		self.SendFlags |= 2;
}

float g_clientmodel_genericsendentity (entity to, int sf)
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

	WriteByte(MSG_ENTITY, ENT_CLIENT_WALL);
	WriteByte(MSG_ENTITY, sf);

	if(sf & 1)
	{
		if(sf & 0x40)
			WriteShort(MSG_ENTITY, self.colormap);
	}

	if(sf & 2)
	{
		WriteCoord(MSG_ENTITY, self.origin.x);
		WriteCoord(MSG_ENTITY, self.origin.y);
		WriteCoord(MSG_ENTITY, self.origin.z);
	}

	if(sf & 4)
	{
		if(sf & 0x10)
		{
			WriteAngle(MSG_ENTITY, self.angles.x);
			WriteAngle(MSG_ENTITY, self.angles.y);
			WriteAngle(MSG_ENTITY, self.angles.z);
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
		}
		else
			WriteShort(MSG_ENTITY, self.modelindex);
		WriteByte(MSG_ENTITY, self.solid);
		WriteShort(MSG_ENTITY, floor(self.scale * 256));
		if(sf & 0x20)
		{
			WriteCoord(MSG_ENTITY, self.mins.x);
			WriteCoord(MSG_ENTITY, self.mins.y);
			WriteCoord(MSG_ENTITY, self.mins.z);
			WriteCoord(MSG_ENTITY, self.maxs.x);
			WriteCoord(MSG_ENTITY, self.maxs.y);
			WriteCoord(MSG_ENTITY, self.maxs.z);
		}
		WriteString(MSG_ENTITY, self.bgmscript);
		if(self.bgmscript != "")
		{
			WriteByte(MSG_ENTITY, floor(self.bgmscriptattack * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptdecay * 64));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptsustain * 255));
			WriteByte(MSG_ENTITY, floor(self.bgmscriptrelease * 64));
			WriteCoord(MSG_ENTITY, self.movedir.x);
			WriteCoord(MSG_ENTITY, self.movedir.y);
			WriteCoord(MSG_ENTITY, self.movedir.z);
			WriteByte(MSG_ENTITY, floor(self.lip * 255));
		}
	}

	return true;
}


#define G_MODEL_INIT(sol) \
	if(self.geomtype) if(autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")) self.movetype = MOVETYPE_PHYSICS; \
	if(!self.scale) self.scale = self.modelscale; \
	SetBrushEntityModel(); \
	self.use = g_model_setcolormaptoactivator; \
	InitializeEntity(self, g_model_dropbyspawnflags, INITPRIO_DROPTOFLOOR); \
	if(!self.solid) self.solid = (sol); else if(self.solid < 0) self.solid = SOLID_NOT;

#define G_CLIENTMODEL_INIT(sol) \
	if(self.geomtype) if(autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")) self.movetype = MOVETYPE_PHYSICS; \
	if(!self.scale) self.scale = self.modelscale; \
	SetBrushEntityModel(); \
	self.use = g_clientmodel_setcolormaptoactivator; \
	InitializeEntity(self, g_clientmodel_dropbyspawnflags, INITPRIO_DROPTOFLOOR); \
	if(!self.solid) self.solid = (sol); else if(self.solid < 0) self.solid = SOLID_NOT; \
	if(!self.bgmscriptsustain) self.bgmscriptsustain = 1; else if(self.bgmscriptsustain < 0) self.bgmscriptsustain = 0; \
	Net_LinkEntity(self, true, 0, g_clientmodel_genericsendentity);

// non-solid model entities:
void spawnfunc_misc_gamemodel()         { self.angles_x = -self.angles.x; G_MODEL_INIT      (SOLID_NOT) } // model entity
void spawnfunc_misc_clientmodel()       { self.angles_x = -self.angles.x; G_CLIENTMODEL_INIT(SOLID_NOT) } // model entity
void spawnfunc_misc_models()            { self.angles_x = -self.angles.x; G_MODEL_INIT      (SOLID_NOT) } // DEPRECATED old compat entity with confusing name, do not use

// non-solid brush entities:
void spawnfunc_func_illusionary()       { G_MODEL_INIT      (SOLID_NOT) } // Q1 name (WARNING: MISPREDICTED)
void spawnfunc_func_clientillusionary() { G_CLIENTMODEL_INIT(SOLID_NOT) } // brush entity
void spawnfunc_func_static()            { G_MODEL_INIT      (SOLID_NOT) } // DEPRECATED old alias name from some other game

// solid brush entities
void spawnfunc_func_wall()              { G_MODEL_INIT      (SOLID_BSP) } // Q1 name
void spawnfunc_func_clientwall()        { G_CLIENTMODEL_INIT(SOLID_BSP) } // brush entity (WARNING: MISPREDICTED)
