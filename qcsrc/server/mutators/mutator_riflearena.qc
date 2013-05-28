.entity ra_nade;
.float ra_nade_refire;

float ra_CanThrowNade()
{
	if(self.vehicle)
		return FALSE;
		
	if(gameover)
		return FALSE;
		
	if(self.deadflag)
		return FALSE;
		
	if not(IS_PLAYER(self))
		return FALSE;
		
	if not(autocvar_g_riflearena_nades)
		return FALSE;
		
	if(forbidWeaponUse())
		return FALSE;
		
	return TRUE;
}

void ra_nade_timer_think()
{
	self.skin = 8 - (self.owner.wait - time) / (autocvar_g_riflearena_nade_lifetime / 10);
	self.nextthink = time;
	if(!self.owner || wasfreed(self.owner))
		remove(self);
	
}

void ra_nade_burn_spawn(entity nade)
{
	switch(nade.realowner.team)
	{
		case NUM_TEAM_1:
			CSQCProjectile(nade, TRUE, PROJECTILE_NADE_RED_BURN, TRUE);
			break;
		case NUM_TEAM_2:
			CSQCProjectile(nade, TRUE, PROJECTILE_NADE_BLUE_BURN, TRUE);
			break;
		default:
			CSQCProjectile(nade, TRUE, PROJECTILE_NADE_RED_BURN, TRUE);
			break;
	}
}

void ra_nade_spawn(entity nade)
{
	entity timer = spawn();
	setmodel(timer, "models/ok_nade_counter/ok_nade_counter.md3");
	setattachment(timer, nade, "");
	timer.classname = "nade_timer";
	timer.colormap = nade.colormap;
	timer.glowmod = nade.glowmod;
	timer.think = ra_nade_timer_think;
	timer.nextthink = time;
	timer.wait = nade.wait;
	timer.owner = nade;	
	timer.skin = 10;
	
	CSQCProjectile(nade, TRUE, ((nade.realowner.team == NUM_TEAM_2) ? PROJECTILE_NADE_BLUE: PROJECTILE_NADE_RED) , TRUE);
	
}

void ra_nade_boom() // TODO: DamageInfo
{
	sound(self, CH_SHOTS_SINGLE, "misc/null.wav", VOL_BASE, ATTN_NORM);
	sound(self, CH_SHOTS, "weapons/rocket_impact.wav", VOL_BASE, ATTN_NORM);
	pointparticles(particleeffectnum((self.realowner.team == NUM_TEAM_2) ? "nade_blue_explode" : "nade_red_explode"), self.origin + '0 0 1', '0 0 0', 1);


	self.takedamage = DAMAGE_NO;
	RadiusDamage(self, self.realowner, autocvar_g_riflearena_nade_damage, autocvar_g_riflearena_nade_edgedamage,
				 autocvar_g_riflearena_nade_radius, self, autocvar_g_riflearena_nade_force, self.projectiledeathtype, self.enemy);

	remove(self);
}

void ra_nade_touch()
{
	PROJECTILE_TOUCH;
	setsize(self, '-2 -2 -2', '2 2 2');
	UpdateCSQCProjectile(self);
	if(self.health == autocvar_g_riflearena_nade_health)
	{
		spamsound(self, CH_SHOTS, strcat("weapons/grenade_bounce", ftos(1 + rint(random() * 5)), ".wav"), VOL_BASE, ATTN_NORM);
		return;
	}

	self.enemy = other;
	ra_nade_boom();
}

void ra_nade_beep()
{
	sound(self, CH_SHOTS_SINGLE, "overkill/grenadebip.wav", VOL_BASE, 0.5 *(ATTN_LARGE + ATTN_MAX));
	self.think = ra_nade_boom;
	self.nextthink = max(self.wait, time);
}

void ra_nade_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	if(DEATH_ISWEAPON(deathtype, WEP_LASER))
		return;
	
	self.velocity += force;

	if(!damage)
		return;

	if(self.health == autocvar_g_riflearena_nade_health)
	{
		sound(self, CH_SHOTS_SINGLE, "misc/null.wav", VOL_BASE, 0.5 *(ATTN_LARGE + ATTN_MAX));
		self.nextthink = max(time + autocvar_g_riflearena_nade_lifetime, time);
		self.think = ra_nade_beep;
	}

	self.health   -= damage;
	self.realowner = attacker;

	if(self.health <= 0)
		W_PrepareExplosionByDamage(attacker, ra_nade_boom);
	else
		ra_nade_burn_spawn(self);
}

void ra_toss_nade(entity ent, vector _velocity, float _time)
{
	entity _nade = ent.ra_nade;
	ent.ra_nade = world;
	
	setorigin(_nade, gettaginfo(_nade, gettagindex(_nade, "Object001")));
	setattachment(_nade, world, "");
	PROJECTILE_MAKETRIGGER(_nade);
	setsize(_nade, '-16 -16 -16', '16 16 16');
	_nade.movetype = MOVETYPE_BOUNCE;
	
	if(ent.crouch)
		_nade.velocity = '0 0 -10';
	else if(autocvar_g_riflearena_nade_newton_style == 1)
		_nade.velocity = ent.velocity + _velocity;
	else if(autocvar_g_riflearena_nade_newton_style == 2)
		_nade.velocity = _velocity;
	else
		_nade.velocity = W_CalculateProjectileVelocity(ent.velocity, _velocity, FALSE);

	_nade.solid = SOLID_BBOX;
	_nade.touch = ra_nade_touch;
	_nade.health = autocvar_g_riflearena_nade_health;
	_nade.takedamage = DAMAGE_YES;
	_nade.event_damage = ra_nade_damage;
	_nade.teleportable = TRUE;

	ra_nade_spawn(_nade);

	if(_time)
	{
		_nade.think = ra_nade_boom;
		_nade.nextthink = _time;
	}
	else
		_nade.projectiledeathtype = DEATH_NADE_NORMAL;

	ent.ra_nade_refire = time + autocvar_g_riflearena_nade_refire;
}

void ra_nade_prime()
{
	if(self.ra_nade)
		remove(self.ra_nade);
	
	self.ra_nade = spawn();
	setmodel(self.ra_nade, "models/weapons/h_ok_grenade.iqm");
	setattachment(self.ra_nade, self.weaponentity, "");
	self.ra_nade.classname = "nade";
	self.ra_nade.realowner = self;
	self.ra_nade.colormap = self.colormap;
	self.ra_nade.glowmod = self.glowmod;
	self.ra_nade.wait = time + autocvar_g_riflearena_nade_lifetime;
	self.ra_nade.cnt = time;
	self.ra_nade.think = ra_nade_beep;
	self.ra_nade.nextthink = max(self.ra_nade.wait - 3, time);
	self.ra_nade.projectiledeathtype = DEATH_NADE_NORMAL;
}

void ra_SetCvars()
{
	cvar_settemp("g_balance_rifle_secondary_spread", ftos(cvar("g_riflearena_rifle_secondary_spread")));
	cvar_settemp("g_balance_rifle_secondary_shots", ftos(cvar("g_riflearena_rifle_secondary_shots")));
	cvar_settemp("g_balance_rifle_secondary_animtime", ftos(cvar("g_riflearena_rifle_secondary_animtime")));
	cvar_settemp("g_balance_rifle_secondary_refire", ftos(cvar("g_riflearena_rifle_secondary_refire")));
	cvar_settemp("g_balance_rifle_secondary_damage", ftos(cvar("g_riflearena_rifle_secondary_damage")));
}

MUTATOR_HOOKFUNCTION(ra_VehicleEnter)
{
	if(other.ra_nade)
		ra_toss_nade(other, '0 0 100', max(other.ra_nade.wait, time + 0.05));
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(ra_PlayerDamage)
{
	if(IS_PLAYER(frag_attacker))
	if(IS_PLAYER(frag_target))
	{
		if (DEATH_ISWEAPON(frag_deathtype, WEP_LASER))
		{
			if(frag_attacker == frag_target)
				frag_damage = 5;
			else
				frag_damage = 0;
			if (frag_target != frag_attacker)
			{
				if (frag_target.health >= 1 && IS_PLAYER(frag_target))
					centerprint(frag_attacker, "Laser inflicts no damage!");
				frag_force = '0 0 0';
			}
		}
	}
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(ra_PlayerSpawn)
{
	WEPSET_CLEAR_E(self);
	WEPSET_OR_EW(self, WEP_RIFLE);
	WEPSET_OR_EW(self, WEP_LASER);
	
	self.ra_nade_refire = time + 2;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(ra_FilterItem)
{
	switch (self.items)
	{
		case IT_5HP:
		case IT_ARMOR_SHARD:
			return FALSE;
	}
		
	return TRUE;
}

MUTATOR_HOOKFUNCTION(ra_PlayerThink)
{
	if(self.ra_nade)
		if(self.ra_nade.wait - 0.1 <= time)
			ra_toss_nade(self, '0 0 0', time + 0.05);

	if(ra_CanThrowNade())
	if(self.ra_nade_refire < time)
	{
		if(self.BUTTON_HOOK)
		{
			if(!self.ra_nade)
				ra_nade_prime();
		}
		else if(time - self.ra_nade.cnt >= 1)
		{
			if(self.ra_nade)
			{
				makevectors(self.v_angle);
				float _force = time - self.ra_nade.cnt;
				_force /= autocvar_g_riflearena_nade_lifetime;
				_force = autocvar_g_riflearena_nade_minforce + (_force * (autocvar_g_riflearena_nade_maxforce - autocvar_g_riflearena_nade_minforce));				
				ra_toss_nade(self, (v_forward * 0.7 + v_up * 0.2 + v_right * 0.1) * _force, 0);
			}
		}
	}
	
	self.hasweapon_complain_spam = time + 5; // this isn't needed, so keep it off
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(ra_RemovePlayer)
{
	if(self.ra_nade)
		remove(self.ra_nade);
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(ra_StartItems)
{
	start_items |= IT_UNLIMITED_AMMO;
	start_ammo_nails = 100;
	
	g_grappling_hook = 0;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(ra_PlayerDies)
{
	if(self.ra_nade)
		ra_toss_nade(self, '0 0 100', max(self.ra_nade.wait, time + 0.05));

	return 0;
}

MUTATOR_HOOKFUNCTION(ra_ForbidThrowCurrentWeapon)
{
	if(!ra_CanThrowNade())
		return 1;

	if(!self.ra_nade)
	{
		if(self.ra_nade_refire < time)
		{
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_NADE);
			ra_nade_prime();
			self.ra_nade_refire  = time + autocvar_g_riflearena_nade_refire;
		}
	}
	else
	{
		if(time - self.ra_nade.cnt >= 1)
		{
			makevectors(self.v_angle);
			float _force = time - self.ra_nade.cnt;
			_force /= autocvar_g_riflearena_nade_lifetime;
			_force = autocvar_g_riflearena_nade_minforce + (_force * (autocvar_g_riflearena_nade_maxforce - autocvar_g_riflearena_nade_minforce));
			ra_toss_nade(self, (v_forward * 0.75 + v_up * 0.2 + v_right * 0.05) * _force, 0);
		}
	}
	return 1;
}

MUTATOR_HOOKFUNCTION(ra_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":RA");
	return 0;
}

MUTATOR_HOOKFUNCTION(ra_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Rifle Arena");
	return 0;
}

MUTATOR_HOOKFUNCTION(ra_SetModname)
{
	modname = "Rifle Arena";
	return TRUE;
}

MUTATOR_DEFINITION(mutator_riflearena)
{
	MUTATOR_HOOK(VehicleEnter, ra_VehicleEnter, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, ra_PlayerDamage, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, ra_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, ra_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, ra_StartItems, CBC_ORDER_ANY);
	MUTATOR_HOOK(MakePlayerObserver, ra_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(ClientDisconnect, ra_RemovePlayer, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, ra_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, ra_PlayerThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, ra_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, ra_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, ra_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	
	MUTATOR_ONADD
	{
		ra_SetCvars();
		
		precache_model("models/ok_nade_counter/ok_nade_counter.md3");
		
		precache_model("models/weapons/h_ok_grenade.iqm");
		precache_model("models/weapons/v_ok_grenade.md3");
		precache_sound("weapons/rocket_impact.wav");
		precache_sound("weapons/grenade_bounce1.wav");
		precache_sound("weapons/grenade_bounce2.wav");
		precache_sound("weapons/grenade_bounce3.wav");
		precache_sound("weapons/grenade_bounce4.wav");
		precache_sound("weapons/grenade_bounce5.wav");
		precache_sound("weapons/grenade_bounce6.wav");
		precache_sound("overkill/grenadebip.wav");
		
		weapon_action(WEP_LASER, WR_PRECACHE);
		weapon_action(WEP_RIFLE, WR_PRECACHE);
		
		get_weaponinfo(WEP_HOOK).spawnflags |= WEP_FLAG_MUTATORBLOCKED;
	}
	
	MUTATOR_ONROLLBACK_OR_REMOVE
	{
		get_weaponinfo(WEP_HOOK).spawnflags &~= WEP_FLAG_MUTATORBLOCKED;
	}
	
	MUTATOR_ONREMOVE
	{
		print("This cannot be removed at runtime\n");
		return -1;
	}

	return 0;
}
