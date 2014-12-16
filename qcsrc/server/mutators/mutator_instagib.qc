void spawnfunc_item_minst_cells (void)
{
	if (!g_instagib) { remove(self); return; }
	if (!self.ammo_cells)
		self.ammo_cells = autocvar_g_instagib_ammo_drop;

	StartItem ("models/items/a_cells.md3",
			   "misc/itempickup.wav", 45, 0,
			   "Vaporizer Ammo", IT_CELLS, 0, 0, generic_pickupevalfunc, 100);
}

void instagib_health_mega()
{
	self.max_health = 1;
	StartItem ("models/items/g_h100.md3",
			   "misc/megahealth.wav", g_pickup_respawntime_powerup, g_pickup_respawntimejitter_powerup,
			   "Extralife", IT_NAILS, 0, FL_POWERUP, generic_pickupevalfunc, BOT_PICKUP_RATING_HIGH);
}

.float instagib_nextthink;
.float instagib_needammo;
void instagib_stop_countdown(entity e)
{
	if (!e.instagib_needammo)
		return;
	Kill_Notification(NOTIF_ONE_ONLY, e, MSG_CENTER_CPID, CPID_INSTAGIB_FINDAMMO);
	e.instagib_needammo = FALSE;
}
void instagib_ammocheck()
{
	if(time < self.instagib_nextthink)
		return;
	if(!IS_PLAYER(self))
		return; // not a player

	if(self.deadflag || gameover)
		instagib_stop_countdown(self);
	else if (self.ammo_cells > 0 || (self.items & IT_UNLIMITED_WEAPON_AMMO) || (self.flags & FL_GODMODE))
		instagib_stop_countdown(self);
	else
	{
		self.instagib_needammo = TRUE;
		if (self.health <= 5)
		{
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_INSTAGIB_TERMINATED);
		}
		else if (self.health <= 10)
		{
			Damage(self, self, self, 5, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_1);
		}
		else if (self.health <= 20)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_2);
		}
		else if (self.health <= 30)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_3);
		}
		else if (self.health <= 40)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_4);
		}
		else if (self.health <= 50)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_5);
		}
		else if (self.health <= 60)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_6);
		}
		else if (self.health <= 70)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_7);
		}
		else if (self.health <= 80)
		{
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_8);
		}
		else if (self.health <= 90)
		{
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_CENTER, CENTER_INSTAGIB_FINDAMMO);
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
			Send_Notification(NOTIF_ONE, self, MSG_ANNCE, ANNCE_NUM_9);
		}
		else
		{
			Send_Notification(NOTIF_ONE_ONLY, self, MSG_MULTI, MULTI_INSTAGIB_FINDAMMO);
			Damage(self, self, self, 10, DEATH_NOAMMO, self.origin, '0 0 0');
		}
	}
	self.instagib_nextthink = time + 1;
}

MUTATOR_HOOKFUNCTION(instagib_MatchEnd)
{
	entity head;
	FOR_EACH_PLAYER(head)
		instagib_stop_countdown(head);

	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_MonsterLoot)
{
	other.monster_loot = spawnfunc_item_minst_cells;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_MonsterSpawn)
{
	// always refill ammo
	if(self.monsterid == MON_MAGE)
		self.skin = 1;
	
	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_BotShouldAttack)
{
	if(checkentity.items & IT_STRENGTH)
		return TRUE;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_MakePlayerObserver)
{
	instagib_stop_countdown(self);
	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_PlayerSpawn)
{
	self.effects |= EF_FULLBRIGHT;
	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_PlayerPreThink)
{
	instagib_ammocheck();
	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_PlayerRegen)
{
	// no regeneration in instagib
	return TRUE;
}

MUTATOR_HOOKFUNCTION(instagib_PlayerPowerups)
{
	if (!(self.effects & EF_FULLBRIGHT))
		self.effects |= EF_FULLBRIGHT;

	if (self.items & IT_STRENGTH)
	{
		play_countdown(self.strength_finished, "misc/poweroff.wav");
		if (time > self.strength_finished)
		{
			self.alpha = default_player_alpha;
			self.exteriorweaponentity.alpha = default_weapon_alpha;
			self.items &= ~IT_STRENGTH;
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERDOWN_INVISIBILITY);
		}
	}
	else
	{
		if (time < self.strength_finished)
		{
			self.alpha = autocvar_g_instagib_invis_alpha;
			self.exteriorweaponentity.alpha = autocvar_g_instagib_invis_alpha;
			self.items |= IT_STRENGTH;
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_POWERUP_INVISIBILITY, self.netname);
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERUP_INVISIBILITY);
		}
	}

	if (self.items & IT_INVINCIBLE)
	{
		play_countdown(self.invincible_finished, "misc/poweroff.wav");
		if (time > self.invincible_finished)
		{
			self.items &= ~IT_INVINCIBLE;
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERDOWN_SPEED);
		}
	}
	else
	{
		if (time < self.invincible_finished)
		{
			self.items |= IT_INVINCIBLE;
			Send_Notification(NOTIF_ALL, world, MSG_INFO, INFO_POWERUP_SPEED, self.netname);
			Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_POWERUP_SPEED);
		}
	}
	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_PlayerPhysics)
{
	if(self.items & IT_INVINCIBLE)
		self.stat_sv_maxspeed = self.stat_sv_maxspeed * autocvar_g_instagib_speed_highspeed;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_SplitHealthArmor)
{
	damage_save = 0;
	damage_take = frag_damage;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_ForbidThrowing)
{
	// weapon dropping on death handled by FilterItem

	return TRUE;
}

MUTATOR_HOOKFUNCTION(instagib_PlayerDamage)
{
	if(autocvar_g_friendlyfire == 0 && SAME_TEAM(frag_target, frag_attacker) && IS_PLAYER(frag_target) && IS_PLAYER(frag_attacker))
		frag_damage = 0;

	if(IS_PLAYER(frag_target))
	{
		if ((frag_deathtype == DEATH_FALL)  ||
			(frag_deathtype == DEATH_DROWN) ||
			(frag_deathtype == DEATH_SLIME) ||
			(frag_deathtype == DEATH_LAVA))
		{
			frag_damage = 0;
		}

		if(IS_PLAYER(frag_attacker))
		if(DEATH_ISWEAPON(frag_deathtype, WEP_VAPORIZER))
		{
			if(frag_deathtype & HITTYPE_SECONDARY)
			{
				frag_damage = frag_mirrordamage = 0;
				
				if(frag_target != frag_attacker)
				{
					if(frag_target.health > 0) { Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_SECONDARY_NODAMAGE); }
					frag_force = '0 0 0';
				}
			}
			else if(frag_target.armorvalue)
			{
				frag_target.armorvalue -= 1;
				frag_damage = 0;
				frag_target.damage_dealt += 1;
				frag_attacker.damage_dealt += 1; // TODO: change this to a specific hitsound for armor hit
				Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_INSTAGIB_LIVES_REMAINING, frag_target.armorvalue);
			}
		}
	}

	if(IS_PLAYER(frag_attacker))
	if(frag_mirrordamage > 0)
	{
		// just lose extra LIVES, don't kill the player for mirror damage
		if(frag_attacker.armorvalue > 0)
		{
			frag_attacker.armorvalue -= 1;
			Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_INSTAGIB_LIVES_REMAINING, frag_attacker.armorvalue);
			frag_attacker.damage_dealt += 1;
		}
		frag_mirrordamage = 0;
	}

	if(frag_target.items & IT_STRENGTH)
		yoda = 1;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_SetStartItems)
{
	start_health       = warmup_start_health       = 100;
	start_armorvalue   = warmup_start_armorvalue   = 0;

	start_ammo_shells  = warmup_start_ammo_shells  = 0;
	start_ammo_nails   = warmup_start_ammo_nails   = 0;
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_instagib_ammo_start");
	start_ammo_plasma  = warmup_start_ammo_plasma  = 0;
	start_ammo_rockets = warmup_start_ammo_rockets = 0;
	start_ammo_fuel    = warmup_start_ammo_fuel    = 0;

	start_weapons = warmup_start_weapons = WEPSET_VAPORIZER;
	start_items |= IT_UNLIMITED_SUPERWEAPONS;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_FilterItem)
{
	if(self.classname == "item_cells")
		return TRUE; // no normal cells?

	if(self.weapon == WEP_VAPORIZER && self.classname == "droppedweapon")
	{
		self.ammo_cells = autocvar_g_instagib_ammo_drop;
		return FALSE;
	}

	if(self.weapon == WEP_DEVASTATOR || self.weapon == WEP_VORTEX)
	{
		entity e = spawn();
		setorigin(e, self.origin);
		entity oldself;
		oldself = self;
		self = e;
		spawnfunc_item_minst_cells();
		self = oldself;
		return TRUE;
	}

	if(self.flags & FL_POWERUP)
		return FALSE;

	if(self.ammo_cells > autocvar_g_instagib_ammo_drop && self.classname != "item_minst_cells")
		self.ammo_cells = autocvar_g_instagib_ammo_drop;

	if(self.ammo_cells && !self.weapon)
		return FALSE;

	return TRUE;
}

MUTATOR_HOOKFUNCTION(instagib_CustomizeWaypoint)
{
	entity e = WaypointSprite_getviewentity(other);

	// if you have the invisibility powerup, sprites ALWAYS are restricted to your team
	// but only apply this to real players, not to spectators
	if((self.owner.flags & FL_CLIENT) && (self.owner.items & IT_STRENGTH) && (e == other))
	if(DIFF_TEAM(self.owner, e))
		return TRUE;

	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_ItemCountdown)
{
	switch(self.items)
	{
		case IT_STRENGTH:   item_name = "item-invis"; item_color = '0 0 1'; break;
		case IT_NAILS:      item_name = "item-extralife"; item_color = '1 0 0'; break;
		case IT_INVINCIBLE: item_name = "item-speed"; item_color = '1 0 1'; break;
	}
	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_ItemTouch)
{
	if(self.ammo_cells)
	{
		// play some cool sounds ;)
		if (IS_CLIENT(other))
		{
			if(other.health <= 5)
				Send_Notification(NOTIF_ONE, other, MSG_ANNCE, ANNCE_INSTAGIB_LASTSECOND);
			else if(other.health < 50)
				Send_Notification(NOTIF_ONE, other, MSG_ANNCE, ANNCE_INSTAGIB_NARROWLY);
		}

		if(other.health < 100)
			other.health = 100;

		return MUT_ITEMTOUCH_CONTINUE;
	}

	if(self.max_health)
	{
		other.armorvalue = bound(other.armorvalue, 999, other.armorvalue + autocvar_g_instagib_extralives);
		Send_Notification(NOTIF_ONE, other, MSG_CENTER, CENTER_EXTRALIVES);
		return MUT_ITEMTOUCH_PICKUP;
	}

	return MUT_ITEMTOUCH_CONTINUE;
}

MUTATOR_HOOKFUNCTION(instagib_OnEntityPreSpawn)
{
	if (!autocvar_g_powerups) { return FALSE; }
	if (!(self.classname == "item_strength" || self.classname == "item_invincible" || self.classname == "item_health_mega"))
		return FALSE;

	entity e = spawn();

	if(random() < 0.3)
		e.think = spawnfunc_item_strength;
	else if(random() < 0.6)
		e.think = instagib_health_mega;
	else
		e.think = spawnfunc_item_invincible;

	e.nextthink = time + 0.1;
	e.spawnflags = self.spawnflags;
	e.noalign = self.noalign;
	setorigin(e, self.origin);

	return TRUE;
}

MUTATOR_HOOKFUNCTION(instagib_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":instagib");
	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", instagib");
	return FALSE;
}

MUTATOR_HOOKFUNCTION(instagib_SetModname)
{
	modname = "instagib";
	return TRUE;
}

MUTATOR_DEFINITION(mutator_instagib)
{
	MUTATOR_HOOK(MatchEnd, instagib_MatchEnd, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterDropItem, instagib_MonsterLoot, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterSpawn, instagib_MonsterSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(BotShouldAttack, instagib_BotShouldAttack, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPhysics, instagib_PlayerPhysics, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, instagib_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, instagib_PlayerDamage, CBC_ORDER_ANY);
	MUTATOR_HOOK(MakePlayerObserver, instagib_MakePlayerObserver, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, instagib_SetStartItems, CBC_ORDER_ANY);
	MUTATOR_HOOK(ItemTouch, instagib_ItemTouch, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, instagib_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(CustomizeWaypoint, instagib_CustomizeWaypoint, CBC_ORDER_ANY);
	MUTATOR_HOOK(Item_RespawnCountdown, instagib_ItemCountdown, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_SplitHealthArmor, instagib_SplitHealthArmor, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPowerups, instagib_PlayerPowerups, CBC_ORDER_ANY);
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, instagib_ForbidThrowing, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, instagib_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerRegen, instagib_PlayerRegen, CBC_ORDER_ANY);
	MUTATOR_HOOK(OnEntityPreSpawn, instagib_OnEntityPreSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, instagib_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, instagib_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetModname, instagib_SetModname, CBC_ORDER_ANY);

	return FALSE;
}
