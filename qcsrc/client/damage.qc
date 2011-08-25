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

// damage effect

.entity dmgent;
.float dmgpartnum, dmgtime;
.float lifetime;

void Ent_DamageEffect_Think()
{
	self.nextthink = time;

	float foundgib;
	entity entcs;

	if(time >= self.lifetime)
	{
		remove(self);
		self = world;
		return;
	}
	if(self.dmgtime > time)
		return;
	entcs = entcs_receiver[self.team];
	if(!entcs)
		return;

	// Scan the owner of all gibs in the world. If a gib owner is the same as the player we're applying
	// the effect to, it means our player is gibbed. Therefore, apply particles to the gibs instead.
	entity head;
	for(head = world; (head = find(head, classname, "gib")); )
	{
		if(head.team == self.team)
		{
			if(autocvar_cl_damageeffect_gibs)
			{
				if(autocvar_cl_damageeffect_gibs_randomize >= random())
					pointparticles(self.dmgpartnum, head.origin, '0 0 0', 1);
				self.dmgtime = time + autocvar_cl_damageeffect_gibs;
			}
			foundgib = TRUE;
		}
	}

	if(foundgib || !autocvar_cl_damageeffect_player)
		return; // don't show effects on the invisible dead body if gibs exist
	if(self.team == player_localentnum - 1 && !autocvar_chase_active)
		return; // if we aren't in third person mode, hide own damage effect

	// Now apply the effect to actual players
	pointparticles(self.dmgpartnum, entcs.origin, '0 0 0', 1);
	self.dmgtime = time + autocvar_cl_damageeffect_player;
}

void Ent_DamageEffect()
{
	float dmg, type, specnum1, specnum2, entnumber, life;
	vector org;
	string specstr, effectnum;
	entity e;

	dmg = ReadByte(); // damage amount
	type = ReadByte(); // damage weapon
	specnum1 = ReadByte(); // player species
	entnumber = ReadByte(); // player entnum

	if(!autocvar_cl_damageeffect_player && !autocvar_cl_damageeffect_gibs)
		return;
	if(autocvar_cl_gentle || autocvar_cl_gentle_damage)
		return;

	specnum2 = (specnum1 & 0x78) / 8; // blood type: using four bits (0..7, bit indexes 3,4,5)
	specstr = species_prefix(specnum2);
	life = bound(0, dmg * autocvar_cl_damageeffect_lifetime, autocvar_cl_damageeffect_lifetime_max);

	e = get_weaponinfo(type);
	effectnum = strcat("weapondamage_", e.netname);
	// If the weapon is a bullet weapon, its damage effect is blood.
	// Since blood is species dependent, we make this effect per-species.
	if(type == WEP_SHOTGUN || type == WEP_UZI || type == WEP_RIFLE)
	if(specstr != "")
	{
		effectnum = strcat(effectnum, "_", specstr);
		effectnum = substring(effectnum, 0, strlen(effectnum) - 1); // remove the _ symbol at the end of the species name
	}

	// if the player already has a damage effect, update it instead of spawning a new one
	entity head;
	for(head = world; (head = find(head, classname, "damageeffect")); )
	{
		if(head.team == entnumber - 1)
		{
			head.dmgpartnum = particleeffectnum(effectnum);
			head.lifetime += life;
			return;
		}
	}

	entity e;
	e = spawn();
	e.classname = "damageeffect";
	e.team = entnumber - 1;
	e.dmgpartnum = particleeffectnum(effectnum);
	e.lifetime = time + life;
	e.think = Ent_DamageEffect_Think;
	e.nextthink = time;
}
