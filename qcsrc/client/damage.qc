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

		if(self.damageforcescale)
			if(vlen(thisforce))
			{
				self.move_velocity = self.move_velocity + damage_explosion_calcpush(self.damageforcescale * thisforce, self.move_velocity, autocvar_g_balance_damagepush_speedfactor);
				self.move_flags &~= FL_ONGROUND;
			}

		if(w_issilent)
			self.silent = 1;

		if(self.event_damage)
			self.event_damage(thisdmg, w_deathtype, w_org, thisforce);
	}

	self = oldself;
	
	if(DEATH_ISVEHICLE(w_deathtype))
	{
	    traceline(w_org - normalize(force) * 16, w_org + normalize(force) * 16, MOVE_NOMONSTERS, world);
	    if(trace_plane_normal != '0 0 0')	    
            w_backoff = trace_plane_normal;
        else
            w_backoff = -1 * normalize(w_org - (w_org + normalize(force) * 16));
	    
	    setorigin(self, w_org + w_backoff * 2); // for sound() calls
	    
	    switch(w_deathtype)
	    {            
            case DEATH_VHCRUSH:
                break;
                
            case DEATH_SBMINIGUN:
                string _snd;
                _snd = strcat("weapons/ric", ftos(1 + rint(random() * 2)), ".waw");
                sound(self, CH_SHOTS, _snd, VOL_BASE, ATTN_NORM);
                pointparticles(particleeffectnum("spiderbot_minigun_impact"), self.origin, w_backoff * 1000, 1);
                break;
            case DEATH_SBROCKET:
                sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
                pointparticles(particleeffectnum("spiderbot_rocket_explode"), self.origin, w_backoff * 1000, 1);
                break;
            case DEATH_SBBLOWUP:
                sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_MIN);
                pointparticles(particleeffectnum("explosion_big"), self.origin, w_backoff * 1000, 1);
                break;
                
            case DEATH_WAKIGUN:
                sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
                pointparticles(particleeffectnum("wakizashi_gun_impact"), self.origin, w_backoff * 1000, 1);
                break;
            case DEATH_WAKIROCKET:
                sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
                pointparticles(particleeffectnum("wakizashi_rocket_explode"), self.origin, w_backoff * 1000, 1);
                break;
            case DEATH_WAKIBLOWUP:
                sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_MIN);
                pointparticles(particleeffectnum("explosion_big"), self.origin, w_backoff * 1000, 1);
                break;
                
            case DEATH_RAPTOR_CANNON:
                sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_NORM);
                pointparticles(particleeffectnum("raptor_cannon_impact"), self.origin, w_backoff * 1000, 1);
                break;
            case DEATH_RAPTOR_BOMB_SPLIT:
                float i;
                vector ang, vel;
                for(i = 1; i < 4; ++i)
                {
                    vel = normalize(w_org - (w_org + normalize(force) * 16)) + randomvec() * 128;
                    ang = vectoangles(vel);
                    RaptorCBShellfragToss(w_org, vel, ang + '0 0 1' * (120 * i));
                }
                    
                
                sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
                pointparticles(particleeffectnum("raptor_bomb_spread"), self.origin, w_backoff * 1000, 1);
                break;
            case DEATH_RAPTOR_BOMB:
                sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
                pointparticles(particleeffectnum("raptor_bomb_impact"), self.origin, w_backoff * 1000, 1);
                break;
            case DEATH_RAPTOR_DEATH:
                sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_MIN);
                pointparticles(particleeffectnum("explosion_big"), self.origin, w_backoff * 1000, 1);
                break;
	    }
	}
	
	
	if(DEATH_ISTURRET(w_deathtype))
	{	    
	    traceline(w_org - normalize(force) * 16, w_org + normalize(force) * 16, MOVE_NOMONSTERS, world);
	    if(trace_plane_normal != '0 0 0')	    
            w_backoff = trace_plane_normal;
        else
            w_backoff = -1 * normalize(w_org - (w_org + normalize(force) * 16));
	    
	    setorigin(self, w_org + w_backoff * 2); // for sound() calls
	    
	    switch(w_deathtype)
	    {   
             case DEATH_TURRET_EWHEEL:
                sound(self, CH_SHOTS, "weapons/laserimpact.wav", VOL_BASE, ATTN_MIN);
                pointparticles(particleeffectnum("electro_impact"), self.origin, w_backoff * 1000, 1);
                break;
             
             case DEATH_TURRET_FLAC:
                vector org2;
                org2 = w_org + w_backoff * 6;
                pointparticles(particleeffectnum("hagar_explode"), org2, '0 0 0', 1);
                if (w_random<0.15)
                    sound(self, CH_SHOTS, "weapons/hagexp1.wav", VOL_BASE, ATTN_NORM);
                else if (w_random<0.7)
                    sound(self, CH_SHOTS, "weapons/hagexp2.wav", VOL_BASE, ATTN_NORM);
                else
                    sound(self, CH_SHOTS, "weapons/hagexp3.wav", VOL_BASE, ATTN_NORM);
                
                break;
                
             case DEATH_TURRET_MLRS:
             case DEATH_TURRET_HK:
             case DEATH_TURRET_WALKER_ROCKET:
             case DEATH_TURRET_HELLION:
                sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_MIN);
                pointparticles(particleeffectnum("rocket_explode"), self.origin, w_backoff * 1000, 1);
                break;
             
             case DEATH_TURRET_MACHINEGUN:
             case DEATH_TURRET_WALKER_GUN:
                string _snd;
                _snd = strcat("weapons/ric", ftos(1 + rint(random() * 2)), ".waw");
                sound(self, CH_SHOTS, _snd, VOL_BASE, ATTN_NORM);
                pointparticles(particleeffectnum("machinegun_impact"), self.origin, w_backoff * 1000, 1);
                break;
                          
             case DEATH_TURRET_PLASMA:
                sound(self, CH_SHOTS, "weapons/electro_impact.wav", VOL_BASE, ATTN_MIN);
                pointparticles(particleeffectnum("electro_impact"), self.origin, w_backoff * 1000, 1);
                break;
                          
             case DEATH_TURRET_WALKER_MEELE:
                sound(self, CH_SHOTS, "weapons/ric1.wav", VOL_BASE, ATTN_MIN);
                pointparticles(particleeffectnum("TE_SPARK"), self.origin, w_backoff * 1000, 1);
                break;

             case DEATH_TURRET_PHASER:
                break;
                
             case DEATH_TURRET_TESLA:
                te_smallflash(self.origin);
                break;

        }        
	}
	
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
