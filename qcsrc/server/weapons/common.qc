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

vector W_SteerProjectileTo(vector thisdir, vector goaldir, float maxturn_cos)
{
	if (thisdir * goaldir > maxturn_cos)
		return goaldir;
	if (thisdir * goaldir < -0.9998) // less than 1 degree and opposite
		return thisdir; // refuse to guide (better than letting a numerical error happen)

	// solve:
	//   g = normalize(thisdir + goaldir * X)
	//   thisdir * g = maxturn
	//
	//   gg = thisdir + goaldir * X
	//   (thisdir * gg)^2 = maxturn^2 * (gg * gg)
	//
	//   (1 + (thisdir * goaldir) * X)^2 = maxturn^2 * (1 + X*X + 2 * X * thisdir * goaldir)
	float f = thisdir * goaldir;
	//   (1 + f * X)^2 = maxturn^2 * (1 + X*X + 2 * X * f)
	//   0 = (m^2 - f^2) * x^2 + (2 * f * (m^2 - 1)) * x + (m^2 - 1)
	float m2 = maxturn_cos * maxturn_cos;
	vector v = solve_quadratic(m2 - f * f, 2 * f * (m2 - 1), m2 - 1);
	return normalize(thisdir + goaldir * v.y); // the larger solution!
}
// assume thisdir == -goaldir:
//   f == -1
//   v = solve_qadratic(m2 - 1, -2 * (m2 - 1), m2 - 1)
//   (m2 - 1) x^2 - 2 * (m2 - 1) * x + (m2 - 1) = 0
//   x^2 - 2 * x + 1 = 0
//   (x - 1)^2 = 0
//   x = 1
//   normalize(thisdir + goaldir)
//   normalize(0)

/// Guides a projectile towards the crosshair (v_forward). Call makevectors first
void W_GuideProjectile(entity this, .entity weaponentity, float guide_rate, float guide_rate_delay, float guide_goal, float guide_delay, entity eff, entity snd, float vol)
{
	float f = (guide_rate_delay)
		? bound(0, (time - this.pushltime) / guide_rate_delay, 1)
		: 1;

	vector md = this.realowner.(weaponentity).movedir;
	vector dv = (W_DualWielding(this.realowner))
		? v_right * -md.y + v_up * md.z
		: '0 0 0'; // don't override!

	float velspeed = vlen(this.velocity);

	makevectors(this.realowner.v_angle);
	vector desireddir = WarpZone_RefSys_TransformVelocity(this.realowner, this, v_forward);
	vector desiredorigin = WarpZone_RefSys_TransformOrigin(this.realowner, this, this.realowner.origin + this.realowner.view_ofs + dv);
	vector olddir = normalize(this.velocity);

	// now it gets tricky... we want to move like some curve to approximate the target direction
	// but we are limiting the rate at which we can turn!
	vector goal = desiredorigin + ((this.origin - desiredorigin) * desireddir + guide_goal) * desireddir;
	vector newdir = W_SteerProjectileTo(olddir, normalize(goal - this.origin), cos(guide_rate * f * frametime * DEG2RAD));

	this.velocity = newdir * velspeed;
	this.angles = vectoangles(this.velocity);

	if (!this.count && guide_delay > 0 && (eff || snd))
	{
		if (eff)
			Send_Effect(eff, this.origin, this.velocity, 1);
		// TODO add a better sound here
		if (snd)
			sound(this.realowner, CH_WEAPON_B, snd, vol, ATTN_NORM);
		this.count = 1;
	}
}
