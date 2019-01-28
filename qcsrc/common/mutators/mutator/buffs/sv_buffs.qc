#include "sv_buffs.qh"

#include <common/mapobjects/target/music.qh>
#include <common/gamemodes/_mod.qh>

void buffs_DelayedInit(entity this);

AUTOCVAR(g_buffs, int, -1, "Enable buffs, -1: enabled but no auto location or replacing powerups, 1: enabled and can replace them");

REGISTER_MUTATOR(buffs, autocvar_g_buffs)
{
	MUTATOR_ONADD
	{
		if(autocvar_g_buffs > 0)
			InitializeEntity(NULL, buffs_DelayedInit, INITPRIO_FINDTARGET);
	}
}

bool buffs_BuffModel_Customize(entity this, entity client)
{
	entity player, myowner;
	bool same_team;

	player = WaypointSprite_getviewentity(client);
	myowner = this.owner;
	same_team = (SAME_TEAM(player, myowner) || SAME_TEAM(player, myowner));

	if(myowner.alpha <= 0.5 && !same_team && myowner.alpha != 0)
		return false;

	if(MUTATOR_CALLHOOK(BuffModel_Customize, this, player))
		return false;

	if(player == myowner || (IS_SPEC(client) && client.enemy == myowner))
	{
		// somewhat hide the model, but keep the glow
		this.effects = 0;
		this.alpha = -1;
	}
	else
	{
		this.effects = EF_FULLBRIGHT | EF_LOWPRECISION;
		this.alpha = 1;
	}
	return true;
}

void buffs_BuffModel_Spawn(entity player)
{
	player.buff_model = spawn();
	setmodel(player.buff_model, MDL_BUFF);
	setsize(player.buff_model, '0 0 -40', '0 0 40');
	setattachment(player.buff_model, player, "");
	setorigin(player.buff_model, '0 0 1' * (player.buff_model.maxs.z * 1));
	player.buff_model.owner = player;
	player.buff_model.scale = 0.7;
	player.buff_model.pflags = PFLAGS_FULLDYNAMIC;
	player.buff_model.light_lev = 200;
	setcefc(player.buff_model, buffs_BuffModel_Customize);
}

vector buff_GlowColor(entity buff)
{
	//if(buff.team) { return Team_ColorRGB(buff.team); }
	return buff.m_color;
}

void buff_Effect(entity player, string eff)
{
	if(!autocvar_g_buffs_effects) { return; }

	if(time >= player.buff_effect_delay)
	{
		Send_Effect_(eff, player.origin + ((player.mins + player.maxs) * 0.5), '0 0 0', 1);
		player.buff_effect_delay = time + 0.05; // prevent spam
	}
}

// buff item
bool buff_Waypoint_visible_for_player(entity this, entity player, entity view)
{
	if(!this.owner.buff_active && !this.owner.buff_activetime)
		return false;

	if (STAT(BUFFS, view))
	{
		return CS(view).cvar_cl_buffs_autoreplace == false || STAT(BUFFS, view) != STAT(BUFFS, this.owner);
	}

	return WaypointSprite_visible_for_player(this, player, view);
}

void buff_Waypoint_Spawn(entity e)
{
	entity buff = buff_FirstFromFlags(STAT(BUFFS, e));
	entity wp = WaypointSprite_Spawn(WP_Buff, 0, autocvar_g_buffs_waypoint_distance, e, '0 0 1' * e.maxs.z, NULL, e.team, e, buff_waypoint, true, RADARICON_Buff);
	wp.wp_extra = buff.m_id;
	WaypointSprite_UpdateTeamRadar(e.buff_waypoint, RADARICON_Buff, e.glowmod);
	e.buff_waypoint.waypointsprite_visible_for_player = buff_Waypoint_visible_for_player;
}

void buff_SetCooldown(entity this, float cd)
{
	cd = max(0, cd);

	if(!this.buff_waypoint)
		buff_Waypoint_Spawn(this);

	WaypointSprite_UpdateBuildFinished(this.buff_waypoint, time + cd);
	this.buff_activetime = cd;
	this.buff_active = !cd;
}

void buff_Respawn(entity this)
{
	if(game_stopped) return;

	vector oldbufforigin = this.origin;
	this.velocity = '0 0 200';

	if(!MoveToRandomMapLocation(this, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY,
		((autocvar_g_buffs_random_location_attempts > 0) ? autocvar_g_buffs_random_location_attempts : 10), 1024, 256))
	{
		entity spot = SelectSpawnPoint(this, true);
		setorigin(this, spot.origin);
		this.velocity = ((randomvec() * 100) + '0 0 200');
		this.angles = spot.angles;
	}

	tracebox(this.origin, this.mins * 1.5, this.maxs * 1.5, this.origin, MOVE_NOMONSTERS, this);

	setorigin(this, trace_endpos); // attempt to unstick

	set_movetype(this, MOVETYPE_TOSS);

	makevectors(this.angles);
	this.angles = '0 0 0';
	if(autocvar_g_buffs_random_lifetime > 0)
		this.lifetime = time + autocvar_g_buffs_random_lifetime;

	Send_Effect(EFFECT_ELECTRO_COMBO, oldbufforigin + ((this.mins + this.maxs) * 0.5), '0 0 0', 1);
	Send_Effect(EFFECT_ELECTRO_COMBO, CENTER_OR_VIEWOFS(this), '0 0 0', 1);

	WaypointSprite_Ping(this.buff_waypoint);

	sound(this, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)
}

void buff_Touch(entity this, entity toucher)
{
	if(game_stopped) return;

	if(ITEM_TOUCH_NEEDKILL())
	{
		buff_Respawn(this);
		return;
	}

	if(!this.buff_active)
		return;

	if(MUTATOR_CALLHOOK(BuffTouch, this, toucher))
		return;
	toucher = M_ARGV(1, entity);

	if(!IS_PLAYER(toucher))
		return; // incase mutator changed toucher

	if((this.team && DIFF_TEAM(toucher, this))
	|| (STAT(FROZEN, toucher))
	|| (toucher.vehicle)
	|| (time < PS(toucher).buff_shield)
	)
	{
		// can't touch this
		return;
	}

	if (STAT(BUFFS, toucher))
	{
		if (CS(toucher).cvar_cl_buffs_autoreplace && STAT(BUFFS, toucher) != STAT(BUFFS, this))
		{
			int buffid = buff_FirstFromFlags(STAT(BUFFS, toucher)).m_id;
			//Send_Notification(NOTIF_ONE, toucher, MSG_MULTI, ITEM_BUFF_DROP, STAT(BUFFS, toucher));
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ITEM_BUFF_LOST, toucher.netname, buffid);

			STAT(BUFFS, toucher) = 0;
			//sound(toucher, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		}
		else { return; } // do nothing
	}

	this.owner = toucher;
	this.buff_active = false;
	this.lifetime = 0;
	int buffid = buff_FirstFromFlags(STAT(BUFFS, this)).m_id;
	Send_Notification(NOTIF_ONE, toucher, MSG_MULTI, ITEM_BUFF_GOT, buffid);
	Send_Notification(NOTIF_ALL_EXCEPT, toucher, MSG_INFO, INFO_ITEM_BUFF, toucher.netname, buffid);

	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
	sound(toucher, CH_TRIGGER, SND_SHIELD_RESPAWN, VOL_BASE, ATTN_NORM);
	STAT(BUFFS, toucher) |= (STAT(BUFFS, this));
}

float buff_Available(entity buff)
{
	if (buff == BUFF_Null)
		return false;
	if (buff == BUFF_AMMO && ((start_items & IT_UNLIMITED_WEAPON_AMMO) || (start_items & IT_UNLIMITED_AMMO) || (cvar("g_melee_only"))))
		return false;
	if (buff == BUFF_VAMPIRE && cvar("g_vampire"))
		return false;
	return cvar(strcat("g_buffs_", buff.netname));
}

.int buff_seencount;

void buff_NewType(entity ent)
{
	RandomSelection_Init();
	FOREACH(Buffs, buff_Available(it),
	{
		// if it's already been chosen, give it a lower priority
		RandomSelection_AddEnt(it, max(0.2, 1 / it.buff_seencount), 1);
	});
	entity newbuff = RandomSelection_chosen_ent;
	newbuff.buff_seencount += 1; // lower chances of seeing this buff again soon
	STAT(BUFFS, ent) = newbuff.m_itemid;
}

void buff_Think(entity this)
{
	if(STAT(BUFFS, this) != this.oldbuffs)
	{
		entity buff = buff_FirstFromFlags(STAT(BUFFS, this));
		this.color = buff.m_color;
		this.glowmod = buff_GlowColor(buff);
		this.skin = buff.m_skin;

		setmodel(this, MDL_BUFF);
		setsize(this, BUFF_MIN, BUFF_MAX);

		if(this.buff_waypoint)
		{
			//WaypointSprite_Disown(this.buff_waypoint, 1);
			WaypointSprite_Kill(this.buff_waypoint);
			buff_Waypoint_Spawn(this);
			if(this.buff_activetime)
				WaypointSprite_UpdateBuildFinished(this.buff_waypoint, time + this.buff_activetime - frametime);
		}

		this.oldbuffs = STAT(BUFFS, this);
	}

	if(!game_stopped)
	if((round_handler_IsActive() && !round_handler_IsRoundStarted()) || time >= game_starttime)
	if(!this.buff_activetime_updated)
	{
		buff_SetCooldown(this, this.buff_activetime);
		this.buff_activetime_updated = true;
	}

	if(!this.buff_active && !this.buff_activetime)
	if(!this.owner || STAT(FROZEN, this.owner) || IS_DEAD(this.owner) || !this.owner.iscreature || this.owner.vehicle || !(STAT(BUFFS, this.owner) & STAT(BUFFS, this)) || this.pickup_anyway > 0 || (this.pickup_anyway >= 0 && autocvar_g_buffs_pickup_anyway))
	{
		buff_SetCooldown(this, autocvar_g_buffs_cooldown_respawn + frametime);
		this.owner = NULL;
		if(autocvar_g_buffs_randomize)
			buff_NewType(this);

		if(autocvar_g_buffs_random_location || (this.spawnflags & 64))
			buff_Respawn(this);
	}

	if(this.buff_activetime)
	if(!game_stopped)
	if((round_handler_IsActive() && !round_handler_IsRoundStarted()) || time >= game_starttime)
	{
		this.buff_activetime = max(0, this.buff_activetime - frametime);

		if(!this.buff_activetime)
		{
			this.buff_active = true;
			sound(this, CH_TRIGGER, SND_STRENGTH_RESPAWN, VOL_BASE, ATTN_NORM);
			Send_Effect(EFFECT_ITEM_RESPAWN, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
		}
	}

	if(this.buff_active)
	{
		if(this.team && !this.buff_waypoint)
			buff_Waypoint_Spawn(this);

		if(this.lifetime)
		if(time >= this.lifetime)
			buff_Respawn(this);
	}

	this.nextthink = time;
	//this.angles_y = time * 110.1;
}

void buff_Waypoint_Reset(entity this)
{
	WaypointSprite_Kill(this.buff_waypoint);

	if(this.buff_activetime) { buff_Waypoint_Spawn(this); }
}

void buff_Reset(entity this)
{
	if(autocvar_g_buffs_randomize)
		buff_NewType(this);
	this.owner = NULL;
	buff_SetCooldown(this, autocvar_g_buffs_cooldown_activate);
	buff_Waypoint_Reset(this);
	this.buff_activetime_updated = false;

	if(autocvar_g_buffs_random_location || (this.spawnflags & 64))
		buff_Respawn(this);
}

bool buff_Customize(entity this, entity client)
{
	entity player = WaypointSprite_getviewentity(client);
	if(!this.buff_active || (this.team && DIFF_TEAM(player, this)))
	{
		this.alpha = 0.3;
		if(this.effects & EF_FULLBRIGHT) { this.effects &= ~(EF_FULLBRIGHT); }
		this.pflags = 0;
	}
	else
	{
		this.alpha = 1;
		if(!(this.effects & EF_FULLBRIGHT)) { this.effects |= EF_FULLBRIGHT; }
		this.light_lev = 220 + 36 * sin(time);
		this.pflags = PFLAGS_FULLDYNAMIC;
	}
	return true;
}

void buff_Init(entity this)
{
	if(!cvar("g_buffs")) { delete(this); return; }

	if(!teamplay && this.team) { this.team = 0; }

	entity buff = buff_FirstFromFlags(STAT(BUFFS, this));

	if(!STAT(BUFFS, this) || !buff_Available(buff))
		buff_NewType(this);

	this.classname = "item_buff";
	this.solid = SOLID_TRIGGER;
	this.flags = FL_ITEM;
	this.bot_pickup = true;
	this.bot_pickupevalfunc = generic_pickupevalfunc;
	this.bot_pickupbasevalue = 1000;
	IL_PUSH(g_items, this);
	setthink(this, buff_Think);
	settouch(this, buff_Touch);
	this.reset = buff_Reset;
	this.nextthink = time + 0.1;
	this.gravity = 1;
	set_movetype(this, MOVETYPE_TOSS);
	this.scale = 1;
	this.skin = buff.m_skin;
	this.effects = EF_FULLBRIGHT | EF_STARDUST | EF_NOSHADOW;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;
	setcefc(this, buff_Customize);
	//this.gravity = 100;
	this.color = buff.m_color;
	this.glowmod = buff_GlowColor(this);
	buff_SetCooldown(this, autocvar_g_buffs_cooldown_activate + max(0, game_starttime - time));
	this.buff_active = !this.buff_activetime;
	this.pflags = PFLAGS_FULLDYNAMIC;

	if(this.spawnflags & 1)
		this.noalign = true;

	if(this.noalign)
		set_movetype(this, MOVETYPE_NONE); // reset by random location

	setmodel(this, MDL_BUFF);
	setsize(this, BUFF_MIN, BUFF_MAX);

	if(cvar("g_buffs_random_location") || (this.spawnflags & 64))
		buff_Respawn(this);
}

void buff_Init_Compat(entity ent, entity replacement)
{
	if (ent.spawnflags & 2)
		ent.team = NUM_TEAM_1;
	else if (ent.spawnflags & 4)
		ent.team = NUM_TEAM_2;

	STAT(BUFFS, ent) = replacement.m_itemid;

	buff_Init(ent);
}

void buff_SpawnReplacement(entity ent, entity old)
{
	setorigin(ent, old.origin);
	ent.angles = old.angles;
	ent.noalign = Item_ShouldKeepPosition(old);

	buff_Init(ent);
}

void buff_Vengeance_DelayedDamage(entity this)
{
	if(this.enemy)
		Damage(this.enemy, this.owner, this.owner, this.dmg, DEATH_BUFF.m_id, DMG_NOWEP, this.enemy.origin, '0 0 0');

	delete(this);
	return;
}

// note: only really useful in teamplay
void buff_Medic_Heal(entity this)
{
	FOREACH_CLIENT(IS_PLAYER(it) && it != this && vdist(it.origin - this.origin, <=, autocvar_g_buffs_medic_heal_range),
	{
		if (DIFF_TEAM(it, this))
		{
			continue;
		}
		float hp = GetResourceAmount(it, RESOURCE_HEALTH);
		if(hp >= autocvar_g_balance_health_regenstable)
		{
			continue;
		}
		Send_Effect(EFFECT_HEALING, it.origin, '0 0 0', 1);
		SetResourceAmount(it, RESOURCE_HEALTH, bound(0, hp + autocvar_g_buffs_medic_heal_amount, autocvar_g_balance_health_regenstable));
	});
}

float buff_Inferno_CalculateTime(float damg, float offset_x, float offset_y, float intersect_x, float intersect_y, float base)
{
	return offset_y + (intersect_y - offset_y) * logn(((damg - offset_x) * ((base - 1) / intersect_x)) + 1, base);
}

// mutator hooks
MUTATOR_HOOKFUNCTION(buffs, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	vector frag_force = M_ARGV(6, vector);

	if(frag_deathtype == DEATH_BUFF.m_id) { return; }

	if(STAT(BUFFS, frag_target) & BUFF_RESISTANCE.m_itemid)
	{
		float reduced = frag_damage * autocvar_g_buffs_resistance_blockpercent;
		frag_damage = bound(0, frag_damage - reduced, frag_damage);
	}

	if(STAT(BUFFS, frag_target) & BUFF_SPEED.m_itemid)
	if(frag_target != frag_attacker)
		frag_damage *= autocvar_g_buffs_speed_damage_take;

	if(STAT(BUFFS, frag_target) & BUFF_MEDIC.m_itemid)
	if((GetResourceAmount(frag_target, RESOURCE_HEALTH) - frag_damage) <= 0)
	if(!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	if(frag_attacker)
	if(random() <= autocvar_g_buffs_medic_survive_chance)
		frag_damage = max(5, GetResourceAmount(frag_target, RESOURCE_HEALTH) - autocvar_g_buffs_medic_survive_health);

	if(STAT(BUFFS, frag_target) & BUFF_JUMP.m_itemid)
	if(frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	if(STAT(BUFFS, frag_target) & BUFF_VENGEANCE.m_itemid)
	if(frag_attacker)
	if(frag_attacker != frag_target)
	if(!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	{
		entity dmgent = spawn();

		dmgent.dmg = frag_damage * autocvar_g_buffs_vengeance_damage_multiplier;
		dmgent.enemy = frag_attacker;
		dmgent.owner = frag_target;
		setthink(dmgent, buff_Vengeance_DelayedDamage);
		dmgent.nextthink = time + 0.1;
	}

	if(STAT(BUFFS, frag_target) & BUFF_BASH.m_itemid)
	if(frag_attacker != frag_target)
		frag_force = '0 0 0';

	if(STAT(BUFFS, frag_attacker) & BUFF_BASH.m_itemid)
	if(frag_force)
	{
		if(frag_attacker == frag_target)
			frag_force *= autocvar_g_buffs_bash_force_self;
		else
			frag_force *= autocvar_g_buffs_bash_force;
	}

	if(STAT(BUFFS, frag_attacker) & BUFF_DISABILITY.m_itemid)
	if(frag_target != frag_attacker)
		frag_target.buff_disability_time = time + autocvar_g_buffs_disability_slowtime;

	if(STAT(BUFFS, frag_target) & BUFF_INFERNO.m_itemid)
	{
		if(frag_deathtype == DEATH_FIRE.m_id)
			frag_damage = 0;
		if(frag_deathtype == DEATH_LAVA.m_id)
			frag_damage *= 0.5; // TODO: cvarize?
	}

	if(STAT(BUFFS, frag_attacker) & BUFF_LUCK.m_itemid)
	if(frag_attacker != frag_target)
	if(autocvar_g_buffs_luck_damagemultiplier > 0)
	if(random() <= autocvar_g_buffs_luck_chance)
		frag_damage *= autocvar_g_buffs_luck_damagemultiplier;

	if(STAT(BUFFS, frag_attacker) & BUFF_INFERNO.m_itemid)
	if(frag_target != frag_attacker) {
		float btime = buff_Inferno_CalculateTime(
			frag_damage,
			0,
			autocvar_g_buffs_inferno_burntime_min_time,
			autocvar_g_buffs_inferno_burntime_target_damage,
			autocvar_g_buffs_inferno_burntime_target_time,
			autocvar_g_buffs_inferno_burntime_factor
		);
		Fire_AddDamage(frag_target, frag_attacker, (frag_damage * autocvar_g_buffs_inferno_damagemultiplier), btime, DEATH_BUFF.m_id);
	}

	// this... is ridiculous (TODO: fix!)
	if(STAT(BUFFS, frag_attacker) & BUFF_VAMPIRE.m_itemid)
	if(!frag_target.vehicle)
	if(!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	if(!IS_DEAD(frag_target))
	if(IS_PLAYER(frag_target) || IS_MONSTER(frag_target))
	if(frag_attacker != frag_target)
	if(!STAT(FROZEN, frag_target))
	if(frag_target.takedamage)
	if(DIFF_TEAM(frag_attacker, frag_target))
	{
		float amount = bound(0, frag_damage * autocvar_g_buffs_vampire_damage_steal,
			GetResourceAmount(frag_target, RESOURCE_HEALTH));
		GiveResourceWithLimit(frag_attacker, RESOURCE_HEALTH, amount, g_pickup_healthsmall_max);
		if (GetResourceAmount(frag_target, RESOURCE_ARMOR))
		{
			amount = bound(0, frag_damage * autocvar_g_buffs_vampire_damage_steal,
				GetResourceAmount(frag_target, RESOURCE_ARMOR));
			GiveResourceWithLimit(frag_attacker, RESOURCE_ARMOR, amount, g_pickup_armorsmall_max);
		}
	}

	M_ARGV(4, float) = frag_damage;
	M_ARGV(6, vector) = frag_force;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	STAT(BUFFS, player) = 0;
	STAT(BUFF_TIME, player) = 0;
	PS(player).buff_shield = time + 0.5; // prevent picking up buffs immediately
	// reset timers here to prevent them continuing after re-spawn
	player.buff_disability_time = 0;
	player.buff_disability_effect_time = 0;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(STAT(BUFFS, player) & BUFF_SPEED.m_itemid)
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_buffs_speed_speed;

	if(time < player.buff_disability_time)
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_buffs_disability_speed;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(STAT(BUFFS, player) & BUFF_JUMP.m_itemid)
		STAT(MOVEVARS_JUMPVELOCITY, player) = autocvar_g_buffs_jump_height;
}

MUTATOR_HOOKFUNCTION(buffs, MonsterMove)
{
	entity mon = M_ARGV(0, entity);

	if(time < mon.buff_disability_time)
	{
		M_ARGV(1, float) *= autocvar_g_buffs_disability_speed; // run speed
		M_ARGV(2, float) *= autocvar_g_buffs_disability_speed; // walk speed
	}
}

MUTATOR_HOOKFUNCTION(buffs, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	if(STAT(BUFFS, frag_target))
	{
		int buffid = buff_FirstFromFlags(STAT(BUFFS, frag_target)).m_id;
		Send_Notification(NOTIF_ALL_EXCEPT, frag_target, MSG_INFO, INFO_ITEM_BUFF_LOST, frag_target.netname, buffid);
		STAT(BUFFS, frag_target) = 0;

		if(frag_target.buff_model)
		{
			delete(frag_target.buff_model);
			frag_target.buff_model = NULL;
		}
	}
}

MUTATOR_HOOKFUNCTION(buffs, PlayerUseKey, CBC_ORDER_FIRST)
{
	if(MUTATOR_RETURNVALUE || game_stopped || !autocvar_g_buffs_drop) return;

	entity player = M_ARGV(0, entity);

	if(STAT(BUFFS, player))
	{
		int buffid = buff_FirstFromFlags(STAT(BUFFS, player)).m_id;
		Send_Notification(NOTIF_ONE, player, MSG_MULTI, ITEM_BUFF_DROP, buffid);
		Send_Notification(NOTIF_ALL_EXCEPT, player, MSG_INFO, INFO_ITEM_BUFF_LOST, player.netname, buffid);

		STAT(BUFFS, player) = 0;
		PS(player).buff_shield = time + max(0, autocvar_g_buffs_pickup_delay);
		//STAT(BUFF_TIME, player) = 0; // already notified
		sound(player, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(buffs, ForbidThrowCurrentWeapon)
{
	if(MUTATOR_RETURNVALUE || game_stopped) return;
	entity player = M_ARGV(0, entity);

	if(STAT(BUFFS, player) & BUFF_SWAPPER.m_itemid)
	{
		float best_distance = autocvar_g_buffs_swapper_range;
		entity closest = NULL;
		FOREACH_CLIENT(IS_PLAYER(it), {
			if(!IS_DEAD(it) && !STAT(FROZEN, it) && !it.vehicle)
			if(DIFF_TEAM(it, player))
			{
				float test = vlen2(player.origin - it.origin);
				if(test <= best_distance * best_distance)
				{
					best_distance = sqrt(test);
					closest = it;
				}
			}
		});

		if(closest)
		{
			vector my_org, my_vel, my_ang, their_org, their_vel, their_ang;

			my_org = player.origin;
			my_vel = player.velocity;
			my_ang = player.angles;
			their_org = closest.origin;
			their_vel = closest.velocity;
			their_ang = closest.angles;

			Drop_Special_Items(closest);

			MUTATOR_CALLHOOK(PortalTeleport, player); // initiate flag dropper

			setorigin(player, their_org);
			setorigin(closest, my_org);

			closest.velocity = my_vel;
			closest.angles = my_ang;
			if (IS_BOT_CLIENT(closest))
			{
				closest.v_angle = closest.angles;
				bot_aim_reset(closest);
			}
			closest.fixangle = true;
			closest.oldorigin = my_org;
			closest.oldvelocity = my_vel;
			player.velocity = their_vel;
			player.angles = their_ang;
			if (IS_BOT_CLIENT(player))
			{
				player.v_angle = player.angles;
				bot_aim_reset(player);
			}
			player.fixangle = true;
			player.oldorigin = their_org;
			player.oldvelocity = their_vel;

			// set pusher so player gets the kill if they fall into void
			closest.pusher = player;
			closest.pushltime = time + autocvar_g_maxpushtime;
			closest.istypefrag = PHYS_INPUT_BUTTON_CHAT(closest);

			Send_Effect(EFFECT_ELECTRO_COMBO, their_org, '0 0 0', 1);
			Send_Effect(EFFECT_ELECTRO_COMBO, my_org, '0 0 0', 1);

			sound(player, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NORM);
			sound(closest, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NORM);

			// TODO: add a counter to handle how many times one can teleport, and a delay to prevent spam
			STAT(BUFFS, player) = 0;
			return true;
		}
	}
}

bool buffs_RemovePlayer(entity player)
{
	if(player.buff_model)
	{
		delete(player.buff_model);
		player.buff_model = NULL;
	}

	// also reset timers here to prevent them continuing after spectating
	player.buff_disability_time = 0;
	player.buff_disability_effect_time = 0;

	return false;
}
MUTATOR_HOOKFUNCTION(buffs, MakePlayerObserver) { entity player = M_ARGV(0, entity); return buffs_RemovePlayer(player); }
MUTATOR_HOOKFUNCTION(buffs, ClientDisconnect) { entity player = M_ARGV(0, entity); return buffs_RemovePlayer(player); }

MUTATOR_HOOKFUNCTION(buffs, CustomizeWaypoint)
{
	entity wp = M_ARGV(0, entity);
	entity player = M_ARGV(1, entity);

	entity e = WaypointSprite_getviewentity(player);

	// if you have the invisibility powerup, sprites ALWAYS are restricted to your team
	// but only apply this to real players, not to spectators
	if((wp.owner.flags & FL_CLIENT) && (STAT(BUFFS, wp.owner) & BUFF_INVISIBLE.m_itemid) && (e == player))
	if(DIFF_TEAM(wp.owner, e))
		return true;
}

MUTATOR_HOOKFUNCTION(buffs, FilterItem)
{
	if(autocvar_g_buffs < 0)
		return false; // no auto replacing of entities in this mode

	entity item = M_ARGV(0, entity);

	if(autocvar_g_buffs_replace_powerups)
	{
		switch(item.classname)
		{
			case "item_strength":
			case "item_shield":
			{
				entity e = spawn();
				buff_SpawnReplacement(e, item);
				return true;
			}
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(buffs, WeaponRateFactor)
{
	entity player = M_ARGV(1, entity);

	if(STAT(BUFFS, player) & BUFF_SPEED.m_itemid)
		M_ARGV(0, float) *= autocvar_g_buffs_speed_rate;

	if(time < player.buff_disability_time)
		M_ARGV(0, float) *= autocvar_g_buffs_disability_rate;
}

MUTATOR_HOOKFUNCTION(buffs, WeaponSpeedFactor)
{
	entity player = M_ARGV(1, entity);

	if(STAT(BUFFS, player) & BUFF_SPEED.m_itemid)
		M_ARGV(0, float) *= autocvar_g_buffs_speed_weaponspeed;

	if(time < player.buff_disability_time)
		M_ARGV(0, float) *= autocvar_g_buffs_disability_weaponspeed;
}

.bool buff_flight_crouchheld;

MUTATOR_HOOKFUNCTION(buffs, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if(game_stopped || IS_DEAD(player) || frametime || !IS_PLAYER(player)) return;

	if(STAT(BUFFS, player) & BUFF_FLIGHT.m_itemid)
	{
		if(!PHYS_INPUT_BUTTON_CROUCH(player))
			player.buff_flight_crouchheld = false;
		else if(!player.buff_flight_crouchheld)
		{
			player.buff_flight_crouchheld = true;
			player.gravity *= -1;
		}
	}

	if(time < player.buff_disability_time)
	if(time >= player.buff_disability_effect_time)
	{
		Send_Effect(EFFECT_SMOKING, player.origin + ((player.mins + player.maxs) * 0.5), '0 0 0', 1);
		player.buff_disability_effect_time = time + 0.5;
	}

	// handle buff lost status
	// 1: notify everyone else
	// 2: notify carrier as well
	int buff_lost = 0;

	if(STAT(BUFF_TIME, player) && STAT(BUFFS, player))
	if(time >= STAT(BUFF_TIME, player))
	{
		STAT(BUFF_TIME, player) = 0;
		buff_lost = 2;
	}

	if(STAT(FROZEN, player)) { buff_lost = 1; }

	if(buff_lost)
	{
		if(STAT(BUFFS, player))
		{
			int buffid = buff_FirstFromFlags(STAT(BUFFS, player)).m_id;
			if(buff_lost == 2)
			{
				Send_Notification(NOTIF_ONE, player, MSG_MULTI, ITEM_BUFF_DROP, buffid); // TODO: special timeout message?
				sound(player, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
			}
			else
				Send_Notification(NOTIF_ALL_EXCEPT, player, MSG_INFO, INFO_ITEM_BUFF_LOST, player.netname, buffid);
			STAT(BUFFS, player) = 0;
			PS(player).buff_shield = time + max(0, autocvar_g_buffs_pickup_delay); // always put in a delay, even if small
		}
	}

	if(STAT(BUFFS, player) & BUFF_MAGNET.m_itemid)
	{
		vector pickup_size;
		IL_EACH(g_items, it.itemdef,
		{
			if(STAT(BUFFS, it))
				pickup_size = '1 1 1' * autocvar_g_buffs_magnet_range_buff;
			else
				pickup_size = '1 1 1' * autocvar_g_buffs_magnet_range_item;

			if(boxesoverlap(player.absmin - pickup_size, player.absmax + pickup_size, it.absmin, it.absmax))
			{
				if(gettouch(it))
					gettouch(it)(it, player);
			}
		});
	}

	if(STAT(BUFFS, player) & BUFF_AMMO.m_itemid)
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(player.(weaponentity).clip_size)
				player.(weaponentity).clip_load = player.(weaponentity).(weapon_load[player.(weaponentity).m_switchweapon.m_id]) = player.(weaponentity).clip_size;
		}
	}

	if((STAT(BUFFS, player) & BUFF_INVISIBLE.m_itemid) && (player.oldbuffs & BUFF_INVISIBLE.m_itemid))
		player.alpha = ((autocvar_g_buffs_invisible_alpha) ? autocvar_g_buffs_invisible_alpha : -1); // powerups reset alpha, so we must enforce this (TODO)

	if(STAT(BUFFS, player) & BUFF_MEDIC.m_itemid)
	if(time >= player.buff_medic_healtime)
	{
		buff_Medic_Heal(player);
		player.buff_medic_healtime = time + autocvar_g_buffs_medic_heal_delay;
	}

#define BUFF_ONADD(b) if ( (STAT(BUFFS, player) & (b).m_itemid) && !(player.oldbuffs & (b).m_itemid))
#define BUFF_ONREM(b) if (!(STAT(BUFFS, player) & (b).m_itemid) &&  (player.oldbuffs & (b).m_itemid))

	if(STAT(BUFFS, player) != player.oldbuffs)
	{
		entity buff = buff_FirstFromFlags(STAT(BUFFS, player));
		float bufftime = buff != BUFF_Null ? buff.m_time(buff) : 0;
		STAT(BUFF_TIME, player) = (bufftime) ? time + bufftime : 0;

		BUFF_ONADD(BUFF_AMMO)
		{
			player.buff_ammo_prev_infitems = (player.items & IT_UNLIMITED_WEAPON_AMMO);
			player.items |= IT_UNLIMITED_WEAPON_AMMO;

			if(STAT(BUFFS, player) & BUFF_AMMO.m_itemid)
			{
				for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
				{
					.entity weaponentity = weaponentities[slot];
					if(player.(weaponentity).clip_load)
						player.(weaponentity).buff_ammo_prev_clipload = player.(weaponentity).clip_load;
					if(player.(weaponentity).clip_size)
						player.(weaponentity).clip_load = player.(weaponentity).(weapon_load[player.(weaponentity).m_switchweapon.m_id]) = player.(weaponentity).clip_size;
				}
			}
		}

		BUFF_ONREM(BUFF_AMMO)
		{
			if(player.buff_ammo_prev_infitems)
				player.items |= IT_UNLIMITED_WEAPON_AMMO;
			else
				player.items &= ~IT_UNLIMITED_WEAPON_AMMO;

			if(STAT(BUFFS, player) & BUFF_AMMO.m_itemid)
			{
				for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
				{
					.entity weaponentity = weaponentities[slot];
					if(player.(weaponentity).buff_ammo_prev_clipload)
						player.(weaponentity).clip_load = player.(weaponentity).buff_ammo_prev_clipload;
				}
			}
		}

		BUFF_ONADD(BUFF_INVISIBLE)
		{
			if(time < player.strength_finished && MUTATOR_IS_ENABLED(mutator_instagib))
				player.buff_invisible_prev_alpha = default_player_alpha; // we don't want to save the powerup's alpha, as player may lose the powerup while holding the buff
			else
				player.buff_invisible_prev_alpha = player.alpha;
			player.alpha = autocvar_g_buffs_invisible_alpha;
		}

		BUFF_ONREM(BUFF_INVISIBLE)
		{
			if(time < player.strength_finished && MUTATOR_IS_ENABLED(mutator_instagib))
				player.alpha = autocvar_g_instagib_invis_alpha;
			else
				player.alpha = player.buff_invisible_prev_alpha;
		}

		BUFF_ONADD(BUFF_FLIGHT)
		{
			player.buff_flight_oldgravity = player.gravity;
			if(!player.gravity)
				player.gravity = 1;
		}

		BUFF_ONREM(BUFF_FLIGHT)
			player.gravity = ((player.trigger_gravity_check) ? player.trigger_gravity_check.enemy.gravity : player.buff_flight_oldgravity);

		player.oldbuffs = STAT(BUFFS, player);
		if(STAT(BUFFS, player))
		{
			if(!player.buff_model)
				buffs_BuffModel_Spawn(player);

			player.buff_model.color = buff.m_color;
			player.buff_model.glowmod = buff_GlowColor(player.buff_model);
			player.buff_model.skin = buff.m_skin;

			player.effects |= EF_NOSHADOW;
		}
		else
		{
			if(player.buff_model)
				delete(player.buff_model);
			player.buff_model = NULL;

			player.effects &= ~(EF_NOSHADOW);
		}
	}

	if(player.buff_model)
	{
		player.buff_model.effects = player.effects;
		player.buff_model.effects |= EF_LOWPRECISION;
		player.buff_model.effects = player.buff_model.effects & EFMASK_CHEAP; // eat performance

		player.buff_model.alpha = player.alpha;
	}

#undef BUFF_ONADD
#undef BUFF_ONREM
}

MUTATOR_HOOKFUNCTION(buffs, SpectateCopy)
{
	entity spectatee = M_ARGV(0, entity);
	entity client = M_ARGV(1, entity);

	STAT(BUFFS, client) = STAT(BUFFS, spectatee);
	STAT(BUFF_TIME, client) = STAT(BUFF_TIME, spectatee);
}

MUTATOR_HOOKFUNCTION(buffs, PlayerRegen)
{
	entity player = M_ARGV(0, entity);

	if(STAT(BUFFS, player) & BUFF_MEDIC.m_itemid)
	{
		M_ARGV(2, float) = autocvar_g_buffs_medic_rot; // rot_mod
		M_ARGV(4, float) = M_ARGV(1, float) = autocvar_g_buffs_medic_max; // limit_mod = max_mod
		M_ARGV(2, float) = autocvar_g_buffs_medic_regen; // regen_mod
	}

	if(STAT(BUFFS, player) & BUFF_SPEED.m_itemid)
		M_ARGV(2, float) = autocvar_g_buffs_speed_regen; // regen_mod
}

REPLICATE(cvar_cl_buffs_autoreplace, bool, "cl_buffs_autoreplace");

MUTATOR_HOOKFUNCTION(buffs, BuildMutatorsString)
{
	if(autocvar_g_buffs > 0) // only report as a mutator if they're enabled
		M_ARGV(0, string) = strcat(M_ARGV(0, string), ":Buffs");
}

MUTATOR_HOOKFUNCTION(buffs, BuildMutatorsPrettyString)
{
	if(autocvar_g_buffs > 0)
		M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Buffs");
}

void buffs_DelayedInit(entity this)
{
	if(autocvar_g_buffs_spawn_count > 0)
	if(find(NULL, classname, "item_buff") == NULL)
	{
		float i;
		for(i = 0; i < autocvar_g_buffs_spawn_count; ++i)
		{
			entity e = spawn();
			e.spawnflags |= 64; // always randomize
			e.velocity = randomvec() * 250; // this gets reset anyway if random location works
			buff_Init(e);
		}
	}
}
