#include "sv_buffs.qh"

#include <common/mapobjects/target/music.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/gametypes/_mod.qh>
#include <server/items/items.qh>

#include "buff/_mod.qh"

bool buffs_BuffModel_Customize(entity this, entity client)
{
	entity player = WaypointSprite_getviewentity(client);
	entity myowner = this.owner;
	entity heldbuff = buff_FirstFromFlags(myowner);

	if (!heldbuff)
		return false;

	if (myowner.alpha <= 0.5 && myowner.alpha != 0 && DIFF_TEAM(player, myowner))
		return false;

	if (MUTATOR_CALLHOOK(BuffModel_Customize, this, player))
		return false;

	if (player == myowner)
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
	if (player.alpha < 0 || player.buff_model != this)
	{
		if (player) // remnant from ChatBubbleThink, same question... WHY?!
			player.buff_model = NULL;
		delete(this);
		return;
	}

	entity heldbuff = buff_FirstFromFlags(player);

	if (!heldbuff)
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
	if (player.buff_model)
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
	if (!autocvar_g_buffs_effects)
		return;

	if (time >= player.buff_effect_delay)
	{
		Send_Effect_(eff, player.origin + (player.mins + player.maxs) * 0.5, '0 0 0', 1);
		player.buff_effect_delay = time + 0.05; // prevent spam
	}
}

// buff item
bool buff_Waypoint_visible_for_player(entity this, entity player, entity view)
{
	if (!this.owner.buff_active && !this.owner.buff_activetime || !this.owner.buffdef)
		return false;

	entity heldbuff = buff_FirstFromFlags(view); // TODO: cache this information so it isn't performing a loop every frame
	if (heldbuff) 
		return CS_CVAR(view).cvar_cl_buffs_autoreplace == false || heldbuff != this.owner.buffdef;

	return WaypointSprite_visible_for_player(this, player, view);
}

void buff_Waypoint_Spawn(entity e)
{
	if (autocvar_g_buffs_waypoint_distance <= 0)
		return;

	entity buff = e.buffdef;
	entity wp = WaypointSprite_Spawn(WP_Buff, 0, autocvar_g_buffs_waypoint_distance, e, '0 0 1' * e.maxs.z, NULL, e.team_forced, e, buff_waypoint, true, RADARICON_Buff);
	wp.wp_extra = buff.m_id;
	WaypointSprite_UpdateTeamRadar(e.buff_waypoint, RADARICON_Buff, e.glowmod);
	e.buff_waypoint.waypointsprite_visible_for_player = buff_Waypoint_visible_for_player;
}

void buff_SetCooldown(entity this, float cd)
{
	cd = max(0, cd);

	if (!this.buff_waypoint)
		buff_Waypoint_Spawn(this);
	if (this.buff_waypoint)
		WaypointSprite_UpdateBuildFinished(this.buff_waypoint, time + cd);

	this.buff_activetime = cd;
	this.buff_active = !cd;
}

void buff_Respawn(entity this)
{
	if (game_stopped)
		return;

	vector oldbufforigin = this.origin;
	this.velocity = '0 0 200';

	if (!MoveToRandomMapLocation(this, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY,
		((autocvar_g_buffs_random_location_attempts > 0) ? autocvar_g_buffs_random_location_attempts : 10), 1024, 256))
	{
		entity spot = SelectSpawnPoint(this, true);
		setorigin(this, spot.origin);
		this.velocity = (randomvec() * 100) + '0 0 200';
		this.angles = spot.angles;
	}

	tracebox(this.origin, this.mins * 1.5, this.maxs * 1.5, this.origin, MOVE_NOMONSTERS, this);

	setorigin(this, trace_endpos); // attempt to unstick

	set_movetype(this, MOVETYPE_TOSS);

	makevectors(this.angles);
	this.angles = '0 0 0';
	if (autocvar_g_buffs_random_lifetime > 0)
		this.lifetime = time + autocvar_g_buffs_random_lifetime;

	Send_Effect(EFFECT_ELECTRO_COMBO, oldbufforigin + ((this.mins + this.maxs) * 0.5), '0 0 0', 1);
	Send_Effect(EFFECT_ELECTRO_COMBO, CENTER_OR_VIEWOFS(this), '0 0 0', 1);

	WaypointSprite_Ping(this.buff_waypoint);

	sound(this, CH_TRIGGER, SND_KA_RESPAWN, VOL_BASE, ATTEN_NONE); // ATTEN_NONE (it's a sound intended to be heard anywhere)
}

void buff_Touch(entity this, entity toucher)
{
	if (game_stopped)
		return;

	if (ITEM_TOUCH_NEEDKILL())
	{
		buff_Respawn(this);
		return;
	}

	if (!this.buff_active)
		return;

	if (MUTATOR_CALLHOOK(BuffTouch, this, toucher))
		return;
	toucher = M_ARGV(1, entity);

	if (!IS_PLAYER(toucher))
		return; // incase mutator changed toucher

	if ((this.team_forced && toucher.team != this.team_forced)
		|| toucher.vehicle
		|| !this.buffdef // TODO: error out or maybe reset type if this occurs?
		|| time < toucher.buff_shield)
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
			if (!IS_INDEPENDENT_PLAYER(toucher))
				Send_Notification(NOTIF_ALL_EXCEPT, toucher, MSG_INFO, INFO_ITEM_BUFF_LOST, toucher.netname, buffid);
			//sound(toucher, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		}
		else
			return; // do nothing
	}

	this.owner = toucher;
	this.buff_active = false;
	this.lifetime = 0;
	Send_Notification(NOTIF_ONE, toucher, MSG_MULTI, ITEM_BUFF_GOT, thebuff.m_id);
	if (!IS_INDEPENDENT_PLAYER(toucher))
		Send_Notification(NOTIF_ALL_EXCEPT, toucher, MSG_INFO, INFO_ITEM_BUFF, toucher.netname, thebuff.m_id);

	Send_Effect(EFFECT_ITEM_PICKUP, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
	sound(toucher, CH_TRIGGER, SND_SHIELD_RESPAWN, VOL_BASE, ATTN_NORM);
	float bufftime = (this.buffs_finished) ? this.buffs_finished : thebuff.m_time(thebuff);

	buff_RemoveAll(toucher, STATUSEFFECT_REMOVE_NORMAL); // remove previous buffs so that a new one may be added
	if (!bufftime)
		bufftime = 999;
	StatusEffects_apply(thebuff, toucher, time + bufftime, 0);

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
	FOREACH(StatusEffects, it.instanceOfBuff && buff_Available(it), {
		// if it's already been chosen, give it a lower priority
		float myseencount = (it.buff_seencount > 0) ? it.buff_seencount : 1; // no division by zero please!
		RandomSelection_AddEnt(it, max(0.2, 1 / myseencount), 1);
	});
	entity newbuff = RandomSelection_chosen_ent;
	if (!newbuff)
		return;
	++newbuff.buff_seencount; // lower chances of seeing this buff again soon
	ent.buffdef = newbuff;
}

void buff_RemoveAll(entity actor, int removal_type)
{
	if (!actor.statuseffects)
		return;
	FOREACH(StatusEffects, it.instanceOfBuff, {
		it.m_remove(it, actor, removal_type);
	});
}

entity buff_FirstFromFlags(entity actor)
{
	if (!actor.statuseffects)
		return NULL;
	FOREACH(StatusEffects, it.instanceOfBuff && it.m_active(it, actor), {
		return it;
	});
	return NULL;
}

void buff_Think(entity this)
{
	if (this.buff_waypoint && autocvar_g_buffs_waypoint_distance <= 0)
		WaypointSprite_Kill(this.buff_waypoint);

	if (this.buffdef != this.oldbuffs)
	{
		entity buff = this.buffdef;
		this.color = buff.m_color;
		this.glowmod = buff.m_color;
		this.skin = buff.m_skin;

		setmodel(this, MDL_BUFF);
		setsize(this, ITEM_D_MINS, ITEM_L_MAXS);

		if (this.buff_waypoint)
		{
			//WaypointSprite_Disown(this.buff_waypoint, 1);
			WaypointSprite_Kill(this.buff_waypoint);
			buff_Waypoint_Spawn(this);
			if (this.buff_activetime)
				WaypointSprite_UpdateBuildFinished(this.buff_waypoint, time + this.buff_activetime - frametime);
		}

		this.oldbuffs = this.buffdef;
	}

	if (!game_stopped)
	if ((round_handler_IsActive() && round_handler_IsRoundStarted()) || time >= game_starttime)
	if (!this.buff_activetime_updated)
	{
		buff_SetCooldown(this, this.buff_activetime);
		this.buff_activetime_updated = true;
	}

	if (!this.buff_active && !this.buff_activetime)
	if (!this.owner || STAT(FROZEN, this.owner) || IS_DEAD(this.owner) || !this.owner.iscreature || this.owner.vehicle
		|| this.pickup_anyway > 0 || (this.pickup_anyway >= 0 && autocvar_g_buffs_pickup_anyway)
		|| this.buffdef != buff_FirstFromFlags(this.owner))
	{
		buff_SetCooldown(this, autocvar_g_buffs_cooldown_respawn + frametime);
		this.owner = NULL;
		if (autocvar_g_buffs_randomize && (!teamplay || autocvar_g_buffs_randomize_teamplay))
			buff_NewType(this);

		if (autocvar_g_buffs_random_location || (this.spawnflags & 64))
			buff_Respawn(this);
	}

	if (this.buff_activetime)
	if (!game_stopped)
	if ((round_handler_IsActive() && round_handler_IsRoundStarted()) || time >= game_starttime)
	{
		this.buff_activetime = max(0, this.buff_activetime - frametime);

		if (!this.buff_activetime)
		{
			this.buff_active = true;
			sound(this, CH_TRIGGER, SND_STRENGTH_RESPAWN, VOL_BASE, ATTN_NORM);
			Send_Effect(EFFECT_ITEM_RESPAWN, CENTER_OR_VIEWOFS(this), '0 0 0', 1);
		}
	}

	if (this.buff_active)
	{
		if (this.team_forced && !this.buff_waypoint)
			buff_Waypoint_Spawn(this);

		if (this.lifetime && time >= this.lifetime)
			buff_Respawn(this);
	}

	this.nextthink = time;
	//this.angles_y = time * 110.1;
}

void buff_Waypoint_Reset(entity this)
{
	WaypointSprite_Kill(this.buff_waypoint);

	if (this.buff_activetime)
		buff_Waypoint_Spawn(this);
}

void buff_Reset(entity this)
{
	if (autocvar_g_buffs_randomize && (!teamplay || autocvar_g_buffs_randomize_teamplay))
		buff_NewType(this);
	this.owner = NULL;
	buff_SetCooldown(this, autocvar_g_buffs_cooldown_activate);
	buff_Waypoint_Reset(this);
	this.buff_activetime_updated = false;

	if (autocvar_g_buffs_random_location || (this.spawnflags & 64))
		buff_Respawn(this);
}

bool buff_Customize(entity this, entity client)
{
	entity player = WaypointSprite_getviewentity(client);
	if ((!this.buff_active || !this.buffdef) || (this.team_forced && player.team != this.team_forced))
	{
		this.alpha = 0.3;
		if (this.effects & EF_FULLBRIGHT)
			this.effects &= ~EF_FULLBRIGHT;
		this.pflags = 0;
	}
	else
	{
		this.alpha = 1;
		if (!(this.effects & EF_FULLBRIGHT))
			this.effects |= EF_FULLBRIGHT;
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
	if (!autocvar_g_buffs)
	{
		delete(this);
		return;
	}

	entity buff = this.buffdef;

	// item_buff_random provides a null type so force randomization in that case
	// otherwise replace the buff type if it's unavailable and the option is enabled
	if (!buff || (autocvar_g_buffs_replace_available && !buff_Available(buff)))
	{
		buff_NewType(this);
		buff = this.buffdef;
	}

	// the buff type is still invalid or unavailable, simply delete the item
	if (!buff || !buff_Available(buff))
	{
		delete(this);
		return;
	}

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
	setsize(this, ITEM_D_MINS, ITEM_L_MAXS);
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

	if (!this.buffs_finished)
		this.buffs_finished = this.count; // legacy support

	if (this.spawnflags & 1)
		this.noalign = true;
	if (this.noalign)
		set_movetype(this, MOVETYPE_NONE); // reset by random location

	if (autocvar_g_buffs_random_location || (this.spawnflags & 64))
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
	ent.noalign = ITEM_SHOULD_KEEP_POSITION(old);

	buff_Init(ent);
}

METHOD(Buff, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
	if (IS_PLAYER(actor))
		actor.effects |= EF_NOSHADOW; // does not play well with buff icon
	SUPER(Buff).m_apply(this, actor, eff_time, eff_flags);
}
METHOD(Buff, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
	bool was_active = actor.statuseffects && (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE);
	if (was_active)
	{
		int buffid = this.m_id;
		if (removal_type == STATUSEFFECT_REMOVE_TIMEOUT)
		{
			Send_Notification(NOTIF_ONE, actor, MSG_MULTI, ITEM_BUFF_DROP, buffid); // TODO: special timeout message?
			sound(actor, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		}
		else if (removal_type == STATUSEFFECT_REMOVE_NORMAL && !IS_INDEPENDENT_PLAYER(actor))
			Send_Notification(NOTIF_ALL_EXCEPT, actor, MSG_INFO, INFO_ITEM_BUFF_LOST, actor.netname, buffid);
		actor.buff_shield = time + max(0, autocvar_g_buffs_pickup_delay); // always put in a delay, even if small
	}
	if (IS_PLAYER(actor))
		actor.effects &= ~EF_NOSHADOW;
	SUPER(Buff).m_remove(this, actor, removal_type);
}


// mutator hooks
MUTATOR_HOOKFUNCTION(buffs, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);
	vector frag_force = M_ARGV(6, vector);

	if (frag_deathtype == DEATH_BUFF.m_id)
		return;

	if (StatusEffects_active(BUFF_RESISTANCE, frag_target))
		frag_damage = buff_Resistance_CalculateDamage(frag_damage);

	if (StatusEffects_active(BUFF_MEDIC, frag_target))
	if (GetResource(frag_target, RES_HEALTH) - frag_damage <= 0)
	if (!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	if (frag_attacker)
		frag_damage = buff_Medic_CalculateSurviveDamage(frag_damage, GetResource(frag_target, RES_HEALTH));

	if (StatusEffects_active(BUFF_JUMP, frag_target))
		frag_damage = buff_Jump_ChangeDamage(frag_damage, frag_deathtype);

	if (StatusEffects_active(BUFF_VENGEANCE, frag_target))
	if (frag_attacker && frag_attacker != frag_target)
	if (!ITEM_DAMAGE_NEEDKILL(frag_deathtype))
	{
		entity dmgent = new_pure(dmgent);

		dmgent.dmg = buff_Vengeance_CalculateDamage(frag_damage);
		dmgent.enemy = frag_attacker;
		dmgent.owner = frag_target;
		setthink(dmgent, buff_Vengeance_DelayedDamage);
		dmgent.nextthink = time + 0.1;
	}

	if (StatusEffects_active(BUFF_BASH, frag_target))
		frag_force = buff_Bash_TargetCalculateForce(frag_force, frag_target, frag_attacker);

	if (StatusEffects_active(BUFF_BASH, frag_attacker))
		frag_force = buff_Bash_AttackerCalculateForce(frag_force, frag_target, frag_attacker);

	if (StatusEffects_active(BUFF_DISABILITY, frag_attacker))
		buff_Disability_ApplyStunned(frag_target, frag_attacker);

	if (StatusEffects_active(BUFF_INFERNO, frag_target))
	{
		if (frag_deathtype == DEATH_FIRE.m_id)
			frag_damage = 0;
		if (frag_deathtype == DEATH_LAVA.m_id)
			frag_damage *= 0.5; // TODO: cvarize?
	}

	if (frag_attacker != frag_target)
	{
		if (StatusEffects_active(BUFF_LUCK, frag_attacker))
			frag_damage = buff_Luck_CalculateDamage(frag_damage);

		if (StatusEffects_active(BUFF_INFERNO, frag_attacker))
		{
			float btime = buff_Inferno_CalculateTime(frag_damage);
			Fire_AddDamage(frag_target, frag_attacker, buff_Inferno_CalculateDamage(frag_damage), btime, DEATH_BUFF.m_id);
		}
	}

	M_ARGV(4, float) = frag_damage;
	M_ARGV(6, vector) = frag_force;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerUseKey, CBC_ORDER_FIRST)
{
	if (MUTATOR_RETURNVALUE || game_stopped || !autocvar_g_buffs_drop)
		return;

	entity player = M_ARGV(0, entity);

	entity heldbuff = buff_FirstFromFlags(player);
	if (heldbuff)
	{
		int buffid = heldbuff.m_id;
		Send_Notification(NOTIF_ONE, player, MSG_MULTI, ITEM_BUFF_DROP, buffid);
		if (!IS_INDEPENDENT_PLAYER(player))
			Send_Notification(NOTIF_ALL_EXCEPT, player, MSG_INFO, INFO_ITEM_BUFF_LOST, player.netname, buffid);

		buff_RemoveAll(player, STATUSEFFECT_REMOVE_NORMAL);
		player.buff_shield = time + max(0, autocvar_g_buffs_pickup_delay);
		sound(player, CH_TRIGGER, SND_BUFF_LOST, VOL_BASE, ATTN_NORM);
		return true;
	}
}

bool buffs_RemovePlayer(entity player)
{
	buffs_BuffModel_Remove(player);
	return false;
}
MUTATOR_HOOKFUNCTION(buffs, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);
	return buffs_RemovePlayer(player);
}
MUTATOR_HOOKFUNCTION(buffs, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);
	return buffs_RemovePlayer(player);
}

MUTATOR_HOOKFUNCTION(buffs, FilterItem)
{
	if (autocvar_g_buffs < 0)
		return false; // no auto replacing of entities in this mode

	entity item = M_ARGV(0, entity);

	if (autocvar_g_buffs_replace_powerups && item.itemdef.instanceOfPowerup)
	{
		entity e = spawn();
		buff_SpawnReplacement(e, item);
		return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(buffs, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if (game_stopped || IS_DEAD(player) || !IS_PLAYER(player))
		return;

	// NOTE: this is kept here to ensure crouches are picked up each player movement frame
	if (StatusEffects_active(BUFF_FLIGHT, player))
	{
		if (!PHYS_INPUT_BUTTON_CROUCH(player))
			player.buff_flight_crouchheld = false;
		else if (!player.buff_flight_crouchheld)
		{
			player.buff_flight_crouchheld = true;
			player.gravity *= -1;
		}
	}

	if (IS_PLAYER(player))
		buffs_BuffModel_Update(player);
}

MUTATOR_HOOKFUNCTION(buffs, BuildMutatorsString)
{
	if (autocvar_g_buffs > 0) // only report as a mutator if they're enabled
		M_ARGV(0, string) = strcat(M_ARGV(0, string), ":Buffs");
}

MUTATOR_HOOKFUNCTION(buffs, BuildMutatorsPrettyString)
{
	if (autocvar_g_buffs > 0)
		M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Buffs");
}

void buffs_DelayedInit(entity this)
{
	if (autocvar_g_buffs_spawn_count > 0)
	if (find(NULL, classname, "item_buff") == NULL)
		for (int i = 0; i < autocvar_g_buffs_spawn_count; ++i)
		{
			entity e = spawn();
			e.spawnflags |= 64; // always randomize
			e.velocity = randomvec() * 250; // this gets reset anyway if random location works
			buff_Init(e);
		}
}

void buffs_Initialize()
{
	// if buffs are above 0, allow random spawning
	if (autocvar_g_buffs > 0 && autocvar_g_buffs_spawn_count > 0)
		InitializeEntity(NULL, buffs_DelayedInit, INITPRIO_FINDTARGET);
}
