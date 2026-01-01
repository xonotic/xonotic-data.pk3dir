#include "sv_onslaught.qh"
#include "sv_controlpoint.qh"
#include "sv_generator.qh"

#include <server/bot/api.qh>
#include <server/campaign.qh>
#include <server/command/vote.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <server/world.qh>
#include <common/mapobjects/defs.qh>
#include <common/mapobjects/triggers.qh>

bool g_onslaught;

float autocvar_g_onslaught_teleport_wait;
bool autocvar_g_onslaught_spawn_at_controlpoints;
bool autocvar_g_onslaught_spawn_at_generator;
float autocvar_g_onslaught_cp_proximitydecap;
float autocvar_g_onslaught_cp_proximitydecap_distance = 512;
float autocvar_g_onslaught_cp_proximitydecap_dps = 100;
float autocvar_g_onslaught_spawn_at_controlpoints_chance = 0.5;
float autocvar_g_onslaught_spawn_at_controlpoints_random;
float autocvar_g_onslaught_spawn_at_generator_chance;
float autocvar_g_onslaught_spawn_at_generator_random;
float autocvar_g_onslaught_cp_buildhealth;
float autocvar_g_onslaught_cp_buildtime;
float autocvar_g_onslaught_cp_health;
float autocvar_g_onslaught_cp_regen;
float autocvar_g_onslaught_gen_health;
float autocvar_g_onslaught_shield_force = 100;
float autocvar_g_onslaught_allow_vehicle_touch;
float autocvar_g_onslaught_round_timelimit;
float autocvar_g_onslaught_warmup;
float autocvar_g_onslaught_teleport_radius;
float autocvar_g_onslaught_spawn_choose;
float autocvar_g_onslaught_click_radius;

// =======================
// CaptureShield Functions
// =======================

bool ons_CaptureShield_Customize(entity this, entity client)
{
	entity e = WaypointSprite_getviewentity(client);

	if(!this.enemy.isshielded && (ons_ControlPoint_Attackable(this.enemy, e.team) > 0 || this.enemy.classname != "onslaught_controlpoint")) { return false; }
	if(SAME_TEAM(this, e)) { return false; }

	return true;
}

void ons_CaptureShield_Touch(entity this, entity toucher)
{
	if(!this.enemy.isshielded && (ons_ControlPoint_Attackable(this.enemy, toucher.team) > 0 || this.enemy.classname != "onslaught_controlpoint")) { return; }
	if(!IS_PLAYER(toucher)) { return; }
	if(SAME_TEAM(toucher, this)) { return; }

	vector mymid = (this.absmin + this.absmax) * 0.5;
	vector theirmid = (toucher.absmin + toucher.absmax) * 0.5;

	Damage(toucher, this, this, 0, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, mymid, normalize(theirmid - mymid) * ons_captureshield_force);

	if(IS_REAL_CLIENT(toucher))
	{
		play2(toucher, SND(ONS_DAMAGEBLOCKEDBYSHIELD));

		if(this.enemy.classname == "onslaught_generator")
			Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_ONS_GENERATOR_SHIELDED);
		else
			Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_ONS_CONTROLPOINT_SHIELDED);
	}
}

void ons_CaptureShield_Reset(entity this)
{
	this.colormap = this.enemy.colormap;
	this.team = this.enemy.team;
}

void ons_CaptureShield_Spawn(entity this, Model shield_model)
{
	entity shield = new(ons_captureshield);
	IL_PUSH(g_onsshields, shield);

	shield.enemy = this;
	shield.team = this.team;
	shield.colormap = this.colormap;
	shield.reset = ons_CaptureShield_Reset;
	settouch(shield, ons_CaptureShield_Touch);
	setcefc(shield, ons_CaptureShield_Customize);
	shield.effects = EF_ADDITIVE;
	set_movetype(shield, MOVETYPE_NOCLIP);
	shield.solid = SOLID_TRIGGER;
	shield.avelocity = '7 0 11';
	shield.scale = this.scale;

	float shield_extra_size = 1.20; // hitbox is 20% larger than the object itself
	setorigin(shield, this.origin);
	setmodel(shield, shield_model);
	setsize(shield, shield_extra_size * this.mins, shield_extra_size * this.maxs);
}


// ==========
// Junk Pile
// ==========

void onslaught_updatelinks()
{
	entity l;
	// first check if the game has ended
	LOG_DEBUG("--- updatelinks ---");
	// mark generators as being shielded and networked
	for(l = ons_worldgeneratorlist; l; l = l.ons_worldgeneratornext)
	{
		if (l.iscaptured)
			LOG_DEBUG(etos(l), " (generator) belongs to team ", ftos(l.team));
		else
			LOG_DEBUG(etos(l), " (generator) is destroyed");
		l.islinked = l.iscaptured;
		l.isshielded = l.iscaptured;
		l.sprite.SendFlags |= 16;
	}
	// mark points as shielded and not networked
	for(l = ons_worldcplist; l; l = l.ons_worldcpnext)
	{
		l.islinked = false;
		l.isshielded = true;
		l.aregensneighbor = 0;
		l.arecpsneighbor = 0;
		LOG_DEBUG(etos(l), " (point) belongs to team ", ftos(l.team));
		l.sprite.SendFlags |= 16;
	}
	// flow power outward from the generators through the network
	bool stop = false;
	while (!stop)
	{
		stop = true;
		for(l = ons_worldlinklist; l; l = l.ons_worldlinknext)
		{
			// if both points are captured by the same team, and only one of
			// them is powered, mark the other one as powered as well
			if (l.enemy.iscaptured && l.goalentity.iscaptured)
				if (l.enemy.islinked != l.goalentity.islinked)
					if(SAME_TEAM(l.enemy, l.goalentity))
					{
						if (!l.goalentity.islinked)
						{
							stop = false;
							l.goalentity.islinked = true;
							LOG_DEBUG(etos(l), " (link) is marking ", etos(l.goalentity), " (point) because its team matches ", etos(l.enemy), " (point)");
						}
						else if (!l.enemy.islinked)
						{
							stop = false;
							l.enemy.islinked = true;
							LOG_DEBUG(etos(l), " (link) is marking ", etos(l.enemy), " (point) because its team matches ", etos(l.goalentity), " (point)");
						}
					}
		}
	}
	// now that we know which points are powered we can mark their neighbors
	// as unshielded if team differs
	for(l = ons_worldlinklist; l; l = l.ons_worldlinknext)
	{
		if (l.goalentity.islinked)
		{
			if(DIFF_TEAM(l.goalentity, l.enemy))
			{
				LOG_DEBUG(etos(l), " (link) is unshielding ", etos(l.enemy), " (point) because its team does not match ", etos(l.goalentity), " (point)");
				l.enemy.isshielded = false;
			}
			if(l.goalentity.classname == "onslaught_generator")
				l.enemy.aregensneighbor |= BIT(l.goalentity.team);
			else
				l.enemy.arecpsneighbor |= BIT(l.goalentity.team);
		}
		if (l.enemy.islinked)
		{
			if(DIFF_TEAM(l.goalentity, l.enemy))
			{
				LOG_DEBUG(etos(l), " (link) is unshielding ", etos(l.goalentity), " (point) because its team does not match ", etos(l.enemy), " (point)");
				l.goalentity.isshielded = false;
			}
			if(l.enemy.classname == "onslaught_generator")
				l.goalentity.aregensneighbor |= BIT(l.enemy.team);
			else
				l.goalentity.arecpsneighbor |= BIT(l.enemy.team);
		}
	}
	// now update the generators
	for(l = ons_worldgeneratorlist; l; l = l.ons_worldgeneratornext)
	{
		if (l.isshielded)
		{
			LOG_DEBUG(etos(l), " (generator) is shielded");
			l.takedamage = DAMAGE_NO;
			if(l.bot_attack)
				IL_REMOVE(g_bot_targets, l);
			l.bot_attack = false;
		}
		else
		{
			LOG_DEBUG(etos(l), " (generator) is not shielded");
			l.takedamage = DAMAGE_AIM;
			if(!l.bot_attack)
				IL_PUSH(g_bot_targets, l);
			l.bot_attack = true;
		}

		ons_Generator_UpdateSprite(l);
	}
	// now update the takedamage and alpha variables on control point icons
	for(l = ons_worldcplist; l; l = l.ons_worldcpnext)
	{
		if (l.isshielded)
		{
			LOG_DEBUG(etos(l), " (point) is shielded");
			if (l.goalentity)
			{
				l.goalentity.takedamage = DAMAGE_NO;
				if(l.goalentity.bot_attack)
					IL_REMOVE(g_bot_targets, l.goalentity);
				l.goalentity.bot_attack = false;
			}
		}
		else
		{
			LOG_DEBUG(etos(l), " (point) is not shielded");
			if (l.goalentity)
			{
				l.goalentity.takedamage = DAMAGE_AIM;
				if(!l.goalentity.bot_attack)
					IL_PUSH(g_bot_targets, l.goalentity);
				l.goalentity.bot_attack = true;
			}
		}
		ons_ControlPoint_UpdateSprite(l);
	}
	IL_EACH(g_onsshields, true,
	{
		it.team = it.enemy.team;
		it.colormap = it.enemy.colormap;
	});
}


// ===================
// Main Link Functions
// ===================

bool ons_Link_Send(entity this, entity to, int sendflags)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_RADARLINK);
	WriteByte(MSG_ENTITY, sendflags);
	if(sendflags & 1)
	{
		WriteVector(MSG_ENTITY, this.goalentity.origin);
	}
	if(sendflags & 2)
	{
		WriteVector(MSG_ENTITY, this.enemy.origin);
	}
	if(sendflags & 4)
	{
		WriteByte(MSG_ENTITY, this.clientcolors); // which is goalentity's color + enemy's color * 16
	}
	return true;
}

void ons_Link_CheckUpdate(entity this)
{
	// TODO check if the two sides have moved (currently they won't move anyway)
	float cc = 0, cc1 = 0, cc2 = 0;

	if(this.goalentity.islinked || this.goalentity.iscaptured) { cc1 = (this.goalentity.team - 1) * 0x01; }
	if(this.enemy.islinked || this.enemy.iscaptured) { cc2 = (this.enemy.team - 1) * 0x10; }

	cc = cc1 + cc2;

	if(cc != this.clientcolors)
	{
		this.clientcolors = cc;
		this.SendFlags |= 4;
	}

	this.nextthink = time;
}

void ons_DelayedLinkSetup(entity this)
{
	this.goalentity = find(NULL, targetname, this.target);
	this.enemy = find(NULL, targetname, this.target2);
	if(!this.goalentity) { objerror(this, "can not find target\n"); }
	if(!this.enemy) { objerror(this, "can not find target2\n"); }

	LOG_DEBUG(etos(this.goalentity), " linked with ", etos(this.enemy));
	this.SendFlags |= 3;
	setthink(this, ons_Link_CheckUpdate);
	this.nextthink = time;
}


// =============================
// Main Control Point Functions
// =============================

int ons_ControlPoint_CanBeLinked(entity cp, int teamnum)
{
	if(cp.aregensneighbor & BIT(teamnum)) return 2;
	if(cp.arecpsneighbor & BIT(teamnum)) return 1;

	return 0;
}

// return values:
// -2: SAME TEAM, attackable by enemy!
// -1: SAME TEAM!
// 0: off limits
// 1: attack it
// 2: touch it
// 3: attack it (HIGH PRIO)
// 4: touch it (HIGH PRIO)
int ons_ControlPoint_Attackable(entity cp, int teamnum)
{
	int a;

	if(cp.isshielded)
	{
		return 0;
	}
	else if(cp.goalentity)
	{
		// if there's already an icon built, nothing happens
		if(cp.team == teamnum)
		{
			a = ons_ControlPoint_CanBeLinked(cp, teamnum);
			if(a) // attackable by enemy?
				return -2; // EMERGENCY!
			return -1;
		}
		// we know it can be linked, so no need to check
		// but...
		a = ons_ControlPoint_CanBeLinked(cp, teamnum);
		if(a == 2) // near our generator?
			return 3; // EMERGENCY!
		return 1;
	}
	else
	{
		// free point
		if(ons_ControlPoint_CanBeLinked(cp, teamnum))
		{
			a = ons_ControlPoint_CanBeLinked(cp, teamnum); // why was this here NUM_TEAM_1 + NUM_TEAM_2 - t
			if(a == 2)
				return 4; // GET THIS ONE NOW!
			else
				return 2; // TOUCH ME
		}
	}
	return 0;
}

void ons_ControlPoint_Icon_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(damage <= 0) { return; }

	if (this.owner.isshielded)
	{
		// this is protected by a shield, so ignore the damage
		if (time > this.pain_finished)
			if (IS_PLAYER(attacker))
			{
				play2(attacker, SND(ONS_DAMAGEBLOCKEDBYSHIELD));
				this.pain_finished = time + 1;
				attacker.typehitsound += 1; // play both sounds (shield is way too quiet)
			}

		return;
	}

	if(IS_PLAYER(attacker))
	if(time - ons_notification_time[this.team] > 10)
	{
		play2team(this.team, SND(ONS_CONTROLPOINT_UNDERATTACK));
		ons_notification_time[this.team] = time;
	}

	TakeResource(this, RES_HEALTH, damage);
	if(this.owner.iscaptured)
		WaypointSprite_UpdateHealth(this.owner.sprite, GetResource(this, RES_HEALTH));
	else
		WaypointSprite_UpdateBuildFinished(this.owner.sprite, time + (this.max_health - GetResource(this, RES_HEALTH)) / (this.count / ONS_CP_THINKRATE));
	this.pain_finished = time + 1;
	// particles on every hit
	pointparticles(EFFECT_SPARKS, hitloc, force*-1, 1);
	//sound on every hit
	if (random() < 0.5)
		sound(this, CH_TRIGGER, SND_ONS_HIT1, VOL_BASE+0.3, ATTEN_NORM);
	else
		sound(this, CH_TRIGGER, SND_ONS_HIT2, VOL_BASE+0.3, ATTEN_NORM);

	if (GetResource(this, RES_HEALTH) <= 0)
	{
		sound(this, CH_TRIGGER, SND_ONS_GENERATOR_EXPLODE, VOL_BASE, ATTEN_NORM);
		pointparticles(EFFECT_ROCKET_EXPLODE, this.origin, '0 0 0', 1);

		if (attacker != this)
		{
			GameRules_scoring_add(attacker, ONS_TAKES, 1);
			GameRules_scoring_add(attacker, SCORE, 10);
		}
		else
		{
			FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it), {
				if(vdist(it.origin - this.origin, <, autocvar_g_onslaught_cp_proximitydecap_distance))
				{
					if(DIFF_TEAM(it, this))
					{
						if (attacker == this)
							attacker = it; // show message only for this player
						// reward all players
						GameRules_scoring_add(it, ONS_TAKES, 1);
						GameRules_scoring_add(it, SCORE, 5);
					}
				}
			});
		}

		if (this.owner.message != "")
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(this.team, INFO_ONSLAUGHT_CPDESTROYED), this.owner.message, attacker.netname);
		else
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(this.team, INFO_ONSLAUGHT_CPDESTROYED_NONAME), attacker.netname);

		this.owner.goalentity = NULL;
		this.owner.islinked = false;
		this.owner.iscaptured = false;
		this.owner.team = 0;
		this.owner.colormap = 1024;

		WaypointSprite_UpdateMaxHealth(this.owner.sprite, 0);

		onslaught_updatelinks();

		// Use targets now (somebody make sure this is in the right place..)
		SUB_UseTargets(this.owner, this, NULL);

		this.owner.waslinked = this.owner.islinked;
		if(this.owner.model != "models/onslaught/controlpoint_pad.md3")
			setmodel(this.owner, MDL_ONS_CP_PAD1);
		//setsize(this, '-32 -32 0', '32 32 8');

		delete(this);
	}

	this.SendFlags |= CPSF_STATUS;
}

bool ons_ControlPoint_Icon_Heal(entity targ, entity inflictor, float amount, float limit)
{
	float hlth = GetResource(targ, RES_HEALTH);
	float true_limit = ((limit != RES_LIMIT_NONE) ? limit : targ.max_health);
	if (hlth <= 0 || hlth >= true_limit)
		return false;

	GiveResourceWithLimit(targ, RES_HEALTH, amount, true_limit);
	hlth = GetResource(targ, RES_HEALTH);
	if(targ.owner.iscaptured)
		WaypointSprite_UpdateHealth(targ.owner.sprite, hlth);
	else
		WaypointSprite_UpdateBuildFinished(targ.owner.sprite, time + (targ.max_health - hlth) / (targ.count / ONS_CP_THINKRATE));
	targ.SendFlags |= CPSF_STATUS;
	return true;
}

void ons_ControlPoint_Icon_Think(entity this)
{
	this.nextthink = time + ONS_CP_THINKRATE;

	if (!this.owner.isshielded && autocvar_g_onslaught_cp_proximitydecap)
	{
		int _enemy_count = 0;
		entity first_enemy = NULL;
		int _friendly_count = 0;

		FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it), {
			if(vdist(it.origin - this.origin, <, autocvar_g_onslaught_cp_proximitydecap_distance))
			{
				if(SAME_TEAM(it, this))
					++_friendly_count;
				else
				{
					++_enemy_count;
					if (!first_enemy)
						first_enemy = it;
				}
			}
		});

		float hlt = (_friendly_count - _enemy_count) * (autocvar_g_onslaught_cp_proximitydecap_dps * ONS_CP_THINKRATE);

		if (hlt < 0)
			TakeResource(this, RES_HEALTH, -hlt);
		else if (hlt > 0)
			GiveResourceWithLimit(this, RES_HEALTH, hlt, this.max_health);
		this.SendFlags |= CPSF_STATUS;
		if(GetResource(this, RES_HEALTH) <= 0)
		{
			// if we get here then _enemy_count >= 1
			entity attacker = first_enemy;
			if (_enemy_count > 1)
				attacker = this; // tell ons_ControlPoint_Icon_Damage to find all attackers
			ons_ControlPoint_Icon_Damage(this, this, attacker, 1, 0, DMG_NOWEP, this.origin, '0 0 0');
			return;
		}
	}

	if (time > this.pain_finished + 5)
	{
		if(GetResource(this, RES_HEALTH) < this.max_health)
		{
			GiveResourceWithLimit(this, RES_HEALTH, this.count, this.max_health);
			WaypointSprite_UpdateHealth(this.owner.sprite, GetResource(this, RES_HEALTH));
		}
	}

	if(this.owner.islinked != this.owner.waslinked)
	{
		// unteam the spawnpoint if needed
		int t = this.owner.team;
		if(!this.owner.islinked)
			this.owner.team = 0;

		SUB_UseTargets(this.owner, this, NULL);

		this.owner.team = t;

		this.owner.waslinked = this.owner.islinked;
	}

	// damaged fx
	if(random() < 0.6 - GetResource(this, RES_HEALTH) / this.max_health)
	{
		Send_Effect(EFFECT_ELECTRIC_SPARKS, this.origin + randompos('-10 -10 -20', '10 10 20'), '0 0 0', 1);

		if(random() > 0.8)
			sound(this, CH_PAIN, SND_ONS_SPARK1, VOL_BASE, ATTEN_NORM);
		else if (random() > 0.5)
			sound(this, CH_PAIN, SND_ONS_SPARK2, VOL_BASE, ATTEN_NORM);
	}
}

void ons_ControlPoint_Icon_BuildThink(entity this)
{
	int a;

	this.nextthink = time + ONS_CP_THINKRATE;

	// only do this if there is power
	a = ons_ControlPoint_CanBeLinked(this.owner, this.owner.team);
	if(!a)
		return;

	GiveResource(this, RES_HEALTH, this.count);

	this.SendFlags |= CPSF_STATUS;

	if (GetResource(this, RES_HEALTH) >= this.max_health)
	{
		SetResourceExplicit(this, RES_HEALTH, this.max_health);
		this.count = autocvar_g_onslaught_cp_regen * ONS_CP_THINKRATE; // slow repair rate from now on
		setthink(this, ons_ControlPoint_Icon_Think);
		sound(this, CH_TRIGGER, SND_ONS_CONTROLPOINT_BUILT, VOL_BASE, ATTEN_NORM);
		this.owner.iscaptured = true;
		this.solid = SOLID_BBOX;
		setorigin(this, this.origin); // setorigin after change to solid field to ensure area grid linking

		Send_Effect(EFFECT_CAP(this.owner.team), this.owner.origin, '0 0 0', 1);

		WaypointSprite_UpdateMaxHealth(this.owner.sprite, this.max_health);
		WaypointSprite_UpdateHealth(this.owner.sprite, GetResource(this, RES_HEALTH));

		if(IS_PLAYER(this.owner.ons_toucher))
		{
			if(this.owner.message != "")
			{
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ONSLAUGHT_CAPTURE, this.owner.ons_toucher.netname, this.owner.message);
				Send_Notification(NOTIF_ALL_EXCEPT, this.owner.ons_toucher, MSG_CENTER, APP_TEAM_NUM(this.owner.ons_toucher.team, CENTER_ONS_CAPTURE_TEAM), this.owner.message);
				Send_Notification(NOTIF_ONE, this.owner.ons_toucher, MSG_CENTER, CENTER_ONS_CAPTURE, this.owner.message);
			}
			else
			{
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ONSLAUGHT_CAPTURE_NONAME, this.owner.ons_toucher.netname);
				Send_Notification(NOTIF_ALL_EXCEPT, this.owner.ons_toucher, MSG_CENTER, APP_TEAM_NUM(this.owner.ons_toucher.team, CENTER_ONS_CAPTURE_TEAM_NONAME));
				Send_Notification(NOTIF_ONE, this.owner.ons_toucher, MSG_CENTER, CENTER_ONS_CAPTURE_NONAME);
			}
			GameRules_scoring_add(this.owner.ons_toucher, ONS_CAPS, 1);
			GameRules_scoring_add_team(this.owner.ons_toucher, SCORE, 10);
		}

		this.owner.ons_toucher = NULL;

		onslaught_updatelinks();

		// Use targets now (somebody make sure this is in the right place..)
		SUB_UseTargets(this.owner, this, NULL);

		this.SendFlags |= CPSF_SETUP;
	}
	if(this.owner.model != MDL_ONS_CP_PAD2.model_str())
		setmodel(this.owner, MDL_ONS_CP_PAD2);

	if(random() < 0.9 - GetResource(this, RES_HEALTH) / this.max_health)
		Send_Effect(EFFECT_RAGE, this.origin + 10 * randomvec(), '0 0 -1', 1);
}

void onslaught_controlpoint_icon_link(entity e, void(entity this) spawnproc);

void ons_ControlPoint_Icon_Spawn(entity cp, entity player)
{
	entity e = new(onslaught_controlpoint_icon);

	e.solid = SOLID_NOT; // before setsize/setorigin to prevent area grid linking
	setsize(e, CPICON_MIN, CPICON_MAX);
	setorigin(e, cp.origin + CPICON_OFFSET);

	e.owner = cp;
	e.max_health = autocvar_g_onslaught_cp_health;
	SetResourceExplicit(e, RES_HEALTH, autocvar_g_onslaught_cp_buildhealth);
	e.takedamage = DAMAGE_AIM;
	e.bot_attack = true;
	IL_PUSH(g_bot_targets, e);
	e.event_damage = ons_ControlPoint_Icon_Damage;
	e.event_heal = ons_ControlPoint_Icon_Heal;
	e.team = player.team;
	e.colormap = 1024 + (e.team - 1) * 17;
	e.count = (e.max_health - GetResource(e, RES_HEALTH)) * ONS_CP_THINKRATE / autocvar_g_onslaught_cp_buildtime; // how long it takes to build

	sound(e, CH_TRIGGER, SND_ONS_CONTROLPOINT_BUILD, VOL_BASE, ATTEN_NORM);

	cp.goalentity = e;
	cp.team = e.team;
	cp.colormap = e.colormap;

	Send_Effect(EFFECT_FLAG_TOUCH(player.team), e.origin, '0 0 0', 1);

	WaypointSprite_UpdateBuildFinished(cp.sprite, time + (e.max_health - GetResource(e, RES_HEALTH)) / (e.count / ONS_CP_THINKRATE));
	WaypointSprite_UpdateRule(cp.sprite,cp.team,SPRITERULE_TEAMPLAY);
	cp.sprite.SendFlags |= 16;

	onslaught_controlpoint_icon_link(e, ons_ControlPoint_Icon_BuildThink);
}

entity ons_ControlPoint_Waypoint(entity e)
{
	if(e.team)
	{
		int a = ons_ControlPoint_Attackable(e, e.team);

		if(a == -2) { return WP_OnsCPDefend; } // defend now
		if(a == -1 || a == 1 || a == 2) { return WP_OnsCP; } // touch
		if(a == 3 || a == 4) { return WP_OnsCPAttack; } // attack
	}
	else
		return WP_OnsCP;

	return WP_Null;
}

void ons_ControlPoint_UpdateSprite(entity e)
{
	entity s1 = ons_ControlPoint_Waypoint(e);
	WaypointSprite_UpdateSprites(e.sprite, s1, s1, s1);

	bool sh;
	sh = !(ons_ControlPoint_CanBeLinked(e, NUM_TEAM_1) || ons_ControlPoint_CanBeLinked(e, NUM_TEAM_2) || ons_ControlPoint_CanBeLinked(e, NUM_TEAM_3) || ons_ControlPoint_CanBeLinked(e, NUM_TEAM_4));

	if(e.lastteam != e.team + 2 || e.lastshielded != sh || e.iscaptured != e.lastcaptured)
	{
		if(e.iscaptured) // don't mess up build bars!
		{
			if(sh)
			{
				WaypointSprite_UpdateMaxHealth(e.sprite, 0);
			}
			else
			{
				WaypointSprite_UpdateMaxHealth(e.sprite, e.goalentity.max_health);
				WaypointSprite_UpdateHealth(e.sprite, GetResource(e.goalentity, RES_HEALTH));
			}
		}
		if(e.lastshielded)
		{
			if(e.team)
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_CONTROLPOINT, 0.5 * colormapPaletteColor(e.team - 1, false));
			else
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_CONTROLPOINT, '0.5 0.5 0.5');
		}
		else
		{
			if(e.team)
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_CONTROLPOINT, colormapPaletteColor(e.team - 1, false));
			else
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_CONTROLPOINT, '0.75 0.75 0.75');
		}
		WaypointSprite_Ping(e.sprite);

		e.lastteam = e.team + 2;
		e.lastshielded = sh;
		e.lastcaptured = e.iscaptured;
	}
}

void ons_ControlPoint_Touch(entity this, entity toucher)
{
	int attackable;

	if(IS_VEHICLE(toucher) && toucher.owner)
	{
		if (!autocvar_g_onslaught_allow_vehicle_touch)
			return;
		toucher = toucher.owner;
	}

	if(!IS_PLAYER(toucher)) { return; }
	if(IS_DEAD(toucher)) { return; }

	if ( SAME_TEAM(this,toucher) )
	if ( this.iscaptured )
	{
		if(time <= toucher.teleport_antispam)
			Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_ONS_TELEPORT_ANTISPAM, rint(toucher.teleport_antispam - time));
		else
			Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_ONS_TELEPORT);
	}

	attackable = ons_ControlPoint_Attackable(this, toucher.team);
	if(attackable != 2 && attackable != 4)
		return;
	// we've verified that this player has a legitimate claim to this point,
	// so start building the captured point icon (which only captures this
	// point if it successfully builds without being destroyed first)
	ons_ControlPoint_Icon_Spawn(this, toucher);

	this.ons_toucher = toucher;

	onslaught_updatelinks();
}

void ons_ControlPoint_Think(entity this)
{
	this.nextthink = time + ONS_CP_THINKRATE;
	CSQCMODEL_AUTOUPDATE(this);
}

void ons_ControlPoint_Reset(entity this)
{
	if(this.goalentity)
		delete(this.goalentity);

	this.goalentity = NULL;
	this.team = 0;
	this.colormap = 1024;
	this.iscaptured = false;
	this.islinked = false;
	this.isshielded = true;
	setthink(this, ons_ControlPoint_Think);
	this.ons_toucher = NULL;
	this.nextthink = time + ONS_CP_THINKRATE;
	setmodel(this, MDL_ONS_CP_PAD1);

	WaypointSprite_UpdateMaxHealth(this.sprite, 0);
	WaypointSprite_UpdateRule(this.sprite,this.team,SPRITERULE_TEAMPLAY);

	onslaught_updatelinks();

	SUB_UseTargets(this, this, NULL); // to reset the structures, playerspawns etc.

	CSQCMODEL_AUTOUPDATE(this);
}

void ons_DelayedControlPoint_Setup(entity this)
{
	onslaught_updatelinks();

	// captureshield setup
	ons_CaptureShield_Spawn(this, MDL_ONS_CP_SHIELD);

	CSQCMODEL_AUTOINIT(this);
}

void ons_ControlPoint_Setup(entity cp)
{
	// main setup
	cp.ons_worldcpnext = ons_worldcplist; // link control point into ons_worldcplist
	ons_worldcplist = cp;

	cp.netname = "Control point";
	cp.team = 0;
	cp.solid = SOLID_BBOX;
	set_movetype(cp, MOVETYPE_NONE);
	settouch(cp, ons_ControlPoint_Touch);
	setthink(cp, ons_ControlPoint_Think);
	cp.nextthink = time + ONS_CP_THINKRATE;
	cp.reset = ons_ControlPoint_Reset;
	cp.colormap = 1024;
	cp.iscaptured = false;
	cp.islinked = false;
	cp.isshielded = true;

	// appearence
	setmodel(cp, MDL_ONS_CP_PAD1);

	// control point placement
	if((cp.spawnflags & 1) || cp.noalign) // don't drop to floor, just stay at fixed location
	{
		cp.noalign = true;
		set_movetype(cp, MOVETYPE_NONE);
	}
	else // drop to floor, automatically find a platform and set that as spawn origin
	{
		setorigin(cp, cp.origin + '0 0 20');
		cp.noalign = false;
		DropToFloor_QC_DelayedInit(cp);
		set_movetype(cp, MOVETYPE_TOSS);
	}

	// waypointsprites
	WaypointSprite_SpawnFixed(WP_Null, cp.origin + CPGEN_WAYPOINT_OFFSET, cp, sprite, RADARICON_NONE);
	WaypointSprite_UpdateRule(cp.sprite, cp.team, SPRITERULE_TEAMPLAY);

	InitializeEntity(cp, ons_DelayedControlPoint_Setup, INITPRIO_SETLOCATION);
}


// =========================
// Main Generator Functions
// =========================

entity ons_Generator_Waypoint(entity e)
{
	if (e.isshielded)
		return WP_OnsGenShielded;
	return WP_OnsGen;
}

void ons_Generator_UpdateSprite(entity e)
{
	entity s1 = ons_Generator_Waypoint(e);
	WaypointSprite_UpdateSprites(e.sprite, s1, s1, s1);

	if(e.lastteam != e.team + 2 || e.lastshielded != e.isshielded)
	{
		e.lastteam = e.team + 2;
		e.lastshielded = e.isshielded;
		if(e.lastshielded)
		{
			if(e.team)
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_GENERATOR, 0.5 * colormapPaletteColor(e.team - 1, false));
			else
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_GENERATOR, '0.5 0.5 0.5');
		}
		else
		{
			if(e.team)
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_GENERATOR, colormapPaletteColor(e.team - 1, false));
			else
				WaypointSprite_UpdateTeamRadar(e.sprite, RADARICON_GENERATOR, '0.75 0.75 0.75');
		}
		WaypointSprite_Ping(e.sprite);
	}
}

entity cam;
bool clientcamera_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_ONSCAMERA);
	WriteVector(MSG_ENTITY, this.origin);
	WriteAngleVector(MSG_ENTITY, this.angles);
	return true;
}

void ons_camSetup(entity this)
{
	vector dir;
	vector ang = '0 0 0';
	vector best_ang = '0 0 0';
	float best_trace_fraction = 0;
	while(ang.y < 360)
	{
		dir = vec2(cos(ang.y * DEG2RAD), sin(ang.y * DEG2RAD));
		dir *= 500;
		traceline(this.origin, this.origin - dir, MOVE_WORLDONLY, this);
		if(trace_fraction > best_trace_fraction)
		{
			best_trace_fraction = trace_fraction;
			best_ang = ang;
			if(trace_fraction == 1)
				break;
		}
		ang.y += 90;
		if(ang.y == 360)
			ang.y = 45;
	}
	cam.origin = this.origin;
	setorigin(cam, cam.origin);
	cam.angles = best_ang;
	Net_LinkEntity(cam, false, 0, clientcamera_send);

	FOREACH_CLIENT(true, it.clientcamera = cam;);

	// NOTE: engine networked
	WriteByte(MSG_ALL, SVC_SETVIEWANGLES);
	WriteAngle(MSG_ALL, cam.angles_x);
	WriteAngle(MSG_ALL, cam.angles_y);
	WriteAngle(MSG_ALL, cam.angles_z);
}

void ons_GeneratorDamage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(damage <= 0) return;
	if(warmup_stage || game_stopped) return;
	if(!round_handler_IsRoundStarted()) return;

	if (attacker != this)
	{
		if (this.isshielded)
		{
			// generator is protected by a shield, so ignore the damage
			if (time > this.pain_finished)
				if (IS_PLAYER(attacker))
				{
					play2(attacker, SND(ONS_DAMAGEBLOCKEDBYSHIELD));
					attacker.typehitsound += 1;
					this.pain_finished = time + 1;
				}
			return;
		}
		if (time > this.pain_finished)
		{
			this.pain_finished = time + 10;
			FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it) && SAME_TEAM(it, this), Send_Notification(NOTIF_ONE, it, MSG_CENTER, CENTER_GENERATOR_UNDERATTACK));
			play2team(this.team, SND(ONS_GENERATOR_UNDERATTACK));
		}
	}
	TakeResource(this, RES_HEALTH, damage);
	float hlth = GetResource(this, RES_HEALTH);
	WaypointSprite_UpdateHealth(this.sprite, hlth);
	// choose an animation frame based on health
	this.frame = 10 * bound(0, (1 - hlth / this.max_health), 1);
	// see if the generator is still functional, or dying
	if (hlth > 0)
	{
		this.lasthealth = hlth;
	}
	else
	{
		if (attacker == this)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(this.team, INFO_ONSLAUGHT_GENDESTROYED_OVERTIME));
		else
		{
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(this.team, INFO_ONSLAUGHT_GENDESTROYED));
			GameRules_scoring_add(attacker, SCORE, 100);
		}
		this.iscaptured = false;
		this.islinked = false;
		this.isshielded = false;
		this.takedamage = DAMAGE_NO; // can't be hurt anymore
		this.event_damage = func_null; // won't do anything if hurt
		this.event_heal = func_null;
		this.count = 0;	// reset counter
		setthink(this, func_null);
		this.nextthink = 0;
		//this.think(); // do the first explosion now

		WaypointSprite_UpdateMaxHealth(this.sprite, 0);
		WaypointSprite_Ping(this.sprite);
		//WaypointSprite_Kill(this.sprite); // can't do this yet, code too poor

		onslaught_updatelinks();

		ons_camSetup(this);
	}

	// Throw some flaming gibs on damage, more damage = more chance for gib
	if(random() < damage/220)
	{
		sound(this, CH_TRIGGER, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);
	}
	else
	{
		// particles on every hit
		Send_Effect(EFFECT_SPARKS, hitloc, force * -1, 1);

		//sound on every hit
		if (random() < 0.5)
			sound(this, CH_TRIGGER, SND_ONS_HIT1, VOL_BASE, ATTEN_NORM);
		else
			sound(this, CH_TRIGGER, SND_ONS_HIT2, VOL_BASE, ATTEN_NORM);
	}

	this.SendFlags |= GSF_STATUS;
}

bool ons_GeneratorHeal(entity targ, entity inflictor, float amount, float limit)
{
	float true_limit = ((limit != RES_LIMIT_NONE) ? limit : targ.max_health);
	float hlth = GetResource(targ, RES_HEALTH);
	if (hlth <= 0 || hlth >= true_limit)
		return false;

	GiveResourceWithLimit(targ, RES_HEALTH, amount, true_limit);
	hlth = GetResource(targ, RES_HEALTH);
	WaypointSprite_UpdateHealth(targ.sprite, hlth);
	targ.frame = 10 * bound(0, (1 - hlth / targ.max_health), 1);
	targ.lasthealth = hlth;
	targ.SendFlags |= GSF_STATUS;
	return true;
}

void ons_GeneratorThink(entity this)
{
	this.nextthink = time + GEN_THINKRATE;

	if (game_stopped || this.isshielded || time < this.wait)
		return;

	this.wait = time + 5;
	FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it),
	{
		if (SAME_TEAM(it, this))
		{
			Send_Notification(NOTIF_ONE, it, MSG_CENTER, CENTER_ONS_NOTSHIELDED_TEAM);
			msg_entity = it;
			soundto(MSG_ONE, this, CHAN_AUTO, SND(ONS_GENERATOR_ALARM), VOL_BASE, ATTEN_NONE, 0);
		}
		else
			Send_Notification(NOTIF_ONE, it, MSG_CENTER, APP_TEAM_NUM(this.team, CENTER_ONS_NOTSHIELDED));
	});
}

void ons_GeneratorReset(entity this)
{
	this.team = this.team_saved;
	SetResourceExplicit(this, RES_HEALTH, autocvar_g_onslaught_gen_health);
	this.lasthealth = this.max_health = autocvar_g_onslaught_gen_health;
	this.takedamage = DAMAGE_AIM;
	this.bot_attack = true;
	if(!IL_CONTAINS(g_bot_targets, this))
		IL_PUSH(g_bot_targets, this);
	this.iscaptured = true;
	this.islinked = true;
	this.isshielded = true;
	this.event_damage = ons_GeneratorDamage;
	this.event_heal = ons_GeneratorHeal;
	setthink(this, ons_GeneratorThink);
	this.nextthink = time + GEN_THINKRATE;

	Net_LinkEntity(this, false, 0, generator_send);

	this.SendFlags = GSF_SETUP; // just incase
	this.SendFlags |= GSF_STATUS;

	WaypointSprite_UpdateMaxHealth(this.sprite, this.max_health);
	WaypointSprite_UpdateHealth(this.sprite, GetResource(this, RES_HEALTH));
	WaypointSprite_UpdateRule(this.sprite,this.team,SPRITERULE_TEAMPLAY);

	onslaught_updatelinks();
}

void ons_DelayedGeneratorSetup(entity this)
{
	// bot waypoints
	waypoint_spawnforitem_force(this, this.origin);
	this.nearestwaypointtimeout = 0; // activate waypointing again
	this.bot_basewaypoint = this.nearestwaypoint;

	// captureshield setup
	ons_CaptureShield_Spawn(this, MDL_ONS_GEN_SHIELD);

	onslaught_updatelinks();

	Net_LinkEntity(this, false, 0, generator_send);
}


void onslaught_generator_touch(entity this, entity toucher)
{
	if ( IS_PLAYER(toucher) )
	if ( SAME_TEAM(this,toucher) )
	if ( this.iscaptured )
	{
		Send_Notification(NOTIF_ONE, toucher, MSG_CENTER, CENTER_ONS_TELEPORT);
	}
}

void ons_GeneratorSetup(entity gen) // called when spawning a generator entity on the map as a spawnfunc
{
	// declarations
	int teamnum = gen.team;

	// main setup
	gen.ons_worldgeneratornext = ons_worldgeneratorlist; // link generator into ons_worldgeneratorlist
	ons_worldgeneratorlist = gen;

	gen.netname = sprintf("%s generator", Team_ColoredFullName(teamnum));
	gen.solid = SOLID_BBOX;
	gen.team_saved = teamnum;
	IL_PUSH(g_saved_team, gen);
	set_movetype(gen, MOVETYPE_NONE);
	gen.lasthealth = gen.max_health = autocvar_g_onslaught_gen_health;
	SetResourceExplicit(gen, RES_HEALTH, autocvar_g_onslaught_gen_health);
	gen.takedamage = DAMAGE_AIM;
	gen.bot_attack = true;
	IL_PUSH(g_bot_targets, gen);
	gen.event_damage = ons_GeneratorDamage;
	gen.event_heal = ons_GeneratorHeal;
	gen.reset = ons_GeneratorReset;
	setthink(gen, ons_GeneratorThink);
	gen.nextthink = time + GEN_THINKRATE;
	gen.iscaptured = true;
	gen.islinked = true;
	gen.isshielded = true;
	settouch(gen, onslaught_generator_touch);

	// appearence
	// model handled by CSQC
	setsize(gen, GENERATOR_MIN, GENERATOR_MAX);
	setorigin(gen, (gen.origin + CPGEN_SPAWN_OFFSET));
	gen.colormap = 1024 + (teamnum - 1) * 17;

	// generator placement
	DropToFloor_QC_DelayedInit(gen);

	// waypointsprites
	WaypointSprite_SpawnFixed(WP_Null, gen.origin + CPGEN_WAYPOINT_OFFSET, gen, sprite, RADARICON_NONE);
	WaypointSprite_UpdateRule(gen.sprite, gen.team, SPRITERULE_TEAMPLAY);
	WaypointSprite_UpdateMaxHealth(gen.sprite, gen.max_health);
	WaypointSprite_UpdateHealth(gen.sprite, GetResource(gen, RES_HEALTH));

	InitializeEntity(gen, ons_DelayedGeneratorSetup, INITPRIO_SETLOCATION);
}


// ===============
//  Round Handler
// ===============

int total_generators;
void Onslaught_count_generators()
{
	entity e;
	total_generators = 0;
	for (int i = 1; i <= NUM_TEAMS; ++i)
	{
		Team_SetNumberOfOwnedItems(Team_GetTeamFromIndex(i), 0);
	}
	for(e = ons_worldgeneratorlist; e; e = e.ons_worldgeneratornext)
	{
		++total_generators;
		if (GetResource(e, RES_HEALTH) < 1)
		{
			continue;
		}
		entity team_ = Entity_GetTeam(e);
		int num_generators = Team_GetNumberOfOwnedItems(team_);
		++num_generators;
		Team_SetNumberOfOwnedItems(team_, num_generators);
	}
}

bool Onslaught_CheckWinner()
{
	if ((autocvar_timelimit && time > game_starttime + autocvar_timelimit * 60) || (round_handler_GetEndTime() > 0 && round_handler_GetEndTime() - time <= 0))
	{
		ons_stalemate = true;

		if (!wpforenemy_announced)
		{
			Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_OVERTIME_CONTROLPOINT);
			sound(NULL, CH_INFO, SND_ONS_GENERATOR_DECAY, VOL_BASE, ATTEN_NONE);

			wpforenemy_announced = true;
		}

		entity tmp_entity; // temporary entity
		float d;
		for(tmp_entity = ons_worldgeneratorlist; tmp_entity; tmp_entity = tmp_entity.ons_worldgeneratornext) if(time >= tmp_entity.ons_overtime_damagedelay)
		{
			// tmp_entity.max_health / 300 gives 5 minutes of overtime.
			// control points reduce the overtime duration.
			d = 1;
			entity e;
			for(e = ons_worldcplist; e; e = e.ons_worldcpnext)
			{
				if(DIFF_TEAM(e, tmp_entity))
				if(e.islinked)
					d = d + 1;
			}

			if(autocvar_g_campaign && autocvar__campaign_testrun)
				d = d * tmp_entity.max_health;
			else
				d = d * tmp_entity.max_health / max(30, 60 * autocvar_timelimit_suddendeath);

			Damage(tmp_entity, tmp_entity, tmp_entity, d, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, tmp_entity.origin, '0 0 0');

			tmp_entity.sprite.SendFlags |= 16;

			tmp_entity.ons_overtime_damagedelay = time + 1;
		}
	}
	else { wpforenemy_announced = false; ons_stalemate = false; }

	Onslaught_count_generators();
	int winner_team = Team_GetWinnerTeam_WithOwnedItems(1);
	if (!winner_team)
		return 0;

	if(winner_team > 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_ROUND_TEAM_WIN));
		TeamScore_AddToTeam(winner_team, ST_ONS_GENS, +1);
	}
	else if(winner_team == -1)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_ROUND_TIED);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_ROUND_TIED);
	}

	ons_stalemate = false;

	play2all(SND(CTF_CAPTURE(winner_team)));

	round_handler_Init(7, autocvar_g_onslaught_warmup, autocvar_g_onslaught_round_timelimit);

	FOREACH_CLIENT(IS_PLAYER(it), {
		STAT(ROUNDLOST, it) = true;
		it.player_blocked = true;
		nades_RemovePlayer(it);
	});

	game_stopped = true;
	return 1;
}

bool Onslaught_CheckPlayers()
{
	return 1;
}

void Onslaught_RoundStart()
{
	entity tmp_entity;
	FOREACH_CLIENT(IS_PLAYER(it), it.player_blocked = false);

	for(tmp_entity = ons_worldcplist; tmp_entity; tmp_entity = tmp_entity.ons_worldcpnext)
		tmp_entity.sprite.SendFlags |= 16;

	for(tmp_entity = ons_worldgeneratorlist; tmp_entity; tmp_entity = tmp_entity.ons_worldgeneratornext)
		tmp_entity.sprite.SendFlags |= 16;
}


// ================
// Bot player logic
// ================

// NOTE: LEGACY CODE, needs to be re-written!

void havocbot_role_ons_setrole(entity this, int role)
{
	switch(role)
	{
		case HAVOCBOT_ONS_ROLE_DEFENSE:
			LOG_DEBUG(this.netname, " switched to defense");
			this.havocbot_role = havocbot_role_ons_defense;
			this.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_ONS_ROLE_ASSISTANT:
			LOG_DEBUG(this.netname, " switched to assistant");
			this.havocbot_role = havocbot_role_ons_assistant;
			this.havocbot_role_timeout = 0;
			break;
		case HAVOCBOT_ONS_ROLE_OFFENSE:
			LOG_DEBUG(this.netname, " switched to offense");
			this.havocbot_role = havocbot_role_ons_offense;
			this.havocbot_role_timeout = 0;
			break;
	}
}

void havocbot_goalrating_ons_controlpoints_attack(entity this, float ratingscale)
{
	entity cp, cp1, cp2, best, wp;
	float radius, bestvalue;
	int c;
	bool found;

	// Filter control points
	for(cp2 = ons_worldcplist; cp2; cp2 = cp2.ons_worldcpnext)
	{
		cp2.wpcost = c = 0;
		cp2.wpconsidered = false;

		if(cp2.isshielded)
			continue;

		// Ignore owned controlpoints
		if(!((cp2.aregensneighbor & BIT(this.team)) || (cp2.arecpsneighbor & BIT(this.team))))
			continue;

		// Count teammates interested in this control point
		// (easier and cleaner than keeping counters per cp and teams)
		FOREACH_CLIENT(it != this && IS_PLAYER(it), {
			if(SAME_TEAM(it, this))
			if(it.havocbot_role == havocbot_role_ons_offense)
			if(it.havocbot_ons_target == cp2)
				++c;
		});

		// NOTE: probably decrease the cost of attackable control points
		cp2.wpcost = c;
		cp2.wpconsidered = true;
	}

	// We'll consider only the best case
	bestvalue = FLOAT_MAX;
	cp = NULL;
	for(cp1 = ons_worldcplist; cp1; cp1 = cp1.ons_worldcpnext)
	{
		if (!cp1.wpconsidered)
			continue;

		if(cp1.wpcost<bestvalue)
		{
			bestvalue = cp1.wpcost;
			cp = cp1;
			this.havocbot_ons_target = cp1;
		}
	}

	if (!cp)
		return;

	LOG_DEBUG(this.netname, " chose cp ranked ", ftos(bestvalue));

	if(cp.goalentity)
	{
		// Should be attacked
		// Rate waypoints near it
		found = false;
		best = NULL;
		bestvalue = FLOAT_MAX;
		for (radius = 500; radius <= 1000 && !found; radius += 500)
		{
			IL_EACH(g_waypoints, vdist(cp.origin - it.origin, <, radius),
			{
				if (!(it.wpflags & WAYPOINTFLAG_GENERATED) && checkpvs(it.origin, cp))
				{
					found = true;
					if (it.cnt < bestvalue)
					{
						best = it;
						bestvalue = it.cnt;
					}
				}
			});
		}

		if(best)
		{
			navigation_routerating(this, best, ratingscale, 10000);
			best.cnt += 1;

			this.havocbot_attack_time = 0;
			if(checkpvs(this.origin + this.view_ofs, cp))
			if(checkpvs(this.origin + this.view_ofs, best))
				this.havocbot_attack_time = time + 2;
		}
		else
		{
			navigation_routerating(this, cp, ratingscale, 10000);
		}
		LOG_DEBUG(this.netname, " found an attackable controlpoint at ", vtos(cp.origin));
	}
	else
	{
		// Should be touched
		LOG_DEBUG(this.netname, " found a touchable controlpoint at ", vtos(cp.origin));
		navigation_routerating(this, cp, ratingscale * 2, 10000);
	}
}

bool havocbot_goalrating_ons_generator_attack(entity this, float ratingscale)
{
	entity g, wp, bestwp;
	bool found;
	int bestvalue;

	for(g = ons_worldgeneratorlist; g; g = g.ons_worldgeneratornext)
	{
		if(SAME_TEAM(g, this) || g.isshielded)
			continue;

		// Should be attacked
		// Rate waypoints near it
		found = false;
		bestwp = NULL;
		bestvalue = FLOAT_MAX;

		IL_EACH(g_waypoints, vdist(g.origin - it.origin, <, 400),
		{
			if (checkpvs(it.origin, g))
			{
				found = true;
				if (it.cnt < bestvalue)
				{
					bestwp = it;
					bestvalue = it.cnt;
				}
			}
		});

		if(bestwp)
		{
			LOG_DEBUG("waypoints found around generator");
			navigation_routerating(this, bestwp, ratingscale, 10000);
			bestwp.cnt += 1;

			this.havocbot_attack_time = 0;
			if(checkpvs(this.origin + this.view_ofs, g))
			if(checkpvs(this.origin + this.view_ofs, bestwp))
				this.havocbot_attack_time = time + 5;

			return true;
		}
		else
		{
			LOG_DEBUG("generator found without waypoints around");
			// if there aren't waypoints near the generator go straight to it
			navigation_routerating(this, g, ratingscale, 10000);
			this.havocbot_attack_time = 0;
			return true;
		}
	}
	return false;
}

void havocbot_role_ons_offense(entity this)
{
	if(IS_DEAD(this))
	{
		this.havocbot_attack_time = 0;
		havocbot_ons_reset_role(this);
		return;
	}

	// Set the role timeout if necessary
	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + 120;

	if (time > this.havocbot_role_timeout)
	{
		havocbot_ons_reset_role(this);
		return;
	}

	if(this.havocbot_attack_time>time)
		return;

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);
		havocbot_goalrating_enemyplayers(this, 20000, this.origin, 650);
		if(!havocbot_goalrating_ons_generator_attack(this, 10000))
			havocbot_goalrating_ons_controlpoints_attack(this, 10000);
		havocbot_goalrating_items(this, 25000, this.origin, 10000);
		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_ons_assistant(entity this)
{
	havocbot_ons_reset_role(this);
}

void havocbot_role_ons_defense(entity this)
{
	havocbot_ons_reset_role(this);
}

void havocbot_ons_reset_role(entity this)
{
	if(IS_DEAD(this))
		return;

	this.havocbot_ons_target = NULL;

	// TODO: Defend control points or generator if necessary

	havocbot_role_ons_setrole(this, HAVOCBOT_ONS_ROLE_OFFENSE);
}


/*
 * Find control point or generator owned by the same team self which is nearest to pos
 * if max_dist is positive, only control points within this range will be considered
 */
entity ons_Nearest_ControlPoint(entity this, vector pos, float max_dist)
{
	entity closest_target = NULL;
	for(entity cp = ons_worldcplist; cp; cp = cp.ons_worldcpnext)
	{
		if(SAME_TEAM(cp, this))
		if(cp.iscaptured)
		if(max_dist <= 0 || vdist(cp.origin - pos, <=, max_dist))
		if(vlen2(cp.origin - pos) <= vlen2(closest_target.origin - pos) || closest_target == NULL)
			closest_target = cp;
	}
	for(entity gen = ons_worldgeneratorlist; gen; gen = gen.ons_worldgeneratornext)
	{
		if(SAME_TEAM(gen, this))
		if(max_dist <= 0 || vdist(gen.origin - pos, <, max_dist))
		if(vlen2(gen.origin - pos) <= vlen2(closest_target.origin - pos) || closest_target == NULL)
			closest_target = gen;
	}

	return closest_target;
}

/*
 * Find control point or generator owned by the same team self which is nearest to pos
 * if max_dist is positive, only control points within this range will be considered
 * This function only check distances on the XY plane, disregarding Z
 */
entity ons_Nearest_ControlPoint_2D(entity this, vector pos, float max_dist)
{
	entity closest_target = NULL;
	vector delta;
	float smallest_distance = 0, distance;

	for(entity cp = ons_worldcplist; cp; cp = cp.ons_worldcpnext)
	{
		delta = cp.origin - pos;
		delta_z = 0;
		distance = vlen(delta);

		if(SAME_TEAM(cp, this))
		if(cp.iscaptured)
		if(max_dist <= 0 || distance <= max_dist)
		if(closest_target == NULL || distance <= smallest_distance )
		{
			closest_target = cp;
			smallest_distance = distance;
		}
	}
	for(entity gen = ons_worldgeneratorlist; gen; gen = gen.ons_worldgeneratornext)
	{
		delta = gen.origin - pos;
		delta_z = 0;
		distance = vlen(delta);

		if(SAME_TEAM(gen, this))
		if(max_dist <= 0 || distance <= max_dist)
		if(closest_target == NULL || distance <= smallest_distance )
		{
			closest_target = gen;
			smallest_distance = distance;
		}
	}

	return closest_target;
}
/**
 * find the number of control points and generators in the same team as this
 */
int ons_Count_SelfControlPoints(entity this)
{
	int n = 0;
	for(entity cp = ons_worldcplist; cp; cp = cp.ons_worldcpnext)
	{
		if(SAME_TEAM(cp, this))
		if(cp.iscaptured)
			n++;
	}
	for(entity gen = ons_worldgeneratorlist; gen; gen = gen.ons_worldgeneratornext)
	{
		if(SAME_TEAM(gen, this))
			n++;
	}
	return n;
}

/**
 * Teleport player to a random position near tele_target
 * if tele_effects is true, teleport sound+particles are created
 * return false on failure
 */
bool ons_Teleport(entity player, entity tele_target, float range, bool tele_effects)
{
	if ( !tele_target )
		return false;

	int i;
	vector loc;
	float theta;
	// narrow the range for each iteration to increase chances that a spawnpoint
	// can be found even if there's little room around the control point
	float iteration_scale = 1;
	for(i = 0; i < 16; ++i)
	{
		iteration_scale -= i / 16;
		theta = random() * (2 * M_PI);
		loc_y = sin(theta);
		loc_x = cos(theta);
		loc_z = 0;
		loc *= random() * range * iteration_scale;

		loc += tele_target.origin + '0 0 128' * iteration_scale;

		tracebox(loc, STAT(PL_MIN, player), STAT(PL_MAX, player), loc, MOVE_NORMAL, player);
		if(trace_fraction == 1.0 && !trace_startsolid)
		{
			traceline(tele_target.origin, loc, MOVE_NOMONSTERS, tele_target); // double check to make sure we're not spawning outside the NULL
			if(trace_fraction == 1.0 && !trace_startsolid)
			{
				if ( tele_effects )
				{
					Send_Effect(EFFECT_TELEPORT, player.origin, '0 0 0', 1);
					sound (player, CH_TRIGGER, SND_TELEPORT, VOL_BASE, ATTEN_NORM);
				}
				setorigin(player, loc);
				player.angles = '0 1 0' * ( theta * RAD2DEG + 180 );
				makevectors(player.angles);
				player.fixangle = true;
				if (IS_BOT_CLIENT(player))
				{
					player.v_angle = player.angles;
					bot_aim_reset(player);
				}
				player.teleport_antispam = time + autocvar_g_onslaught_teleport_wait;

				if ( tele_effects )
					Send_Effect(EFFECT_TELEPORT, player.origin + v_forward * 32, '0 0 0', 1);
				return true;
			}
		}
	}

	return false;
}

// ==============
// Hook Functions
// ==============

MUTATOR_HOOKFUNCTION(ons, reset_map_global)
{
	FOREACH_CLIENT(IS_PLAYER(it), {
		STAT(ROUNDLOST, it) = false;
		it.ons_deathloc = '0 0 0';
		PutClientInServer(it);
		it.clientcamera = it;
	});
	return false;
}

MUTATOR_HOOKFUNCTION(ons, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	player.ons_deathloc = '0 0 0';
}

MUTATOR_HOOKFUNCTION(ons, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	player.ons_deathloc = '0 0 0';
}

MUTATOR_HOOKFUNCTION(ons, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if(!round_handler_IsRoundStarted())
	{
		player.player_blocked = true;
		return false;
	}

	entity l;
	for(l = ons_worldgeneratorlist; l; l = l.ons_worldgeneratornext)
	{
		l.sprite.SendFlags |= 16;
	}
	for(l = ons_worldcplist; l; l = l.ons_worldcpnext)
	{
		l.sprite.SendFlags |= 16;
	}

	if(ons_stalemate) { Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_OVERTIME_CONTROLPOINT); }

	if ( autocvar_g_onslaught_spawn_choose )
	if ( player.ons_spawn_by )
	if ( ons_Teleport(player,player.ons_spawn_by,autocvar_g_onslaught_teleport_radius,false) )
	{
		player.ons_spawn_by = NULL;
		return false;
	}

	if(autocvar_g_onslaught_spawn_at_controlpoints)
	if(random() <= autocvar_g_onslaught_spawn_at_controlpoints_chance)
	{
		float random_target = autocvar_g_onslaught_spawn_at_controlpoints_random;
		entity tmp_entity, closest_target = NULL;
		vector spawn_loc = player.ons_deathloc;

		// new joining player or round reset, don't bother checking
		if(spawn_loc == '0 0 0') { return false; }

		if(random_target) { RandomSelection_Init(); }

		for(tmp_entity = ons_worldcplist; tmp_entity; tmp_entity = tmp_entity.ons_worldcpnext)
		{
			if(SAME_TEAM(tmp_entity, player))
			{
				if(random_target)
					RandomSelection_AddEnt(tmp_entity, 1, 1);
				else if(vlen2(tmp_entity.origin - spawn_loc) <= vlen2(closest_target.origin - spawn_loc) || closest_target == NULL)
					closest_target = tmp_entity;
			}
		}

		if(random_target) { closest_target = RandomSelection_chosen_ent; }

		if(closest_target)
		{
			float i;
			vector loc;
			float iteration_scale = 1;
			for(i = 0; i < 10; ++i)
			{
				iteration_scale -= i / 10;
				loc = closest_target.origin + '0 0 96' * iteration_scale;
				loc += ('0 1 0' * random()) * 128 * iteration_scale;
				tracebox(loc, STAT(PL_MIN, player), STAT(PL_MAX, player), loc, MOVE_NORMAL, player);
				if(trace_fraction == 1.0 && !trace_startsolid)
				{
					traceline(closest_target.origin, loc, MOVE_NOMONSTERS, closest_target); // double check to make sure we're not spawning outside the NULL
					if(trace_fraction == 1.0 && !trace_startsolid)
					{
						setorigin(player, loc);
						player.angles = normalize(loc - closest_target.origin) * RAD2DEG;
						return false;
					}
				}
			}
		}
	}

	if(autocvar_g_onslaught_spawn_at_generator)
	if(random() <= autocvar_g_onslaught_spawn_at_generator_chance)
	{
		float random_target = autocvar_g_onslaught_spawn_at_generator_random;
		entity tmp_entity, closest_target = NULL;
		vector spawn_loc = player.ons_deathloc;

		// new joining player or round reset, don't bother checking
		if(spawn_loc == '0 0 0') { return false; }

		if(random_target) { RandomSelection_Init(); }

		for(tmp_entity = ons_worldgeneratorlist; tmp_entity; tmp_entity = tmp_entity.ons_worldgeneratornext)
		{
			if(random_target)
				RandomSelection_AddEnt(tmp_entity, 1, 1);
			else
			{
				if(SAME_TEAM(tmp_entity, player))
				if(vlen2(tmp_entity.origin - spawn_loc) <= vlen2(closest_target.origin - spawn_loc) || closest_target == NULL)
					closest_target = tmp_entity;
			}
		}

		if(random_target) { closest_target = RandomSelection_chosen_ent; }

		if(closest_target)
		{
			float i;
			vector loc;
			float iteration_scale = 1;
			for(i = 0; i < 10; ++i)
			{
				iteration_scale -= i / 10;
				loc = closest_target.origin + '0 0 128' * iteration_scale;
				loc += ('0 1 0' * random()) * 256 * iteration_scale;
				tracebox(loc, STAT(PL_MIN, player), STAT(PL_MAX, player), loc, MOVE_NORMAL, player);
				if(trace_fraction == 1.0 && !trace_startsolid)
				{
					traceline(closest_target.origin, loc, MOVE_NOMONSTERS, closest_target); // double check to make sure we're not spawning outside the NULL
					if(trace_fraction == 1.0 && !trace_startsolid)
					{
						setorigin(player, loc);
						player.angles = normalize(loc - closest_target.origin) * RAD2DEG;
						return false;
					}
				}
			}
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ons, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	frag_target.ons_deathloc = frag_target.origin;
	entity l;
	for(l = ons_worldgeneratorlist; l; l = l.ons_worldgeneratornext)
	{
		l.sprite.SendFlags |= 16;
	}
	for(l = ons_worldcplist; l; l = l.ons_worldcpnext)
	{
		l.sprite.SendFlags |= 16;
	}

	if ( autocvar_g_onslaught_spawn_choose )
	if ( ons_Count_SelfControlPoints(frag_target) > 1 )
		stuffcmd(frag_target, "qc_cmd_cl hud clickradar\n");

	return false;
}

MUTATOR_HOOKFUNCTION(ons, MonsterMove)
{
	entity mon = M_ARGV(0, entity);

	entity e = find(NULL, targetname, mon.target);
	if (e != NULL)
		mon.team = e.team;
}

void ons_MonsterSpawn_Delayed(entity this)
{
	entity own = this.owner;

	if(!own) { delete(this); return; }

	if(own.targetname)
	{
		entity e = find(NULL, target, own.targetname);
		if(e != NULL)
		{
			own.team = e.team;

			own.use(own, e, NULL);
		}
	}

	delete(this);
}

MUTATOR_HOOKFUNCTION(ons, MonsterSpawn)
{
	entity mon = M_ARGV(0, entity);

	entity e = spawn();
	e.owner = mon;
	InitializeEntity(e, ons_MonsterSpawn_Delayed, INITPRIO_FINDTARGET);
}

void ons_TurretSpawn_Delayed(entity this)
{
	entity own = this.owner;

	if(!own) { delete(this); return; }

	if(own.targetname)
	{
		entity e = find(NULL, target, own.targetname);
		if(e != NULL)
		{
			own.team = e.team;
			own.active = ACTIVE_NOT;

			own.use(own, e, NULL);
		}
	}

	delete(this);
}

MUTATOR_HOOKFUNCTION(ons, TurretSpawn)
{
	entity turret = M_ARGV(0, entity);

	entity e = spawn();
	e.owner = turret;
	InitializeEntity(e, ons_TurretSpawn_Delayed, INITPRIO_FINDTARGET);

	return false;
}

MUTATOR_HOOKFUNCTION(ons, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	havocbot_ons_reset_role(bot);
	return true;
}

MUTATOR_HOOKFUNCTION(ons, TeamBalance_CheckAllowedTeams)
{
	// onslaught is special
	for(entity tmp_entity = ons_worldgeneratorlist; tmp_entity; tmp_entity = tmp_entity.ons_worldgeneratornext)
	{
		if (Team_IsValidTeam(tmp_entity.team))
		{
			M_ARGV(0, float) |= Team_TeamToBit(tmp_entity.team);
		}
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ons, SpectateCopy)
{
	entity spectatee = M_ARGV(0, entity);
	entity client = M_ARGV(1, entity);

	STAT(ROUNDLOST, client) = STAT(ROUNDLOST, spectatee); // make spectators see it too
}

MUTATOR_HOOKFUNCTION(ons, SV_ParseClientCommand)
{
	if(MUTATOR_RETURNVALUE) // command was already handled?
		return false;

	entity player = M_ARGV(0, entity);
	string cmd_name = M_ARGV(1, string);
	int cmd_argc = M_ARGV(2, int);

	if ( cmd_name == "ons_spawn" )
	{
		vector pos = player.origin;
		if(cmd_argc > 1)
			pos_x = stof(argv(1));
		if(cmd_argc > 2)
			pos_y = stof(argv(2));
		if(cmd_argc > 3)
			pos_z = stof(argv(3));

		if ( IS_PLAYER(player) )
		{
			entity source_point = ons_Nearest_ControlPoint(player, player.origin, autocvar_g_onslaught_teleport_radius);

			if ( !source_point && GetResource(player, RES_HEALTH) > 0 )
			{
				sprint(player, "\nYou need to be next to a control point\n");
				return true;
			}

			entity closest_target = ons_Nearest_ControlPoint_2D(player, pos, autocvar_g_onslaught_click_radius);

			if ( closest_target == NULL )
			{
				sprint(player, "\nNo control point found\n");
				return true;
			}

			if ( GetResource(player, RES_HEALTH) <= 0 )
			{
				player.ons_spawn_by = closest_target;
				player.respawn_flags = player.respawn_flags | RESPAWN_FORCE;
			}
			else
			{
				if ( source_point == closest_target )
				{
					sprint(player, "\nTeleporting to the same point\n");
					return true;
				}

				if ( !ons_Teleport(player,closest_target,autocvar_g_onslaught_teleport_radius,true) )
					sprint(player, "\nUnable to teleport there\n");
			}

			return true;
		}

		return true;
	}
	return false;
}

MUTATOR_HOOKFUNCTION(ons, PlayerUseKey)
{
	if(MUTATOR_RETURNVALUE || game_stopped) return false;

	entity player = M_ARGV(0, entity);

	if((time > player.teleport_antispam) && (!IS_DEAD(player)) && !player.vehicle)
	{
		entity source_point = ons_Nearest_ControlPoint(player, player.origin, autocvar_g_onslaught_teleport_radius);
		if ( source_point )
		{
			stuffcmd(player, "qc_cmd_cl hud clickradar\n");
			return true;
		}
	}
}

MUTATOR_HOOKFUNCTION(ons, PlayHitsound)
{
	entity frag_victim = M_ARGV(0, entity);

	return (frag_victim.classname == "onslaught_generator" && !frag_victim.isshielded)
		|| (frag_victim.classname == "onslaught_controlpoint_icon" && !frag_victim.owner.isshielded);
}

MUTATOR_HOOKFUNCTION(ons, SendWaypoint)
{
    entity wp = M_ARGV(0, entity);
    entity to = M_ARGV(1, entity);
    int sf = M_ARGV(2, int);
    int wp_flag = M_ARGV(3, int);

	if(sf & 16)
	{
		if(wp.owner.classname == "onslaught_controlpoint")
		{
			entity wp_owner = wp.owner;
			entity e = WaypointSprite_getviewentity(to);
			if(SAME_TEAM(e, wp_owner) && GetResource(wp_owner.goalentity, RES_HEALTH) >= wp_owner.goalentity.max_health) { wp_flag |= 2; }
			if(!ons_ControlPoint_Attackable(wp_owner, e.team)) { wp_flag |= 2; }
		}
		if(wp.owner.classname == "onslaught_generator")
		{
			entity wp_owner = wp.owner;
			if(wp_owner.isshielded && GetResource(wp_owner, RES_HEALTH) >= wp_owner.max_health) { wp_flag |= 2; }
			if(GetResource(wp_owner, RES_HEALTH) <= 0) { wp_flag |= 2; }
		}
	}

	M_ARGV(3, int) = wp_flag;
}

MUTATOR_HOOKFUNCTION(ons, TurretValidateTarget)
{
	entity turret_target = M_ARGV(1, entity);

	if(substring(turret_target.classname, 0, 10) == "onslaught_") // don't attack onslaught targets, that's the player's job!
	{
		M_ARGV(3, float) = -3;
		return true;
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ons, TurretThink)
{
    entity turret = M_ARGV(0, entity);

	// ONS uses somewhat backwards linking.
	if(turret.target)
	{
		entity e = find(NULL, targetname, turret.target);
		if (e != NULL)
			turret.team = e.team;
	}

	if(turret.team != turret.tur_head.team)
		turret_respawn(turret);
}


// ==========
// Spawnfuncs
// ==========

/*QUAKED spawnfunc_onslaught_link (0 .5 .8) (-16 -16 -16) (16 16 16)
  Link between control points.

  This entity targets two different spawnfunc_onslaught_controlpoint or spawnfunc_onslaught_generator entities, and suppresses shielding on both if they are owned by different teams.

keys:
"target" - first control point.
"target2" - second control point.
 */
spawnfunc(onslaught_link)
{
	if(!g_onslaught) { delete(this); return; }

	if (this.target == "" || this.target2 == "")
		objerror(this, "target and target2 must be set\n");

	this.ons_worldlinknext = ons_worldlinklist; // link into ons_worldlinklist
	ons_worldlinklist = this;

	InitializeEntity(this, ons_DelayedLinkSetup, INITPRIO_FINDTARGET);
	Net_LinkEntity(this, false, 0, ons_Link_Send);
}

/*QUAKED spawnfunc_onslaught_controlpoint (0 .5 .8) (-32 -32 0) (32 32 128)
  Control point. Be sure to give this enough clearance so that the shootable part has room to exist

  This should link to an spawnfunc_onslaught_controlpoint entity or spawnfunc_onslaught_generator entity.

keys:
"targetname" - name that spawnfunc_onslaught_link entities will use to target this.
"target" - target any entities that are tied to this control point, such as vehicles and buildable structure entities.
"message" - name of this control point (should reflect the location in the map, such as "center bridge", "north tower", etc)
 */

spawnfunc(onslaught_controlpoint)
{
	if(!g_onslaught) { delete(this); return; }

	ons_ControlPoint_Setup(this);
}

/*QUAKED spawnfunc_onslaught_generator (0 .5 .8) (-32 -32 -24) (32 32 64)
  Base generator.

  spawnfunc_onslaught_link entities can target this.

keys:
"team" - team that owns this generator (5 = red, 14 = blue, etc), MUST BE SET.
"targetname" - name that spawnfunc_onslaught_link entities will use to target this.
 */
spawnfunc(onslaught_generator)
{
	if(!g_onslaught) { delete(this); return; }
	if(!this.team) { objerror(this, "team must be set"); }

	ons_GeneratorSetup(this);
}

// scoreboard setup
void ons_ScoreRules()
{
	entity balance = TeamBalance_CheckAllowedTeams(NULL);
	int teams = TeamBalance_GetAllowedTeams(balance);
	TeamBalance_Destroy(balance);
	GameRules_scoring(teams, SFL_SORT_PRIO_PRIMARY, 0, {
	    field_team(ST_ONS_GENS, "generators", SFL_SORT_PRIO_PRIMARY);
	    field(SP_ONS_CAPS, "caps", SFL_SORT_PRIO_SECONDARY);
	    field(SP_ONS_TAKES,	"takes", 0);
	});
}

void ons_DelayedInit(entity this) // Do this check with a delay so we can wait for teams to be set up
{
	ons_ScoreRules();

	round_handler_Spawn(Onslaught_CheckPlayers, Onslaught_CheckWinner, Onslaught_RoundStart);
	round_handler_Init(5, autocvar_g_onslaught_warmup, autocvar_g_onslaught_round_timelimit);
}

void ons_Initialize()
{
	g_onslaught = true;
	g_onsshields = IL_NEW();
	ons_captureshield_force = autocvar_g_onslaught_shield_force;

	cam = new(objective_camera);

	InitializeEntity(NULL, ons_DelayedInit, INITPRIO_GAMETYPE);
}
