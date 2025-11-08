#include "sv_nades.qh"

#include <common/gametypes/_mod.qh>
#include <common/weapons/all.qh>
#include <common/mutators/mutator/overkill/okmachinegun.qh>
#include <common/mutators/mutator/overkill/okshotgun.qh>
#include <server/command/common.qh>

.float nade_time_primed;

.entity nade_spawnloc;

vector nades_PlayerColor(entity this, bool isPants)
{
	if(teamplay)
		return Team_ColorRGB(this.team);

	// logic copied from Scoreboard_GetName
	int col = (this.colormap >= 1024) ? this.colormap - 1024 : this.clientcolors;
	return (isPants) ? colormapPaletteColor(col % 16, true) : colormapPaletteColor(floor(col / 16), false);
}

void nade_timer_think(entity this)
{
	this.skin = 8 - (this.wait - time) / (this.nade_lifetime / 10);
	this.nextthink = time;
	if(!this.owner || wasfreed(this.owner))
		delete(this);
}

void nade_burn_spawn(entity _nade)
{
	CSQCProjectile(_nade, true, REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, _nade)).m_projectile[1], true);
}

void nade_spawn(entity _nade)
{
	entity timer = new(nade_timer);
	setmodel(timer, MDL_NADE_TIMER);
	setattachment(timer, _nade, "");
	timer.colormap = _nade.colormap;
	timer.glowmod = _nade.glowmod;
	setthink(timer, nade_timer_think);
	timer.nextthink = time;
	timer.wait = _nade.wait;
	timer.nade_lifetime = _nade.nade_lifetime;
	timer.owner = _nade;
	timer.skin = 10;

	_nade.effects |= EF_LOWPRECISION;

	CSQCProjectile(_nade, true, REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, _nade)).m_projectile[0], true);
}


void nades_orb_think(entity this)
{
	if(time >= this.ltime)
	{
		delete(this);
		return;
	}

	this.nextthink = time;

	if(time >= this.nade_special_time)
	{
		this.nade_special_time = time+0.25;
		this.nade_show_particles = 1;
	}
	else
		this.nade_show_particles = 0;
}

entity nades_spawn_orb(entity own, entity realown, vector org, float orb_ltime, float orb_rad)
{
	// NOTE: this function merely places an orb
	// you must add a custom touch function to the returned entity if desired
	// also set .colormod if you wish to have it colorized
	entity orb = new(nades_spawn_orb);
	orb.owner = own;
	orb.realowner = realown;
	setorigin(orb, org);

	orb.orb_lifetime = orb_ltime; // required for timers
	orb.ltime = time + orb.orb_lifetime;
	orb.bot_dodge = false;
	orb.team = realown.team;
	orb.solid = SOLID_TRIGGER;

	setmodel(orb, MDL_NADE_ORB);
	orb.skin = 1;
	orb.orb_radius = orb_rad; // required for fading
	vector size = '.5 .5 .5' * orb.orb_radius;
	setsize(orb, -size, size);

	Net_LinkEntity(orb, true, 0, orb_send);
	orb.SendFlags |= 1;

	setthink(orb, nades_orb_think);
	orb.nextthink = time;

	return orb;
}


void nade_boom(entity this)
{
	entity expef = NULL;
	vector expcol_min = '0 0 0', expcol_max = '0 0 0';

	Nade ntype = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, this));

	if (!this.takedamage || ntype == NADE_TYPE_Null)
	{
		// first condition: nade was destroyed by something (lava, void, etc.), just do a normal explosion
		// this prevents weird cases like spawn nade setting your spawnpoint on the void, translocate sending you into the void, etc.
		ntype = NADE_TYPE_NORMAL;
	}

#define SET_NADE_EFFECT(nade_type, exp_effect, exp_color_min, exp_color_max) \
	case nade_type: \
		expef = exp_effect; \
		expcol_min = exp_color_min; \
		expcol_max = exp_color_max; \
		break

	switch (ntype)
	{
		SET_NADE_EFFECT(NADE_TYPE_NAPALM,      EFFECT_EXPLOSION_MEDIUM, '0 0 0', '0 0 0');
		SET_NADE_EFFECT(NADE_TYPE_ICE,         EFFECT_ELECTRO_COMBO,    '0 0 0', '0 0 0');
		SET_NADE_EFFECT(NADE_TYPE_TRANSLOCATE, NULL,                    '0 0 0', '0 0 0');
		SET_NADE_EFFECT(NADE_TYPE_MONSTER,     NULL,                    nades_PlayerColor(this.realowner, false), nades_PlayerColor(this.realowner, true));
		SET_NADE_EFFECT(NADE_TYPE_SPAWN,       EFFECT_SPAWN,            nades_PlayerColor(this.realowner, false), nades_PlayerColor(this.realowner, true));
		SET_NADE_EFFECT(NADE_TYPE_HEAL,        EFFECT_SPAWN,            '1 0 0', '1 0 0');
		SET_NADE_EFFECT(NADE_TYPE_ENTRAP,      EFFECT_SPAWN,            '1 1 0', '1 1 0');
		SET_NADE_EFFECT(NADE_TYPE_VEIL,        EFFECT_SPAWN,            '0 0 0', '0 0 0');
		SET_NADE_EFFECT(NADE_TYPE_AMMO,        EFFECT_SPAWN,            '0.33 0.33 1', '0.33 0.33 1');
		SET_NADE_EFFECT(NADE_TYPE_DARKNESS,    EFFECT_EXPLOSION_MEDIUM, '0 0 0', '0 0 0');
		SET_NADE_EFFECT(NADE_TYPE_NORMAL,      EFFECT_NADE_EXPLODE,     nades_PlayerColor(this.realowner, false), nades_PlayerColor(this.realowner, true));
	}
#undef SET_NADE_EFFECT

	if (expef)
		Send_Effect_Except(expef, findbetterlocation(this.origin, 8), '0 0 0', 1, expcol_min, expcol_max, NULL);

	sound(this, CH_SHOTS_SINGLE, SND_Null,          VOL_BASE, ATTEN_NORM);
	sound(this, CH_SHOTS,        SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

	this.event_damage = func_null; // prevent somehow calling damage in the next call

	switch (ntype)
	{
		case NADE_TYPE_NORMAL:      nade_normal_boom(this);      break;
		case NADE_TYPE_NAPALM:      nade_napalm_boom(this);      break;
		case NADE_TYPE_ICE:         nade_ice_boom(this);         break;
		case NADE_TYPE_TRANSLOCATE: nade_translocate_boom(this); break;
		case NADE_TYPE_SPAWN:       nade_spawn_boom(this);       break;
		case NADE_TYPE_HEAL:        nade_heal_boom(this);        break;
		case NADE_TYPE_MONSTER:     nade_monster_boom(this);     break;
		case NADE_TYPE_ENTRAP:      nade_entrap_boom(this);      break;
		case NADE_TYPE_VEIL:        nade_veil_boom(this);        break;
		case NADE_TYPE_AMMO:        nade_ammo_boom(this);        break;
		case NADE_TYPE_DARKNESS:    nade_darkness_boom(this);    break;
	}

	IL_EACH(g_projectiles, it.classname == "grapplinghook" && it.aiment == this,
	{
		RemoveHook(it);
	});

	delete(this);
}

void spawn_held_nade(entity player, entity nowner, float ntime, string ntype, string pntype);
void nade_pickup(entity this, entity thenade)
{
	spawn_held_nade(this, thenade.realowner, autocvar_g_nades_pickup_time, REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, thenade)).netname, thenade.pokenade_type);

	// set refire so player can't even
	this.nade_refire = time + autocvar_g_nades_nade_refire;
	STAT(NADE_TIMER, this) = 0;

	if(this.nade)
		this.nade.nade_time_primed = thenade.nade_time_primed;
}

bool CanThrowNade(entity this);
void nade_touch(entity this, entity toucher)
{
	if(toucher)
		UpdateCSQCProjectile(this);

	if(toucher == this.realowner)
		return; // no this impacts

	if(autocvar_g_nades_pickup)
	if(time >= this.spawnshieldtime)
	if(!toucher.nade && GetResource(this, RES_HEALTH) == this.max_health) // no boosted shot pickups, thank you very much
	if(CanThrowNade(toucher)) // prevent some obvious things, like dead players
	if(IS_REAL_CLIENT(toucher)) // above checks for IS_PLAYER, don't need to do it here
	{
		nade_pickup(toucher, this);
		sound(this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, 0.5 *(ATTEN_LARGE + ATTEN_MAX));
		delete(this);
		return;
	}
	/*float is_weapclip = 0;
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NODRAW)
	if (!(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NONSOLID))
	if (!(trace_dphitcontents & DPCONTENTS_OPAQUE))
		is_weapclip = 1;*/
	if(ITEM_TOUCH_NEEDKILL()) // || is_weapclip)
	{
		IL_EACH(g_projectiles, it.classname == "grapplinghook" && it.aiment == this,
		{
			RemoveHook(it);
		});
		delete(this);
		return;
	}

	PROJECTILE_TOUCH(this, toucher);

	//setsize(this, '-2 -2 -2', '2 2 2');
	//UpdateCSQCProjectile(this);
	if(GetResource(this, RES_HEALTH) == this.max_health)
	{
		spamsound(this, CH_SHOTS, SND_GRENADE_BOUNCE_RANDOM(), VOL_BASE, ATTEN_NORM);
		return;
	}

	this.enemy = toucher;
	nade_boom(this);
}

void nade_beep(entity this)
{
	sound(this, CH_SHOTS_SINGLE, SND_NADE_BEEP, VOL_BASE, 0.5 *(ATTEN_LARGE + ATTEN_MAX));
	setthink(this, nade_boom);
	this.nextthink = max(this.wait, time);
}

void nade_damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
	{
		this.takedamage = DAMAGE_NO;
		W_PrepareExplosionByDamage(this, attacker, nade_boom);
		return;
	}

	if(STAT(NADE_BONUS_TYPE, this) == NADE_TYPE_TRANSLOCATE.m_id || STAT(NADE_BONUS_TYPE, this) == NADE_TYPE_SPAWN.m_id)
		return;

	if (MUTATOR_CALLHOOK(Nade_Damage, this, DEATH_WEAPONOF(deathtype), force, damage)) {}
	else if(DEATH_ISWEAPON(deathtype, WEP_BLASTER))
	{
		force *= 1.5;
		damage = 0;
	}
	else if(DEATH_ISWEAPON(deathtype, WEP_VORTEX) || DEATH_ISWEAPON(deathtype, WEP_VAPORIZER) || DEATH_ISWEAPON(deathtype, WEP_OVERKILL_NEX))
	{
		force *= 6;
		damage = this.max_health * 0.55;
	}
	else if(DEATH_ISWEAPON(deathtype, WEP_MACHINEGUN) || DEATH_ISWEAPON(deathtype, WEP_OVERKILL_MACHINEGUN))
		damage = this.max_health * 0.1;
	else if(DEATH_ISWEAPON(deathtype, WEP_SHOTGUN) || DEATH_ISWEAPON(deathtype, WEP_OVERKILL_SHOTGUN)) // WEAPONTODO
	{
		if(!(deathtype & HITTYPE_SECONDARY))
			damage = this.max_health * 1.15;
	}

	// melee slaps
	entity death_weapon = DEATH_WEAPONOF(deathtype);
	if(((deathtype & HITTYPE_SECONDARY) ? (death_weapon.spawnflags & WEP_TYPE_MELEE_SEC) : (death_weapon.spawnflags & WEP_TYPE_MELEE_PRI)))
	{
		damage = this.max_health * 0.1;
		force *= 10;
	}

	this.velocity += force;
	UpdateCSQCProjectile(this);

	if(damage <= 0 || ((IS_ONGROUND(this)) && IS_PLAYER(attacker)))
		return;

	float hp = GetResource(this, RES_HEALTH);
	if(hp == this.max_health)
	{
		sound(this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, 0.5 *(ATTEN_LARGE + ATTEN_MAX));
		this.nextthink = max(time + this.nade_lifetime, time);
		setthink(this, nade_beep);
	}

	hp -= damage;
	SetResource(this, RES_HEALTH, hp);

	if(STAT(NADE_BONUS_TYPE, this) != NADE_TYPE_TRANSLOCATE.m_id && STAT(NADE_BONUS_TYPE, this) != NADE_TYPE_SPAWN.m_id)
	if(STAT(NADE_BONUS_TYPE, this) != NADE_TYPE_HEAL.m_id || IS_PLAYER(attacker))
		this.realowner = attacker;

	if(hp <= 0)
	{
		if(nade_spawn_DestroyDamage(this, attacker))
			return;
		if(nade_translocate_DestroyDamage(this, attacker))
			return;

		W_PrepareExplosionByDamage(this, attacker, nade_boom);
	}
	else
		nade_burn_spawn(this);
}

void toss_nade(entity e, bool set_owner, vector _velocity, float _time)
{
	if(e.nade == NULL)
		return;

	entity _nade = e.nade;
	e.nade = NULL;

	if(e.fake_nade)
		delete(e.fake_nade);
	e.fake_nade = NULL;

	Kill_Notification(NOTIF_ONE_ONLY, e, MSG_CENTER, CPID_NADES);

	makevectors(e.v_angle);

	// NOTE: always throw from first weapon entity?
	W_SetupShot(e, _nade.weaponentity_fld, false, false, SND_Null, CH_WEAPON_A, 0, DEATH_NADE.m_id);

	vector offset = (v_forward * autocvar_g_nades_throw_offset.x)
	              + (v_right * autocvar_g_nades_throw_offset.y)
	              + (v_up * autocvar_g_nades_throw_offset.z);

	setorigin(_nade, w_shotorg + offset);
	//setmodel(_nade, MDL_PROJECTILE_NADE);
	//setattachment(_nade, NULL, "");
	PROJECTILE_MAKETRIGGER(_nade);
	if(STAT(NADES_SMALL, e))
		setsize(_nade, '-8 -8 -8', '8 8 8');
	else
		setsize(_nade, '-16 -16 -16', '16 16 16');
	set_movetype(_nade, MOVETYPE_BOUNCE);

	tracebox(_nade.origin, _nade.mins, _nade.maxs, _nade.origin, MOVE_NOMONSTERS, _nade);
	if (trace_startsolid)
		setorigin(_nade, e.origin);

	if(e.v_angle.x >= 70 && e.v_angle.x <= 110 && PHYS_INPUT_BUTTON_CROUCH(e))
		_nade.velocity = '0 0 100';
	else if(autocvar_g_nades_nade_newton_style == 1)
		_nade.velocity = e.velocity + _velocity;
	else if(autocvar_g_nades_nade_newton_style == 2)
		_nade.velocity = _velocity;
	else
		_nade.velocity = W_CalculateProjectileVelocity(e, e.velocity, _velocity, true);

	if(set_owner)
		_nade.realowner = e;

	settouch(_nade, nade_touch);
	_nade.spawnshieldtime = time + 0.1; // prevent instantly picking up again
	SetResource(_nade, RES_HEALTH, autocvar_g_nades_nade_health);
	_nade.max_health = GetResource(_nade, RES_HEALTH);
	_nade.takedamage = DAMAGE_AIM;
	_nade.event_damage = nade_damage;
	setcefc(_nade, func_null);
	_nade.exteriormodeltoclient = NULL;
	_nade.traileffectnum = 0;
	_nade.teleportable = true;
	_nade.pushable = true;
	_nade.gravity = 1;
	_nade.missile_flags = MIF_SPLASH | MIF_ARC;
	_nade.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, _nade);
	_nade.angles = vectoangles(_nade.velocity);
	_nade.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, _nade);
	IL_PUSH(g_bot_dodge, _nade);
	_nade.projectiledeathtype = DEATH_NADE.m_id;
	_nade.toss_time = time;
	_nade.solid = SOLID_CORPSE; //((STAT(NADE_BONUS_TYPE, _nade) == NADE_TYPE_TRANSLOCATE) ? SOLID_CORPSE : SOLID_BBOX);

	if(STAT(NADE_BONUS_TYPE, _nade) == NADE_TYPE_TRANSLOCATE.m_id
	|| STAT(NADE_BONUS_TYPE, _nade) == NADE_TYPE_SPAWN.m_id
	|| STAT(NADE_BONUS_TYPE, _nade) == NADE_TYPE_MONSTER.m_id)
		_nade.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	else
		_nade.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;

	nade_spawn(_nade);

	if(_time)
	{
		setthink(_nade, nade_boom);
		_nade.nextthink = _time;
	}

	e.nade_refire = time + autocvar_g_nades_nade_refire;
	STAT(NADE_TIMER, e) = 0;
}

Nade nades_CheckTypes(Nade ntype)
{
#define NADE_TYPE_CHECK(nade_ent, nade_cvar) \
	case nade_ent.m_id: \
		if (nade_cvar) \
			return ntype; \
		break

	switch (ntype.m_id)
	{
		case 0: return NADE_TYPE_Null; // use NADE_TYPE_Null to signify a random nade
		NADE_TYPE_CHECK(NADE_TYPE_NAPALM,      autocvar_g_nades_napalm);
		NADE_TYPE_CHECK(NADE_TYPE_ICE,         autocvar_g_nades_ice);
		NADE_TYPE_CHECK(NADE_TYPE_TRANSLOCATE, autocvar_g_nades_translocate);
		NADE_TYPE_CHECK(NADE_TYPE_SPAWN,       autocvar_g_nades_spawn);
		NADE_TYPE_CHECK(NADE_TYPE_HEAL,        autocvar_g_nades_heal);
		NADE_TYPE_CHECK(NADE_TYPE_MONSTER,     autocvar_g_nades_pokenade && autocvar_g_monsters); // if monsters disabled, this nade can't do anything, use instead normal nade
		NADE_TYPE_CHECK(NADE_TYPE_ENTRAP,      autocvar_g_nades_entrap);
		NADE_TYPE_CHECK(NADE_TYPE_VEIL,        autocvar_g_nades_veil);
		NADE_TYPE_CHECK(NADE_TYPE_AMMO,        autocvar_g_nades_ammo);
		NADE_TYPE_CHECK(NADE_TYPE_DARKNESS,    autocvar_g_nades_darkness);
	}
	return NADE_TYPE_NORMAL; // default to NADE_TYPE_NORMAL for unknown nade types
#undef NADE_TYPE_CHECK
}

void nades_GiveBonus(entity player, float score)
{
	if (autocvar_g_nades)
	if (autocvar_g_nades_bonus)
	if (IS_REAL_CLIENT(player))
	if (IS_PLAYER(player) && STAT(NADE_BONUS, player) < autocvar_g_nades_bonus_max)
	if (!STAT(FROZEN, player))
	if (!IS_DEAD(player))
	{
		if ( STAT(NADE_BONUS_SCORE, player) < 1 )
			STAT(NADE_BONUS_SCORE, player) += score/autocvar_g_nades_bonus_score_max;

		if ( STAT(NADE_BONUS_SCORE, player) >= 1 )
		{
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_NADE_BONUS);
			play2(player, SND(NADE_BONUS));
			STAT(NADE_BONUS, player)++;
			STAT(NADE_BONUS_SCORE, player) -= 1;
		}
	}
}

/** Remove all bonus nades from a player */
void nades_RemoveBonus(entity player)
{
	STAT(NADE_BONUS, player) = STAT(NADE_BONUS_SCORE, player) = 0;
}

MUTATOR_HOOKFUNCTION(nades, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	nades_RemoveBonus(player);
}

bool nade_customize(entity this, entity client)
{
	//if(IS_SPEC(client)) { return false; }
	if(client == this.exteriormodeltoclient || (IS_SPEC(client) && client.enemy == this.exteriormodeltoclient))
	{
		// somewhat hide the model, but keep the glow
		//this.effects = 0;
		if(this.traileffectnum)
			this.traileffectnum = 0;
		this.alpha = -1;
	}
	else
	{
		//this.effects = EF_ADDITIVE | EF_FULLBRIGHT | EF_LOWPRECISION;
		if(!this.traileffectnum)
		{
			entity nade = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, this));
			this.traileffectnum = _particleeffectnum(Nade_TrailEffect(nade.m_projectile[0], this.team).eent_eff_name);
		}
		this.alpha = 1;
	}

	return true;
}

int nade_choose_random()
{
	RandomSelection_Init();
	FOREACH(Nades, it != NADE_TYPE_Null, {
		if (nades_CheckTypes(it) == it) // this nade type is allowed
			RandomSelection_AddEnt(it, 1, 1);
	});
	return RandomSelection_chosen_ent.m_id;
}

Nade Nades_FromString(string ntype)
{
	FOREACH(Nades, it != NADE_TYPE_Null && (it.netname == ntype || ftos(it.impulse) == ntype),
	{
		return it;
	});
	return NADE_TYPE_Null;
}

Nade Nades_GetType(string ntype)
{
	Nade def = Nades_FromString(ntype);
	if(ntype == "random" || ntype == "0")
		def = REGISTRY_GET(Nades, nade_choose_random());

	return (def == NADE_TYPE_Null) ? NADE_TYPE_NORMAL : def;
}

void spawn_held_nade(entity player, entity nowner, float ntime, string ntype, string pntype)
{
	entity n = new(nade), fn = new(fake_nade);

	Nade def = Nades_GetType(ntype);

	n.pokenade_type = pntype;

	STAT(NADE_BONUS_TYPE, n) = def.m_id;

	.entity weaponentity = weaponentities[0]; // TODO: unhardcode

	setmodel(n, MDL_PROJECTILE_NADE);
	//setattachment(n, player, "bip01 l hand");
	n.exteriormodeltoclient = player;
	setcefc(n, nade_customize);
	n.traileffectnum = _particleeffectnum(Nade_TrailEffect(def.m_projectile[0], player.team).eent_eff_name);
	n.colormod = def.m_color;
	n.realowner = nowner;
	n.colormap = player.colormap;
	n.glowmod = player.glowmod;
	n.wait = time + max(0, ntime);
	n.nade_time_primed = time;
	setthink(n, nade_beep);
	n.nextthink = max(n.wait - 3, time);
	n.projectiledeathtype = DEATH_NADE.m_id;
	n.weaponentity_fld = weaponentity;
	n.nade_lifetime = ntime;
	n.alpha = def.m_alpha;

	setmodel(fn, MDL_NADE_VIEW);
	//setattachment(fn, player.(weaponentity), "");
	fn.viewmodelforclient = player;
	fn.realowner = fn.owner = player;
	fn.colormod = def.m_color;
	fn.colormap = player.colormap;
	fn.glowmod = player.glowmod;
	setthink(fn, SUB_Remove);
	fn.nextthink = n.wait;
	fn.weaponentity_fld = weaponentity;
	fn.alpha = def.m_alpha;

	player.nade = n;
	player.fake_nade = fn;
}

void nade_prime(entity this)
{
	if(autocvar_g_nades_bonus_only && !STAT(NADE_BONUS, this))
		return; // only allow bonus nades

	// TODO: handle old nade if it exists?
	if(this.nade)
		delete(this.nade);
	this.nade = NULL;

	if(this.fake_nade)
		delete(this.fake_nade);
	this.fake_nade = NULL;

	Nade ntype;
	string pntype = this.pokenade_type;

	if(StatusEffects_active(STATUSEFFECT_Strength, this) && autocvar_g_nades_bonus_onstrength)
		ntype = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, this));
	else if (STAT(NADE_BONUS, this) >= 1)
	{
		ntype = REGISTRY_GET(Nades, STAT(NADE_BONUS_TYPE, this));
		pntype = this.pokenade_type;
		STAT(NADE_BONUS, this) -= 1;
	}
	else
	{
		if (autocvar_g_nades_client_select)
		{
			ntype  = nades_CheckTypes(Nades_FromString(CS_CVAR(this).cvar_cl_nade_type));
			pntype = CS_CVAR(this).cvar_cl_pokenade_type;
		}
		else
		{
			ntype  = Nades_FromString(autocvar_g_nades_nade_type);
			pntype = autocvar_g_nades_pokenade_monster_type;
		}
	}

	spawn_held_nade(this, this, autocvar_g_nades_nade_lifetime, ntype.netname, pntype);
}

bool CanThrowNade(entity this)
{
	return !(this.vehicle || !autocvar_g_nades || IS_DEAD(this) || !IS_PLAYER(this) || weaponLocked(this));
}

.bool nade_altbutton;

void nades_CheckThrow(entity this)
{
	if(!CanThrowNade(this))
		return;

	entity held_nade = this.nade;
	if (!held_nade)
	{
		this.nade_altbutton = true;
		if(time > this.nade_refire)
		{
			nade_prime(this);
			this.nade_refire = time + autocvar_g_nades_nade_refire;
		}
	}
	else
	{
		this.nade_altbutton = false;
		if (time >= held_nade.nade_time_primed + 1) {
			makevectors(this.v_angle);
			float _force = time - held_nade.nade_time_primed;
			_force /= autocvar_g_nades_nade_lifetime;
			_force = autocvar_g_nades_nade_minforce + (_force * (autocvar_g_nades_nade_maxforce - autocvar_g_nades_nade_minforce));
			vector dir = (v_forward * 0.75 + v_up * 0.2 + v_right * 0.05);
			dir = W_CalculateSpread(dir, autocvar_g_nades_spread, autocvar_g_projectiles_spread_style, false);
			toss_nade(this, true, dir * _force, 0);
		}
	}
}

void nades_Clear(entity player)
{
	if(player.nade)
		delete(player.nade);
	if(player.fake_nade)
		delete(player.fake_nade);

	player.nade = player.fake_nade = NULL;
	STAT(NADE_TIMER, player) = 0;
}

MUTATOR_HOOKFUNCTION(nades, VehicleEnter)
{
	entity player = M_ARGV(0, entity);

	if(player.nade)
		toss_nade(player, true, '0 0 100', max(player.nade.wait, time + 0.05));
}

CLASS(NadeOffhand, OffhandWeapon)
	METHOD(NadeOffhand, offhand_think, void(NadeOffhand this, entity player, bool key_pressed))
	{
		entity held_nade = player.nade;

		if (!CanThrowNade(player)) return;
		if (!(time > player.nade_refire)) return;
		if (key_pressed) {
			if (!held_nade) {
				nade_prime(player);
				held_nade = player.nade;
			}
		} else if (time >= held_nade.nade_time_primed + 1) {
			if (held_nade) {
				makevectors(player.v_angle);
				float _force = time - held_nade.nade_time_primed;
				_force /= autocvar_g_nades_nade_lifetime;
				_force = autocvar_g_nades_nade_minforce + (_force * (autocvar_g_nades_nade_maxforce - autocvar_g_nades_nade_minforce));
				vector dir = (v_forward * 0.7 + v_up * 0.2 + v_right * 0.1);
				dir = W_CalculateSpread(dir, autocvar_g_nades_spread, autocvar_g_projectiles_spread_style, false);
				toss_nade(player, false, dir * _force, 0);
			}
		}
	}
ENDCLASS(NadeOffhand)
NadeOffhand OFFHAND_NADE;
REGISTER_MUTATOR(nades, autocvar_g_nades)
{
	MUTATOR_ONADD
	{
		OFFHAND_NADE = NEW(NadeOffhand);
	}
	return 0;
}

MUTATOR_HOOKFUNCTION(nades, ForbidThrowCurrentWeapon, CBC_ORDER_LAST)
{
	entity player = M_ARGV(0, entity);

	if (player.offhand != OFFHAND_NADE || (STAT(WEAPONS, player) & WEPSET(HOOK)) || autocvar_g_nades_override_dropweapon) {
		nades_CheckThrow(player);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(nades, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if (!IS_PLAYER(player)) { return; }

	if (player.nade && (player.offhand != OFFHAND_NADE || (STAT(WEAPONS, player) & WEPSET(HOOK))))
		OFFHAND_NADE.offhand_think(OFFHAND_NADE, player, player.nade_altbutton);

	entity held_nade = player.nade;
	if (held_nade)
	{
		STAT(NADE_TIMER, player) = bound(0, (time - held_nade.nade_time_primed) / held_nade.nade_lifetime, 1);
		// LOG_TRACEF("%d %d", STAT(NADE_TIMER, player), time - held_nade.nade_time_primed);
		makevectors(player.angles);
		held_nade.velocity = player.velocity;
		setorigin(held_nade, player.origin + player.view_ofs + v_forward * 8 + v_right * -8 + v_up * 0);
		held_nade.angles_y = player.angles.y;

		if (time + 0.1 >= held_nade.wait)
		{
			toss_nade(player, false, '0 0 0', time + 0.05);
			Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_NADE_THROW);
		}
	}

	if(IS_PLAYER(player))
	{
		if ( autocvar_g_nades_bonus && autocvar_g_nades )
		{
			entity key;
			float key_count = 0;
			FOR_EACH_KH_KEY(key) if(key.owner == player) { ++key_count; }

			float time_score;
			if(GameRules_scoring_is_vip(player))
				time_score = autocvar_g_nades_bonus_score_time_flagcarrier;
			else
				time_score = autocvar_g_nades_bonus_score_time;

			if(key_count)
				time_score = autocvar_g_nades_bonus_score_time_flagcarrier * key_count; // multiply by the number of keys the player is holding

			if(autocvar_g_nades_bonus_client_select)
			{
				STAT(NADE_BONUS_TYPE, player) = nades_CheckTypes(Nades_FromString(CS_CVAR(player).cvar_cl_nade_type)).m_id;
				player.pokenade_type          = CS_CVAR(player).cvar_cl_pokenade_type;
			}
			else
			{
				STAT(NADE_BONUS_TYPE, player) = Nades_FromString(autocvar_g_nades_bonus_type).m_id;
				player.pokenade_type          = autocvar_g_nades_pokenade_monster_type;
			}

			if(STAT(NADE_BONUS_SCORE, player) >= 0 && autocvar_g_nades_bonus_score_max)
				nades_GiveBonus(player, time_score / autocvar_g_nades_bonus_score_max);
		}
		else
		{
			STAT(NADE_BONUS, player) = STAT(NADE_BONUS_SCORE, player) = 0;
		}

		nade_veil_Apply(player);
	}
}

MUTATOR_HOOKFUNCTION(nades, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if (StatusEffects_active(STATUSEFFECT_SpawnShield, player))
		player.nade_refire = StatusEffects_gettime(STATUSEFFECT_SpawnShield, player);
	else
		player.nade_refire = time;

	if (!autocvar_g_nades_onspawn)
		player.nade_refire += autocvar_g_nades_nade_refire;

	if(autocvar_g_nades_bonus_client_select)
		STAT(NADE_BONUS_TYPE, player) = Nades_FromString(CS_CVAR(player).cvar_cl_nade_type).m_id;

	STAT(NADE_TIMER, player) = 0;

	if (!player.offhand) player.offhand = OFFHAND_NADE;

	if(player.nade_spawnloc)
	{
		setorigin(player, player.nade_spawnloc.origin);
		player.nade_spawnloc.cnt -= 1;

		if(player.nade_spawnloc.cnt <= 0)
		{
			delete(player.nade_spawnloc);
			player.nade_spawnloc = NULL;
		}

		nade_spawn_SetSpawnHealth(player);
	}
}

MUTATOR_HOOKFUNCTION(nades, PlayerDies, CBC_ORDER_LAST)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if(frag_target.nade)
	if(!STAT(FROZEN, frag_target) || !autocvar_g_freezetag_revive_nade)
		toss_nade(frag_target, true, '0 0 100', max(frag_target.nade.wait, time + 0.05));

	if(IS_PLAYER(frag_attacker))
	{
		float killcount_bonus = ((CS(frag_attacker).killcount >= 1) ? bound(0, autocvar_g_nades_bonus_score_minor * CS(frag_attacker).killcount, autocvar_g_nades_bonus_score_medium) 
																	: autocvar_g_nades_bonus_score_minor);
		if (SAME_TEAM(frag_attacker, frag_target) || frag_attacker == frag_target)
			nades_RemoveBonus(frag_attacker);
		else if(GameRules_scoring_is_vip(frag_target))
			nades_GiveBonus(frag_attacker, autocvar_g_nades_bonus_score_medium);
		else if(autocvar_g_nades_bonus_score_spree && CS(frag_attacker).killcount > 1)
		{
			#define SPREE_ITEM(counta,countb,center,normal,gentle) \
				case counta: { nades_GiveBonus(frag_attacker, autocvar_g_nades_bonus_score_spree); break; }
			switch(CS(frag_attacker).killcount)
			{
				KILL_SPREE_LIST
				default: nades_GiveBonus(frag_attacker, autocvar_g_nades_bonus_score_minor); break;
			}
			#undef SPREE_ITEM
		}
		else
			nades_GiveBonus(frag_attacker, killcount_bonus);
	}

	nades_RemoveBonus(frag_target);
}

MUTATOR_HOOKFUNCTION(nades, Damage_Calculate)
{
	entity frag_inflictor = M_ARGV(0, entity);
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);

	if(autocvar_g_freezetag_revive_nade && STAT(FROZEN, frag_target) && frag_attacker == frag_target && frag_deathtype == DEATH_NADE.m_id)
	if(time - frag_inflictor.toss_time <= 0.1)
	{
		freezetag_Unfreeze(frag_target, false);
		SetResource(frag_target, RES_HEALTH, autocvar_g_freezetag_revive_nade_health);
		Send_Effect(EFFECT_ICEORGLASS, frag_target.origin, '0 0 0', 3);
		M_ARGV(4, float) = 0;
		M_ARGV(6, vector) = '0 0 0';
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_REVIVED_NADE, frag_target.netname);
		Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_FREEZETAG_REVIVE_SELF);
	}
}

MUTATOR_HOOKFUNCTION(nades, MonsterDies)
{
	entity frag_target = M_ARGV(0, entity);
	entity frag_attacker = M_ARGV(1, entity);

	if(IS_PLAYER(frag_attacker))
	if(DIFF_TEAM(frag_attacker, frag_target))
	if(!(frag_target.spawnflags & MONSTERFLAG_SPAWNED))
		nades_GiveBonus(frag_attacker, autocvar_g_nades_bonus_score_minor);
}

MUTATOR_HOOKFUNCTION(nades, DropSpecialItems)
{
	entity frag_target = M_ARGV(0, entity);

	if(frag_target.nade)
		toss_nade(frag_target, true, '0 0 0', time + 0.05);
}

void nades_RemovePlayer(entity this)
{
	nades_Clear(this);
	nades_RemoveBonus(this);
}

MUTATOR_HOOKFUNCTION(nades, MakePlayerObserver) { entity player = M_ARGV(0, entity); nades_RemovePlayer(player); }
MUTATOR_HOOKFUNCTION(nades, ClientDisconnect) { entity player = M_ARGV(0, entity); nades_RemovePlayer(player); }
MUTATOR_HOOKFUNCTION(nades, reset_map_global)
{
	FOREACH_CLIENT(IS_PLAYER(it),
	{
		nades_RemovePlayer(it);
	});
}

MUTATOR_HOOKFUNCTION(nades, SpectateCopy)
{
	entity spectatee = M_ARGV(0, entity);
	entity client = M_ARGV(1, entity);

	STAT(NADE_TIMER, client) = STAT(NADE_TIMER, spectatee);
	STAT(NADE_BONUS_TYPE, client) = STAT(NADE_BONUS_TYPE, spectatee);
	client.pokenade_type = spectatee.pokenade_type;
	STAT(NADE_BONUS, client) = STAT(NADE_BONUS, spectatee);
	STAT(NADE_BONUS_SCORE, client) = STAT(NADE_BONUS_SCORE, spectatee);
}

MUTATOR_HOOKFUNCTION(nades, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Nades");
}

MUTATOR_HOOKFUNCTION(nades, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":Nades");
}
