#include "csqcmodel_hooks.qh"
#include "_all.qh"

#include "gibs.qh"
#include "player_skeleton.qh"

#include "weapons/projectile.qh"

#include "../common/animdecide.qh"
#include "../common/csqcmodel_settings.qh"
#include "../common/effects.qh"
#include "../common/teams.qh"
#include "../common/triggers/trigger/viewloc.qh"

#include "mutators/events.qh"

#include "../csqcmodellib/cl_model.qh"
#include "../csqcmodellib/cl_player.qh"
#include "../csqcmodellib/interpolate.qh"


.float death_time;
.int modelflags;

void CSQCModel_Hook_PreDraw(bool isplayer);

.bool isplayermodel;

// FEATURE: LOD
.int lodmodelindex0;
.int lodmodelindex1;
.int lodmodelindex2;
void CSQCPlayer_LOD_Apply(void)
{
	// LOD model loading
	if(self.lodmodelindex0 != self.modelindex)
	{
		string modelname = self.model;
		string s;

		vector mi = self.mins;
		vector ma = self.maxs;

		// set modelindex
		self.lodmodelindex0 = self.modelindex;
		self.lodmodelindex1 = self.modelindex;
		self.lodmodelindex2 = self.modelindex;

		// FIXME: this only supports 3-letter extensions
		s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod1", substring(modelname, -4, 4));
		if(fexists(s))
		{
			precache_model(s);
			setmodel(self, s);
			if(self.modelindex)
				self.lodmodelindex1 = self.modelindex;
		}

		s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod2", substring(modelname, -4, 4));
		if(fexists(s))
		{
			precache_model(s);
			setmodel(self, s);
			if(self.modelindex)
				self.lodmodelindex2 = self.modelindex;
		}

		setmodel(self, modelname); // make everything normal again
		setsize(self, mi, ma);
	}

	// apply LOD
	if(autocvar_cl_playerdetailreduction <= 0)
	{
		if(autocvar_cl_playerdetailreduction <= -2)
			self.modelindex = self.lodmodelindex2;
		else if(autocvar_cl_playerdetailreduction <= -1)
			self.modelindex = self.lodmodelindex1;
		else
			self.modelindex = self.lodmodelindex0;
	}
	else
	{
		float distance = vlen(self.origin - view_origin);
		float f = (distance * current_viewzoom + 100.0) * autocvar_cl_playerdetailreduction;
		f *= 1.0 / bound(0.01, view_quality, 1);
		if(f > autocvar_cl_loddistance2)
			self.modelindex = self.lodmodelindex2;
		else if(f > autocvar_cl_loddistance1)
			self.modelindex = self.lodmodelindex1;
		else
			self.modelindex = self.lodmodelindex0;
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
.vector old_glowmod;

void CSQCPlayer_ModelAppearance_PreUpdate(void)
{
	self.model = self.forceplayermodels_savemodel;
	self.modelindex = self.forceplayermodels_savemodelindex;
	self.skin = self.forceplayermodels_saveskin;
	self.colormap = self.forceplayermodels_savecolormap;
}
void CSQCPlayer_ModelAppearance_PostUpdate(void)
{
	self.forceplayermodels_savemodel = self.model;
	self.forceplayermodels_savemodelindex = self.modelindex;
	self.forceplayermodels_saveskin = self.skin;
	self.forceplayermodels_savecolormap = self.colormap;

	if(self.forceplayermodels_savemodel != self.forceplayermodels_isgoodmodel_mdl)
	{
		self.forceplayermodels_isgoodmodel = fexists(self.forceplayermodels_savemodel);
		self.forceplayermodels_isgoodmodel_mdl = self.forceplayermodels_savemodel;
		if(!self.forceplayermodels_isgoodmodel)
			LOG_INFOF("Warning: missing model %s has been used\n", self.forceplayermodels_savemodel);
	}
}
void CSQCPlayer_ModelAppearance_Apply(bool islocalplayer)
{
	// FORCEMODEL
	// which one is ALWAYS good?
	if (!forceplayermodels_goodmodel)
	{
		entity e;
		e = spawn();
		precache_model(cvar_defstring("_cl_playermodel"));
		setmodel(e, cvar_defstring("_cl_playermodel"));
		forceplayermodels_goodmodel = e.model;
		forceplayermodels_goodmodelindex = e.modelindex;
		remove(e);
	}

	// first, try finding it from the server
	if(self.forceplayermodels_savemodelindex && self.forceplayermodels_savemodel != "null")
	{
		if(islocalplayer)
		{
			if(!isdemo()) // this is mainly cheat protection; not needed for demos
			{
				// trust server's idea of "own player model"
				forceplayermodels_modelisgoodmodel = self.forceplayermodels_isgoodmodel;
				forceplayermodels_model = self.forceplayermodels_savemodel;
				forceplayermodels_modelindex = self.forceplayermodels_savemodelindex;
				forceplayermodels_skin = self.forceplayermodels_saveskin;
				forceplayermodels_attempted = 1;
			}
		}
	}

	// forcemodel finding
	if(!forceplayermodels_attempted)
	{
		forceplayermodels_attempted = 1;

		// only if this failed, find it out on our own
		entity e;
		e = spawn();
		setmodel(e, autocvar__cl_playermodel); // this is harmless, see below
		forceplayermodels_modelisgoodmodel = fexists(e.model);
		forceplayermodels_model = e.model;
		forceplayermodels_modelindex = e.modelindex;
		forceplayermodels_skin = autocvar__cl_playerskin;
		remove(e);
	}

	if(autocvar_cl_forcemyplayermodel != "" && autocvar_cl_forcemyplayermodel != forceplayermodels_mymodel)
	{
		entity e;
		e = spawn();
		setmodel(e, autocvar_cl_forcemyplayermodel); // this is harmless, see below
		forceplayermodels_myisgoodmodel = fexists(e.model);
		forceplayermodels_mymodel = e.model;
		forceplayermodels_mymodelindex = e.modelindex;
		remove(e);
	}

	// apply it
	bool isfriend;
	int cm;
	cm = self.forceplayermodels_savecolormap;
	cm = (cm >= 1024) ? cm : (stof(getplayerkeyvalue(cm - 1, "colors")) + 1024);

	if(teamplay)
		isfriend = (cm == 1024 + 17 * myteam);
	else
		isfriend = islocalplayer;

	if(autocvar_cl_forcemyplayermodel != "" && forceplayermodels_myisgoodmodel && isfriend)
	{
		self.model = forceplayermodels_mymodel;
		self.modelindex = forceplayermodels_mymodelindex;
		self.skin = autocvar_cl_forcemyplayerskin;
	}
	else if(autocvar_cl_forceplayermodels && forceplayermodels_modelisgoodmodel)
	{
		self.model = forceplayermodels_model;
		self.modelindex = forceplayermodels_modelindex;
		self.skin = forceplayermodels_skin;
	}
	else if(self.forceplayermodels_isgoodmodel)
	{
		self.model = self.forceplayermodels_savemodel;
		self.modelindex = self.forceplayermodels_savemodelindex;
		self.skin = self.forceplayermodels_saveskin;
	}
	else
	{
		self.model = forceplayermodels_goodmodel;
		self.modelindex = forceplayermodels_goodmodelindex;
		self.skin = self.forceplayermodels_saveskin;
	}

	// forceplayercolors too
	if(teamplay)
	{
		// own team's color is never forced
		int forcecolor_friend = 0;
		int forcecolor_enemy = 0;
		entity tm;

		if(autocvar_cl_forcemyplayercolors)
			forcecolor_friend = 1024 + autocvar_cl_forcemyplayercolors;
		if(autocvar_cl_forceplayercolors && team_count == 2)
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
				self.colormap = forcecolor_friend;
		}
		else
		{
			if(forcecolor_enemy)
				self.colormap = forcecolor_enemy;
		}
	}
	else
	{
		if(autocvar_cl_forcemyplayercolors && islocalplayer)
			self.colormap = 1024 + autocvar_cl_forcemyplayercolors;
		else if(autocvar_cl_forceplayercolors)
			self.colormap = player_localnum + 1;
	}

	// GLOWMOD AND DEATH FADING
	if(self.colormap > 0)
		self.glowmod = colormapPaletteColor(((self.colormap >= 1024) ? self.colormap : stof(getplayerkeyvalue(self.colormap - 1, "colors"))) & 0x0F, true) * 2;
	else
		self.glowmod = '1 1 1';

	if(autocvar_cl_deathglow > 0)
	{
		if(self.csqcmodel_isdead)
		{
			// Fade out to black now...
			if(self.old_glowmod == '0 0 0') { self.old_glowmod = self.glowmod; }
			self.colormap = 0;

			self.glowmod = self.old_glowmod * bound(0, 1 - (time - self.death_time) / autocvar_cl_deathglow, 1);
			self.glowmod_x = max(self.glowmod.x, 0.0001);
			self.glowmod_y = max(self.glowmod.y, 0.0001);
			self.glowmod_z = max(self.glowmod.z, 0.0001);
		}
		else if(self.old_glowmod != '0 0 0') { self.old_glowmod = '0 0 0'; }
	}

	//printf("CSQCPlayer_ModelAppearance_Apply(): state = %s, colormap = %f, glowmod = %s\n", (self.csqcmodel_isdead ? "DEAD" : "ALIVE"), self.colormap, vtos(self.glowmod));
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
void CSQCPlayer_FallbackFrame_PreUpdate(void)
{
	self.frame = self.csqcmodel_saveframe;
	self.frame2 = self.csqcmodel_saveframe2;
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	self.frame3 = self.csqcmodel_saveframe3;
	self.frame4 = self.csqcmodel_saveframe4;
#endif
}
void CSQCPlayer_FallbackFrame_PostUpdate(bool isnew)
{
	self.csqcmodel_saveframe = self.frame;
	self.csqcmodel_saveframe2 = self.frame2;
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	self.csqcmodel_saveframe3 = self.frame3;
	self.csqcmodel_saveframe4 = self.frame4;
#endif

	// hack for death animations: set their frametime to zero in case a
	// player "pops in"
	if(isnew)
	{
#define FIX_FRAMETIME(f,ft) do {																					\
		if(IS_DEAD_FRAME(self.f) && self.ft != 0 && self.death_time != 0)											\
			self.ft = self.death_time;																				\
} while(0)
		FIX_FRAMETIME(frame, frame1time);
		FIX_FRAMETIME(frame2, frame2time);
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
		FIX_FRAMETIME(frame3, frame3time);
		FIX_FRAMETIME(frame4, frame4time);
#endif
	}
	self.csqcmodel_isdead = IS_DEAD_FRAME(self.frame);
}
void CSQCPlayer_AnimDecide_PostUpdate(bool isnew)
{
	self.csqcmodel_isdead = !!(self.anim_state & (ANIMSTATE_DEAD1 | ANIMSTATE_DEAD2));
}
int CSQCPlayer_FallbackFrame(int f)
{
	if(frameduration(self.modelindex, f) > 0)
		return f; // goooooood
	if(frameduration(self.modelindex, 1) <= 0)
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
	LOG_INFOF("Frame %d missing in model %s, and we have no fallback - FAIL!\n", f, self.model);
	return f;
}
void CSQCPlayer_FallbackFrame_Apply(void)
{
	self.frame = CSQCPlayer_FallbackFrame(self.frame);
	self.frame2 = CSQCPlayer_FallbackFrame(self.frame2);
#ifdef CSQCMODEL_HAVE_TWO_FRAMES
	self.frame3 = CSQCPlayer_FallbackFrame(self.frame3);
	self.frame4 = CSQCPlayer_FallbackFrame(self.frame4);
#endif
}

// FEATURE: auto tag_index
.entity tag_entity;
.int tag_entity_lastmodelindex;
.int tag_index;
void CSQCModel_AutoTagIndex_Apply(void)
{
	if(self.tag_entity && wasfreed(self.tag_entity))
		self.tag_entity = world;

	if(self.viewloc && wasfreed(self.viewloc))
		self.viewloc = world;

	if(self.viewloc.entnum != self.tag_networkviewloc)
		self.viewloc = findfloat(world, entnum, self.tag_networkviewloc);

	MUTATOR_CALLHOOK(TagIndex_Update, self);

	if(self.tag_networkentity)
	{
		// we are ATTACHED!
		bool changed = 0;
		if(self.tag_entity.entnum != self.tag_networkentity)
		{
			self.tag_entity = findfloat(world, entnum, self.tag_networkentity);
			changed = 1;
		}

		// recursive predraw call to fix issues with forcemodels and LOD if bone indexes mismatch
		if(self.tag_entity.classname == "csqcmodel")
		{
			entity oldself = self;
			self = self.tag_entity;
			CSQCModel_Hook_PreDraw((self.entnum >= 1 && self.entnum <= maxclients));
			self = oldself;
		}

		if(self.tag_entity.modelindex != self.tag_entity_lastmodelindex)
		{
			self.tag_entity_lastmodelindex = self.tag_entity.modelindex;
			changed = 1;
		}
		if(changed)
		{
			if(self.tag_entity)
			{
				// the best part is: IT EXISTS
				if(substring(self.model, 0, 14) == "models/weapons")
				{
					if(substring(self.tag_entity.model, 0, 14) == "models/weapons")
					{
						self.tag_index = gettagindex(self.tag_entity, "weapon");
						if(!self.tag_index)
							self.tag_index = gettagindex(self.tag_entity, "tag_weapon");
						if(!self.tag_index)
						{
							// we need to prevent this from 'appening
							self.tag_entity = world;
							self.drawmask = 0;
							LOG_TRACE("h_ model lacks weapon attachment, but v_ model is attached to it\n");
						}
					}
					else if(self.tag_entity.isplayermodel)
					{
						skeleton_loadinfo(self.tag_entity);
						self.tag_index = self.tag_entity.bone_weapon;
					}
				}

				if(substring(self.tag_entity.model, 0, 14) == "models/weapons")
				{
					self.tag_index = gettagindex(self.tag_entity, "shot");
					if(!self.tag_index)
						self.tag_index = gettagindex(self.tag_entity, "tag_shot");
				}

				MUTATOR_CALLHOOK(TagIndex_Apply, self);
			}
			else
			{
				// damn, see you next frame
				self.drawmask = 0;
			}
		}
	}
}

// FEATURE: EF_NODRAW workalike
const int EF_BRIGHTFIELD	= 1;
const int EF_BRIGHTLIGHT 	= 4;
const int EF_DIMLIGHT 		= 8;
const int EF_DOUBLESIDED 	= 32768;
const int EF_NOSELFSHADOW 	= 65536;
const int EF_DYNAMICMODELLIGHT = 131072;
const int EF_RESTARTANIM_BIT = 1048576;
const int EF_TELEPORT_BIT = 2097152;
const int MF_ROCKET  =   1; // leave a trail
const int MF_GRENADE =   2; // leave a trail
const int MF_GIB     =   4; // leave a trail
const int MF_ROTATE  =   8; // rotate (bonus items)
const int MF_TRACER  =  16; // green split trail
const int MF_ZOMGIB  =  32; // small blood trail
const int MF_TRACER2 =  64; // orange split trail
const int MF_TRACER3 = 128; // purple trail
.int csqcmodel_effects;
.int csqcmodel_modelflags;
void CSQCModel_Effects_PreUpdate(void)
{
	self.effects = self.csqcmodel_effects;
	self.modelflags = self.csqcmodel_modelflags;
}
void Reset_ArcBeam(void);
void CSQCModel_Effects_PostUpdate(void)
{
	if (self == csqcplayer) {
		if (self.csqcmodel_teleported) {
			Reset_ArcBeam();
		}
	}
	self.csqcmodel_effects = self.effects;
	self.csqcmodel_modelflags = self.modelflags;
	self.effects = 0;
	self.modelflags = 0;
	if(self.csqcmodel_teleported)
		Projectile_ResetTrail(self.origin);
}
.int snd_looping;
void CSQCModel_Effects_Apply(void)
{
	int eff = self.csqcmodel_effects & ~CSQCMODEL_EF_RESPAWNGHOST;

	self.renderflags &= ~(RF_DEPTHHACK | RF_ADDITIVE | RF_FULLBRIGHT | EF_NOSHADOW | RF_USEAXIS);
	self.effects = 0;
	self.traileffect = 0;

	if(eff & EF_BRIGHTFIELD)
		self.traileffect = particleeffectnum(EFFECT_TR_NEXUIZPLASMA);
	// ignoring EF_MUZZLEFLASH
	if(eff & EF_BRIGHTLIGHT)
		adddynamiclight(self.origin, 400, '3 3 3');
	if(eff & EF_DIMLIGHT)
		adddynamiclight(self.origin, 200, '1.5 1.5 1.5');
	if((eff & EF_NODRAW) || (self.alpha < 0))
		self.drawmask = 0;
	if(eff & EF_ADDITIVE)
		self.renderflags |= RF_ADDITIVE;
	if(eff & EF_BLUE)
		adddynamiclight(self.origin, 200, '0.15 0.15 1.5');
	if(eff & EF_RED)
		adddynamiclight(self.origin, 200, '1.5 0.15 0.15');
	// ignoring EF_NOGUNBOB
	if(eff & EF_FULLBRIGHT)
		self.renderflags |= RF_FULLBRIGHT;
	if(eff & EF_FLAME)
		pointparticles(particleeffectnum(EFFECT_EF_FLAME), self.origin, '0 0 0', bound(0, frametime, 0.1));
	if(eff & EF_STARDUST)
		pointparticles(particleeffectnum(EFFECT_EF_STARDUST), self.origin, '0 0 0', bound(0, frametime, 0.1));
	if(eff & EF_NOSHADOW)
		self.renderflags |= RF_NOSHADOW;
	if(eff & EF_NODEPTHTEST)
		self.renderflags |= RF_DEPTHHACK;
	// ignoring EF_SELECTABLE
	if(eff & EF_DOUBLESIDED)
		self.effects |= EF_DOUBLESIDED;
	if(eff & EF_NOSELFSHADOW)
		self.effects |= EF_NOSELFSHADOW;
	if(eff & EF_DYNAMICMODELLIGHT)
		self.renderflags |= RF_DYNAMICMODELLIGHT;
	// ignoring EF_UNUSED18, EF_UNUSED19, EF_RESTARTANIM_BIT, EF_TELEPORT_BIT, EF_LOWPRECISION
	if(self.csqcmodel_modelflags & MF_ROCKET)
		self.traileffect = particleeffectnum(EFFECT_TR_ROCKET);
	if(self.csqcmodel_modelflags & MF_GRENADE)
		self.traileffect = particleeffectnum(EFFECT_TR_GRENADE);
	if(self.csqcmodel_modelflags & MF_GIB)
		self.traileffect = particleeffectnum(EFFECT_TR_BLOOD);
	if(self.csqcmodel_modelflags & MF_ROTATE)
	{
		self.renderflags |= RF_USEAXIS;
		makevectors(self.angles + '0 100 0' * fmod(time, 3.6));
	}
	if(self.csqcmodel_modelflags & MF_TRACER)
		self.traileffect = particleeffectnum(EFFECT_TR_WIZSPIKE);
	if(self.csqcmodel_modelflags & MF_ZOMGIB)
		self.traileffect = particleeffectnum(EFFECT_TR_SLIGHTBLOOD);
	if(self.csqcmodel_modelflags & MF_TRACER2)
		self.traileffect = particleeffectnum(EFFECT_TR_KNIGHTSPIKE);
	if(self.csqcmodel_modelflags & MF_TRACER3)
		self.traileffect = particleeffectnum(EFFECT_TR_VORESPIKE);

	if(self.drawmask)
		Projectile_DrawTrail(self.origin);
	else
		Projectile_ResetTrail(self.origin);

	if(self.csqcmodel_effects & CSQCMODEL_EF_RESPAWNGHOST)
		self.renderflags |= RF_ADDITIVE;
		// also special in CSQCPlayer_GlowMod_Apply

	if(self.csqcmodel_modelflags & MF_ROCKET)
	{
		if(!self.snd_looping)
		{
			sound(self, CH_TRIGGER_SINGLE, "misc/jetpack_fly.wav", VOL_BASE, autocvar_g_jetpack_attenuation);
			self.snd_looping = CH_TRIGGER_SINGLE;
		}
	}
	else
	{
		if(self.snd_looping)
		{
			sound(self, self.snd_looping, "misc/null.wav", VOL_BASE, autocvar_g_jetpack_attenuation);
			self.snd_looping = 0;
		}
	}
}

void CSQCPlayer_Precache()
{
	precache_sound("misc/jetpack_fly.wav");
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
void CSQCModel_Hook_PreDraw(bool isplayer)
{
	if(self.csqcmodel_predraw_run == framecount)
		return;
	self.csqcmodel_predraw_run = framecount;

	if(!self.modelindex || self.model == "null")
	{
		self.drawmask = 0;
		return;
	}
	else
		self.drawmask = MASK_NORMAL;

	if(self.isplayermodel) // this checks if it's a player MODEL!
	{
		CSQCPlayer_ModelAppearance_Apply(self.entnum == player_localnum + 1);
		CSQCPlayer_LOD_Apply();

		if(!isplayer)
		{
			skeleton_loadinfo(self);
			bool doblend = (self.bone_upperbody >= 0);
			CSQCPlayer_FallbackFrame_Apply();
			if(doblend)
			{
				skeleton_from_frames(self, self.csqcmodel_isdead);
			}
			else
			{
				free_skeleton_from_frames(self);
				// just in case, clear these (we're animating in frame and frame3)
				self.lerpfrac = 0;
				self.lerpfrac4 = 0;
			}
		}
		else
		{
			// we know that frame3 and frame4 fields, used by InterpolateAnimation, are left alone - but that is all we know!
			skeleton_loadinfo(self);
			bool doblend = (self.bone_upperbody >= 0);
			bool onground = 0;
			if(self == csqcplayer)
			{
				if(self.flags & FL_ONGROUND)
					onground = 1;
				self.anim_prev_pmove_flags = self.flags;
				if(self.flags & FL_DUCKED)
					animdecide_setstate(self, self.anim_state | ANIMSTATE_DUCK, false);
				else if(self.anim_state & ANIMSTATE_DUCK)
					animdecide_setstate(self, self.anim_state - ANIMSTATE_DUCK, false);
			}
			else
			{
				tracebox(self.origin + '0 0 1', self.mins, self.maxs, self.origin - '0 0 4', MOVE_NORMAL, self);
				if(trace_startsolid || trace_fraction < 1)
					onground = 1;
			}
			animdecide_load_if_needed(self);
			animdecide_setimplicitstate(self, onground);
			animdecide_setframes(self, doblend, anim_frame, anim_frame1time, anim_frame2, anim_frame2time);
			int sf = 0;
			if(self.anim_saveframe != self.anim_frame || self.anim_saveframe1time != self.anim_frame1time)
				sf |= CSQCMODEL_PROPERTY_FRAME;
			if(self.anim_saveframe2 != self.anim_frame2 || self.anim_saveframe2time != self.anim_frame2time)
				sf |= CSQCMODEL_PROPERTY_FRAME2;
			self.anim_saveframe = self.anim_frame;
			self.anim_saveframe1time = self.anim_frame1time;
			self.anim_saveframe2 = self.anim_frame2;
			self.anim_saveframe2time = self.anim_frame2time;
			// Note: we always consider lerpfrac "changed", as it uses fixed values every time anyway.
			// This ensures that .frame etc. are always written.
			CSQCModel_InterpolateAnimation_2To4_PreNote(sf | CSQCMODEL_PROPERTY_LERPFRAC);
			self.lerpfrac = (doblend ? 0.5 : 0);
			self.frame = self.anim_frame;
			self.frame1time = self.anim_frame1time;
			self.frame2 = self.anim_frame2;
			self.frame2time = self.anim_frame2time;
			CSQCModel_InterpolateAnimation_2To4_Note(sf | CSQCMODEL_PROPERTY_LERPFRAC, false);
			CSQCModel_InterpolateAnimation_2To4_Do();
			if(doblend)
			{
				skeleton_from_frames(self, self.csqcmodel_isdead);
			}
			else
			{
				free_skeleton_from_frames(self);
				// just in case, clear these (we're animating in frame and frame3)
				self.lerpfrac = 0;
				self.lerpfrac4 = 0;
			}
		}
	}

	CSQCModel_AutoTagIndex_Apply();

	CSQCModel_Effects_Apply();
}

void CSQCModel_Hook_PreUpdate(bool isnew, bool isplayer, bool islocalplayer)
{
	// interpolate v_angle
	self.iflags |= IFLAG_V_ANGLE_X;
	// revert to values from server
	CSQCModel_Effects_PreUpdate();
	if(self.isplayermodel)
	{
		if(!isplayer)
			CSQCPlayer_FallbackFrame_PreUpdate();
		CSQCPlayer_ModelAppearance_PreUpdate();
	}
}

void CSQCModel_Hook_PostUpdate(bool isnew, bool isplayer, bool islocalplayer)
{
	// is it a player model? (shared state)
	self.isplayermodel = (substring(self.model, 0, 14) == "models/player/" || substring(self.model, 0, 17) == "models/ok_player/" || (substring(self.model, 0, 16) == "models/monsters/" && (self.entnum >= 1 && self.entnum <= maxclients)));

	// save values set by server
	if(self.isplayermodel)
	{
		CSQCPlayer_ModelAppearance_PostUpdate();
		if(isplayer)
			CSQCPlayer_AnimDecide_PostUpdate(isnew);
		else
			CSQCPlayer_FallbackFrame_PostUpdate(isnew);
	}
	CSQCModel_Effects_PostUpdate();
}
