

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

		if(!fexists(modelname))
		{
			print(sprintf(_("Trying to use non existing model %s. "), modelname));
			modelname = cvar_defstring("_cl_playermodel");
			print(sprintf(_("Reverted to %s.\n"), modelname));
		}

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
		float distance = vlen(self.origin - other.origin);
		float f = (distance + 100.0) * autocvar_cl_playerdetailreduction;
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
float forceplayermodels_modelindex;
float forceplayermodels_skin;
float forceplayermodels_attempted;
.string forceplayermodels_savemodel;
.float forceplayermodels_savemodelindex;
.float forceplayermodels_saveskin;
void CSQCPlayer_ForceModel_PreUpdate(void)
{
	self.model = self.forceplayermodels_savemodel;
	self.modelindex = self.forceplayermodels_savemodelindex;
	self.skin = self.forceplayermodels_saveskin;
}
void CSQCPlayer_ForceModel_PostUpdate(void)
{
	self.forceplayermodels_savemodel = self.model;
	self.forceplayermodels_savemodelindex = self.modelindex;
	self.forceplayermodels_saveskin = self.skin;
}
void CSQCPlayer_ForceModel_Apply(float islocalplayer)
{
	// first, try finding it from the server

	if(self.forceplayermodels_savemodelindex && self.forceplayermodels_savemodel != "null")
	{
		if(islocalplayer)
		{
			// trust server's idea of "own player model"
			forceplayermodels_model = self.model;
			forceplayermodels_modelindex = self.modelindex;
			forceplayermodels_skin = self.skin;
			forceplayermodels_attempted = 1;
		}
	}

	// forcemodel finding
	if(!forceplayermodels_attempted)
	{
		// only if this failed, find it out on our own
		entity e;
		e = spawn();
		setmodel(e, autocvar__cl_playermodel); // this is harmless, see below
		forceplayermodels_model = e.model;
		forceplayermodels_modelindex = e.modelindex;
		forceplayermodels_skin = autocvar__cl_playerskin;
		forceplayermodels_attempted = 1;
		remove(e);
	}

	// apply it
	if(autocvar_cl_forceplayermodels && forceplayermodels_modelindex)
	{
		self.model = forceplayermodels_model;
		self.modelindex = forceplayermodels_modelindex;
		self.skin = forceplayermodels_skin;
	}
	else
	{
		self.model = self.forceplayermodels_savemodel;
		self.modelindex = self.forceplayermodels_savemodelindex;
		self.skin = self.forceplayermodels_saveskin;
	}
}

// FEATURE: fallback frames
.float csqcmodel_saveframe;
.float csqcmodel_saveframe2;
.float csqcmodel_saveframe3;
.float csqcmodel_saveframe4;
.float csqcmodel_framecount;
void CSQCPlayer_FallbackFrame_PreUpdate(void)
{
	self.frame = self.csqcmodel_saveframe;
	self.frame2 = self.csqcmodel_saveframe2;
	self.frame3 = self.csqcmodel_saveframe3;
	self.frame4 = self.csqcmodel_saveframe4;
}
void CSQCPlayer_FallbackFrame_PostUpdate(void)
{
	self.csqcmodel_saveframe = self.frame;
	self.csqcmodel_saveframe2 = self.frame2;
	self.csqcmodel_saveframe3 = self.frame3;
	self.csqcmodel_saveframe4 = self.frame4;
}
float CSQCPlayer_FallbackFrame(float f)
{
	if(frameduration(self.modelindex, f) > 0)
		return f; // goooooood
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

// FEATURE: auto glowmod
.vector glowmod;
void CSQCPlayer_GlowMod_Apply(void)
{
	if(self.colormap > 0)
		self.glowmod = colormapPaletteColor(((self.colormap >= 1024) ? self.colormap : stof(getplayerkeyvalue(self.colormap - 1, "colors"))) & 0x0F, TRUE) * 2;
	else
		self.glowmod = '1 1 1';
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

				if(substring(self.model, 0, 17) == "models/weapons/v_")
					if(substring(self.tag_entity.model, 0, 14) == "models/player/")
					{
						self.tag_index = gettagindex(self.tag_entity, "tag_weapon");
						if(!self.tag_index)
							self.tag_index = gettagindex(self.tag_entity, "bip01 r hand");
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
	eff &~= CSQCMODEL_EF_INVISIBLE;

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
	if((eff & EF_NODRAW) || (self.csqcmodel_effects & CSQCMODEL_EF_INVISIBLE))
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
	// ignoring EF_UNUSED17, EF_UNUSED18, EF_UNUSED19, EF_RESTARTANIM_BIT, EF_TELEPORT_BIT, EF_LOWPRECISION
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
}

// general functions
void CSQCModel_Hook_PreDraw(float isplayer, float islocalplayer)
{
	if(!self.modelindex || self.model == "null")
	{
		self.drawmask = 0;
		return;
	}
	else
		self.drawmask = MASK_NORMAL;

	if(isplayer)
	{
		CSQCPlayer_GlowMod_Apply();
		CSQCPlayer_ForceModel_Apply(islocalplayer);
		CSQCPlayer_LOD_Apply();
		CSQCPlayer_FallbackFrame_Apply();
	}

	if(!isplayer)
		CSQCModel_AutoTagIndex_Apply();

	CSQCModel_Effects_Apply();
}

void CSQCModel_Hook_PreUpdate(float isplayer, float islocalplayer)
{
	CSQCModel_Effects_PreUpdate();
	if(isplayer)
	{
		// revert to values from server
		CSQCPlayer_FallbackFrame_PreUpdate();
		CSQCPlayer_ForceModel_PreUpdate();
	}
}

void CSQCModel_Hook_PostUpdate(float isplayer, float islocalplayer)
{
	if(isplayer)
	{
		// save values set by server
		CSQCPlayer_ForceModel_PostUpdate();
		CSQCPlayer_FallbackFrame_PostUpdate();
	}
	CSQCModel_Effects_PostUpdate();
}
