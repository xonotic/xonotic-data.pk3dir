.vector glowmod;
.float lodmodelindex0;
.float lodmodelindex1;
.float lodmodelindex2;

.entity tag_entity;
.float tag_index;

void CSQCModel_Hook_PreDraw(float isplayer)
{
	// auto glowmod from colormap
	self.glowmod = colormapPaletteColor(((self.colormap >= 1024) ? (self.colormap & 0xFF) : stof(getplayerkeyvalue(self.entnum - 1, "colors"))), TRUE) * 2;

	if(self.modelindex != 0)
	{
		// LOD
		if(self.lodmodelindex0 != self.modelindex)
		{
			string modelname = self.model;
			string s;

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
				if(self.modelindex > 0)
					self.lodmodelindex1 = self.modelindex;
			}

			s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod2", substring(modelname, -4, 4));
			if(fexists(s))
			{
				precache_model(s);
				setmodel(self, s);
				if(self.modelindex > 0)
					self.lodmodelindex2 = self.modelindex;
			}

			setmodel(self, modelname); // make everything normal again
		}

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
