void CSQCModel_Hook_PreDraw();

.float isplayermodel;

// FEATURE: LOD
.float lodmodelindex0;
.float lodmodelindex1;
.float lodmodelindex2;
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

// FEATURE: forcemodel (MUST be called BEFORE LOD!)
string forceplayermodels_model;
float forceplayermodels_modelisgoodmodel;
float forceplayermodels_modelindex;
float forceplayermodels_skin;

string forceplayermodels_mymodel;
float forceplayermodels_myisgoodmodel;
float forceplayermodels_mymodelindex;

float forceplayermodels_attempted;

.string forceplayermodels_savemodel;
.float forceplayermodels_savemodelindex;
.float forceplayermodels_saveskin;
.float forceplayermodels_savecolormap;

.string forceplayermodels_isgoodmodel_mdl;
.float forceplayermodels_isgoodmodel;

string forceplayermodels_goodmodel;
float forceplayermodels_goodmodelindex;

void CSQCPlayer_ForceModel_PreUpdate(void)
{
	self.model = self.forceplayermodels_savemodel;
	self.modelindex = self.forceplayermodels_savemodelindex;
	self.skin = self.forceplayermodels_saveskin;
	self.colormap = self.forceplayermodels_savecolormap;
}
void CSQCPlayer_ForceModel_PostUpdate(void)
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
			print(sprintf("Warning: missing model %s has been used\n", self.forceplayermodels_savemodel));
	}
}
void CSQCPlayer_ForceModel_Apply(float islocalplayer)
{
	// which one is ALWAYS good?
	if not(forceplayermodels_goodmodel)
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
			// trust server's idea of "own player model"
			forceplayermodels_modelisgoodmodel = self.forceplayermodels_isgoodmodel;
			forceplayermodels_model = self.forceplayermodels_savemodel;
			forceplayermodels_modelindex = self.forceplayermodels_savemodelindex;
			forceplayermodels_skin = self.forceplayermodels_saveskin;
			forceplayermodels_attempted = 1;
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
	if(autocvar_cl_forcemyplayermodel != "" && forceplayermodels_myisgoodmodel && islocalplayer)
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
	if(!teamplay)
	{
		if(autocvar_cl_forcemyplayercolors && islocalplayer)
			self.colormap = 1024 + autocvar_cl_forcemyplayercolors;
		else if(autocvar_cl_forceplayercolors)
			self.colormap = player_localnum + 1;
	}
}

// FEATURE: fallback frames
.float csqcmodel_saveframe;
.float csqcmodel_saveframe2;
.float csqcmodel_saveframe3;
.float csqcmodel_saveframe4;
.float csqcmodel_framecount;

#define IS_DEAD_FRAME(f) ((f) == 0 || (f) == 1)
void CSQCPlayer_FallbackFrame_PreUpdate(void)
{
	self.frame = self.csqcmodel_saveframe;
	self.frame2 = self.csqcmodel_saveframe2;
	self.frame3 = self.csqcmodel_saveframe3;
	self.frame4 = self.csqcmodel_saveframe4;
}
void CSQCPlayer_FallbackFrame_PostUpdate(float isnew)
{
	self.csqcmodel_saveframe = self.frame;
	self.csqcmodel_saveframe2 = self.frame2;
	self.csqcmodel_saveframe3 = self.frame3;
	self.csqcmodel_saveframe4 = self.frame4;

	// hack for death animations: set their frametime to zero in case a
	// player "pops in"
	if(isnew)
	{
#define FIX_FRAMETIME(f,ft) \
		if(IS_DEAD_FRAME(self.f) && self.ft != 0 && self.death_time != 0) \
		{ \
			self.ft = self.death_time; \
		}
		FIX_FRAMETIME(frame, frame1time)
		FIX_FRAMETIME(frame2, frame2time)
		FIX_FRAMETIME(frame3, frame3time)
		FIX_FRAMETIME(frame4, frame4time)
	}
	self.csqcmodel_isdead = IS_DEAD_FRAME(self.frame);
}
float CSQCPlayer_FallbackFrame(float f)
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
	print(sprintf("Frame %d missing in model %s, and we have no fallback - FAIL!\n", f, self.model));
	return f;
}
void CSQCPlayer_FallbackFrame_Apply(void)
{
	self.frame = CSQCPlayer_FallbackFrame(self.frame);
	self.frame2 = CSQCPlayer_FallbackFrame(self.frame2);
	self.frame3 = CSQCPlayer_FallbackFrame(self.frame3);
	self.frame4 = CSQCPlayer_FallbackFrame(self.frame4);
}

// FEATURE: auto tag_index
.entity tag_entity;
.float tag_entity_lastmodelindex;
.float tag_index;
void CSQCModel_AutoTagIndex_Apply(void)
{
	if(self.tag_entity && wasfreed(self.tag_entity))
		self.tag_entity = world;

	if(self.tag_networkentity)
	{
		// we are ATTACHED!
		float changed = 0;
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
			CSQCModel_Hook_PreDraw();
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
				if(substring(self.model, 0, 17) == "models/weapons/v_")
				{
					if(substring(self.tag_entity.model, 0, 17) == "models/weapons/h_")
					{
						self.tag_index = gettagindex(self.tag_entity, "weapon");
						if(!self.tag_index)
							self.tag_index = gettagindex(self.tag_entity, "tag_weapon");
						if(!self.tag_index)
						{
							// we need to prevent this from 'appening
							self.tag_entity = world;
							self.drawmask = 0;
							dprint("h_ model lacks weapon attachment, but v_ model is attached to it\n");
						}
					}
					else if(self.tag_entity.isplayermodel)
					{
						self.tag_index = gettagindex(self.tag_entity, "weapon");
						if(!self.tag_index)
							self.tag_index = gettagindex(self.tag_entity, "tag_weapon");
						if(!self.tag_index)
							self.tag_index = gettagindex(self.tag_entity, "bip01 r hand");
					}
				}

				if(substring(self.tag_entity.model, 0, 17) == "models/weapons/v_")
				{
					self.tag_index = gettagindex(self.tag_entity, "shot");
					if(!self.tag_index)
						self.tag_index = gettagindex(self.tag_entity, "tag_shot");
				}
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
float EF_BRIGHTFIELD	= 1;
float EF_BRIGHTLIGHT 	= 4;
float EF_DIMLIGHT 	= 8;
float EF_DOUBLESIDED = 32768;
float EF_NOSELFSHADOW = 65536;
float EF_DYNAMICMODELLIGHT = 131072;
float MF_ROCKET  =   1; // leave a trail
float MF_GRENADE =   2; // leave a trail
float MF_GIB     =   4; // leave a trail
float MF_ROTATE  =   8; // rotate (bonus items)
float MF_TRACER  =  16; // green split trail
float MF_ZOMGIB  =  32; // small blood trail
float MF_TRACER2 =  64; // orange split trail
float MF_TRACER3 = 128; // purple trail
.float csqcmodel_effects;
.float csqcmodel_modelflags;
void CSQCModel_Effects_PreUpdate(void)
{
	self.effects = self.csqcmodel_effects;
	self.modelflags = self.csqcmodel_modelflags;
}
void CSQCModel_Effects_PostUpdate(void)
{
	self.csqcmodel_effects = self.effects;
	self.csqcmodel_modelflags = self.modelflags;
	self.effects = 0;
	self.modelflags = 0;
	if(self.csqcmodel_teleported)
		Projectile_ResetTrail(self.origin);
}
void CSQCModel_Effects_Apply(void)
{
	float eff = self.csqcmodel_effects;
	eff &~= CSQCMODEL_EF_RESPAWNGHOST;

	self.renderflags &~= (RF_DEPTHHACK | RF_ADDITIVE | RF_FULLBRIGHT | EF_NOSHADOW | RF_USEAXIS);
	self.effects = 0;
	self.traileffect = 0;
	                
	if(eff & EF_BRIGHTFIELD)
		self.traileffect = particleeffectnum("TR_NEXUIZPLASMA");
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
		pointparticles(particleeffectnum("EF_FLAME"), self.origin, '0 0 0', bound(0, frametime, 0.1));
	if(eff & EF_STARDUST)
		pointparticles(particleeffectnum("EF_STARDUST"), self.origin, '0 0 0', bound(0, frametime, 0.1));
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
		self.traileffect = particleeffectnum("TR_ROCKET");
	if(self.csqcmodel_modelflags & MF_GRENADE)
		self.traileffect = particleeffectnum("TR_GRENADE");
	if(self.csqcmodel_modelflags & MF_GIB)
		self.traileffect = particleeffectnum("TR_BLOOD");
	if(self.csqcmodel_modelflags & MF_ROTATE)
	{
		self.renderflags |= RF_USEAXIS;
		makevectors(self.angles + '0 100 0' * fmod(time, 3.6));
	}
	if(self.csqcmodel_modelflags & MF_TRACER)
		self.traileffect = particleeffectnum("TR_WIZSPIKE");
	if(self.csqcmodel_modelflags & MF_ZOMGIB)
		self.traileffect = particleeffectnum("TR_SLIGHTBLOOD");
	if(self.csqcmodel_modelflags & MF_TRACER2)
		self.traileffect = particleeffectnum("TR_KNIGHTSPIKE");
	if(self.csqcmodel_modelflags & MF_TRACER3)
		self.traileffect = particleeffectnum("TR_VORESPIKE");

	if(self.drawmask)
		Projectile_DrawTrail(self.origin);
	else
		Projectile_ResetTrail(self.origin);

	if(self.csqcmodel_effects & CSQCMODEL_EF_RESPAWNGHOST)
		self.renderflags |= RF_ADDITIVE;
		// also special in CSQCPlayer_GlowMod_Apply
}

// FEATURE: auto glowmod
.vector glowmod;
void CSQCPlayer_GlowMod_Apply(void)
{
	float cm = self.colormap;

	if(self.csqcmodel_effects & CSQCMODEL_EF_RESPAWNGHOST)
		cm = 1024;

	if(self.colormap > 0)
		self.glowmod = colormapPaletteColor(((self.colormap >= 1024) ? self.colormap : stof(getplayerkeyvalue(self.colormap - 1, "colors"))) & 0x0F, TRUE) * 2;
	else
		self.glowmod = '1 1 1';

	if(autocvar_cl_deathglow > 0)
		if(self.csqcmodel_isdead)
		{
			self.glowmod = self.glowmod * bound(0, 1 - (time - self.death_time) / autocvar_cl_deathglow, 1);
			// prevent the zero vector
			self.glowmod_x = max(self.glowmod_x, 0.0001);
			self.glowmod_y = max(self.glowmod_y, 0.0001);
			self.glowmod_z = max(self.glowmod_z, 0.0001);
		}
}

// general functions
.float csqcmodel_predraw_run;
void CSQCModel_Hook_PreDraw()
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
		CSQCPlayer_ForceModel_Apply(self.entnum == player_localnum + 1);
		CSQCPlayer_GlowMod_Apply();
		CSQCPlayer_LOD_Apply();
		CSQCPlayer_FallbackFrame_Apply();
	}

	CSQCModel_AutoTagIndex_Apply();

	CSQCModel_Effects_Apply();
}

void CSQCModel_Hook_PreUpdate(float isnew, float isplayer, float islocalplayer)
{
	// revert to values from server
	CSQCModel_Effects_PreUpdate();
	if(self.isplayermodel)
	{
		CSQCPlayer_FallbackFrame_PreUpdate();
		CSQCPlayer_ForceModel_PreUpdate();
	}
}

void CSQCModel_Hook_PostUpdate(float isnew, float isplayer, float islocalplayer)
{
	// is it a player model? (shared state)
	self.isplayermodel = (substring(self.model, 0, 14) == "models/player/" || substring(self.model, 0, 17) == "models/ok_player/");

	// save values set by server
	if(self.isplayermodel)
	{
		CSQCPlayer_ForceModel_PostUpdate();
		CSQCPlayer_FallbackFrame_PostUpdate(isnew);
	}
	CSQCModel_Effects_PostUpdate();
}
