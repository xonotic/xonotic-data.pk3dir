void spawnfunc_item_minst_cells (void) 
{
	if not(g_minstagib)
	{
		remove(self);
		return;
	}
}

.float minstagib_nextthink;
.float minstagib_needammo;
void minstagib_stop_countdown(entity e)
{
	if (!e.minstagib_needammo)
		return;
	Send_CSQC_Centerprint_Generic_Expire(e, CPID_MINSTA_FINDAMMO);
	e.minstagib_needammo = FALSE;
}
void minstagib_ammocheck(void)
{
	if (time < self.minstagib_nextthink)
		return;

	if (self.deadflag || gameover)
		minstagib_stop_countdown(self);
	else if (self.ammo_cells > 0 || (self.items & IT_UNLIMITED_WEAPON_AMMO))
	{
		minstagib_stop_countdown(self);
		if(self.health < 100)
			self.health = 100;
	}
	else
	{
		self.minstagib_needammo = TRUE;
		if (self.health == 5)
		{
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "terminated");
		}
		else if (self.health == 10)
		{
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "1");
		}
		else if (self.health == 20)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "2");
		}
		else if (self.health == 30)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "3");
		}
		else if (self.health == 40)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "4");
		}
		else if (self.health == 50)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "5");
		}
		else if (self.health == 60)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "6");
		}
		else if (self.health == 70)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "7");
		}
		else if (self.health == 80)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "8");
		}
		else if (self.health == 90)
		{
			Send_CSQC_Centerprint_Generic(self, CPID_MINSTA_FINDAMMO, "^1%d^7 seconds left to find some ammo", 1, 9);
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			AnnounceTo(self, "9");
		}
		else if (self.health == 100)
		{
			Send_CSQC_Centerprint_Generic(self, CPID_MINSTA_FINDAMMO, "get some ammo or\nyou'll be dead in ^3%d^7 seconds...", 1, 10);
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			if not(self.flags & FL_GODMODE)
				AnnounceTo(self, "10");
		}
	}
	self.minstagib_nextthink = time + 1;
}

MUTATOR_HOOKFUNCTION(minstagib_BotShouldAttack)
{
	if(checkentity.items & IT_STRENGTH)
		return TRUE;
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_MakePlayerObserver)
{
	minstagib_stop_countdown(self);
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_PlayerSpawn)
{
	self.effects |= EF_FULLBRIGHT;
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_PlayerPreThink)
{
	minstagib_ammocheck();
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_PlayerPowerups)
{
	if not(self.effects & EF_FULLBRIGHT)
		self.effects |= EF_FULLBRIGHT;

	if (self.items & IT_STRENGTH)
	{
		play_countdown(self.strength_finished, "misc/poweroff.wav");
		if (time > self.strength_finished)
		{
			self.alpha = default_player_alpha;
			self.exteriorweaponentity.alpha = default_weapon_alpha;
			self.items &~= IT_STRENGTH;
			sprint(self, "^3Invisibility has worn off\n");
		}
	}
	else
	{
		if (time < self.strength_finished)
		{
			self.alpha = g_minstagib_invis_alpha;
			self.exteriorweaponentity.alpha = g_minstagib_invis_alpha;
			self.items |= IT_STRENGTH;
			sprint(self, "^3You are invisible\n");
		}
	}

	if (self.items & IT_INVINCIBLE)
	{
		play_countdown(self.invincible_finished, "misc/poweroff.wav");
		if (time > self.invincible_finished)
		{
			self.items &~= IT_INVINCIBLE;
			sprint(self, "^3Speed has worn off\n");
		}
	}
	else
	{
		if (time < self.invincible_finished)
		{
			self.items |= IT_INVINCIBLE;
			sprint(self, "^3You are on speed\n");
		}
	}
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_PlayerPhysics)
{
	if(self.items & IT_INVINCIBLE)
		self.stat_sv_maxspeed = self.stat_sv_maxspeed * autocvar_g_minstagib_speed_highspeed;
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_SplitHealthArmor)
{
	damage_save = 0;
	damage_take = frag_damage;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_ForbidThrowing)
{
	if (self.health < 1)
		return FALSE;
		
	return TRUE;
}

MUTATOR_HOOKFUNCTION(minstagib_PlayStrengthSound)
{
	// You shall not play!
	return TRUE;
}

MUTATOR_HOOKFUNCTION(minstagib_PlayerDamage)
{
	if(autocvar_g_friendlyfire == 0)
		frag_damage = 0;
		
	if(frag_target.classname == "player")
	{
		if ((frag_deathtype == DEATH_FALL)  ||
			(frag_deathtype == DEATH_DROWN) ||
			(frag_deathtype == DEATH_SLIME) ||
			(frag_deathtype == DEATH_LAVA))
		{
			frag_damage = 0;
		}
		
		if (frag_target.armorvalue && (frag_deathtype == WEP_MINSTANEX) && frag_damage)
		{
			frag_target.armorvalue -= 1;
			centerprint(frag_target, strcat("^3Remaining extra lives: ",ftos(frag_target.armorvalue)));
			frag_damage = 0;
			frag_target.hitsound += 1;
			frag_attacker.hitsound += 1; // TODO change this to a future specific hitsound for armor hit
		}
		if (DEATH_ISWEAPON(frag_deathtype, WEP_LASER))
		{
			frag_damage = 0;
			frag_mirrordamage = 0;
			if (frag_target != frag_attacker)
			{
				if ((frag_target.health >= 1) && (frag_target.classname == "player"))
					centerprint(frag_attacker, "Secondary fire inflicts no damage!");
				frag_force = '0 0 0';
				// keep mirrorfrag_force
				frag_attacker = frag_target;
			}
		}
	}
	
	if(frag_mirrordamage > 0)
	{
		// just lose extra LIVES, don't kill the player for mirror damage
		if(frag_attacker.armorvalue > 0)
		{
			frag_attacker.armorvalue = frag_attacker.armorvalue - 1;
			centerprint(frag_attacker, strcat("^3Remaining extra lives: ", ftos(frag_attacker.armorvalue)));
			frag_attacker.hitsound += 1;
		}
		frag_mirrordamage = 0;
	}
	
	if(frag_target.items & IT_STRENGTH)
		yoda = 1;
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_SetStartItems)
{
	start_ammo_cells = cvar("g_minstagib_ammo_start");
	
	g_pinata = 0; // incompatible
	g_weapon_stay = 0; // incompatible
	g_bloodloss = 0; // incompatible
	start_health = 100;
	start_armorvalue = 0;
	WEPSET_COPY_AW(start_weapons, WEP_MINSTANEX);
	g_minstagib_invis_alpha = cvar("g_minstagib_invis_alpha");
	start_items |= IT_UNLIMITED_SUPERWEAPONS;

	if (g_minstagib_invis_alpha <= 0)
		g_minstagib_invis_alpha = -1;
		
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_FilterItem)
{
	if(self.weapon == -2)
		return FALSE;
		
	if(self.classname == "item_minst_cells" || self.weapon == WEP_ROCKET_LAUNCHER || self.weapon == WEP_NEX)
	{
		self.ammo_cells = autocvar_g_minstagib_ammo_drop;
		StartItem ("models/items/a_cells.md3",
			"misc/itempickup.wav", 45, 0,
			"MinstaNex Ammo", IT_CELLS, -2, 0, generic_pickupevalfunc, 100);
		return FALSE;
	}
		
	if(self.flags & FL_POWERUP)
	{
		// randomize
		float rnd = random() * 3;
		if (rnd <= 1)
			self.items = IT_STRENGTH;
		else if (rnd <= 2)
			self.items = IT_NAILS;
		else
			self.items = IT_INVINCIBLE;
		
		if (self.items == IT_STRENGTH)
		{
			if(!self.strength_finished)
				self.strength_finished = autocvar_g_balance_powerup_strength_time;
			StartItem ("models/items/g_strength.md3",
				"misc/powerup.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
				"Invisibility", IT_STRENGTH, -2, FL_POWERUP, generic_pickupevalfunc, BOT_PICKUP_RATING_MID);
		}
		// replace with extra lives
		else if (self.items == IT_NAILS)
		{
			self.max_health = 1;
			StartItem ("models/items/g_h100.md3",
				"misc/megahealth.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
				"Extralife", IT_NAILS, -2, FL_POWERUP, generic_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
		}
		// replace with speed
		else if (self.items == IT_INVINCIBLE)
		{
			if(!self.invincible_finished)
				self.invincible_finished = autocvar_g_balance_powerup_invincible_time;
			StartItem ("models/items/g_invincible.md3",
				"misc/powerup_shield.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
				"Speed", IT_INVINCIBLE, -2, FL_POWERUP, generic_pickupevalfunc, BOT_PICKUP_RATING_MID);
		}
		return FALSE;
	}
		
	return TRUE;
}

MUTATOR_HOOKFUNCTION(minstagib_ItemCountdown)
{
	switch(self.items)
	{
		case IT_STRENGTH:   item_name = "item-invis"; item_color = '0 0 1'; break;
		case IT_NAILS:      item_name = "item-extralife"; item_color = '1 0 0'; break;
		case IT_INVINCIBLE: item_name = "item-speed"; item_color = '1 0 1'; break;
	}
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_GiveItem)
{
	float it;
	float prevcells = giveplayer.ammo_cells;
	
	player_pickedup |= Item_GiveAmmoTo(giveitem, giveplayer, ammo_fuel, g_pickup_fuel_max, ITEM_MODE_FUEL);
	player_pickedup |= Item_GiveAmmoTo(giveitem, giveplayer, ammo_cells, 999, ITEM_MODE_NONE);

	if(giveplayer.ammo_cells > prevcells)
	{
		player_wswitch = TRUE;
		// play some cool sounds ;)
		if (clienttype(giveplayer) == CLIENTTYPE_REAL)
		{
			if(giveplayer.health <= 5)
				AnnounceTo(giveplayer, "lastsecond");
			else if(giveplayer.health < 50)
				AnnounceTo(giveplayer, "narrowly");
		}

		if (WEPSET_CONTAINS_EW(giveitem, WEP_MINSTANEX))
			W_GiveWeapon (giveplayer, WEP_MINSTANEX, giveitem.netname);
		giveplayer.health = 100;
	}

	if((it = (giveitem.items - (giveitem.items & giveplayer.items)) & IT_PICKUPMASK))
	{
		player_pickedup = TRUE;
		giveplayer.items |= it;
		sprint (giveplayer, strcat("You got the ^2", giveitem.netname, "\n"));
	}

	// extralife powerup
	if (giveitem.max_health)
	{
		player_pickedup = TRUE;
		// sound not available
		// AnnounceTo(giveplayer, "_lives");
		giveplayer.armorvalue = bound(giveplayer.armorvalue, 999, giveplayer.armorvalue + autocvar_g_minstagib_extralives);
		sprint(giveplayer, "^3You picked up some extra lives\n");
	}

	// invis powerup
	if (giveitem.strength_finished)
	{
		player_pickedup = TRUE;
		// sound not available
		// AnnounceTo(giveplayer, "invisible");
		giveplayer.strength_finished = max(giveplayer.strength_finished, time) + autocvar_g_balance_powerup_strength_time;
	}

	// speed powerup
	if (giveitem.invincible_finished)
	{
		player_pickedup = TRUE;
		// sound not available
		// AnnounceTo(giveplayer, "speed");
		giveplayer.invincible_finished = max(giveplayer.invincible_finished, time) + autocvar_g_balance_powerup_invincible_time;
	}
		
	return TRUE;
}

MUTATOR_HOOKFUNCTION(minstagib_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":MinstaGib");
	return FALSE;
}

MUTATOR_HOOKFUNCTION(minstagib_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", MinstaGib");
	return FALSE;
}

MUTATOR_DEFINITION(mutator_minstagib)
{
	MUTATOR_HOOK(BotShouldAttack, minstagib_BotShouldAttack, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPhysics, minstagib_PlayerPhysics, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, minstagib_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, minstagib_PlayerDamage, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayStrengthSound, minstagib_PlayStrengthSound, CBC_ORDER_ANY);
	MUTATOR_HOOK(MakePlayerObserver, minstagib_MakePlayerObserver, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, minstagib_SetStartItems, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, minstagib_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(Item_RespawnCountdown, minstagib_ItemCountdown, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_SplitHealthArmor, minstagib_SplitHealthArmor, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPowerups, minstagib_PlayerPowerups, CBC_ORDER_ANY);
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, minstagib_ForbidThrowing, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, minstagib_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, minstagib_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, minstagib_BuildMutatorsPrettyString, CBC_ORDER_ANY);

	return FALSE;
}
