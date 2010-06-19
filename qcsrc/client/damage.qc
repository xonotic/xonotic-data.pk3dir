void Ent_DamageInfo(float isNew)
{
	float dmg, rad, edge, thisdmg, forcemul;
	vector force, thisforce;
	entity oldself;

	oldself = self;

	w_deathtype = ReadShort();
	w_issilent = (w_deathtype & 0x8000);
	w_deathtype = (w_deathtype & 0x7FFF);

	w_org_x = ReadCoord();
	w_org_y = ReadCoord();
	w_org_z = ReadCoord();

	dmg = ReadByte();
	rad = ReadByte();
	edge = ReadByte();
	force = decompressShortVector(ReadShort());

	if not(isNew)
		return;

	if(rad < 0)
	{
		rad = -rad;
		forcemul = -1;
	}
	else
		forcemul = 1;
	
	for(self = findradius(w_org, rad); self; self = self.chain)
	{
		if(rad)
		{
			thisdmg = vlen(self.origin - w_org) / rad;
			if(thisdmg >= 1)
				continue;
			if(dmg)
			{
				thisdmg = dmg + (edge - dmg) * thisdmg;
				thisforce = forcemul * vlen(force) * (thisdmg / dmg) * normalize(self.origin - w_org);
			}
			else
			{
				thisdmg = 0;
				thisforce = forcemul * vlen(force) * normalize(self.origin - w_org);
			}
		}
		else
		{
			thisdmg = dmg;
			thisforce = forcemul * force;
		}

		//print("check ", ftos(num_for_edict(self)), " ", self.classname, "\n");
		//print(ftos(self.damageforcescale), "\n");
		//print(vtos(thisforce), "\n");
		if(self.damageforcescale)
			if(vlen(thisforce))
			{
				self.move_velocity = self.move_velocity + self.damageforcescale * thisforce;
				self.move_flags &~= FL_ONGROUND;
				//print("pushed ", ftos(num_for_edict(self)), " loose\n");
			}

		if(w_issilent)
			self.silent = 1;

		if(self.event_damage)
			self.event_damage(thisdmg, w_deathtype, w_org, thisforce);
	}

	self = oldself;

	// TODO spawn particle effects and sounds based on w_deathtype
	
	if(!DEATH_ISSPECIAL(w_deathtype))
	{
		float hitwep;

		hitwep = DEATH_WEAPONOFWEAPONDEATH(w_deathtype);
		w_random = prandom();

		traceline(w_org - normalize(force) * 16, w_org + normalize(force) * 16, MOVE_NOMONSTERS, world);
		if(trace_fraction < 1 && hitwep != WEP_NEX && hitwep != WEP_MINSTANEX)
			w_backoff = trace_plane_normal;
		else
			w_backoff = -1 * normalize(force);
		setorigin(self, w_org + w_backoff * 2); // for sound() calls

		(get_weaponinfo(hitwep)).weapon_func(WR_IMPACTEFFECT);
	}
}

void DamageInfo_Precache()
{
	float i;
	for(i = WEP_FIRST; i <= WEP_LAST; ++i)
		(get_weaponinfo(i)).weapon_func(WR_PRECACHE);
}
