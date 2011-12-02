.vector glowmod;
.float lodmodelindex0;
.float lodmodelindex1;
.float lodmodelindex2;

.entity tag_entity;
.float tag_index;

void CSQCModel_Hook_PreDraw(float isplayer)
{
	// auto glowmod from colormap
	if(isplayer)
	{
		if(self.colormap > 0)
			self.glowmod = colormapPaletteColor(((self.colormap >= 1024) ? (self.colormap & 0xFF) : stof(getplayerkeyvalue(self.colormap - 1, "colors"))), TRUE) * 2;
		else
			self.glowmod = '1 1 1';

		if(self.modelindex && self.model != "null")
		{
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
	}

	if(!isplayer)
	{
		if(self.tag_entity && wasfreed(self.tag_entity))
			self.tag_entity = world;

		if(self.tag_networkentity)
		{
			// we are ATTACHED!
			if(self.tag_entity.entnum == self.tag_networkentity)
			{
				// already good
				self.drawmask = MASK_NORMAL;
			}
			else
			{
				// to something NEW NEW NEW NEW!
				self.tag_entity = findfloat(world, entnum, self.tag_networkentity);
				if(self.tag_entity)
				{
					// the best part is: IT EXISTS
					self.drawmask = MASK_NORMAL;

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
		else
		{
			// no brain no pain
			self.drawmask = MASK_NORMAL;
		}
	}
}

string forceplayermodels_model;
float forceplayermodels_modelindex;
float forceplayermodels_skin;
.string forceplayermodels_savemodel;
.float forceplayermodels_savemodelindex;
.float forceplayermodels_saveskin;
void CSQCModel_Hook_PreUpdate(float isplayer, float islocalplayer)
{
	if(isplayer)
	{
		// revert to values from server
		self.model = self.forceplayermodels_savemodel;
		self.modelindex = self.forceplayermodels_savemodelindex;
		self.skin = self.forceplayermodels_saveskin;
	}
}

void CSQCModel_Hook_PostUpdate(float isplayer, float islocalplayer)
{
	if(isplayer)
	{
		// save values set by server
		self.forceplayermodels_savemodel = self.model;
		self.forceplayermodels_savemodelindex = self.modelindex;
		self.forceplayermodels_saveskin = self.skin;

		if(self.modelindex && self.model != "null")
		{
			if(islocalplayer)
			{
				// trust server's idea of "own player model"
				forceplayermodels_model = self.model;
				forceplayermodels_modelindex = self.modelindex;
				forceplayermodels_skin = self.skin;
			}
			if(!forceplayermodels_modelindex)
			{
				// only if this failed, find it out on our own
				setmodel(self, autocvar__cl_playermodel); // this is harmless, see below
				forceplayermodels_model = self.model;
				forceplayermodels_modelindex = self.modelindex;
				forceplayermodels_skin = autocvar__cl_playerskin;
			}
		}

		if(autocvar_cl_forceplayermodels)
		{
			self.model = forceplayermodels_model;
			self.modelindex = forceplayermodels_modelindex;
			self.skin = forceplayermodels_skin;
		}

		// LOD model loading
		if(self.lodmodelindex0 != self.modelindex)
		{
			string modelname = self.model;
			string s;

			if(!fexists(modelname))
			{
				print(sprintf(_("Trying to use non existing model %s. "), modelname));
				modelname = cvar_defstring("_cl_playermodel");
				print(sprintf(_("Reverted to %s."), modelname));
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
	}
}
