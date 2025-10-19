#include "minelayer.qh"

#ifdef SVQC

void W_MineLayer_Stick(entity this, entity to)
{
	spamsound(this, CH_SHOTS, SND_MINE_STICK, VOL_BASE, ATTN_NORM);

	// in order for mines to face properly when sticking to the ground, they must be a server side entity rather than a csqc projectile

	entity newmine = spawn();
	IL_PUSH(g_mines, newmine);
	newmine.weaponentity_fld = this.weaponentity_fld;
	newmine.classname = this.classname;

	newmine.bot_dodge = this.bot_dodge;
	newmine.bot_dodgerating = this.bot_dodgerating;

	newmine.owner = this.owner;
	newmine.realowner = this.realowner;
	newmine.glowmod = colormapPaletteColor(this.realowner.clientcolors & 0x0F, true);

	PROJECTILE_MAKETRIGGER(newmine);
	setorigin(newmine, this.origin);
	setmodel(newmine, MDL_MINELAYER_MINE);
	setsize(newmine, '-4 -4 -4', '4 4 4');
	newmine.angles = vectoangles(-trace_plane_normal); // face against the surface

	newmine.movedir = -trace_plane_normal;

	newmine.takedamage = this.takedamage;
	newmine.damageforcescale = this.damageforcescale;
	SetResourceExplicit(newmine, RES_HEALTH, GetResource(this, RES_HEALTH));
	newmine.event_damage = this.event_damage;
	newmine.spawnshieldtime = this.spawnshieldtime;
	newmine.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, newmine);

	set_movetype(newmine, MOVETYPE_NONE); // lock the mine in place
	newmine.projectiledeathtype = this.projectiledeathtype;

	newmine.mine_time = this.mine_time;

	settouch(newmine, func_null);
	setthink(newmine, W_MineLayer_Think);
	newmine.nextthink = time;
	newmine.cnt = this.cnt;
	newmine.flags = this.flags;
	IL_PUSH(g_projectiles, newmine);
	IL_PUSH(g_bot_dodge, newmine);

	delete(this);

	if(to)
		SetMovetypeFollow(newmine, to);
}

void W_MineLayer_Explode(entity this, entity directhitentity)
{
	if(directhitentity.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(directhitentity))
			if(DIFF_TEAM(this.realowner, directhitentity))
				if(!IS_DEAD(directhitentity))
					if(IsFlying(directhitentity))
						Send_Notification(NOTIF_ONE, this.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_AIRSHOT);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	RadiusDamage(this, this.realowner, WEP_CVAR(WEP_MINE_LAYER, damage), WEP_CVAR(WEP_MINE_LAYER, edgedamage), WEP_CVAR(WEP_MINE_LAYER, radius), NULL, NULL, WEP_CVAR(WEP_MINE_LAYER, force), this.projectiledeathtype, this.weaponentity_fld, directhitentity);

	.entity weaponentity = this.weaponentity_fld;
	Weapon thiswep = WEP_MINE_LAYER;
	if(this.realowner.(weaponentity).m_weapon == thiswep)
	{
		entity own = this.realowner;
		if(!thiswep.wr_checkammo1(thiswep, own, weaponentity))
		if(!(own.items & IT_UNLIMITED_AMMO))
		{
			own.cnt = thiswep.m_id;
			ATTACK_FINISHED(own, weaponentity) = time;
			own.(weaponentity).m_switchweapon = w_getbestweapon(own, weaponentity);
		}
	}
	delete(this);
}

void W_MineLayer_Explode_think(entity this)
{
	W_MineLayer_Explode(this, NULL);
}

void W_MineLayer_DoRemoteExplode(entity this)
{
	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;

	if(this.move_movetype == MOVETYPE_NONE || this.move_movetype == MOVETYPE_FOLLOW)
		this.velocity = this.movedir; // .velocity must be != '0 0 0' for particle fx and decal to work

	RadiusDamage(this, this.realowner, WEP_CVAR(WEP_MINE_LAYER, remote_damage), WEP_CVAR(WEP_MINE_LAYER, remote_edgedamage), WEP_CVAR(WEP_MINE_LAYER, remote_radius),
						NULL, NULL, WEP_CVAR(WEP_MINE_LAYER, remote_force), this.projectiledeathtype | HITTYPE_BOUNCE, this.weaponentity_fld, NULL);

	.entity weaponentity = this.weaponentity_fld;
	Weapon thiswep = WEP_MINE_LAYER;
	if(this.realowner.(weaponentity).m_weapon == thiswep)
	{
		entity own = this.realowner;
		if(!thiswep.wr_checkammo1(thiswep, own, weaponentity))
		if(!(own.items & IT_UNLIMITED_AMMO))
		{
			own.cnt = thiswep.m_id;
			ATTACK_FINISHED(own, weaponentity) = time;
			own.(weaponentity).m_switchweapon = w_getbestweapon(own, weaponentity);
		}
	}
	delete(this);
}

void W_MineLayer_RemoteExplode(entity this)
{
	if(IS_DEAD(this.realowner))
		return;

	if(this.spawnshieldtime >= 0)
	{
		if(time < this.spawnshieldtime) // timer
			return;
	}
	else
	{
		/* make sure no friend is in the mine's radius.
		 * WEAPONTODO: modify protection cvar to allow disabling remote detonation protection.
		 * disabling it currently allows Mine Layer-flying, even more powerful than rocket-flying
		 * ... even without Rocket Flying mutator enabled
		 */
		entity head = WarpZone_FindRadius(this.origin, WEP_CVAR(WEP_MINE_LAYER, remote_radius), false);
		while(head)
		{
			if(SAME_TEAM(head, this.realowner))
				return;
			head = head.chain;
		}
	}

	W_MineLayer_DoRemoteExplode(this);
}

void W_MineLayer_ProximityExplode(entity this)
{
	// make sure no friend is in the mine's radius. If there is any, explosion is delayed until they're at a safe distance
	if(WEP_CVAR(WEP_MINE_LAYER, protection) && this.mine_explodeanyway == 0)
	{
		entity head = WarpZone_FindRadius(this.origin, WEP_CVAR(WEP_MINE_LAYER, radius), false);
		while(head)
		{
			if(SAME_TEAM(head, this.realowner))
				return;
			head = head.chain;
		}
	}

	this.mine_time = 0;
	W_MineLayer_Explode(this, NULL);
}

int W_MineLayer_Count(entity e, .entity weaponentity)
{
	int minecount = 0;
	IL_EACH(g_mines, it.realowner == e && it.weaponentity_fld == weaponentity,
	{
		minecount += 1;
	});

	return minecount;
}

void W_MineLayer_Think(entity this)
{
	entity head;

	this.nextthink = time;

	if(this.move_movetype == MOVETYPE_FOLLOW)
	{
		if(LostMovetypeFollow(this))
		{
			UnsetMovetypeFollow(this);
			set_movetype(this, MOVETYPE_NONE);
		}
	}

	// our lifetime has expired, it's time to die - mine_time just allows us to play a sound for this
	// TODO: replace this mine_trigger.wav sound with a real countdown
	if((time > this.cnt) && (!this.mine_time) && (this.cnt > 0))
	{
		if(WEP_CVAR(WEP_MINE_LAYER, lifetime_countdown) > 0)
			spamsound(this, CH_SHOTS, SND_MINE_TRIGGER, VOL_BASE, ATTN_NORM);
		this.mine_time = time + WEP_CVAR(WEP_MINE_LAYER, lifetime_countdown);
		this.mine_explodeanyway = 1; // make the mine super aggressive -- Samual: Rather, make it not care if a teammate is near.
	}

	// a player's mines shall explode if they disconnect or die
	if(!IS_PLAYER(this.realowner) || IS_DEAD(this.realowner) || STAT(FROZEN, this.realowner))
	{
		this.projectiledeathtype |= HITTYPE_BOUNCE;
		W_MineLayer_Explode(this, NULL);
		return;
	}

	// set the mine for detonation when a foe gets close enough
	float time_core = WEP_CVAR(WEP_MINE_LAYER, proximity_time_core);
	float time_edge = WEP_CVAR(WEP_MINE_LAYER, proximity_time_edge);
	float proxrad = WEP_CVAR(WEP_MINE_LAYER, proximity_radius);
	head = WarpZone_FindRadius(this.origin, proxrad, false);
	while(head)
	{
		if(IS_PLAYER(head) && !IS_DEAD(head) && !STAT(FROZEN, head) && !IS_INDEPENDENT_PLAYER(head))
		if(DIFF_TEAM(head, this.realowner)) // don't trigger for teammates
		{
			if(!this.mine_time) // don't repeat the sound
				spamsound(this, CH_SHOTS, SND_MINE_TRIGGER, VOL_BASE, ATTN_NORM);
			// scale from time_edge to time_core based on how close the player is to the mine
			float new_mine_time = time + time_core;
			if(time_edge != time_core)
				new_mine_time += (time_edge - time_core) * vlen(head.WarpZone_findradius_dist) / proxrad;
			if((!this.mine_time) || this.mine_time > new_mine_time) // choose the earliest explosion time
				this.mine_time = new_mine_time;
		}
		head = head.chain;
	}

	// explode if it's time to
	if(this.mine_time && time >= this.mine_time)
	{
		W_MineLayer_ProximityExplode(this);
		return;
	}

	// remote detonation
	.entity weaponentity = this.weaponentity_fld;
	if(this.realowner.(weaponentity).m_weapon == WEP_MINE_LAYER)
	if(!IS_DEAD(this.realowner))
	if(this.minelayer_detonate)
		W_MineLayer_RemoteExplode(this);
}

void W_MineLayer_Touch(entity this, entity toucher)
{
	if(this.move_movetype == MOVETYPE_NONE || this.move_movetype == MOVETYPE_FOLLOW)
		return; // we're already a stuck mine, why do we get called? TODO does this even happen?
	if(time <= this.wait)
		return; // don't reattach yet

	PROJECTILE_TOUCH(this, toucher);

	if (toucher.solid == SOLID_BSP)
		W_MineLayer_Stick(this, toucher);
}

void W_MineLayer_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	// Reading the cvar here because this.damageforcescale is overridden in blaster.qc
	// this way the blaster can hit mines midair but can only detach them when enabled by this cvar.
	if (WEP_CVAR(WEP_MINE_LAYER, damageforcescale) && inflictor.classname != "mine")
	{
		set_movetype(this, MOVETYPE_BOUNCE); // not TOSS: so a direct perpendicular hit can move the mine
		this.wait = time + 0.0625; // after this time it will reattach instead of bouncing
		settouch(this, W_MineLayer_Touch);
		this.avelocity = this.velocity += force * WEP_CVAR(WEP_MINE_LAYER, damageforcescale);
	}

	float is_from_enemy = (inflictor.realowner != this.realowner);

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, (is_from_enemy ? 1 : -1)))
		return; // g_projectiles_damage says to halt

	TakeResource(this, RES_HEALTH, damage);
	this.angles = vectoangles(this.velocity);

	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, attacker, W_MineLayer_Explode_think);
}

void W_MineLayer_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	// scan how many mines we placed, and return if we reached our limit
	if(WEP_CVAR(WEP_MINE_LAYER, limit))
	{
		int minecount = W_MineLayer_Count(actor, weaponentity);
		if(minecount >= WEP_CVAR(WEP_MINE_LAYER, limit))
		{
			// the refire delay keeps this message from being spammed
			Send_Notification(NOTIF_ONE, actor, MSG_MULTI, WEAPON_MINELAYER_LIMIT, WEP_CVAR(WEP_MINE_LAYER, limit));
			play2(actor, SND(UNAVAILABLE));
			return;
		}
	}

	W_DecreaseAmmo(thiswep, actor, WEP_CVAR(WEP_MINE_LAYER, ammo), weaponentity);

	W_SetupShot_ProjectileSize(actor, weaponentity, '-4 -4 -4', '4 4 4', false, 5, SND_MINE_FIRE, CH_WEAPON_A, WEP_CVAR(WEP_MINE_LAYER, damage), thiswep.m_id);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, w_shotdir);

	entity mine = WarpZone_RefSys_SpawnSameRefSys(actor);
	mine.weaponentity_fld = weaponentity;
	IL_PUSH(g_mines, mine);
	mine.owner = mine.realowner = actor;
	if(WEP_CVAR(WEP_MINE_LAYER, detonatedelay) >= 0)
		mine.spawnshieldtime = time + WEP_CVAR(WEP_MINE_LAYER, detonatedelay);
	else
		mine.spawnshieldtime = -1;
	mine.classname = "mine";
	mine.bot_dodge = true;
	mine.bot_dodgerating = WEP_CVAR(WEP_MINE_LAYER, damage) * 2; // * 2 because it can detonate inflight which makes it even more dangerous

	mine.takedamage = DAMAGE_YES;
	mine.damageforcescale = WEP_CVAR(WEP_MINE_LAYER, damageforcescale);
	SetResourceExplicit(mine, RES_HEALTH, WEP_CVAR(WEP_MINE_LAYER, health));
	mine.event_damage = W_MineLayer_Damage;
	mine.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, mine);

	set_movetype(mine, MOVETYPE_TOSS);
	PROJECTILE_MAKETRIGGER(mine);
	mine.projectiledeathtype = thiswep.m_id;
	mine.weaponentity_fld = weaponentity;
	setsize(mine, '-4 -4 -4', '4 4 4'); // give it some size so it can be shot

	setorigin(mine, w_shotorg - v_forward * 4); // move it back so it hits the wall at the right point
	W_SetupProjVelocity_Basic(mine, WEP_CVAR(WEP_MINE_LAYER, speed), 0);
	mine.angles = vectoangles(mine.velocity);

	settouch(mine, W_MineLayer_Touch);
	setthink(mine, W_MineLayer_Think);
	mine.nextthink = time;
	mine.cnt = (WEP_CVAR(WEP_MINE_LAYER, lifetime) - WEP_CVAR(WEP_MINE_LAYER, lifetime_countdown));
	mine.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, mine);
	IL_PUSH(g_bot_dodge, mine);
	mine.missile_flags = MIF_SPLASH | MIF_ARC | MIF_PROXY;

	if(mine.cnt > 0) { mine.cnt += time; }

	CSQCProjectile(mine, true, PROJECTILE_MINE, true);

	// common properties

	MUTATOR_CALLHOOK(EditProjectile, actor, mine);
}

bool W_MineLayer_PlacedMines(entity this, .entity weaponentity, bool detonate)
{
	bool minfound = false;

	IL_EACH(g_mines, it.realowner == this && it.weaponentity_fld == weaponentity,
	{
		if(detonate)
		{
			if(!it.minelayer_detonate)
			{
				it.minelayer_detonate = true;
				minfound = true;
			}
		}
		else
			minfound = true;
	});
	return minfound;
}

METHOD(MineLayer, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	// aim and decide to fire if appropriate
	int minecount = W_MineLayer_Count(actor, weaponentity);
	if(minecount >= WEP_CVAR(WEP_MINE_LAYER, limit))
		PHYS_INPUT_BUTTON_ATCK(actor) = false;
	else
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, WEP_CVAR(WEP_MINE_LAYER, speed), 0, WEP_CVAR(WEP_MINE_LAYER, lifetime), false, false);
	if(skill >= 2) // skill 0 and 1 bots won't detonate mines!
	{
		// decide whether to detonate mines
		float edgedamage, coredamage, edgeradius, recipricoledgeradius;
		float selfdamage, teamdamage, enemydamage;
		edgedamage = WEP_CVAR(WEP_MINE_LAYER, edgedamage);
		coredamage = WEP_CVAR(WEP_MINE_LAYER, damage);
		edgeradius = WEP_CVAR(WEP_MINE_LAYER, radius);
		recipricoledgeradius = 1 / edgeradius;
		selfdamage = 0;
		teamdamage = 0;
		enemydamage = 0;

		IL_EACH(g_mines, it.realowner == actor,
		{
			entity mine = it;
			IL_EACH(g_bot_targets, it.bot_attack,
			{
				float d = vlen(it.origin + (it.mins + it.maxs) * 0.5 - mine.origin);
				d = bound(0, edgedamage + (coredamage - edgedamage) * sqrt(1 - d * recipricoledgeradius), 10000);
				// count potential damage according to type of target
				if(it == actor)
					selfdamage = selfdamage + d;
				else if(SAME_TEAM(it, actor))
					teamdamage = teamdamage + d;
				else if(bot_shouldattack(actor, it))
					enemydamage = enemydamage + d;
			});
		});

		float desirabledamage;
		desirabledamage = enemydamage;
		if(StatusEffects_active(STATUSEFFECT_Shield, actor) && !StatusEffects_active(STATUSEFFECT_SpawnShield, actor))
			desirabledamage = desirabledamage - selfdamage * autocvar_g_balance_selfdamagepercent;
		if(teamplay && actor.team)
			desirabledamage = desirabledamage - teamdamage;

		makevectors(actor.v_angle);
		IL_EACH(g_mines, it.realowner == actor,
		{
			if(skill > 9) // normal players only do this for the target they are tracking
			{
				entity mine = it;
				IL_EACH(g_bot_targets, it.bot_attack,
				{
					if((v_forward * normalize(mine.origin - it.origin) < 0.1)
						&& desirabledamage > 0.1 * coredamage
						) PHYS_INPUT_BUTTON_ATCK2(actor) = true;
				});
			}
			else
			{
				//As the distance gets larger, a correct detonation gets near imposible
				//Bots are assumed to use the mine spawnfunc_light to see if the mine gets near a player
				if((v_forward * normalize(it.origin - actor.enemy.origin) < 0.1)
					&& IS_PLAYER(actor.enemy)
					&& (desirabledamage >= 0.1 * coredamage)
					)
				{
					float distance = bound(300, vlen(actor.origin - actor.enemy.origin), 30000);
					if(random() / distance * 300 > frametime * bound(0, (10 - skill) * 0.2, 1))
						PHYS_INPUT_BUTTON_ATCK2(actor) = true;
				}
			}
		});

		// if we would be doing at X percent of the core damage, detonate it
		// but don't fire a new shot at the same time!
		if(desirabledamage >= 0.75 * coredamage) //this should do group damage in rare fortunate events
			PHYS_INPUT_BUTTON_ATCK2(actor) = true;
		if((skill > 6.5) && (selfdamage > GetResource(actor, RES_HEALTH)))
			PHYS_INPUT_BUTTON_ATCK2(actor) = false;
		//if(PHYS_INPUT_BUTTON_ATCK2(actor) == true)
		//	dprint(ftos(desirabledamage),"\n");
		if(PHYS_INPUT_BUTTON_ATCK2(actor)) PHYS_INPUT_BUTTON_ATCK(actor) = false;
	}
}

METHOD(MineLayer, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	actor.(weaponentity).minelayer_mines = W_MineLayer_Count(actor, weaponentity);

	if(autocvar_g_balance_minelayer_reload_ammo && actor.(weaponentity).clip_load < WEP_CVAR(WEP_MINE_LAYER, ammo)) // forced reload
	{
		// not if we're holding the minelayer without enough ammo, but can detonate existing mines
		bool enough_ammo = (GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_MINE_LAYER, ammo));
		if(actor.items & IT_UNLIMITED_AMMO)
			enough_ammo = true;
		if(!(W_MineLayer_PlacedMines(actor, weaponentity, false) && !enough_ammo)) {
			thiswep.wr_reload(thiswep, actor, weaponentity);
		}
	}
	else if(fire & 1)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR(WEP_MINE_LAYER, refire)))
		{
			W_MineLayer_Attack(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR(WEP_MINE_LAYER, animtime), w_ready);
		}
	}

	if(fire & 2)
	{
		if(W_MineLayer_PlacedMines(actor, weaponentity, true))
			sound(actor, CH_WEAPON_B, SND_MINE_DET, VOL_BASE, ATTN_NORM);
	}
}

METHOD(MineLayer, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	// actually do // don't switch while placing a mine
	//if(ATTACK_FINISHED(actor, weaponentity) <= time || PS(actor).m_weapon != WEP_MINE_LAYER)
	//{
		float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR(WEP_MINE_LAYER, ammo);
		ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR(WEP_MINE_LAYER, ammo);
		return ammo_amount;
	//}
	//return true;
}

METHOD(MineLayer, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	if(W_MineLayer_PlacedMines(actor, weaponentity, false))
		return true;
	else
		return false;
}

METHOD(MineLayer, wr_resetplayer, void(entity thiswep, entity actor))
{
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		actor.(weaponentity).minelayer_mines = 0;
	}
}

METHOD(MineLayer, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	W_Reload(actor, weaponentity, WEP_CVAR(WEP_MINE_LAYER, ammo), SND_RELOAD);
}

METHOD(MineLayer, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_MINELAYER_SUICIDE;
}

METHOD(MineLayer, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_MINELAYER_MURDER;
}

#endif
#ifdef CSQC

METHOD(MineLayer, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_ROCKET_EXPLODE, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_MINE_EXP, VOL_BASE, ATTN_NORM);
}

#endif
#ifdef MENUQC
#include <common/gametypes/gametype/assault/assault.qh>
#include <common/gametypes/gametype/ctf/ctf.qh>
#include <common/gametypes/gametype/onslaught/onslaught.qh>
#include <common/items/item/ammo.qh>

METHOD(MineLayer, describe, string(MineLayer this))
{
	TC(MineLayer, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s places mines on the ground when fired, which detonate and damage enemies if stepped on. "
	      "Only a couple mines can be placed at any time, and after several seconds they will self-detonate."), COLORED_NAME(this));
	PAR(_("The secondary fire instantaneously detonates any mines fired by the primary fire, first waiting until you're far enough away."));
	PAR(_("It consumes %s ammo for each mine laid."), COLORED_NAME(ITEM_Rockets));
	PAR(_("The mines are not launched very far before they hit the ground, so the %s isn't very effective at medium to long ranges. "
	      "It is often used to protect important areas of the map such as the flag in %s, control points in %s, or checkpoints in %s."), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_CTF), COLORED_NAME(MAPINFO_TYPE_ONSLAUGHT), COLORED_NAME(MAPINFO_TYPE_ASSAULT));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOne_unnamed(this.netname));
	return PAGE_TEXT;
}

#endif
