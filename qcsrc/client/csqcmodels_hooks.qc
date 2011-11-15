.vector glowmod;
.float modelindex_lod0;
.float modelindex_lod1;
.float modelindex_lod2;

void CSQCModels_Hook_PreDraw()
{
	// auto glowmod from colormap
	self.glowmod = colormapPaletteColor(((self.colormap >= 1024) ? (self.colormap & 0xFF) : stof(getplayerkey(self.entnum - 1, "colors"))), TRUE) * 2;

	if(self.modelindex != 0)
	{
		// LOD
		if(self.modelindex_lod0 != self.modelindex)
		{
			string modelname = self.model;
			string s;

			// set modelindex
			self.modelindex_lod0 = self.modelindex;
			self.modelindex_lod1 = self.modelindex;
			self.modelindex_lod2 = self.modelindex;

			// FIXME: this only supports 3-letter extensions
			s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod1", substring(modelname, -4, 4));
			if(fexists(s))
			{
				precache_model(s);
				setmodel(self, s);
				if(self.modelindex > 0)
					self.modelindex_lod1 = self.modelindex;
			}

			s = strcat(substring(modelname, 0, strlen(modelname)-4), "_lod2", substring(modelname, -4, 4));
			if(fexists(s))
			{
				precache_model(s);
				setmodel(self, s);
				if(self.modelindex > 0)
					self.modelindex_lod2 = self.modelindex;
			}

			setmodel(self, modelname); // make everything normal again
		}

		if(autocvar_cl_playerdetailreduction <= 0)
		{
			if(autocvar_cl_playerdetailreduction <= -2)
				self.modelindex = self.modelindex_lod2;
			else if(autocvar_cl_playerdetailreduction <= -1)
				self.modelindex = self.modelindex_lod1;
			else
				self.modelindex = self.modelindex_lod0;
		}
		else
		{
			float distance = vlen(self.origin - other.origin);
			float f = (distance + 100.0) * autocvar_cl_playerdetailreduction;
			if(f > autocvar_cl_loddistance2)
				self.modelindex = self.modelindex_lod2;
			else if(f > autocvar_cl_loddistance1)
				self.modelindex = self.modelindex_lod1;
			else
				self.modelindex = self.modelindex_lod0;
		}
	}
}

