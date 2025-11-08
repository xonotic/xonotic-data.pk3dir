#include "csqcmodel_hooks.qh"

#include <client/mutators/_mod.qh>
#include <client/player_skeleton.qh>
#include <client/weapons/projectile.qh>
#include <common/animdecide.qh>
#include <common/effects/all.inc>
#include <common/effects/all.qh>
#include <common/ent_cs.qh>
#include <common/gametypes/_mod.qh>
#include <common/mapinfo.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <common/physics/player.qh>
#include <common/viewloc.qh>
#include <lib/csqcmodel/cl_model.qh>
#include <lib/csqcmodel/cl_player.qh>
#include <lib/csqcmodel/interpolate.qh>

.int modelflags;

// FEATURE: LOD
.int lodmodelindex0;
.int lodmodelindex1;
.int lodmodelindex2;
.float loddistance1;
.float loddistance2;
void CSQCModel_LOD_Apply(entity this, bool isplayer)
{
	int detailreduction = ((isplayer) ? autocvar_cl_playerdetailreduction : autocvar_cl_modeldetailreduction);

	// LOD model loading
	if(this.lodmodelindex0 != this.modelindex && this.lodmodelindex1 != this.modelindex && this.lodmodelindex2 != this.modelindex)
	{
		string modelname = this.model;
		string s;

		vector mi = this.mins;
		vector ma = this.maxs;

		// set modelindex
		this.lodmodelindex0 = this.modelindex;
		this.lodmodelindex1 = this.modelindex;
		this.lodmodelindex2 = this.modelindex;

		// FIXME: this only supports 3-letter extensions
		s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod1", substring(modelname, -4, 4));
		if(fexists(s))
		{
			precache_model(s);
			_setmodel(this, s);
			if(this.modelindex)
				this.lodmodelindex2 = this.lodmodelindex1 = this.modelindex;
		}

		s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod2", substring(modelname, -4, 4));
		if(fexists(s))
		{
			precache_model(s);
			_setmodel(this, s);
			if(this.modelindex)
				this.lodmodelindex2 = this.modelindex;
		}

		_setmodel(this, modelname); // make everything normal again
		setsize(this, mi, ma);
	}

	// apply LOD
	if(detailreduction <= 0)
	{
		if(detailreduction <= -2)
			this.modelindex = this.lodmodelindex2;
		else if(detailreduction <= -1)
			this.modelindex = this.lodmodelindex1;
		else
			this.modelindex = this.lodmodelindex0;
	}
	else
	{
		float distance = vlen(((isplayer) ? this.origin : NearestPointOnBox(this, view_origin)) - view_origin); // TODO: perhaps it should just use NearestPointOnBox all the time, player hitbox can potentially be huge
		float dist1 = (this.loddistance1 > 0) ? this.loddistance1 : autocvar_cl_loddistance1;
		float dist2 = (this.loddistance2 > 0) ? this.loddistance2 : autocvar_cl_loddistance2;
		float f = (distance * current_viewzoom + 100.0) * detailreduction;
		f *= 1.0 / bound(0.01, view_quality, 1);
		if(f > dist2)
			this.modelindex = this.lodmodelindex2;
		else if(f > dist1)
			this.modelindex = this.lodmodelindex1;
		else
			this.modelindex = this.lodmodelindex0;
	}
}

// FEATURE: forcemodel and model color selection (MUST be called BEFORE LOD!)
string forceplayermodels_model;
bool forceplayermodels_modelisgoodmodel;
int forceplayermodels_modelindex;
int forceplayermodels_skin;

string forceplayermodels_mymodel;
bool forceplayermodels_myisgoodmodel;
int forceplayermodels_mymodelindex;

bool forceplayermodels_attempted;

.string forceplayermodels_savemodel;
.int forceplayermodels_savemodelindex;
.int forceplayermodels_saveskin;
.int forceplayermodels_savecolormap;

.string forceplayermodels_isgoodmodel_mdl;
.bool forceplayermodels_isgoodmodel;

string forceplayermodels_goodmodel;
int forceplayermodels_goodmodelindex;

.vector glowmod;

void CSQCPlayer_ModelAppearance_PreUpdate(entity this)
{
	this.model = this.forceplayermodels_savemodel;
	this.modelindex = this.forceplayermodels_savemodelindex;
	this.skin = this.forceplayermodels_saveskin;
	this.colormap = this.forceplayermodels_savecolormap;
}
void CSQCPlayer_ModelAppearance_PostUpdate(entity this)
{
	this.forceplayermodels_savemodel = this.model;
	this.forceplayermodels_savemodelindex = this.modelindex;
	this.forceplayermodels_saveskin = this.skin;
	this.forceplayermodels_savecolormap = this.colormap;

	if(this.forceplayermodels_savemodel != this.forceplayermodels_isgoodmodel_mdl)
	{
		this.forceplayermodels_isgoodmodel = fexists(this.forceplayermodels_savemodel);
		this.forceplayermodels_isgoodmodel_mdl = this.forceplayermodels_savemodel;
		if(!this.forceplayermodels_isgoodmodel)
			LOG_INFOF("Warning: missing model %s has been used", this.forceplayermodels_savemodel);
	}
}
void CSQCPlayer_ModelAppearance_Apply(entity this, bool islocalplayer)
{
	int cm = this.forceplayermodels_savecolormap;
	cm = (cm >= 1024) ? cm : (entcs_GetClientColors(cm - 1) + 1024);

	if(MUTATOR_CALLHOOK(ForcePlayermodels_Skip, this, islocalplayer))
		goto skipforcemodels;

	// FORCEMODEL
	// which one is ALWAYS good?
	if (!forceplayermodels_goodmodel)
	{
		entity e = spawn();
		precache_model(cvar_defstring("_cl_playermodel"));
		_setmodel(e, cvar_defstring("_cl_playermodel"));
		forceplayermodels_goodmodel = e.model;
		forceplayermodels_goodmodelindex = e.modelindex;
		delete(e);
	}

	// first, try finding it from the server
	if(this.forceplayermodels_savemodelindex && this.forceplayermodels_savemodel != "null")
	{
		if(islocalplayer)
		{
			if(!isdemo()) // this is mainly cheat protection; not needed for demos
			{
				// trust server's idea of "own player model"
				forceplayermodels_modelisgoodmodel = this.forceplayermodels_isgoodmodel;
				forceplayermodels_model = this.forceplayermodels_savemodel;
				forceplayermodels_modelindex = this.forceplayermodels_savemodelindex;
				forceplayermodels_skin = this.forceplayermodels_saveskin;
				forceplayermodels_attempted = 1;
			}
		}
	}

	// forcemodel finding
	if(!forceplayermodels_attempted)
	{
		forceplayermodels_attempted = 1;

		// only if this failed, find it out on our own
		entity e = spawn();
		precache_model(autocvar__cl_playermodel);
		_setmodel(e, autocvar__cl_playermodel); // this is harmless, see below
		forceplayermodels_modelisgoodmodel = fexists(e.model);
		forceplayermodels_model = e.model;
		forceplayermodels_modelindex = e.modelindex;
		forceplayermodels_skin = autocvar__cl_playerskin;
		delete(e);
	}

	if(autocvar_cl_forcemyplayermodel != "" && autocvar_cl_forcemyplayermodel != forceplayermodels_mymodel)
	{
		entity e = spawn();
		_setmodel(e, autocvar_cl_forcemyplayermodel); // this is harmless, see below
		forceplayermodels_myisgoodmodel = fexists(e.model);
		forceplayermodels_mymodel = e.model;
		forceplayermodels_mymodelindex = e.modelindex;
		delete(e);
	}

	// apply it
	bool isfriend;

	if(teamplay)
		isfriend = (cm == 1024 + 17 * myteam);
	else
		isfriend = islocalplayer;

	if(autocvar_cl_forcemyplayermodel != "" && forceplayermodels_myisgoodmodel && isfriend)
	{
		this.model = forceplayermodels_mymodel;
		this.modelindex = forceplayermodels_mymodelindex;
		this.skin = autocvar_cl_forcemyplayerskin;
	}
	else if(autocvar_cl_forceplayermodels && forceplayermodels_modelisgoodmodel)
	{
		this.model = forceplayermodels_model;
		this.modelindex = forceplayermodels_modelindex;
		this.skin = forceplayermodels_skin;
	}
	else if(this.forceplayermodels_isgoodmodel)
	{
		this.model = this.forceplayermodels_savemodel;
		this.modelindex = this.forceplayermodels_savemodelindex;
		this.skin = this.forceplayermodels_saveskin;
	}
	else
	{
		this.model = forceplayermodels_goodmodel;
		this.modelindex = forceplayermodels_goodmodelindex;
		this.skin = this.forceplayermodels_saveskin;
	}

	LABEL(skipforcemodels)

	if(MUTATOR_CALLHOOK(ForcePlayercolors_Skip, this, islocalplayer))
		goto skipforcecolors;

	bool forceplayercolors_enabled = false;
	#define fpc autocvar_cl_forceplayercolors
	if (gametype.m_1v1)
	{
		if ((myteam != NUM_SPECTATOR) && (fpc == 1 || fpc == 2 || fpc == 3 || fpc == 5))
			forceplayercolors_enabled = true;
	}
	else if (teamplay)
	{
		if ((team_count == 2) && (myteam != NUM_SPECTATOR) && (fpc == 2 || fpc == 4 || fpc == 5))
			forceplayercolors_enabled = true;
	}
	else
	{
		if (fpc == 1 || fpc == 2)
			forceplayercolors_enabled = true;
	}

	// forceplayercolors too
	if(teamplay)
	{
		// own team's color is never forced
		int forcecolor_friend = 0, forcecolor_enemy = 0;
		entity tm;

		if(autocvar_cl_forcemyplayercolors)
			forcecolor_friend = 1024 + autocvar_cl_forcemyplayercolors;

		if(forceplayercolors_enabled)
			forcecolor_enemy = 1024 + autocvar__cl_color;

		if(forcecolor_enemy && !forcecolor_friend)
		{
			// only enemy color is forced?
			// verify it is not equal to the friend color
			if(forcecolor_enemy == 1024 + 17 * myteam)
				forcecolor_enemy = 0;
		}

		if(forcecolor_friend && !forcecolor_enemy)
		{
			// only friend color is forced?
			// verify it is not equal to the enemy color
			for(tm = teams.sort_next; tm; tm = tm.sort_next)
				// note: we even compare against our own team.
				// if we rejected because we matched our OWN team color,
				// this is not bad; we then simply keep our color as is
				// anyway.
				if(forcecolor_friend == 1024 + 17 * tm.team)
					forcecolor_friend = 0;
		}

		if(cm == 1024 + 17 * myteam)
		{
			if(forcecolor_friend)
				this.colormap = forcecolor_friend;
		}
		else
		{
			if(forcecolor_enemy)
				this.colormap = forcecolor_enemy;
		}
	}
	else // if(!teamplay)
	{
		if(autocvar_cl_forcemyplayercolors && islocalplayer)
			this.colormap = 1024 + autocvar_cl_forcemyplayercolors;
		else if (autocvar_cl_forceuniqueplayercolors && !islocalplayer && !gametype.m_1v1)
		{
			// Assign each enemy an unique color combination
			// pick colors from 0 to 14 since 15 is the rainbow color
			// pl01 0 1, pl02 1 2, ..., pl14 13 14, pl15 14 0
			// pl16 0 2, pl17 1 3, ..., pl29 13  0, pl30 14 1
			int num;
			if (this.isplayermodel & ISPLAYER_CLIENT)
				num = this.entnum - 1;
			else
				num = this.sv_entnum - 1;
			int c1 = num % 15;
			int q = floor(num / 15);
			int c2 = (c1 + 1 + q) % 15;
			this.colormap = 1024 + (c1 << 4) + c2;
		}
		else if(forceplayercolors_enabled)
			this.colormap = player_localnum + 1;
	}

	LABEL(skipforcecolors)

	if((this.csqcmodel_effects & CSQCMODEL_EF_RESPAWNGHOST) && !autocvar_cl_respawn_ghosts_keepcolors)
	{
		this.glowmod = '0 0 0';
		this.colormap = 0;
		return;
	}

	// GLOWMOD AND DEATH FADING
	if(this.colormap > 0)
		this.glowmod = colormapPaletteColor(((this.colormap >= 1024) ? this.colormap : entcs_GetClientColors(this.colormap - 1)) & 0x0F, true);
	else
		this.glowmod = '1 1 1';

	if(autocvar_cl_deathglow > 0)
	{
		if(this.csqcmodel_isdead)
		{
			float min_factor = bound(0, autocvar_cl_deathglow_min, 1);
			if(this.colormap > 0)
				min_factor /= 2;
			float glow_fade = bound(0, 1 - (time - this.death_time) / autocvar_cl_deathglow, 1);
			this.glowmod *= (min_factor + glow_fade * (1 - min_factor));
			if (this.glowmod == '0 0 0')
				this.glowmod.x = 0.000001;
		}
	}

	// don't let the engine increase player's glowmod
	if (autocvar_r_hdr_glowintensity > 1)
		this.glowmod /= autocvar_r_hdr_glowintensity;

	//printf("CSQCPlayer_ModelAppearance_Apply(): state = %s, colormap = %f, glowmod = %s\n", (this.csqcmodel_isdead ? "DEAD" : "ALIVE"), this.colormap, vtos(this.glowmod));
}

// FEATURE: fallback frames
.int csqcmodel_saveframe;
.int csqcmodel_saveframe2;
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
.int csqcmodel_saveframe3;
.int csqcmodel_saveframe4;
#endif
.int csqcmodel_framecount;

#define IS_DEAD_FRAME(f) ((f) == 0 || (f) == 1)
void CSQCPlayer_FallbackFrame_PreUpdate(entity this)
{
	this.frame = this.csqcmodel_saveframe;
	this.frame2 = this.csqcmodel_saveframe2;
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	this.frame3 = this.csqcmodel_saveframe3;
	this.frame4 = this.csqcmodel_saveframe4;
#endif
}
void CSQCPlayer_FallbackFrame_PostUpdate(entity this, bool isnew)
{
	this.csqcmodel_saveframe = this.frame;
	this.csqcmodel_saveframe2 = this.frame2;
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	this.csqcmodel_saveframe3 = this.frame3;
	this.csqcmodel_saveframe4 = this.frame4;
#endif

	// hack for death animations: set their frametime to zero in case a
	// player "pops in"
	if(isnew)
	{
#define FIX_FRAMETIME(f,ft) MACRO_BEGIN \
		if(IS_DEAD_FRAME(this.f) && this.ft != 0 && this.death_time != 0) \
			this.ft = this.death_time; \
MACRO_END
		FIX_FRAMETIME(frame, frame1time);
		FIX_FRAMETIME(frame2, frame2time);
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
		FIX_FRAMETIME(frame3, frame3time);
		FIX_FRAMETIME(frame4, frame4time);
#endif
	}
	this.csqcmodel_isdead = IS_DEAD_FRAME(this.frame);
}
void CSQCPlayer_AnimDecide_PostUpdate(entity this, bool isnew)
{
	this.csqcmodel_isdead = boolean(this.anim_state & (ANIMSTATE_DEAD1 | ANIMSTATE_DEAD2));
}
int CSQCPlayer_FallbackFrame(entity this, int f)
{
	TC(int, f);
	if(frameduration(this.modelindex, f) > 0)
		return f; // goooooood
	if(frameduration(this.modelindex, 1) <= 0)
		return f; // this is a static model. We can't fix it if we wanted to
	switch(f)
	{
		case 23: return 11; // anim_melee -> anim_shoot
		case 24: return 4; // anim_duckwalkbackwards -> anim_duckwalk
		case 25: return 4; // anim_duckwalkstrafeleft -> anim_duckwalk
		case 26: return 4; // anim_duckwalkstraferight -> anim_duckwalk
		case 27: return 4; // anim_duckwalkforwardright -> anim_duckwalk
		case 28: return 4; // anim_duckwalkforwardleft -> anim_duckwalk
		case 29: return 4; // anim_duckwalkbackright -> anim_duckwalk
		case 30: return 4; // anim_duckwalkbackleft -> anim_duckwalk
	}
	LOG_DEBUGF("Frame %d missing in model %s, and we have no fallback - FAIL!", f, this.model);
	return f;
}
void CSQCPlayer_FallbackFrame_Apply(entity this)
{
	this.frame = CSQCPlayer_FallbackFrame(this, this.frame);
	this.frame2 = CSQCPlayer_FallbackFrame(this, this.frame2);
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	this.frame3 = CSQCPlayer_FallbackFrame(this, this.frame3);
	this.frame4 = CSQCPlayer_FallbackFrame(this, this.frame4);
#endif
}

// FEATURE: auto tag_index
.entity tag_entity;
.int tag_entity_lastmodelindex;
.int tag_index;
void CSQCModel_AutoTagIndex_Apply(entity this)
{
	if(this.tag_entity && wasfreed(this.tag_entity))
		this.tag_entity = NULL;

	MUTATOR_CALLHOOK(TagIndex_Update, this);

	if(this.tag_networkentity)
	{
		// we are ATTACHED!
		bool changed = 0;
		if(this.tag_entity.entnum != this.tag_networkentity)
		{
			this.tag_entity = findfloat(NULL, entnum, this.tag_networkentity);
			changed = 1;
		}

		// recursive predraw call to fix issues with forcemodels and LOD if bone indexes mismatch
		if(this.tag_entity.classname == "ENT_CLIENT_MODEL")
		{
			CSQCModel_Hook_PreDraw(this.tag_entity, (this.tag_entity.isplayermodel & ISPLAYER_CLIENT));
		}

		if(this.tag_entity.modelindex != this.tag_entity_lastmodelindex)
		{
			this.tag_entity_lastmodelindex = this.tag_entity.modelindex;
			changed = 1;
		}
		if(changed)
		{
			if(this.tag_entity)
			{
				// the best part is: IT EXISTS
				if(substring(this.model, 0, 14) == "models/weapons")
				{
					if(substring(this.tag_entity.model, 0, 14) == "models/weapons")
					{
						this.tag_index = gettagindex(this.tag_entity, "weapon");
						if(!this.tag_index)
							this.tag_index = gettagindex(this.tag_entity, "tag_weapon");
						if(!this.tag_index)
						{
							// we need to prevent this from 'appening
							this.tag_entity = NULL;
							this.drawmask = 0;
							LOG_TRACE("h_ model lacks weapon attachment, but v_ model is attached to it");
						}
					}
					else if((this.tag_entity.isplayermodel & ISPLAYER_MODEL))
					{
						skeleton_loadinfo(this.tag_entity);
						this.tag_index = this.tag_entity.bone_weapon;
					}
				}

				if(substring(this.tag_entity.model, 0, 14) == "models/weapons")
				{
					this.tag_index = gettagindex(this.tag_entity, "shot");
					if(!this.tag_index)
						this.tag_index = gettagindex(this.tag_entity, "tag_shot");
				}

				MUTATOR_CALLHOOK(TagIndex_Apply, this);
			}
			else
			{
				// damn, see you next frame
				this.drawmask = 0;
			}
		}
	}
}

void CSQCModel_Effects_PreUpdate(entity this)
{
	this.effects = this.csqcmodel_effects;
	this.modelflags = this.csqcmodel_modelflags;
	this.traileffect = this.csqcmodel_traileffect;
}
void Reset_ArcBeam();
void CSQCModel_Effects_PostUpdate(entity this)
{
	if (this == csqcplayer) {
		if (this.csqcmodel_teleported) {
			Reset_ArcBeam();
		}
	}
	this.csqcmodel_effects = this.effects;
	this.csqcmodel_modelflags = this.modelflags;
	this.csqcmodel_traileffect = this.traileffect;
	this.effects = 0;
	this.modelflags = 0;
	if(this.csqcmodel_teleported)
		Projectile_ResetTrail(this, this.origin);
}
.int snd_looping;
void CSQCModel_Effects_Apply(entity this)
{
	int eff = this.csqcmodel_effects & ~CSQCMODEL_EF_RESPAWNGHOST;
	int tref = this.csqcmodel_traileffect;

	this.renderflags &= ~(RF_DEPTHHACK | RF_ADDITIVE | RF_FULLBRIGHT | EF_NOSHADOW | RF_USEAXIS);
	this.effects = 0;
	this.traileffect = 0;

	if(eff & EF_BRIGHTFIELD)
		tref = EFFECT_TR_NEXUIZPLASMA.m_id;
	// ignoring EF_MUZZLEFLASH
	if(eff & EF_BRIGHTLIGHT)
		adddynamiclight(this.origin, 400, '3 3 3');
	if(eff & EF_DIMLIGHT)
		adddynamiclight(this.origin, 200, '1.5 1.5 1.5');
	if((eff & EF_NODRAW) || (this.alpha < 0))
		this.drawmask = 0;
	if(eff & EF_ADDITIVE)
		this.renderflags |= RF_ADDITIVE;
		if(eff & EF_BLUE)
			adddynamiclight(this.origin, 200, '0.15 0.15 1.5');
		if(eff & EF_RED)
			adddynamiclight(this.origin, 200, '1.5 0.15 0.15');
	// ignoring EF_NOGUNBOB
	if(eff & EF_FULLBRIGHT)
		this.renderflags |= RF_FULLBRIGHT;
	if(eff & EF_FLAME)
	{
		// XONRELEASE TODO: xonotic-v0.9.0 after release remove the ef_shock_num check
		// NOTE here we check if EF_SHOCK exists because it was added together with the change to EF_FLAME
		int ef_shock_num = particleeffectnum(EFFECT_EF_SHOCK);
		if (ef_shock_num >= 0) // in the old version of EF_FLAME the light was spawned by boxparticles
			adddynamiclight2(this.origin + '0 0 10', 200, '1 0.35 0', 6, "", PFLAGS_FULLDYNAMIC); // no PFLAGS_CORONA, it looks bad
		int ef_flame_num = particleeffectnum(EFFECT_EF_FLAME);
		boxparticles(ef_flame_num, this, this.absmin, this.absmax, this.velocity, this.velocity, bound(0, frametime, 0.1), 0);
		//pointparticles(EFFECT_EF_FLAME, this.origin, '0 0 0', bound(0, frametime, 0.1));
	}
	if(eff & EF_SHOCK)
	{
		// XONRELEASE TODO: xonotic-v0.9.0 after release remove the ef_shock_num check
		int ef_shock_num = particleeffectnum(EFFECT_EF_SHOCK);
		if (ef_shock_num >= 0) // in ARC_LIGHTNING the light is spawned by boxparticles
			adddynamiclight2(this.origin, 50, '3.1 4.4 10', 10, "", PFLAGS_FULLDYNAMIC); // no PFLAGS_CORONA, it looks bad
		else
			ef_shock_num = particleeffectnum(EFFECT_ARC_LIGHTNING);
		boxparticles(ef_shock_num, this, this.absmin, this.absmax, '0 0 0', '0 0 0', bound(0, frametime, 0.1), 0);
		//pointparticles(EFFECT_ARC_LIGHTNING, this.origin, '0 0 0', bound(0, frametime, 0.1));
	}
	if(eff & EF_STARDUST)
	{
		boxparticles(particleeffectnum(EFFECT_EF_STARDUST), this, this.absmin, this.absmax, this.velocity, this.velocity, bound(0, frametime, 0.1), 0);
		//pointparticles(EFFECT_EF_STARDUST, this.origin, '0 0 0', bound(0, frametime, 0.1));
	}
	if(eff & EF_NOSHADOW)
		this.renderflags |= RF_NOSHADOW;
	if(eff & EF_NODEPTHTEST)
		this.renderflags |= RF_DEPTHHACK;
	// ignoring EF_SELECTABLE
	if(eff & EF_DOUBLESIDED)
		this.effects |= EF_DOUBLESIDED;
	if(eff & EF_NOSELFSHADOW)
		this.effects |= EF_NOSELFSHADOW;
	if(eff & EF_DYNAMICMODELLIGHT)
		this.renderflags |= RF_DYNAMICMODELLIGHT;
	// ignoring EF_UNUSED18, EF_UNUSED19, EF_RESTARTANIM_BIT, EF_TELEPORT_BIT, EF_LOWPRECISION
	if(this.csqcmodel_modelflags & MF_ROCKET)
		tref = EFFECT_TR_ROCKET.m_id;
	if(this.csqcmodel_modelflags & MF_GRENADE)
		tref = EFFECT_TR_GRENADE.m_id;
	if(this.csqcmodel_modelflags & MF_GIB)
		tref = EFFECT_TR_BLOOD.m_id;
	if(this.csqcmodel_modelflags & MF_ROTATE)
	{
		// This will be hard to replace with MAKE_VECTORS because it's called as part of the predraw function
		// as documented in csprogs.h in the engine. The globals can then be read in many places in the engine.
		// However MF_ROTATE is currently only used in one place - might be possible to get rid of it entirely.
		this.renderflags |= RF_USEAXIS;
		makevectors(this.angles + '0 100 0' * fmod(time, 3.6));
	}
	if(this.csqcmodel_modelflags & MF_TRACER)
		tref = EFFECT_TR_WIZSPIKE.m_id;
	if(this.csqcmodel_modelflags & MF_ZOMGIB)
		tref = EFFECT_TR_SLIGHTBLOOD.m_id;
	if(this.csqcmodel_modelflags & MF_TRACER2)
		tref = EFFECT_TR_KNIGHTSPIKE.m_id;
	if(this.csqcmodel_modelflags & MF_TRACER3)
		tref = EFFECT_TR_VORESPIKE.m_id;

	this.traileffect = tref;

	if(this.drawmask)
		Projectile_DrawTrail(this, this.origin);
	else
		Projectile_ResetTrail(this, this.origin);

	if(this.csqcmodel_effects & CSQCMODEL_EF_RESPAWNGHOST)
		this.renderflags |= RF_ADDITIVE;
		// also special in CSQCPlayer_GlowMod_Apply

	if(this.csqcmodel_modelflags & MF_ROCKET)
	{
		if(!this.snd_looping)
		{
			sound(this, CH_TRIGGER_SINGLE, SND_JETPACK_FLY, VOL_BASE, autocvar_cl_jetpack_attenuation);
			this.snd_looping = CH_TRIGGER_SINGLE;
		}
	}
	else
	{
		if(this.snd_looping)
		{
			sound(this, this.snd_looping, SND_Null, VOL_BASE, autocvar_cl_jetpack_attenuation);
			this.snd_looping = 0;
		}
	}
}

// general functions
.int csqcmodel_predraw_run;
.int anim_frame;
.int anim_frame1time;
.int anim_frame2;
.int anim_frame2time;
.int anim_saveframe;
.int anim_saveframe1time;
.int anim_saveframe2;
.int anim_saveframe2time;
.int anim_prev_pmove_flags;
void CSQCModel_Hook_PreDraw(entity this, bool isplayer)
{
	if(this.csqcmodel_predraw_run == framecount)
		return;
	this.csqcmodel_predraw_run = framecount;

	if(!this.modelindex || this.model == "null")
	{
		this.drawmask = 0;
		if(this.snd_looping > 0)
		{
			sound(this, this.snd_looping, SND_Null, VOL_BASE, autocvar_cl_jetpack_attenuation);
			this.snd_looping = 0;
		}
		return;
	}
	else
		this.drawmask = MASK_NORMAL;

	if((this.isplayermodel & ISPLAYER_MODEL) && this.drawmask) // this checks if it's a player MODEL!
	{
		CSQCPlayer_ModelAppearance_Apply(this, (this.isplayermodel & ISPLAYER_LOCAL));
		CSQCModel_LOD_Apply(this, true);

		if(!isplayer)
		{
			skeleton_loadinfo(this);
			bool doblend = (this.bone_upperbody >= 0);
			CSQCPlayer_FallbackFrame_Apply(this);
			if(doblend)
			{
				skeleton_from_frames(this, this.csqcmodel_isdead);
			}
			else
			{
				free_skeleton_from_frames(this);
				// just in case, clear these (we're animating in frame and frame3)
				this.lerpfrac = 0;
				this.lerpfrac4 = 0;
			}
		}
		else
		{
			// we know that frame3 and frame4 fields, used by InterpolateAnimation, are left alone - but that is all we know!
			skeleton_loadinfo(this);
			bool doblend = (this.bone_upperbody >= 0);
			bool onground = 0;
			if(this == csqcplayer)
			{
				if(IS_ONGROUND(this))
					onground = 1;
				this.anim_prev_pmove_flags = this.flags;
				if(this.flags & FL_DUCKED)
					animdecide_setstate(this, this.anim_state | ANIMSTATE_DUCK, false);
				else if(this.anim_state & ANIMSTATE_DUCK)
					animdecide_setstate(this, this.anim_state - ANIMSTATE_DUCK, false);
			}
			else
			{
				tracebox(this.origin + '0 0 1', this.mins, this.maxs, this.origin - '0 0 4', MOVE_NORMAL, this);
				if(trace_startsolid || trace_fraction < 1)
					onground = 1;
				// predicted clients handle smoothing in the prediction code
				this.origin = CSQCModel_ApplyStairSmoothing(this, onground, this.origin);
			}
			animdecide_load_if_needed(this);
			animdecide_setimplicitstate(this, onground);
			animdecide_setframes(this, doblend, anim_frame, anim_frame1time, anim_frame2, anim_frame2time);
			int sf = 0;
			if(this.anim_saveframe != this.anim_frame || this.anim_saveframe1time != this.anim_frame1time)
				sf |= CSQCMODEL_PROPERTY_FRAME;
			if(this.anim_saveframe2 != this.anim_frame2 || this.anim_saveframe2time != this.anim_frame2time)
				sf |= CSQCMODEL_PROPERTY_FRAME2;
			this.anim_saveframe = this.anim_frame;
			this.anim_saveframe1time = this.anim_frame1time;
			this.anim_saveframe2 = this.anim_frame2;
			this.anim_saveframe2time = this.anim_frame2time;
			// Note: we always consider lerpfrac "changed", as it uses fixed values every time anyway.
			// This ensures that .frame etc. are always written.
			CSQCModel_InterpolateAnimation_2To4_PreNote(this, sf | CSQCMODEL_PROPERTY_LERPFRAC);
			this.lerpfrac = (doblend ? 0.5 : 0);
			this.frame = this.anim_frame;
			this.frame1time = this.anim_frame1time;
			this.frame2 = this.anim_frame2;
			this.frame2time = this.anim_frame2time;
			CSQCModel_InterpolateAnimation_2To4_Note(this, sf | CSQCMODEL_PROPERTY_LERPFRAC, false);
			CSQCModel_InterpolateAnimation_2To4_Do(this);
			if(doblend)
			{
				skeleton_from_frames(this, this.csqcmodel_isdead);
			}
			else
			{
				free_skeleton_from_frames(this);
				// just in case, clear these (we're animating in frame and frame3)
				this.lerpfrac = 0;
				this.lerpfrac4 = 0;
			}
		}
	}
	else
		CSQCModel_LOD_Apply(this, false);

	CSQCModel_AutoTagIndex_Apply(this);

	CSQCModel_Effects_Apply(this);
}

void CSQCModel_Hook_PreUpdate(entity this, bool isnew, bool isplayer, bool islocalplayer)
{
	// interpolate v_angle
	this.iflags |= IFLAG_V_ANGLE_X;
	// revert to values from server
	CSQCModel_Effects_PreUpdate(this);
	if((this.isplayermodel & ISPLAYER_MODEL))
	{
		if(!isplayer)
			CSQCPlayer_FallbackFrame_PreUpdate(this);
		CSQCPlayer_ModelAppearance_PreUpdate(this);
	}
}

void CSQCModel_Hook_PostUpdate(entity this, bool isnew, bool isplayer, bool islocalplayer)
{
	// is it a player model? (shared state)
	bool is_playermodel = (substring(this.model, 0, 14) == "models/player/" || substring(this.model, 0, 17) == "models/ok_player/" || 
							(substring(this.model, 0, 16) == "models/monsters/" && (this.isplayermodel & BIT(1))));
	this.isplayermodel = BITSET(this.isplayermodel, ISPLAYER_MODEL, is_playermodel);
	this.csqcmodel_isdead = false; // workaround for dead players who become a spectator

	// save values set by server
	if((this.isplayermodel & ISPLAYER_MODEL))
	{
		CSQCPlayer_ModelAppearance_PostUpdate(this);
		if(isplayer)
			CSQCPlayer_AnimDecide_PostUpdate(this, isnew);
		else
			CSQCPlayer_FallbackFrame_PostUpdate(this, isnew);
	}
	CSQCModel_Effects_PostUpdate(this);
}
