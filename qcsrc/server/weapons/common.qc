#include "common.qh"

#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/items/_mod.qh>
#include <common/net_linked.qh>
#include <common/notifications/all.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <common/wepent.qh>
#include <server/command/common.qh>
#include <server/damage.qh>
#include <server/hook.qh>
#include <server/items/items.qh>
#include <server/mutators/_mod.qh>
#include <server/weapons/csqcprojectile.qh>

bool W_DualWielding(entity player)
{
	int held_weapons = 0;
	for (int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if (player.(weaponentity) && player.(weaponentity).m_switchweapon != WEP_Null)
			++held_weapons;
	}

	return held_weapons > 1;
}

void W_GiveWeapon(entity e, int wep)
{
	if (!wep)
		return;
	STAT(WEAPONS, e) |= WepSet_FromWeapon(REGISTRY_GET(Weapons, wep));
}

void W_PlayStrengthSound(entity player)
{
	MUTATOR_CALLHOOK(W_PlayStrengthSound, player);
}

float W_CheckProjectileDamage(entity inflictor, entity projowner, int deathtype, float exception)
{
	bool is_from_contents = (deathtype == DEATH_SLIME.m_id || deathtype == DEATH_LAVA.m_id);
	bool is_from_owner = (inflictor == projowner);
	bool is_from_exception = (exception != -1);

	//dprint(strcat("W_CheckProjectileDamage: from_contents ", ftos(is_from_contents), " : from_owner ", ftos(is_from_owner), " : exception ", strcat(ftos(is_from_exception), " (", ftos(exception), "). \n")));

	if (autocvar_g_projectiles_damage <= -2)
	{
		return false; // no damage to projectiles at all, not even with the exceptions
	}
	else if (autocvar_g_projectiles_damage == -1)
	{
		if (is_from_exception)
			return exception; // if exception is detected, allow it to override
		else
			return false; // otherwise, no other damage is allowed
	}
	else if (autocvar_g_projectiles_damage == 0)
	{
		if (is_from_exception)
			return exception; // if exception is detected, allow it to override
		else if (!is_from_contents)
			return false; // otherwise, only allow damage from contents
	}
	else if (autocvar_g_projectiles_damage == 1)
	{
		if (is_from_exception)
			return exception; // if exception is detected, allow it to override
		else if (!(is_from_contents || is_from_owner))
			return false; // otherwise, only allow self damage and damage from contents
	}
	else if (autocvar_g_projectiles_damage == 2) // allow any damage, but override for exceptions
	{
		if (is_from_exception)
			return exception; // if exception is detected, allow it to override
	}

	return true; // if none of these return, then allow damage anyway.
}

void W_PrepareExplosionByDamage(entity this, entity attacker, void(entity this) explode)
{
	this.takedamage = DAMAGE_NO;
	this.event_damage = func_null;

	MUTATOR_CALLHOOK(PrepareExplosionByDamage, this, attacker);

	if (IS_CLIENT(attacker) && !autocvar_g_projectiles_keep_owner)
	{
		this.owner = attacker;
		this.realowner = attacker;
	}

	// do not explode NOW but in the NEXT FRAME!
	// because recursive calls to RadiusDamage are not allowed
	this.nextthink = time;
	setthink(this, explode);
}

void adaptor_think2use_hittype_splash(entity this) // for timed projectile detonation
{
	if (!(IS_ONGROUND(this))) // if onground, we ARE touching something, but HITTYPE_SPLASH is to be networked if the damage causing projectile is not touching ANYTHING
		this.projectiledeathtype |= HITTYPE_SPLASH;
	adaptor_think2use(this);
}

bool SUB_NoImpactCheck(entity this, entity toucher)
{
	// zero hitcontents = this is not the real impact, but either the
	// mirror-impact of something hitting the projectile instead of the
	// projectile hitting the something, or a touchareagrid one. Neither of
	// these stop the projectile from moving, so...
	// NOTE: this notice is disabled to prevent spam as projectiles can hit content-less objects (other projectiles!)
#if 0
	if (trace_dphitcontents == 0)
	{
		LOG_TRACEF("A hit from a projectile happened with no hit contents! DEBUG THIS, this should never happen for projectiles! Projectile will self-destruct. (edict: %i, classname: %s, origin: %v)", this, this.classname, this.origin);
		checkclient(this); // TODO: .health is checked in the engine with this, possibly replace with a QC function?
	}
#endif
	if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		return true;

	if (toucher == NULL && this.size != '0 0 0')
	{
		vector tic = this.velocity * sys_frametime;
		tic += normalize(tic) * vlen(this.maxs - this.mins);
		traceline(this.origin - tic, this.origin + tic, MOVE_NORMAL, this);
		if (trace_fraction >= 1)
		{
			// NOTE: this notice can occur when projectiles hit non-world objects, better to not spam the console!
			//LOG_TRACE("Odd... did not hit...?");
		}
		else if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
		{
			LOG_TRACE("Detected and prevented the sky-grapple bug.");
			return true;
		}
	}

	return false;
}

bool WarpZone_Projectile_Touch_ImpactFilter_Callback(entity this, entity toucher)
{
	if (toucher && toucher == this.owner)
		return true;

	if (autocvar_g_projectiles_interact == 1 && toucher.classname == "blasterbolt")
	{
		if (this.movetype == MOVETYPE_BOUNCE || this.movetype == MOVETYPE_BOUNCEMISSILE)
			// We'll bounce off it due to limitations so let it deflect us
			// to hide the problem, see PROJECTILE_MAKETRIGGER.
			gettouch(toucher)(toucher, this);
		return true;
	}

	if (SUB_NoImpactCheck(this, toucher))
	{
		if (this.classname == "nade")
			return false; // no checks here
		else if (this.classname == "grapplinghook")
			RemoveHook(this);
		else
			delete(this);
		return true;
	}
	if (trace_ent && trace_ent.solid > SOLID_TRIGGER)
		UpdateCSQCProjectile(this);
	return false;
}


vector W_LaserPlay_last_hit_org;
vector W_LaserPlay_end_org;
void W_LaserPlay_trace_callback(vector start, vector hit, vector end)
{
	if (end == W_LaserPlay_end_org) // must be the final trace segment
		return;
	W_LaserPlay_last_hit_org = hit;
	Send_Effect(EFFECT_FIREBALL_LASER, start, hit - start, 1);
	//trailparticles(this, particleeffectnum(EFFECT_FIREBALL_LASER), start, hit);
}
/// Randomly chooses a player within the radius to shoot a laser towards
void W_LaserPlay(entity this, float rad, float damage, float edgedamage, float burntime, WarpZone_FindRadius_cond_callback_t cb)
{
	if (damage <= 0 && edgedamage <= 0)
		return;

	RandomSelection_Init();
	entity last = NULL;
	float rad2 = rad * rad;
	WarpZone_SearchInRadius_otherent = this;
	for (entity e = WarpZone_SearchInRadius(this.origin, rad, MOVE_NOMONSTERS, cb); e; e = e.chain)
	{
		// adjust the hit location to be a random position inside the entity's bbox
		vector p = e.origin + e.mins;
		p.x += random() * (e.maxs.x - e.mins.x);
		p.y += random() * (e.maxs.y - e.mins.y);
		p.z += random() * (e.maxs.z - e.mins.z);
		float dist2 = vlen2(this.origin - WarpZone_UnTransformOrigin(e, p));
		if (dist2 <= rad2) // there's a chance this is false, so we optimize by only calling sqrt if true
		{
			e.dest = p;
			e.dmg_radius = sqrt(dist2);
			last = e;
			RandomSelection_AddEnt(e, 1 / (1 + e.dmg_radius), !StatusEffects_active(STATUSEFFECT_Burning, e));
		}
	}
	if (RandomSelection_chosen_ent)
	{
		float dist = damage + (edgedamage - damage) * (RandomSelection_chosen_ent.dmg_radius / rad);
		Fire_AddDamage(RandomSelection_chosen_ent, this.realowner, dist * burntime, burntime, this.projectiledeathtype | HITTYPE_BOUNCE);

		// WarpZone_TraceLine_ThroughZone with callback to draw the line-effect through zones on the way to the end,
		// but then for the final segment draw towards .dest instead of the trace's end (.WarpZone_findradius_nearest).
		// This is probably the best we can do
		W_LaserPlay_last_hit_org = this.origin;
		if (RandomSelection_chosen_ent.warpzone_transform != '0 0 0' || RandomSelection_chosen_ent.warpzone_shift != '0 0 0')
		{
			W_LaserPlay_end_org = RandomSelection_chosen_ent.WarpZone_findradius_nearest;
			WarpZone_TraceLine_ThroughZone(this.origin, WarpZone_UnTransformOrigin(RandomSelection_chosen_ent, W_LaserPlay_end_org),
				MOVE_NOTHING, NULL, NULL, W_LaserPlay_trace_callback);
		}
		Send_Effect(EFFECT_FIREBALL_LASER, W_LaserPlay_last_hit_org, RandomSelection_chosen_ent.dest - W_LaserPlay_last_hit_org, 1);
		//trailparticles(this, particleeffectnum(EFFECT_FIREBALL_LASER), this.origin, RandomSelection_chosen_ent.dest);
	}
}

.float wait;
/// Automatically guides a projectile towards its enemy.
/// RefSys must be setup
float W_SeekOutEnemy(entity this,
	float speed_decel, float speed_accel, float speed_max, float turn_rate,
	bool smart, float smart_mindist, float smart_trace_min, float smart_trace_max)
{
	if (this.enemy != NULL
	&&  this.enemy.takedamage != DAMAGE_AIM || IS_DEAD(this.enemy))
		this.enemy = NULL;
	if (!this.enemy)
		return 0;

	float spd = vlen(this.velocity);
	spd = bound(
		spd - speed_decel * frametime,
		speed_max,
		spd + speed_accel * frametime);

	vector eorg = WarpZone_RefSys_TransformOrigin(this.enemy, this, 0.5 * (this.enemy.absmin + this.enemy.absmax));
	float dist = vlen(eorg - this.origin);
	vector desireddir = (eorg - this.origin) * 1 / dist;
	vector olddir = this.velocity * 1 / spd; // get my current direction

	// Do evasive maneuvers for world objects? ( this should be a cpu hog. :P )
	if (smart && dist > smart_mindist)
	{
		// Is it a better idea (shorter distance) to trace to the target itself?
		if (vdist(this.origin + olddir * this.wait, <, dist))
			WarpZone_TraceLine(this.origin, this.origin + olddir * this.wait, false, this);
		else
			WarpZone_TraceLine(this.origin, eorg, false, this);

		// Setup adaptive tracelength
		this.wait = bound(
			smart_trace_min,
			vlen(this.origin - WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos)),
			smart_trace_max);

		// Calc how important it is that we turn and add this to the desired (enemy) dir
		desireddir = normalize((trace_plane_normal * (1 - trace_fraction)) + (desireddir * trace_fraction));
	}

	vector newdir = normalize(olddir + desireddir * turn_rate); // take the average of the 2 directions; not the best method but simple & easy
	this.velocity = newdir * spd; // make me fly in the new direction at my flight speed
	return dist;
}
