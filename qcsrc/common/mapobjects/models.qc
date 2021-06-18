#include "models.qh"

#ifdef SVQC
#include <common/constants.qh>
#include <common/mapobjects/bgmscript.qh>
#include <common/mapobjects/subs.qh>
#include <common/mapobjects/triggers.qh>
#include <common/net_linked.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <lib/csqcmodel/sv_model.qh>

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
	// Flag to set func_clientwall state
	// 1 == deactivate, 2 == activate, 0 == do nothing
	if(this.classname == "func_clientwall" || this.classname == "func_clientillusionary")
		this.antiwall_flag = trigger.antiwall_flag;

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
		WriteVector(MSG_ENTITY, this.origin);
	}

	if(sf & BIT(2))
	{
		if(sf & 0x10)
			WriteAngleVector(MSG_ENTITY, this.angles);
	}

	if(sf & BIT(3))
	{
		if(sf & 0x80)
		{
			WriteShort(MSG_ENTITY, this.lodmodelindex0);
			WriteShort(MSG_ENTITY, bound(0, this.loddistance1, 32767));
			WriteShort(MSG_ENTITY, this.lodmodelindex1);
			WriteShort(MSG_ENTITY, bound(0, this.loddistance2, 32767));
			WriteShort(MSG_ENTITY, this.lodmodelindex2);
		}
		else
			WriteShort(MSG_ENTITY, this.modelindex);
		WriteByte(MSG_ENTITY, this.solid);
		WriteShort(MSG_ENTITY, floor(this.scale * 256));
		if(sf & 0x20)
		{
			WriteVector(MSG_ENTITY, this.mins);
			WriteVector(MSG_ENTITY, this.maxs);
		}
		WriteString(MSG_ENTITY, this.bgmscript);
		if(this.bgmscript != "")
		{
			WriteByte(MSG_ENTITY, floor(this.bgmscriptattack * 64));
			WriteByte(MSG_ENTITY, floor(this.bgmscriptdecay * 64));
			WriteByte(MSG_ENTITY, floor(this.bgmscriptsustain * 255));
			WriteByte(MSG_ENTITY, floor(this.bgmscriptrelease * 64));
			WriteVector(MSG_ENTITY, this.movedir);
			WriteByte(MSG_ENTITY, floor(this.lip * 255));
		}
		WriteShort(MSG_ENTITY, bound(0, this.fade_start, 32767));
		WriteShort(MSG_ENTITY, bound(0, this.fade_end, 32767));
		WriteByte(MSG_ENTITY, floor(this.alpha_max * 256));
		WriteByte(MSG_ENTITY, floor(this.alpha_min * 256));
		WriteByte(MSG_ENTITY, this.inactive);
		WriteShort(MSG_ENTITY, this.fade_vertical_offset);
	}

	return true;
}


#define G_MODEL_INIT(ent,sol) \
	if(ent.geomtype && autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")) set_movetype(ent, MOVETYPE_PHYSICS); \
	if(!ent.scale) ent.scale = ent.modelscale; \
	SetBrushEntityModel(ent,true); \
	ent.use = g_model_setcolormaptoactivator; \
	InitializeEntity(ent, g_model_dropbyspawnflags, INITPRIO_DROPTOFLOOR); \
	if(!ent.solid) ent.solid = (sol); \
	else if(ent.solid < 0) ent.solid = SOLID_NOT;

#define G_CLIENTMODEL_INIT(ent,sol) \
	if(ent.geomtype && autocvar_physics_ode && checkextension("DP_PHYSICS_ODE")) set_movetype(ent, MOVETYPE_PHYSICS); \
	if(!ent.scale) ent.scale = ent.modelscale; \
	SetBrushEntityModel(ent,true); \
	ent.use = g_clientmodel_use; \
	InitializeEntity(ent, g_clientmodel_dropbyspawnflags, INITPRIO_DROPTOFLOOR); \
	if(!ent.solid) ent.solid = (sol); \
	else if(ent.solid < 0) ent.solid = SOLID_NOT; \
	if(!ent.bgmscriptsustain) ent.bgmscriptsustain = 1; \
	else if(ent.bgmscriptsustain < 0) ent.bgmscriptsustain = 0; \
	Net_LinkEntity(ent, true, 0, g_clientmodel_genericsendentity); \
	ent.default_solid = sol;

// non-solid model entities:
spawnfunc(misc_gamemodel)         { this.angles_x = -this.angles.x; G_MODEL_INIT      (this, SOLID_NOT) } // model entity
spawnfunc(misc_clientmodel)       { this.angles_x = -this.angles.x; G_CLIENTMODEL_INIT(this, SOLID_NOT) } // model entity
spawnfunc(misc_models)            { this.angles_x = -this.angles.x; G_MODEL_INIT      (this, SOLID_NOT) } // DEPRECATED old compat entity with confusing name, do not use

// non-solid brush entities:
spawnfunc(func_illusionary)       { G_MODEL_INIT      (this, SOLID_NOT) } // Q1 name (WARNING: MISPREDICTED)
spawnfunc(func_clientillusionary) { G_CLIENTMODEL_INIT(this, SOLID_NOT) } // brush entity

// solid brush entities
spawnfunc(func_wall)              { G_MODEL_INIT      (this, SOLID_BSP) } // Q1 name
spawnfunc(func_clientwall)        { G_CLIENTMODEL_INIT(this, SOLID_BSP) } // brush entity (WARNING: MISPREDICTED)
spawnfunc(func_static)            { G_MODEL_INIT      (this, SOLID_BSP) } // DEPRECATED old alias name from some other game
#elif defined(CSQC)
.float alpha;
.float scale;
.vector movedir;

void Ent_Wall_PreDraw(entity this)
{
	float alph = this.alpha;
	if (this.inactive)
	{
		alph = 0;
	}
	else
	{
		vector org = getpropertyvec(VF_ORIGIN);
		if(!checkpvs(org, this))
			alph = 0;
		else if(this.fade_start || this.fade_end) {
			vector offset = '0 0 0';
			offset_z = this.fade_vertical_offset;
			vector player_dist_math = org - this.origin - 0.5 * (this.mins + this.maxs) + offset;
			if (this.fade_end == this.fade_start)
			{
				if (vdist(player_dist_math, >=, this.fade_start))
					alph = 0;
				else
					alph = 1;
			}
			else
			{
				float player_dist = vlen(player_dist_math);
				alph = (this.alpha_min + this.alpha_max * bound(0,
							   (this.fade_end - player_dist)
							   / (this.fade_end - this.fade_start), 1)) / 100.0;
			}
		}
		else
		{
			alph = 1;
		}
	}
	this.alpha = alph;
	this.drawmask = (alph <= 0) ? 0 : MASK_NORMAL;
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
	strfree(this.bgmscript);
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
		this.skin = ReadByte();
	}

	if(f & 2)
	{
		this.origin = ReadVector();
		setorigin(this, this.origin);
	}

	if(f & 4)
	{
		if(f & 0x10)
			this.angles = ReadAngleVector();
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
			this.mins = ReadVector();
			this.maxs = ReadVector();
		}
		else
			this.mins = this.maxs = '0 0 0';
		setsize(this, this.mins, this.maxs);

		string s = ReadString();
		if(substring(s, 0, 1) == "<")
		{
			strcpy(this.bgmscript, substring(s, 1, -1));
			this.bgmscriptangular = 1;
		}
		else
		{
			strcpy(this.bgmscript, s);
			this.bgmscriptangular = 0;
		}
		if(this.bgmscript != "")
		{
			this.bgmscriptattack = ReadByte() / 64.0;
			this.bgmscriptdecay = ReadByte() / 64.0;
			this.bgmscriptsustain = ReadByte() / 255.0;
			this.bgmscriptrelease = ReadByte() / 64.0;
			this.movedir = ReadVector();
			this.lip = ReadByte() / 255.0;
		}
		this.fade_start = ReadShort();
		this.fade_end = ReadShort();
		this.alpha_max = ReadByte() / 255.0;
		this.alpha_min = ReadByte() / 255.0;
		this.inactive = ReadByte();
		this.fade_vertical_offset = ReadShort();
		BGMScript_InitEntity(this);
	}

	return = true;

	InterpolateOrigin_Note(this);

	this.saved = this.(fld);

	this.entremove = Ent_Wall_Remove;
	this.draw = Ent_Wall_Draw;
	if (isnew) IL_PUSH(g_drawables, this);
	setpredraw(this, Ent_Wall_PreDraw);
}
#endif
