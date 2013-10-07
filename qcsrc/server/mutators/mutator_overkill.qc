void ok_DecreaseCharge(entity ent, float wep)
{
	if not(autocvar_g_overkill_ammo_charge) return;

	entity wepent = get_weaponinfo(wep);

	if(wepent.netname == "")
		return; // dummy

	ent.ammo_charge[wep] -= cvar(sprintf("g_overkill_ammo_decharge_%s", wepent.netname));
}

void ok_IncreaseCharge(entity ent, float wep)
{
	entity wepent = get_weaponinfo(wep);

	if(wepent.netname == "")
		return; // dummy

	if(autocvar_g_overkill_ammo_charge)
	if not(ent.BUTTON_ATCK)
	if(ent.ammo_charge[wep] <= autocvar_g_overkill_ammo_charge_limit)
		ent.ammo_charge[wep] = min(autocvar_g_overkill_ammo_charge_limit, ent.ammo_charge[wep] + cvar(sprintf("g_overkill_ammo_charge_rate_%s", wepent.netname)) * frametime / W_TICSPERFRAME);
}

float ok_CheckWeaponCharge(entity ent, float wep, float swep)
{
	if not(autocvar_g_overkill_ammo_charge) return TRUE;
	//if(wep != swep) return TRUE; // switching, don't even bother checking

	entity wepent = get_weaponinfo(wep);

	if(wepent.netname == "")
		return 0; // dummy

	return !(ent.ammo_charge[wep] < cvar(sprintf("g_overkill_ammo_decharge_%s", wepent.netname)));
}

MUTATOR_HOOKFUNCTION(ok_PlayerDamage_Calculate)
{
	if(DEATH_ISWEAPON(frag_deathtype, WEP_LASER) && frag_target == frag_attacker)
		frag_damage = 0;

	if(!IS_PLAYER(frag_target) || frag_target == frag_attacker)
		return FALSE;

	if not (DEATH_ISWEAPON(frag_deathtype, WEP_LASER))
		return FALSE;

	frag_damage = 0;
	if(frag_target.health >= 1 && !frag_target.freezetag_frozen)
		Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_MINSTA_SECONDARY);

	frag_force = '0 0 0';

	return FALSE;
}

MUTATOR_HOOKFUNCTION(ok_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":OK");
	return FALSE;
}

MUTATOR_HOOKFUNCTION(ok_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Overkill");
	return FALSE;
}

void ok_Item_Touch()
{
	if(IS_PLAYER(other) && other.deadflag == DEAD_NO && !other.freezetag_frozen)
	{
		Item_Touch();
		remove(self);
	}
}

MUTATOR_HOOKFUNCTION(ok_PlayerDies)
{
	self.ok_lastwep = self.weapon;
	self.ok_deathloc = self.origin;

	entity oldself = self;
	float gpi = autocvar_g_pickup_items;
	
	cvar_set("g_pickup_items", "1");
	self = spawn();
	self.ok_item = TRUE;
	self.noalign = TRUE;
	spawnfunc_item_armor_small();
	self.movetype = MOVETYPE_TOSS;
	self.gravity = 1;
	setorigin(self, frag_target.origin + '0 0 32');
	self.velocity = '0 0 200' + normalize(frag_attacker.origin - self.origin) * 500;
	self.touch = ok_Item_Touch;
	SUB_SetFade(self, time + 5, 1);
	self = oldself;
	cvar_set("g_pickup_items", ftos(gpi));

	return FALSE;
}

MUTATOR_HOOKFUNCTION(ok_ForbidThrowCurrentWeapon)
{
	nades_CheckThrow();

	return TRUE;
}

MUTATOR_HOOKFUNCTION(ok_PlayerPreThink)
{
	if(intermission_running || gameover)
		return FALSE;

	if(self.deadflag != DEAD_NO || !IS_PLAYER(self))
		return FALSE;

	if(self.freezetag_frozen)
		return FALSE;

	ok_IncreaseCharge(self, self.weapon);

	if(self.BUTTON_ATCK2)
		if(self.jump_interval <= time)
		{
			self.jump_interval = time + autocvar_g_balance_laser_primary_refire * W_WeaponRateFactor();
			makevectors(self.v_angle);
			float w = self.weapon;
			self.weapon = WEP_LASER;
			W_Laser_Attack(3);
			self.weapon = w;
		}

	self.weapon_blocked = FALSE;

	self.ok_ammo_charge = self.ammo_charge[self.weapon];

	if(autocvar_g_overkill_ammo_charge)
	if(!ok_CheckWeaponCharge(self, self.weapon, self.switchweapon))
	{
		if(autocvar_g_overkill_ammo_charge_notice && time > self.ok_notice_time && self.BUTTON_ATCK && IS_REAL_CLIENT(self))
		{
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_OVERKILL_CHARGE);
			self.ok_notice_time = time + 2;
			play2(self, "weapons/dryfire.wav");
		}
		if(self.weaponentity.state != WS_CLEAR)
			w_ready();

		self.weapon_blocked = TRUE;
	}

	self.BUTTON_ATCK2 = 0;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(ok_PlayerSpawn)
{
	if(autocvar_g_overkill_ammo_charge)
	{
		float i;

		for(i = WEP_FIRST; i <= WEP_LAST; ++i)
			self.ammo_charge[i] = autocvar_g_overkill_ammo_charge_limit;

		self.ok_use_ammocharge = 1;
		self.ok_notice_time = time;
	}
	else
		self.ok_use_ammocharge = 0;

	if(autocvar_g_overkill_spawnsystem_delay_death)
		self.ok_spawnsys_timer = time + autocvar_g_overkill_spawnsystem_delay_death;

	if(teamplay == 0 || autocvar_g_overkill_spawnsystem == 0)
		return FALSE;

	entity team_mate, best_mate = world;
	vector best_spot = '0 0 0';
	float pc = 0., best_dist = 0., dist = 0.;
	FOR_EACH_PLAYER(team_mate)
	{
		if((autocvar_g_overkill_spawnsystem_check_health != 0 && team_mate.health >= 100) || autocvar_g_overkill_spawnsystem_check_health == 0)
			if(team_mate.deadflag == DEAD_NO)
				if(team_mate.ok_spawnsys_timer < time)
					if(team_mate.team == self.team && (g_ctf || g_tdm || g_keyhunt))
						if(team_mate != self)
						{
							tracebox(team_mate.origin, PL_MIN, PL_MAX, team_mate.origin - '0 0 100', MOVE_WORLDONLY, team_mate);
							if(trace_fraction != 1.0)
								if not(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
								{
									pc = pointcontents(trace_endpos + '0 0 1');
									if(pc == CONTENT_EMPTY)
									{
										if(vlen(team_mate.velocity) > 5)
											fixedmakevectors(vectoangles(team_mate.velocity));
										else
											fixedmakevectors(team_mate.angles);

										for(pc = 0; pc != 5; ++pc) // test 5 diffrent spots close to mate
										{
											switch(pc)
											{
											case 0:
												tracebox(team_mate.origin , PL_MIN, PL_MAX, team_mate.origin + v_right * 128, MOVE_NORMAL, team_mate);
												break;
											case 1:
												tracebox(team_mate.origin , PL_MIN, PL_MAX,team_mate.origin - v_right * 128 , MOVE_NORMAL, team_mate);
												break;
											case 2:
												tracebox(team_mate.origin , PL_MIN, PL_MAX, team_mate.origin + v_right * 64 - v_forward * 64, MOVE_NORMAL, team_mate);
												break;
											case 3:
												tracebox(team_mate.origin , PL_MIN, PL_MAX, team_mate.origin - v_right * 64 - v_forward * 64, MOVE_NORMAL, team_mate);
												break;
											case 4:
												tracebox(team_mate.origin , PL_MIN, PL_MAX, team_mate.origin - v_forward * 128, MOVE_NORMAL, team_mate);
												break;
											}

											if(trace_fraction == 1.0)
											{
												traceline(trace_endpos + '0 0 4', trace_endpos - '0 0 100', MOVE_NORMAL, team_mate);
												if(trace_fraction != 1.0)
												{
													if(autocvar_g_overkill_spawnsystem_close2death)
													{
														dist = vlen(trace_endpos - self.ok_deathloc);
														if(dist < best_dist || best_dist == 0)
														{
															best_dist = dist;
															best_spot = trace_endpos;
															best_mate = team_mate;
														}
													}
													else
													{
														setorigin(self, trace_endpos);
														self.angles = team_mate.angles;
														team_mate.ok_spawnsys_timer = time + autocvar_g_overkill_spawnsystem_delay;
														return FALSE;
													}
												}
											}
										}
									}
								}
						}
	}

	if(autocvar_g_overkill_spawnsystem_close2death)
		if(best_dist)
		{
			setorigin(self, best_spot);
			self.angles = best_mate.angles;
			best_mate.ok_spawnsys_timer = time + autocvar_g_overkill_spawnsystem_delay;
		}

	return 0;
}

void start_hmg()
{
	float gpi = autocvar_g_pickup_items;
	cvar_set("g_pickup_items", "1");
	self.classname = "weapon_hmg";
	self.ok_item = TRUE;
	//self.weapons = WEP_HMG;
	//self.flags |= FL_POWERUP;
	self.respawntime = autocvar_g_overkill_superguns_respawn_time;
	setmodel(self, "models/weapons/g_ok_hmg.md3");
	spawnfunc_weapon_hmg();

	cvar_set("g_pickup_items", ftos(gpi));
}

void start_rpc()
{
	float gpi = autocvar_g_pickup_items;
	cvar_set("g_pickup_items", "1");
	self.classname = "weapon_rpc";
	self.respawntime = autocvar_g_overkill_superguns_respawn_time;
	self.ok_item = TRUE;
	//self.weapons = WEP_RPC;
	//self.flags |= FL_POWERUP;
	setmodel(self, "models/weapons/g_ok_rl.md3");
	spawnfunc_weapon_rpc();
	cvar_set("g_pickup_items", ftos(gpi));
}

void start_mh_anyway()
{
	cvar_set("g_pickup_items", "1");
	self.classname = "item_health_mega";
	self.ok_item = TRUE;
	spawnfunc_item_health_mega();
	cvar_set("g_pickup_items", "0");
}

void start_ma_anyway()
{
	cvar_set("g_pickup_items", "1");
	self.classname = "item_armor_large";
	self.ok_item = TRUE;
	spawnfunc_item_armor_large();
	cvar_set("g_pickup_items", "0");
}

MUTATOR_HOOKFUNCTION(ok_OnEntityPreSpawn)
{
	if(autocvar_g_powerups)
	if(autocvar_g_overkill_powerups_replace)
	if(self.classname == "item_strength")
	{
		entity wep = spawn();
		setorigin(wep, self.origin);
		wep.ok_item = TRUE;
		wep.think = start_hmg;
		wep.nextthink = time + 0.1;
		return TRUE;
	}

	if(autocvar_g_powerups)
	if(autocvar_g_overkill_powerups_replace)
	if(self.classname == "item_invincible")
	{
		entity wep = spawn();
		setorigin(wep, self.origin);
		wep.ok_item = TRUE;
		wep.think = start_rpc;
		wep.nextthink = time + 0.1;
		return TRUE;
	}

	return FALSE;
}

MUTATOR_HOOKFUNCTION(ok_ItemRemove)
{
	if(self.ok_item)
		return FALSE;

	switch(self.items)
	{
		case IT_HEALTH: return !(autocvar_g_overkill_100h_anyway);
		case IT_ARMOR: return !(autocvar_g_overkill_100a_anyway);
	}
	
	return TRUE;
}

MUTATOR_HOOKFUNCTION(ok_SpectateCopy)
{
	self.ammo_charge[self.weapon] = other.ammo_charge[other.weapon];
	self.ok_use_ammocharge = other.ok_use_ammocharge;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(ok_SetModname)
{
	modname = "Overkill";
	return TRUE;
}

MUTATOR_HOOKFUNCTION(ok_StartItems)
{
	start_items |= IT_UNLIMITED_WEAPON_AMMO;
	start_weapons = (WEPSET_UZI | WEPSET_NEX | WEPSET_SHOTGUN);

	start_ammo_nails = start_ammo_cells = start_ammo_shells = start_ammo_rockets =
	warmup_start_ammo_nails = warmup_start_ammo_cells = warmup_start_ammo_shells = warmup_start_ammo_rockets = autocvar_g_overkill_ammo_start;

	return FALSE;
}

void ok_Initialize()
{
	precache_all_playermodels("models/ok_player/*.dpm");

	precache_model("models/weapons/h_ok_rl.iqm");
	precache_model("models/weapons/v_ok_rl.md3");
	precache_model("models/weapons/g_ok_rl.md3");
	precache_model("models/weapons/ok_rocket.md3");

	precache_model("models/weapons/h_ok_mg.iqm");
	precache_model("models/weapons/v_ok_mg.md3");
	precache_model("models/weapons/g_ok_mg.md3");

	precache_model("models/weapons/h_ok_hmg.iqm");
	precache_model("models/weapons/v_ok_hmg.md3");
	precache_model("models/weapons/g_ok_hmg.md3");

	precache_model("models/weapons/h_ok_shotgun.iqm");
	precache_model("models/weapons/v_ok_shotgun.md3");
	precache_model("models/weapons/g_ok_shotgun.md3");

	precache_model("models/weapons/h_ok_sniper.iqm");
	precache_model("models/weapons/v_ok_sniper.md3");
	precache_model("models/weapons/g_ok_sniper.md3");

	precache_sound("weapons/dryfire.wav");
	
	addstat(STAT_OK_AMMO_CHARGE, AS_FLOAT, ok_use_ammocharge);
	addstat(STAT_OK_AMMO_CHARGEPOOl, AS_FLOAT, ok_ammo_charge);

	w_uzi(WR_PRECACHE);
	w_nex(WR_PRECACHE);
	w_shotgun(WR_PRECACHE);
	w_laser(WR_PRECACHE);

	(get_weaponinfo(WEP_RPC)).spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;
	(get_weaponinfo(WEP_HMG)).spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;

	(get_weaponinfo(WEP_SHOTGUN)).mdl = "ok_shotgun";
	(get_weaponinfo(WEP_UZI)).mdl = "ok_mg";
	(get_weaponinfo(WEP_NEX)).mdl = "ok_sniper";

	string s;
	float fh = fopen("overkill.cfg", FILE_READ);
	if(fh >= 0)
	{
		while((s = fgets(fh)))
		{
			tokenize_console(s);
			if not(argv(0) == "" || argv(1) == "//" || argv(1) == "")
				cvar_settemp(argv(0), argv(1));
		}
		fclose(fh);
	}
	else
		dprint("^1Mutator Overkill: WARNING! overkill.cfg NOT found, things will be strange!\n");
}

MUTATOR_DEFINITION(mutator_overkill)
{
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, ok_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, ok_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, ok_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, ok_PlayerPreThink, CBC_ORDER_LAST);
	MUTATOR_HOOK(PlayerSpawn, ok_PlayerSpawn, CBC_ORDER_LAST);
	MUTATOR_HOOK(PlayerDamage_Calculate, ok_PlayerDamage_Calculate, CBC_ORDER_LAST);
	MUTATOR_HOOK(PlayerDies, ok_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(OnEntityPreSpawn, ok_OnEntityPreSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetModname, ok_SetModname, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, ok_ItemRemove, CBC_ORDER_ANY);
	MUTATOR_HOOK(SpectateCopy, ok_SpectateCopy, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, ok_StartItems, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		ok_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		(get_weaponinfo(WEP_RPC)).spawnflags |= WEP_FLAG_MUTATORBLOCKED;
		(get_weaponinfo(WEP_HMG)).spawnflags |= WEP_FLAG_MUTATORBLOCKED;
	}

	return FALSE;
}
