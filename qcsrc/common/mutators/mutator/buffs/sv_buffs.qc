#include "sv_buffs.qh"

#include <common/mapobjects/target/music.qh>
#include <common/mutators/mutator/powerups/_mod.qh>
#include <common/gamemodes/_mod.qh>
#include <server/items/items.qh>

bool buffs_BuffModel_Customize(entity this, entity client)
{
	entity player = WaypointSprite_getviewentity(client);
	entity myowner = this.owner;
	entity heldbuff = buff_FirstFromFlags(myowner);

	if(!heldbuff)
		return false;

	if(myowner.alpha <= 0.5 && DIFF_TEAM(player, myowner) && myowner.alpha != 0)
		return false;

	if(MUTATOR_CALLHOOK(BuffModel_Customize, this, player))
		return false;

	if(player == myowner)
	{
		// somewhat hide the model, but keep the glow
		this.effects = 0;
		this.alpha = -1;
	}
	else
	{
		this.effects = EF_FULLBRIGHT | EF_LOWPRECISION;
		this.alpha = myowner.alpha;
	}
	return true;
}

void buffs_BuffModel_Think(entity this)
{
	this.nextthink = time;
	entity player = this.owner;
	if(player.alpha < 0 || player.buff_model != this)
	{
		if(player) // remnant from ChatBubbleThink, same question... WHY?!
			player.buff_model = NULL;
		delete(this);
		return;
	}

	entity heldbuff = buff_FirstFromFlags(player);

	if(!heldbuff)
	{
		this.effects = EF_NODRAW;
		return;
	}

	this.color = heldbuff.m_color;
	this.glowmod = heldbuff.m_color;
	this.skin = heldbuff.m_skin;

	this.effects = player.effects;
	this.effects |= EF_LOWPRECISION;
	this.effects = this.effects & EFMASK_CHEAP; // eat performance

	this.alpha = player.alpha;
}

void buffs_BuffModel_Remove(entity player)
{
	if(player.buff_model)
		delete(player.buff_model);
	player.buff_model = NULL;
}

void buffs_BuffModel_Spawn(entity player)
{
	player.buff_model = new(buff_model);
	setmodel(player.buff_model, MDL_BUFF);
	setsize(player.buff_model, '0 0 -40', '0 0 40');
	setattachment(player.buff_model, player, "");
	setorigin(player.buff_model, '0 0 1' * (player.buff_model.maxs.z * 1));
	player.buff_model.owner = player;
	player.buff_model.exteriormodeltoclient = player;
	player.buff_model.scale = 0.7;
	player.buff_model.pflags = PFLAGS_FULLDYNAMIC;
	player.buff_model.light_lev = 200;
	setthink(player.buff_model, buffs_BuffModel_Think);
	player.buff_model.nextthink = time;
	setcefc(player.buff_model, buffs_BuffModel_Customize);
}

void buffs_BuffModel_Update(entity this)
{
	if (this.alpha < 0)
		return;
	// spawn a buff model entity if needed
	if (!this.buff_model)
		buffs_BuffModel_Spawn(this);
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
	if(!this.owner.buff_active && !this.owner.buff_activetime || !this.owner.buffdef)
		return false;

	entity heldbuff = buff_FirstFromFlags(view); // TODO: cache this information so it isn't performing a loop every frame
	if (heldbuff) 
	{
		return CS_CVAR(view).cvar_cl_buffs_autoreplace == false || heldbuff != this.owner.buffdef;
	}

	return WaypointSprite_visible_for_player(this, player, view);
}

void buff_Waypoint_Spawn(entity e)
{
	if(autocvar_g_buffs_waypoint_distance <= 0) return;

	entity buff = e.buffdef;
	entity wp = WaypointSprite_Spawn(WP_Buff, 0, autocvar_g_buffs_waypoint_distance, e, '0 0 1' * e.maxs.z, NULL, e.team_forced, e, buff_waypoint, true, RADARICON_Buff);
	wp.wp_extra = buff.m_id;
	WaypointSprite_UpdateTeamRadar(e.buff_waypoint, RADARICON_Buff, e.glowmod);
	e.buff_waypoint.waypointsprite_visible_for_player = buff_Waypoint_visible_for_player;
}

void buff_SetCooldown(entity this, float cd)
{
	cd = max(0, cd);

	if(!this.buff_waypoint)
		buff_Waypoint_Spawn(this);

	if(this.buff_waypoint)
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

	if((this.team_forced && toucher.team != this.team_forced)
	|| (STAT(FROZEN, toucher))
	|| (toucher.vehicle)
	|| (!this.buffdef) // TODO: error out or maybe reset type if this occurs?
	|| (time < toucher.buff_shield)
	)
	{
		// can't touch this
		return;
	}

	entity heldbuff = buff_FirstFromFlags(toucher);
	entity thebuff = this.buffdef;

	if (heldbuff)
	{
		if (CS_CVAR(toucher).cvar_cl_buffs_autoreplace && heldbuff != thebuff)
		{
			// TODO: lost-gained notification for this case
			int buffid = heldbuff.m_id;
			Send_Notification(NOTIF_ONE, toucher, MSG_INFO, INFO_ITEM_BUFF_LOST, toucher.netname, buffid);
			if(!IS_INDEPENDENT_PLAYER(toucher))
				Send_Notification(NOTIF_ALL_EXCEPT, toucher, MSG_INFO, INFO_ITEM_BUFF_LOST, toucher.netname, buffid);

			//sound(toucher, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		}
		else { return; } // do nothing
	}

	this.owner = toucher;
	this.buff_active = false;
	this.lifetime = 0;
	Send_Notification(NOTIF_ONE, toucher, MSG_MULTI, ITEM_BUFF_GOT, thebuff.m_id);
	if(!IS_INDEPENDENT_PLAYER(toucher))
		Send_Notification(NOTIF_ALL_EXCEPT, toucher, MSG_INFO, INFO_ITEM_BUFF, toucher.netname, thebuff.m_id);

	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
	sound(toucher, CH_TRIGGER, SND_SHIELD_RESPAWN, VOL_BASE, ATTN_NORM);
	float oldtime = StatusEffects_gettime(thebuff, toucher);
	float bufftime = ((this.buffs_finished) ? this.buffs_finished : thebuff.m_time(thebuff));

	buff_RemoveAll(toucher, STATUSEFFECT_REMOVE_NORMAL); // remove previous buffs so that a new one may be added
	if(bufftime)
		StatusEffects_apply(thebuff, toucher, min(time + bufftime, max(oldtime, time) + bufftime), 0);
	else
		StatusEffects_apply(thebuff, toucher, time + 999, 0); // HACK: zero timer means "infinite"!

	STAT(LAST_PICKUP, toucher) = time;
}

float buff_Available(entity buff)
{
	if (!buff)
		return false;
	if (buff == BUFF_AMMO && ((start_items & IT_UNLIMITED_AMMO) || cvar("g_melee_only")))
		return false;
	if (buff == BUFF_VAMPIRE && cvar("g_vampire"))
		return false;
	return cvar(strcat("g_buffs_", buff.netname));
}

.int buff_seencount;

void buff_NewType(entity ent)
{
	RandomSelection_Init();
	FOREACH(StatusEffect, it.instanceOfBuff && buff_Available(it),
	{
		// if it's already been chosen, give it a lower priority
		float myseencount = (it.buff_seencount > 0) ? it.buff_seencount : 1; // no division by zero please!
		RandomSelection_AddEnt(it, max(0.2, 1 / myseencount), 1);
	});
	entity newbuff = RandomSelection_chosen_ent;
	if(!newbuff)
		return;
	newbuff.buff_seencount += 1; // lower chances of seeing this buff again soon
	ent.buffdef = newbuff;
}

void buff_RemoveAll(entity actor, int removal_type)
{
	if(!actor.statuseffects)
		return;
	FOREACH(StatusEffect, it.instanceOfBuff,
	{
		it.m_remove(it, actor, removal_type);
	});
}

entity buff_FirstFromFlags(entity actor)
{
	if(!actor.statuseffects)
		return NULL;
	FOREACH(StatusEffect, it.instanceOfBuff && it.m_active(it, actor), { return it; });
	return NULL;
}

void buff_Think(entity this)
{
	if(this.buff_waypoint && autocvar_g_buffs_waypoint_distance <= 0)
		WaypointSprite_Kill(this.buff_waypoint);

	if(this.buffdef != this.oldbuffs)
	{
		entity buff = this.buffdef;
		this.color = buff.m_color;
		this.glowmod = buff.m_color;
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

		this.oldbuffs = this.buffdef;
	}

	if(!game_stopped)
	if((round_handler_IsActive() && round_handler_IsRoundStarted()) || time >= game_starttime)
	if(!this.buff_activetime_updated)
	{
		buff_SetCooldown(this, this.buff_activetime);
		this.buff_activetime_updated = true;
	}

	if(!this.buff_active && !this.buff_activetime)
	if(!this.owner || STAT(FROZEN, this.owner) || IS_DEAD(this.owner) || !this.owner.iscreature || this.owner.vehicle
		|| this.pickup_anyway > 0 || (this.pickup_anyway >= 0 && autocvar_g_buffs_pickup_anyway) || this.buffdef != buff_FirstFromFlags(this.owner))
	{
		buff_SetCooldown(this, autocvar_g_buffs_cooldown_respawn + frametime);
		this.owner = NULL;
		if(autocvar_g_buffs_randomize && (!teamplay || autocvar_g_buffs_randomize_teamplay))
			buff_NewType(this);

		if(autocvar_g_buffs_random_location || (this.spawnflags & 64))
			buff_Respawn(this);
	}

	if(this.buff_activetime)
	if(!game_stopped)
	if((round_handler_IsActive() && round_handler_IsRoundStarted()) || time >= game_starttime)
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
		if(this.team_forced && !this.buff_waypoint)
			buff_Waypoint_Spawn(this);

		if(this.lifetime && time >= this.lifetime)
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
	if(autocvar_g_buffs_randomize && (!teamplay || autocvar_g_buffs_randomize_teamplay))
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
	if((!this.buff_active || !this.buffdef) || (this.team_forced && player.team != this.team_forced))
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

void buff_Delete(entity this)
{
	WaypointSprite_Kill(this.buff_waypoint);
	delete_fn(this);
}

void buff_Init(entity this)
{
	if(!cvar("g_buffs")) { delete(this); return; }

	entity buff = this.buffdef;

	if(!buff || !buff_Available(buff))
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
	setmodel(this, MDL_BUFF);
	setsize(this, BUFF_MIN, BUFF_MAX);
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
	this.glowmod = buff.m_color;
	buff_SetCooldown(this, autocvar_g_buffs_cooldown_activate + max(0, game_starttime - time));
	this.buff_active = !this.buff_activetime;
	this.pflags = PFLAGS_FULLDYNAMIC;
	this.dtor = buff_Delete;

	if(!this.buffs_finished)
		this.buffs_finished = this.count; // legacy support

	if(this.spawnflags & 1)
		this.noalign = true;

	if(this.noalign)
		set_movetype(this, MOVETYPE_NONE); // reset by random location

	if(cvar("g_buffs_random_location") || (this.spawnflags & 64))
		buff_Respawn(this);
}

void buff_Init_Compat(entity ent, entity replacement)
{
	if (teamplay)
	{
		if (ent.spawnflags & 2)
			ent.team_forced = NUM_TEAM_1;
		else if (ent.spawnflags & 4)
			ent.team_forced = NUM_TEAM_2;
	}

	ent.buffdef = replacement;

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

float buff_Inferno_CalculateTime(float damg, float offset_x, float offset_y, float intersect_x, float intersect_y, float base)
{
	return offset_y + (intersect_y - offset_y) * logn(((damg - offset_x) * ((base - 1) / intersect_x)) + 1, base);
}

METHOD(Buff, m_apply, void(StatusEffects this, entity actor, float eff_time, float eff_flags))
{
    if(IS_PLAYER(actor))
    	actor.effects |= EF_NOSHADOW; // does not play well with buff icon
    SUPER(Buff).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(Buff, m_remove, void(StatusEffects this, entity actor, int removal_type))
{
	bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
	if(wasactive)
	{
		int buffid = this.m_id;
		if(removal_type == STATUSEFFECT_REMOVE_TIMEOUT)
		{
			Send_Notification(NOTIF_ONE, actor, MSG_MULTI, ITEM_BUFF_DROP, buffid); // TODO: special timeout message?
			sound(actor, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		}
		else if(removal_type == STATUSEFFECT_REMOVE_NORMAL && !IS_INDEPENDENT_PLAYER(actor))
			Send_Notification(NOTIF_ALL_EXCEPT, actor, MSG_INFO, INFO_ITEM_BUFF_LOST, actor.netname, buffid);
		actor.buff_shield = time + max(0, autocvar_g_buffs_pickup_delay); // always put in a delay, even if small
	}
	if(IS_PLAYER(actor))
		actor.effects &= ~EF_NOSHADOW;
	SUPER(Buff).m_remove(this, actor, removal_type);
}

METHOD(Disabled, m_tick, void(StatusEffects this, entity actor))
{
	if(time >= actor.disabled_effect_time)
	{
		Send_Effect(EFFECT_SMOKING, actor.origin + ((actor.mins + actor.maxs) * 0.5), '0 0 0', 1);
		actor.disabled_effect_time = time + 0.5;
	}
	SUPER(Disabled).m_tick(this, actor);
}
METHOD(Disabled, m_remove, void(StatusEffects this, entity actor, int removal_type))
{
	actor.disabled_effect_time = 0;
	SUPER(Disabled).m_remove(this, actor, removal_type);
}

METHOD(AmmoBuff, m_apply, void(StatusEffects this, entity actor, float eff_time, float eff_flags))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(!wasactive)
    {
        actor.buff_ammo_prev_infitems = (actor.items & IT_UNLIMITED_AMMO);
        actor.items |= IT_UNLIMITED_AMMO;
        for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(!actor.(weaponentity))
				continue;
			if(actor.(weaponentity).clip_load)
				actor.(weaponentity).buff_ammo_prev_clipload = actor.(weaponentity).clip_load;
			if(actor.(weaponentity).clip_size)
				actor.(weaponentity).clip_load = actor.(weaponentity).(weapon_load[actor.(weaponentity).m_switchweapon.m_id]) = actor.(weaponentity).clip_size;
		}
    }
    SUPER(AmmoBuff).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(AmmoBuff, m_remove, void(StatusEffects this, entity actor, int removal_type))
{
	bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
	if(wasactive)
	{
		actor.items = BITSET(actor.items, IT_UNLIMITED_AMMO, actor.buff_ammo_prev_infitems);
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(!actor.(weaponentity))
				continue;
			if(actor.(weaponentity).buff_ammo_prev_clipload)
			{
				actor.(weaponentity).clip_load = actor.(weaponentity).buff_ammo_prev_clipload;
				actor.(weaponentity).buff_ammo_prev_clipload = 0;
			}
		}
	}
	actor.buff_ammo_prev_infitems = 0;
	SUPER(AmmoBuff).m_remove(this, actor, removal_type);
}
METHOD(AmmoBuff, m_tick, void(StatusEffects this, entity actor))
{
	if(IS_PLAYER(actor))
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(actor.(weaponentity).clip_size)
				actor.(weaponentity).clip_load = actor.(weaponentity).(weapon_load[actor.(weaponentity).m_switchweapon.m_id]) = actor.(weaponentity).clip_size;
		}
	}

	SUPER(AmmoBuff).m_tick(this, actor);
}


METHOD(FlightBuff, m_apply, void(StatusEffects this, entity actor, float eff_time, float eff_flags))
{
    bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
    if(!wasactive)
    {
        actor.buff_flight_oldgravity = actor.gravity;
		if(!actor.gravity)
			actor.gravity = 1;
    }
    SUPER(FlightBuff).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(FlightBuff, m_remove, void(StatusEffects this, entity actor, int removal_type))
{
	bool wasactive = (actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE));
	if(wasactive)
	{
		actor.gravity = ((actor.trigger_gravity_check) ? actor.trigger_gravity_check.enemy.gravity : actor.buff_flight_oldgravity);
	}
	actor.buff_flight_oldgravity = 0;
	SUPER(FlightBuff).m_remove(this, actor, removal_type);
}

METHOD(MagnetBuff, m_tick, void(StatusEffects this, entity actor))
{
	if(IS_PLAYER(actor))
	{
		vector pickup_size;
		IL_EACH(g_items, it.itemdef,
		{
			if(it.buffdef)
				pickup_size = '1 1 1' * autocvar_g_buffs_magnet_range_buff;
			else
				pickup_size = '1 1 1' * autocvar_g_buffs_magnet_range_item;

			if(boxesoverlap(actor.absmin - pickup_size, actor.absmax + pickup_size, it.absmin, it.absmax))
			{
				if(gettouch(it))
					gettouch(it)(it, actor);
			}
		});
	}

	SUPER(MagnetBuff).m_tick(this, actor);
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

	if(StatusEffects_active(BUFF_RESISTANCE, frag_target))
	{
		float reduced = frag_damage * autocvar_g_buffs_resistance_blockpercent;
		frag_damage = bound(0, frag_damage - reduced, frag_damage);
	}

	if(StatusEffects_active(BUFF_MEDIC, frag_target))
	if((GetResource(frag_target, RES_HEALTH) - frag_damage) <= 0)
	if(!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	if(frag_attacker)
	if(random() <= autocvar_g_buffs_medic_survive_chance)
		frag_damage = max(5, GetResource(frag_target, RES_HEALTH) - autocvar_g_buffs_medic_survive_health);

	if(StatusEffects_active(BUFF_JUMP, frag_target))
	if(frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	if(StatusEffects_active(BUFF_VENGEANCE, frag_target))
	if(frag_attacker)
	if(frag_attacker != frag_target)
	if(!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	{
		entity dmgent = new_pure(dmgent);

		dmgent.dmg = frag_damage * autocvar_g_buffs_vengeance_damage_multiplier;
		dmgent.enemy = frag_attacker;
		dmgent.owner = frag_target;
		setthink(dmgent, buff_Vengeance_DelayedDamage);
		dmgent.nextthink = time + 0.1;
	}

	if(StatusEffects_active(BUFF_BASH, frag_target))
	if(frag_attacker != frag_target)
		frag_force = '0 0 0';

	if(StatusEffects_active(BUFF_BASH, frag_attacker))
	if(frag_force)
	{
		if(frag_attacker == frag_target)
			frag_force *= autocvar_g_buffs_bash_force_self;
		else
			frag_force *= autocvar_g_buffs_bash_force;
	}

	if(StatusEffects_active(BUFF_DISABILITY, frag_attacker))
	if(frag_target != frag_attacker)
		StatusEffects_apply(STATUSEFFECT_Disabled, frag_target, time + autocvar_g_buffs_disability_slowtime, 0);

	if(StatusEffects_active(BUFF_INFERNO, frag_target))
	{
		if(frag_deathtype == DEATH_FIRE.m_id)
			frag_damage = 0;
		if(frag_deathtype == DEATH_LAVA.m_id)
			frag_damage *= 0.5; // TODO: cvarize?
	}

	if(StatusEffects_active(BUFF_LUCK, frag_attacker))
	if(frag_attacker != frag_target)
	if(autocvar_g_buffs_luck_damagemultiplier > 0)
	if(random() <= autocvar_g_buffs_luck_chance)
		frag_damage *= autocvar_g_buffs_luck_damagemultiplier;

	if(StatusEffects_active(BUFF_INFERNO, frag_attacker))
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

	M_ARGV(4, float) = frag_damage;
	M_ARGV(6, vector) = frag_force;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerDamage_SplitHealthArmor)
{
	// NOTE: vampire PlayerDamage_SplitHealthArmor code is similar
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	if(!StatusEffects_active(BUFF_VAMPIRE, frag_attacker))
		return;
	float health_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));

	if (!StatusEffects_active(STATUSEFFECT_SpawnShield, frag_target) && frag_target != frag_attacker
		&& IS_PLAYER(frag_attacker) && !IS_DEAD(frag_target) && !STAT(FROZEN, frag_target))
	{
		GiveResource(frag_attacker, RES_HEALTH, autocvar_g_buffs_vampire_damage_steal * health_take);
	}
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPhysics_UpdateStats)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(StatusEffects_active(STATUSEFFECT_Disabled, player))
		STAT(MOVEVARS_HIGHSPEED, player) *= autocvar_g_buffs_disability_speed;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPhysics)
{
	entity player = M_ARGV(0, entity);
	// these automatically reset, no need to worry

	if(StatusEffects_active(BUFF_JUMP, player))
		STAT(MOVEVARS_JUMPVELOCITY, player) = autocvar_g_buffs_jump_height;
}

MUTATOR_HOOKFUNCTION(buffs, MonsterMove)
{
	entity mon = M_ARGV(0, entity);

	if(StatusEffects_active(STATUSEFFECT_Disabled, mon))
	{
		M_ARGV(1, float) *= autocvar_g_buffs_disability_speed; // run speed
		M_ARGV(2, float) *= autocvar_g_buffs_disability_speed; // walk speed
	}
}

MUTATOR_HOOKFUNCTION(buffs, PlayerUseKey, CBC_ORDER_FIRST)
{
	if(MUTATOR_RETURNVALUE || game_stopped || !autocvar_g_buffs_drop) return;

	entity player = M_ARGV(0, entity);

	entity heldbuff = buff_FirstFromFlags(player);
	if(heldbuff)
	{
		int buffid = heldbuff.m_id;
		Send_Notification(NOTIF_ONE, player, MSG_MULTI, ITEM_BUFF_DROP, buffid);
		if(!IS_INDEPENDENT_PLAYER(player))
			Send_Notification(NOTIF_ALL_EXCEPT, player, MSG_INFO, INFO_ITEM_BUFF_LOST, player.netname, buffid);

		buff_RemoveAll(player, STATUSEFFECT_REMOVE_NORMAL);
		player.buff_shield = time + max(0, autocvar_g_buffs_pickup_delay);
		sound(player, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(buffs, ForbidThrowCurrentWeapon)
{
	if(MUTATOR_RETURNVALUE || game_stopped) return;
	entity player = M_ARGV(0, entity);

	if(StatusEffects_active(BUFF_SWAPPER, player))
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
			buff_RemoveAll(player, STATUSEFFECT_REMOVE_NORMAL);
			return true;
		}
	}
}

bool buffs_RemovePlayer(entity player)
{
	buffs_BuffModel_Remove(player);

	return false;
}
MUTATOR_HOOKFUNCTION(buffs, MakePlayerObserver) { entity player = M_ARGV(0, entity); return buffs_RemovePlayer(player); }
MUTATOR_HOOKFUNCTION(buffs, ClientDisconnect) { entity player = M_ARGV(0, entity); return buffs_RemovePlayer(player); }

MUTATOR_HOOKFUNCTION(buffs, FilterItem)
{
	if(autocvar_g_buffs < 0)
		return false; // no auto replacing of entities in this mode

	entity item = M_ARGV(0, entity);

	if(autocvar_g_buffs_replace_powerups && item.itemdef.instanceOfPowerup)
	{
		entity e = spawn();
		buff_SpawnReplacement(e, item);
		return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(buffs, WeaponRateFactor)
{
	entity player = M_ARGV(1, entity);

	if(StatusEffects_active(STATUSEFFECT_Disabled, player))
		M_ARGV(0, float) *= autocvar_g_buffs_disability_rate;
}

MUTATOR_HOOKFUNCTION(buffs, WeaponSpeedFactor)
{
	entity player = M_ARGV(1, entity);

	if(StatusEffects_active(STATUSEFFECT_Disabled, player))
		M_ARGV(0, float) *= autocvar_g_buffs_disability_weaponspeed;
}

MUTATOR_HOOKFUNCTION(buffs, Freeze)
{
	entity targ = M_ARGV(0, entity);
	buff_RemoveAll(targ, STATUSEFFECT_REMOVE_NORMAL);
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if(game_stopped || IS_DEAD(player) || !IS_PLAYER(player)) return;

	// NOTE: this is kept here to ensure crouches are picked up each player movement frame
	if(StatusEffects_active(BUFF_FLIGHT, player))
	{
		if(!PHYS_INPUT_BUTTON_CROUCH(player))
			player.buff_flight_crouchheld = false;
		else if(!player.buff_flight_crouchheld)
		{
			player.buff_flight_crouchheld = true;
			player.gravity *= -1;
		}
	}

	if(IS_PLAYER(player))
		buffs_BuffModel_Update(player);
}

MUTATOR_HOOKFUNCTION(buffs, PlayerRegen)
{
	entity player = M_ARGV(0, entity);

	if(StatusEffects_active(BUFF_MEDIC, player))
	{
		M_ARGV(3, float) = autocvar_g_buffs_medic_rot; // rot_mod
		M_ARGV(4, float) = M_ARGV(1, float) = autocvar_g_buffs_medic_max; // limit_mod = max_mod
		M_ARGV(2, float) = autocvar_g_buffs_medic_regen; // regen_mod
	}
}

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

void buffs_Initialize()
{
	// if buffs are above 0, allow random spawning
	if(autocvar_g_buffs > 0 && autocvar_g_buffs_spawn_count > 0)
		InitializeEntity(NULL, buffs_DelayedInit, INITPRIO_FINDTARGET);
}
