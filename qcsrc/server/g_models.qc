#include "g_models.qh"

#include "g_subs.qh"
#include <common/net_linked.qh>
#include "../common/triggers/subs.qh"
#include "../common/triggers/triggers.qh"

entityclass(BGMScript);
class(BGMScript) .string bgmscript;
class(BGMScript) .float bgmscriptattack;
class(BGMScript) .float bgmscriptdecay;
class(BGMScript) .float bgmscriptsustain;
class(BGMScript) .float bgmscriptrelease;

#include "../common/constants.qh"
#include "../lib/csqcmodel/sv_model.qh"

.float modelscale;

void g_model_setcolormaptoactivator(entity this, entity actor, entity trigger)
{
	if(teamplay)
	{
		if(actor.team)
			this.colormap = (actor.team - 1) * 0x11;
		else
			this.colormap = 0x00;
	}
	else
		this.colormap = floor(random() * 256);
	this.colormap |= BIT(10); // RENDER_COLORMAPPED
}

void g_clientmodel_setcolormaptoactivator(entity this, entity actor, entity trigger)
{
	g_model_setcolormaptoactivator(this, actor, trigger);
	this.SendFlags |= (BIT(3) | BIT(0));
}

void g_clientmodel_use(entity this, entity actor, entity trigger)
{
	if (this.antiwall_flag == 1)
	{
		this.inactive = 1;
		this.solid = SOLID_NOT;
	}
	else if (this.antiwall_flag == 2)
	{
		this.inactive = 0;
		this.solid = this.default_solid;
	}
	g_clientmodel_setcolormaptoactivator(this, actor, trigger);
}

void g_model_dropbyspawnflags(entity this)
{
	if((this.spawnflags & 3) == 1) // ALIGN_ORIGIN
	{
		traceline(this.origin, this.origin - '0 0 4096', MOVE_NOMONSTERS, this);
		setorigin(this, trace_endpos);
	}
	else if((this.spawnflags & 3) == 2) // ALIGN_BOTTOM
	{
		tracebox(this.origin, this.mins, this.maxs, this.origin - '0 0 4096', MOVE_NOMONSTERS, this);
		setorigin(this, trace_endpos);
	}
	else if((this.spawnflags & 3) == 3) // ALIGN_ORIGIN | ALIGN_BOTTOM
	{
		traceline(this.origin, this.origin - '0 0 4096', MOVE_NOMONSTERS, this);
		setorigin(this, trace_endpos - '0 0 1' * this.mins.z);
	}
}

void g_clientmodel_dropbyspawnflags(entity this)
{
	vector o0;
	o0 = this.origin;
	g_model_dropbyspawnflags(this);
	if(this.origin != o0)
		this.SendFlags |= 2;
}

bool g_clientmodel_genericsendentity(entity this, entity to, int sf)
{
	sf = sf & 0x0F;
	if(this.angles != '0 0 0')
		sf |= 0x10;
	if(this.mins != '0 0 0' || this.maxs != '0 0 0')
		sf |= 0x20;
	if(this.colormap != 0)
		sf |= 0x40;
	if(this.lodmodelindex1)
		sf |= 0x80;

	WriteHeader(MSG_ENTITY, ENT_CLIENT_WALL);
	WriteByte(MSG_ENTITY, sf);

	if(sf & BIT(0))
	{
		if(sf & 0x40)
			WriteShort(MSG_ENTITY, this.colormap);
		WriteByte(MSG_ENTITY, this.skin);
	}

	if(sf & BIT(1))
	{
		WriteCoord(MSG_ENTITY, this.origin.x);
		WriteCoord(MSG_ENTITY, this.origin.y);
		WriteCoord(MSG_ENTITY, this.origin.z);
	}

	if(sf & BIT(2))
	{
		if(sf & 0x10)
		{
			WriteAngle(MSG_ENTITY, this.angles.x);
			WriteAngle(MSG_ENTITY, this.angles.y);
			WriteAngle(MSG_ENTITY, this.angles.z);
		}
	}

	if(sf & BIT(3))
	{
		if(sf & 0x80)
		{
			WriteShort(MSG_ENTITY, this.lodmodelindex0);
			WriteShort(MSG_ENTITY, bound(0, this.loddistance1, 65535));
			WriteShort(MSG_ENTITY, this.lodmodelindex1);
			WriteShort(MSG_ENTITY, bound(0, this.loddistance2, 65535));
			WriteShort(MSG_ENTITY, this.lodmodelindex2);
		}
		else
			WriteShort(MSG_ENTITY, this.modelindex);
		WriteByte(MSG_ENTITY, this.solid);
		WriteShort(MSG_ENTITY, floor(this.scale * 256));
		if(sf & 0x20)
		{
			WriteCoord(MSG_ENTITY, this.mins.x);
			WriteCoord(MSG_ENTITY, this.mins.y);
			WriteCoord(MSG_ENTITY, this.mins.z);
			WriteCoord(MSG_ENTITY, this.maxs.x);
			WriteCoord(MSG_ENTITY, this.maxs.y);
			WriteCoord(MSG_ENTITY, this.maxs.z);
		}
		WriteString(MSG_ENTITY, this.bgmscript);
		if(this.bgmscript != "")
		{
			WriteByte(MSG_ENTITY, floor(this.bgmscriptattack * 64));
			WriteByte(MSG_ENTITY, floor(this.bgmscriptdecay * 64));
			WriteByte(MSG_ENTITY, floor(this.bgmscriptsustain * 255));
			WriteByte(MSG_ENTITY, floor(this.bgmscriptrelease * 64));
			WriteCoord(MSG_ENTITY, this.movedir.x);
			WriteCoord(MSG_ENTITY, this.movedir.y);
			WriteCoord(MSG_ENTITY, this.movedir.z);
			WriteByte(MSG_ENTITY, floor(this.lip * 255));
		}
		WriteByte(MSG_ENTITY, this.fade_start);
		WriteByte(MSG_ENTITY, this.fade_end);
		WriteByte(MSG_ENTITY, this.alpha_max);
		WriteByte(MSG_ENTITY, this.alpha_min);
		WriteByte(MSG_ENTITY, this.inactive);
		WriteShort(MSG_ENTITY, this.fade_vertical_offset);
	}

	return true;
}


#define G_MODEL_INIT(ent,sol) \
	if(ent.geomtype) if(autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")) set_movetype(ent, MOVETYPE_PHYSICS); \
	if(!ent.scale) ent.scale = ent.modelscale; \
	SetBrushEntityModel(ent); \
	ent.use = g_model_setcolormaptoactivator; \
	InitializeEntity(ent, g_model_dropbyspawnflags, INITPRIO_DROPTOFLOOR); \
	if(!ent.solid) ent.solid = (sol); else if(ent.solid < 0) ent.solid = SOLID_NOT;

#define G_CLIENTMODEL_INIT(ent,sol) \
	if(ent.geomtype) if(autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")) set_movetype(ent, MOVETYPE_PHYSICS); \
	if(!ent.scale) ent.scale = ent.modelscale; \
	SetBrushEntityModel(ent); \
	ent.use = g_clientmodel_use; \
	InitializeEntity(ent, g_clientmodel_dropbyspawnflags, INITPRIO_DROPTOFLOOR); \
	if(!ent.solid) ent.solid = (sol); else if(ent.solid < 0) ent.solid = SOLID_NOT; \
	if(!ent.bgmscriptsustain) ent.bgmscriptsustain = 1; else if(ent.bgmscriptsustain < 0) ent.bgmscriptsustain = 0; \
	Net_LinkEntity(ent, true, 0, g_clientmodel_genericsendentity); \
	ent.default_solid = sol;

// non-solid model entities:
spawnfunc(misc_gamemodel)         { this.angles_x = -this.angles.x; G_MODEL_INIT      (this, SOLID_NOT) } // model entity
spawnfunc(misc_clientmodel)       { this.angles_x = -this.angles.x; G_CLIENTMODEL_INIT(this, SOLID_NOT) } // model entity
spawnfunc(misc_models)            { this.angles_x = -this.angles.x; G_MODEL_INIT      (this, SOLID_NOT) } // DEPRECATED old compat entity with confusing name, do not use

// non-solid brush entities:
spawnfunc(func_illusionary)       { G_MODEL_INIT      (this, SOLID_NOT) } // Q1 name (WARNING: MISPREDICTED)
spawnfunc(func_clientillusionary) { G_CLIENTMODEL_INIT(this, SOLID_NOT) } // brush entity
spawnfunc(func_static)            { G_MODEL_INIT      (this, SOLID_NOT) } // DEPRECATED old alias name from some other game

// solid brush entities
spawnfunc(func_wall)              { G_MODEL_INIT      (this, SOLID_BSP) } // Q1 name
spawnfunc(func_clientwall)        { G_CLIENTMODEL_INIT(this, SOLID_BSP) } // brush entity (WARNING: MISPREDICTED)
