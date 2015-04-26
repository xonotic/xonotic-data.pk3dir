float za_spawn_delay;

void za_SpawnMonster()
{
	if(gameover) { return; }

	entity e = spawn(), mon;

	if(MoveToRandomMapLocation(e, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, 10, 1024, 256))
		mon = spawnmonster(autocvar_g_za_spawnmonster, 0, self, self, e.origin, false, false, 2);

	e.think = SUB_Remove;
	e.nextthink = time + 0.1;
}

.vector za_viewofs;

void za_SetEnemy(entity player)
{
	entity head;
	entity closest_targ = world;
	FOR_EACH_PLAYER(head) if(head != player)
	if(vlen(head.origin - player.origin) < autocvar_g_monsters_target_range)
	if(!closest_targ || vlen(closest_targ.origin - player.origin) > vlen(head.origin - player.origin))
		closest_targ = head;

	if(!closest_targ)
	{
		FOR_EACH_MONSTER(head)
		if(vlen(head.origin - player.origin) < autocvar_g_monsters_target_range)
		if(!closest_targ || vlen(closest_targ.origin - player.origin) > vlen(head.origin - player.origin))
			closest_targ = head;
	}

	if(closest_targ)
		player.enemy = closest_targ;
}

MUTATOR_HOOKFUNCTION(za_FixPlayermodel)
{
	if(self.monsterid)
		ret_string = (get_monsterinfo(self.monsterid)).model;
	return false;
}

MUTATOR_HOOKFUNCTION(za_PlayerPhysics)
{
	if(!self.monsterid) { return false; }

	entity mon = get_monsterinfo(self.monsterid);

	self.weapons = '0 0 0';
	self.switchweapon = 0;
	self.stat_pl_min = mon.mins;
	self.stat_pl_max = mon.maxs;
	self.stat_pl_crouch_min = mon.mins;
	self.stat_pl_crouch_max = mon.maxs;
	self.stat_pl_crouch_view_ofs = self.za_viewofs;
	self.stat_pl_view_ofs = self.za_viewofs;
	self.stat_sv_jumpvelocity = 0;

	self.stat_sv_maxspeed = self.speed2;
	self.stat_sv_maxairspeed = self.speed2;
	self.BUTTON_CROUCH = false;

	return false;
}

MUTATOR_HOOKFUNCTION(za_PlayerThink)
{
	if(!self.monsterid || time < self.attack_finished_single) { return false; }

	MON_ACTION(self.monsterid, MR_THINK);

	if(self.BUTTON_ATCK)
	if(self.monster_attackfunc)
	{
		za_SetEnemy(self);
		if(self.monster_attackfunc(MONSTER_ATTACK_MELEE))
			animdecide_setaction(self, ANIMACTION_MELEE, false);
	}

	if(self.BUTTON_ATCK2)
	if(self.monster_attackfunc)
	{
		za_SetEnemy(self);
		if(self.monster_attackfunc(MONSTER_ATTACK_RANGED))
			animdecide_setaction(self, ANIMACTION_SHOOT, false);
	}

	return false;
}

MUTATOR_HOOKFUNCTION(za_ItemTouch)
{
	if(other.monsterid)
		return MUT_ITEMTOUCH_RETURN;

	return false;
}

MUTATOR_HOOKFUNCTION(za_PlayerDies)
{
	if(!autocvar_g_za_infect) { return false; }

	if(!IS_MONSTER(frag_attacker))
	{
		self.monsterid = 0;
		return false;
	}

	entity mon = get_monsterinfo(frag_attacker.monsterid);

	self.monsterid = frag_attacker.monsterid;
	self.health = frag_attacker.max_health;
	self.weapons = '0 0 0';
	self.switchweapon = 0;
	self.stat_pl_min = mon.mins;
	self.stat_pl_max = mon.maxs;
	self.stat_pl_crouch_min = mon.mins;
	self.stat_pl_crouch_max = mon.maxs;
	self.monster_attack = false;
	self.speed = frag_attacker.speed;
	self.speed2 = frag_attacker.speed2;
	self.stopspeed = frag_attacker.stopspeed;
	self.view_ofs = self.za_viewofs = frag_attacker.view_ofs;
	self.attack_range = ((frag_attacker.attack_range) ? frag_attacker.attack_range : 150);
	//self.attack_range = frag_attacker.attack_range;
	self.monster_attackfunc = mon.monster_attackfunc;
	setsize(self, frag_attacker.mins, frag_attacker.maxs);

	return false;
}

MUTATOR_HOOKFUNCTION(za_StartFrame)
{
	if(time < za_spawn_delay || autocvar_g_za_max_monsters <= 0 || !autocvar_g_za)
		return false;

	float n_monsters = 0, maxmon = autocvar_g_za_max_monsters;
	entity head;

	// count dead monsters too (zombies)
	FOR_EACH_MONSTER(head) ++n_monsters;

	while(n_monsters < maxmon)
	{
		++n_monsters;
		za_SpawnMonster();
	}

	za_spawn_delay = time + autocvar_g_za_spawn_delay;

	return false;
}

MUTATOR_DEFINITION(mutator_zombie_apocalypse)
{
	MUTATOR_HOOK(FixPlayermodel, za_FixPlayermodel, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPhysics, za_PlayerPhysics, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, za_PlayerThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(ItemTouch, za_ItemTouch, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, za_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(SV_StartFrame, za_StartFrame, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		za_spawn_delay = time + game_starttime;
	}

	return false;
}
