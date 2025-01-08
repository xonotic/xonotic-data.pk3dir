#include "portals.qh"

#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/effects/all.qh>
#include <common/mapobjects/subs.qh>
#include <common/mapobjects/teleporters.qh>
#include <common/mapobjects/triggers.qh>
#include <common/notifications/all.qh>
#include <common/util.qh>
#include <common/vehicles/sv_vehicles.qh>
#include <common/vehicles/vehicle.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/weapon/porto.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <lib/warpzone/anglestransform.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>
#include <server/client.qh>
#include <server/damage.qh>
#include <server/hook.qh>
#include <server/mutators/_mod.qh>
#include <server/player.qh>
#include <server/weapons/common.qh>

#define PORTALS_ARE_NOT_SOLID

const vector SAFENUDGE = '1 1 1';
const vector SAFERNUDGE = '8 8 8';

.vector portal_transform;
.vector portal_safe_origin;
.float portal_wants_to_vanish;
.float portal_activatetime;
.float savemodelindex;

float PlayerEdgeDistance(entity p, vector v)
{
	vector vbest = vec3(
		((v.x < 0) ? p.mins.x : p.maxs.x),
		((v.y < 0) ? p.mins.y : p.maxs.y),
		((v.z < 0) ? p.mins.z : p.maxs.z));

	return vbest * v;
}

vector Portal_ApplyTransformToPlayerAngle(vector transform, vector vangle)
{
	vector old_forward, old_up;
	vector old_yawforward;
	vector new_forward, new_up;
	vector new_yawforward;

	vector ang;
	ang = vangle;
	/*
	   ang_x = bound(-89, mod(-ang_x + 180, 360) - 180, 89);
	   ang = AnglesTransform_ApplyToVAngles(transform, ang);
	 */

	// PLAYERS use different math
#if !(POSITIVE_PITCH_IS_DOWN)
	ang.x = -ang.x;
#endif

	//print("reference: ", vtos(AnglesTransform_ApplyToVAngles(transform, ang)), "\n");

	fixedmakevectors(ang);
	old_forward = v_forward;
	old_up = v_up;
	fixedmakevectors(ang.y * '0 1 0');
	old_yawforward = v_forward;

	// their aiming directions are portalled...
	new_forward = AnglesTransform_Apply(transform, old_forward);
	new_up = AnglesTransform_Apply(transform, old_up);
	new_yawforward = AnglesTransform_Apply(transform, old_yawforward);

	// but now find a new sense of direction
	// this is NOT easy!
	// assume new_forward points straight up.
	// What is our yaw?
	//
	// new_up could now point forward OR backward... which direction to choose?

	if(new_forward.z > 0.7 || new_forward.z < -0.7) // far up; in this case, the "up" vector points backwards
	{
		// new_yawforward and new_yawup define the new aiming half-circle
		// we "just" need to find out whether new_up or -new_up is in that half circle
		ang = fixedvectoangles(new_forward); // this still gets us a nice pitch value...
		if(new_up * new_yawforward < 0)
			new_up = -1 * new_up;
		ang.y = vectoyaw(new_up); // this vector is the yaw we want
		//print("UP/DOWN path: ", vtos(ang), "\n");
	}
	else
	{
		// good angles; here, "forward" suffices
		ang = fixedvectoangles(new_forward);
		//print("GOOD path: ", vtos(ang), "\n");
	}

#if !(POSITIVE_PITCH_IS_DOWN)
	ang.x = -ang.x;
#endif
	ang.z = vangle.z;
	return ang;
}

.vector right_vector;
float Portal_TeleportPlayer(entity teleporter, entity player, entity portal_owner)
{
	vector from, to, safe, step, transform, ang, newvel;
	float planeshift, s, t;

	if (!teleporter.enemy)
	{
		backtrace("Portal_TeleportPlayer called without other portal being set. Stop.");
		return 0;
	}

	from = teleporter.origin;
	transform = teleporter.portal_transform;

	to = teleporter.enemy.origin;
	to = to + AnglesTransform_Apply(teleporter.portal_transform, player.origin - from);
	newvel = AnglesTransform_Apply(transform, player.velocity);
	// this now is INSIDE the plane... can't use that

	// shift it out
	fixedmakevectors(teleporter.enemy.mangle);

	// first shift it ON the plane if needed
	planeshift = ((teleporter.enemy.origin - to) * v_forward) + PlayerEdgeDistance(player, v_forward) + 1;
	/*
	if(planeshift > 0 && (newvel * v_forward) > vlen(newvel) * 0.01)
		// if we can't, let us not do the planeshift and do somewhat incorrect transformation in the end
		to += newvel * (planeshift / (newvel * v_forward));
	else
	*/
		to += v_forward * planeshift;

	s = (to - teleporter.enemy.origin) * v_right;
	t = (to - teleporter.enemy.origin) * v_up;
	s = bound(-48, s, 48);
	t = bound(-48, t, 48);
	to = teleporter.enemy.origin
	   + ((to - teleporter.enemy.origin) * v_forward) * v_forward
	   +     s                                        * v_right
	   +     t                                        * v_up;

	safe = teleporter.enemy.portal_safe_origin; // a valid player origin
	step = to + ((safe - to) * v_forward) * v_forward;
	tracebox(safe, player.mins - SAFENUDGE, player.maxs + SAFENUDGE, step, MOVE_NOMONSTERS, player);
	if(trace_startsolid)
	{
		LOG_INFO("'safe' teleport location is not safe!");
		// FAIL TODO why does this happen?
		return 0;
	}
	safe = trace_endpos + normalize(safe - trace_endpos) * 0;
	tracebox(safe, player.mins - SAFENUDGE, player.maxs + SAFENUDGE, to, MOVE_NOMONSTERS, player);
	if(trace_startsolid)
	{
		LOG_INFO("trace_endpos in solid, this can't be!");
		// FAIL TODO why does this happen? (reported by MrBougo)
		return 0;
	}
	to = trace_endpos + normalize(safe - trace_endpos) * 0;
	//print(vtos(to), "\n");

	// ang_x stuff works around weird quake angles
	if(IS_PLAYER(player))
		ang = Portal_ApplyTransformToPlayerAngle(transform, player.v_angle);
	else
		ang = AnglesTransform_ApplyToAngles(transform, player.angles);

	// factor -1 allows chaining portals, but may be weird
	player.right_vector = -1 * AnglesTransform_Apply(transform, player.right_vector);

	MUTATOR_CALLHOOK(PortalTeleport, player);

	if (!teleporter.enemy)
	{
		backtrace("Portal_TeleportPlayer ended up without other portal being set BEFORE TeleportPlayer. Stop.");
		return 0;
	}

	tdeath_hit = 0;
	TeleportPlayer(teleporter, player, to, ang, newvel, teleporter.enemy.absmin, teleporter.enemy.absmax, TELEPORT_FLAGS_PORTAL);
	if(tdeath_hit)
	{
		// telefrag within 1 second of portal creation = amazing
		if(time < teleporter.teleport_time + 1)
			Send_Notification(NOTIF_ONE, player, MSG_ANNCE, ANNCE_ACHIEVEMENT_AMAZING);
	}
	else if(player != portal_owner && IS_PLAYER(portal_owner) && IS_PLAYER(player))
	{
		player.pusher = portal_owner;
		player.pushltime = time + autocvar_g_maxpushtime;
		player.istypefrag = PHYS_INPUT_BUTTON_CHAT(player);
	}

	if (!teleporter.enemy)
	{
		backtrace("Portal_TeleportPlayer ended up without other portal being set AFTER TeleportPlayer. Stop.");
		return 0;
	}

	// reset fade counter
	teleporter.portal_wants_to_vanish = 0;
	teleporter.fade_time = ((autocvar_g_balance_portal_lifetime >= 0) ? time + autocvar_g_balance_portal_lifetime : 0);
	SetResourceExplicit(teleporter, RES_HEALTH, autocvar_g_balance_portal_health);
	SetResourceExplicit(teleporter.enemy, RES_HEALTH, autocvar_g_balance_portal_health);

	return 1;
}

float Portal_FindSafeOrigin(entity portal)
{
	vector o;
	o = portal.origin;
	portal.mins = PL_MIN_CONST - SAFERNUDGE;
	portal.maxs = PL_MAX_CONST + SAFERNUDGE;
	fixedmakevectors(portal.mangle);
	portal.origin += 16 * v_forward;
	if(!move_out_of_solid(portal))
	{
#ifdef DEBUG
		LOG_INFO("NO SAFE ORIGIN");
#endif
		return 0;
	}
	portal.portal_safe_origin = portal.origin;
	setorigin(portal, o);
	return 1;
}

float Portal_WillHitPlane(vector eorg, vector emins, vector emaxs, vector evel, vector porg, vector pnorm, float psize)
{
	float dist, distpersec, delta;
	vector v;

	dist = (eorg - porg) * pnorm;
	dist += min(emins.x * pnorm.x, emaxs.x * pnorm.x);
	dist += min(emins.y * pnorm.y, emaxs.y * pnorm.y);
	dist += min(emins.z * pnorm.z, emaxs.z * pnorm.z);
	if(dist < -1) // other side?
		return 0;
#ifdef PORTALS_ARE_NOT_SOLID
	distpersec = evel * pnorm;
	if(distpersec >= 0) // going away from the portal?
		return 0;
	// we don't need this check with solid portals, them being SOLID_BSP should suffice
	delta = dist / distpersec;
	v = eorg - evel * delta - porg;
	v = v - pnorm * (pnorm * v);
	return vlen(v) < psize;
#else
	return 1;
#endif
}

void Portal_Touch(entity this, entity toucher)
{
	vector g;

#ifdef PORTALS_ARE_NOT_SOLID
	// portal is being removed?
	if(this.solid != SOLID_TRIGGER)
		return; // possibly engine bug

	if(IS_PLAYER(toucher))
		return; // handled by think
#endif

	if(toucher.classname == "item_flag_team")
		return; // never portal these

	if(toucher.classname == "grapplinghook")
		return; // handled by think

	if(!autocvar_g_vehicles_teleportable)
	if(IS_VEHICLE(toucher))
		return; // no teleporting vehicles?

	if(!this.enemy)
		error("Portal_Touch called for a broken portal\n");

#ifdef PORTALS_ARE_NOT_SOLID
	if(trace_fraction < 1)
		return; // only handle TouchAreaGrid ones (only these can teleport)
#else
	if(trace_fraction >= 1)
		return; // only handle impacts
#endif

	if(toucher.classname == "porto")
	{
		if(toucher.portal_id == this.portal_id)
			return;
	}
	if(time < this.portal_activatetime)
		if(toucher == this.aiment)
		{
			this.portal_activatetime = time + 0.1;
			return;
		}
	if(toucher != this.aiment)
		if(IS_PLAYER(toucher))
			if(IS_INDEPENDENT_PLAYER(toucher) || IS_INDEPENDENT_PLAYER(this.aiment))
				return; // cannot go through someone else's portal
	if(toucher.aiment != this.aiment)
		if(IS_PLAYER(toucher.aiment))
			if(IS_INDEPENDENT_PLAYER(toucher.aiment) || IS_INDEPENDENT_PLAYER(this.aiment))
				return; // cannot go through someone else's portal
	fixedmakevectors(this.mangle);
	g = frametime * '0 0 -1' * autocvar_sv_gravity;
	if(!Portal_WillHitPlane(toucher.origin, toucher.mins, toucher.maxs, toucher.velocity + g, this.origin, v_forward, this.maxs.x))
		return;

	/*
	if(toucher.mins_x < PL_MIN.x || toucher.mins_y < PL_MIN.y || toucher.mins_z < PL_MIN.z
	|| toucher.maxs_x > PL_MAX.x || toucher.maxs_y > PL_MAX.y || toucher.maxs_z > PL_MAX.z)
	{
		// can't teleport this
		return;
	}
	*/

	if(Portal_TeleportPlayer(this, toucher, this.aiment))
		if(toucher.classname == "porto")
			if(toucher.effects & EF_RED)
				toucher.effects = (toucher.effects & ~EF_RED) | EF_BLUE;
}

void Portal_MakeBrokenPortal(entity portal)
{
	portal.skin = 2;
	portal.solid = SOLID_NOT;
	settouch(portal, func_null);
	setthink(portal, func_null);
	portal.effects = 0;
	portal.nextthink = 0;
	portal.takedamage = DAMAGE_NO;
}

void Portal_MakeWaitingPortal(entity portal)
{
	portal.skin = 2;
	portal.solid = SOLID_NOT;
	settouch(portal, func_null);
	setthink(portal, func_null);
	portal.effects = EF_ADDITIVE;
	portal.nextthink = 0;
	portal.takedamage = DAMAGE_YES;
}

void Portal_MakeInPortal(entity portal)
{
	portal.skin = 0;
	portal.solid = SOLID_NOT; // this is done when connecting them!
	settouch(portal, Portal_Touch);
	setthink(portal, Portal_Think);
	portal.effects = EF_RED;
	portal.nextthink = time;
	portal.takedamage = DAMAGE_NO;
}

void Portal_MakeOutPortal(entity portal)
{
	portal.skin = 1;
	portal.solid = SOLID_NOT;
	settouch(portal, func_null);
	setthink(portal, func_null);
	portal.effects = EF_STARDUST | EF_BLUE;
	portal.nextthink = 0;
	portal.takedamage = DAMAGE_YES;
}

void Portal_Disconnect(entity teleporter, entity destination)
{
	teleporter.enemy = NULL;
	destination.enemy = NULL;
	Portal_MakeBrokenPortal(teleporter);
	Portal_MakeBrokenPortal(destination);
}

void Portal_Connect(entity teleporter, entity destination)
{
	teleporter.portal_transform = AnglesTransform_RightDivide(AnglesTransform_TurnDirectionFR(destination.mangle), teleporter.mangle);

	teleporter.enemy = destination;
	destination.enemy = teleporter;
	Portal_MakeInPortal(teleporter);
	Portal_MakeOutPortal(destination);
	teleporter.fade_time = ((autocvar_g_balance_portal_lifetime >= 0) ? time + autocvar_g_balance_portal_lifetime : 0);
	destination.fade_time = teleporter.fade_time;
	teleporter.portal_wants_to_vanish = 0;
	destination.portal_wants_to_vanish = 0;
	teleporter.teleport_time = time;
#ifdef PORTALS_ARE_NOT_SOLID
	teleporter.solid = SOLID_TRIGGER;
#else
	teleporter.solid = SOLID_BSP;
#endif
	setorigin(teleporter, teleporter.origin); // link it to the area grid
}

void Portal_Remove(entity portal, float killed)
{
	entity e;
	e = portal.enemy;

	if(e)
	{
		Portal_Disconnect(portal, e);
		Portal_Remove(e, killed);
	}

	if(portal == portal.aiment.portal_in)
		portal.aiment.portal_in = NULL;
	if(portal == portal.aiment.portal_out)
		portal.aiment.portal_out = NULL;
	//portal.aiment = NULL;

	// makes the portal vanish
	if(killed)
	{
		fixedmakevectors(portal.mangle);
		sound(portal, CH_SHOTS, SND_PORTO_EXPLODE, VOL_BASE, ATTEN_NORM);
		Send_Effect(EFFECT_ROCKET_EXPLODE, portal.origin + v_forward * 16, v_forward * 1024, 4);
		delete(portal);
	}
	else
	{
		Portal_MakeBrokenPortal(portal);
		sound(portal, CH_SHOTS, SND_PORTO_EXPIRE, VOL_BASE, ATTEN_NORM);
		SUB_SetFade(portal, time, 0.5);
	}
}

void Portal_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(deathtype == DEATH_TELEFRAG.m_id)
		return;
	if(attacker != this.aiment)
		if(IS_INDEPENDENT_PLAYER(attacker) || IS_INDEPENDENT_PLAYER(this.aiment))
			return;
	TakeResource(this, RES_HEALTH, damage);
	if(GetResource(this, RES_HEALTH) < 0)
		Portal_Remove(this, 1);
}

void Portal_Think_TryTeleportPlayer(entity this, entity e, vector g, entity portal_owner)
{
	if(!Portal_WillHitPlane(e.origin, e.mins, e.maxs, e.velocity + g, this.origin, v_forward, this.maxs.x))
		return;

	// if e would hit the portal in a frame...
	// already teleport him
	tracebox(e.origin, e.mins, e.maxs, e.origin + e.velocity * 2 * frametime, MOVE_NORMAL, e);
	if(trace_ent == this)
		Portal_TeleportPlayer(this, e, portal_owner);
}

void Portal_Think(entity this)
{
	entity o;
	vector g;

#ifdef PORTALS_ARE_NOT_SOLID
	// portal is being removed?
	if(this.solid != SOLID_TRIGGER)
		return; // possibly engine bug

	if(!this.enemy)
		error("Portal_Think called for a broken portal\n");

	o = this.aiment;
	this.solid = SOLID_BBOX;
	this.aiment = NULL;

	g = frametime * '0 0 -1' * autocvar_sv_gravity;

	fixedmakevectors(this.mangle);

	FOREACH_CLIENT(IS_PLAYER(it), {
		if(it != o)
			if(IS_INDEPENDENT_PLAYER(it) || IS_INDEPENDENT_PLAYER(o))
				continue; // cannot go through someone else's portal

		if(it != o || time >= this.portal_activatetime)
			Portal_Think_TryTeleportPlayer(this, it, g, o);

		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	    {
	    	.entity weaponentity = weaponentities[slot];
	    	if(it.(weaponentity).hook)
	    		Portal_Think_TryTeleportPlayer(this, it.(weaponentity).hook, g, o);
	    }
	});
	this.solid = SOLID_TRIGGER;
	this.aiment = o;
#endif

	this.nextthink = time;

	if(this.fade_time && time > this.fade_time)
		Portal_Remove(this, 0);
}

bool Portal_Customize(entity this, entity client)
{
	if(IS_SPEC(client))
		client = client.enemy;
	if(client == this.aiment)
	{
		this.modelindex = this.savemodelindex;
	}
	else if(IS_INDEPENDENT_PLAYER(client) || IS_INDEPENDENT_PLAYER(this.aiment))
	{
		this.modelindex = 0;
	}
	else
	{
		this.modelindex = this.savemodelindex;
	}
	return true;
}

// cleanup:
//   when creating in-portal:
//     disconnect
//     clear existing in-portal
//     set as in-portal
//     connect
//   when creating out-portal:
//     disconnect
//     clear existing out-portal
//     set as out-portal
//   when player dies:
//     disconnect portals
//     clear both portals
//   after timeout of in-portal:
//     disconnect portals
//     clear both portals
//   TODO: ensure only one portal shot at once
float Portal_SetInPortal(entity own, entity portal)
{
	if(own.portal_in)
	{
		if(own.portal_out)
			Portal_Disconnect(own.portal_in, own.portal_out);
		Portal_Remove(own.portal_in, 0);
	}
	own.portal_in = portal;
	if(own.portal_out)
	{
		own.portal_out.portal_id = portal.portal_id;
		Portal_Connect(own.portal_in, own.portal_out);
	}
	return 2;
}
float Portal_SetOutPortal(entity own, entity portal)
{
	if(own.portal_out)
	{
		if(own.portal_in)
			Portal_Disconnect(own.portal_in, own.portal_out);
		Portal_Remove(own.portal_out, 0);
	}
	own.portal_out = portal;
	if(own.portal_in)
	{
		own.portal_in.portal_id = portal.portal_id;
		Portal_Connect(own.portal_in, own.portal_out);
	}
	return 1;
}
void Portal_ClearAll_PortalsOnly(entity own)
{
	if(own.portal_in)
		Portal_Remove(own.portal_in, 0);
	if(own.portal_out)
		Portal_Remove(own.portal_out, 0);
}
void Portal_ClearAll(entity own)
{
	Portal_ClearAll_PortalsOnly(own);
	W_Porto_Remove(own);
}
void Portal_RemoveLater_Think(entity this)
{
	Portal_Remove(this, this.cnt);
}
void Portal_RemoveLater(entity portal, float kill)
{
	Portal_MakeBrokenPortal(portal);
	portal.cnt = kill;
	setthink(portal, Portal_RemoveLater_Think);
	portal.nextthink = time;
}
void Portal_ClearAllLater_PortalsOnly(entity own)
{
	if(own.portal_in)
		Portal_RemoveLater(own.portal_in, 0);
	if(own.portal_out)
		Portal_RemoveLater(own.portal_out, 0);
}
void Portal_ClearAllLater(entity own)
{
	Portal_ClearAllLater_PortalsOnly(own);
	W_Porto_Remove(own);
}
void Portal_ClearWithID(entity own, float id)
{
	if(own.portal_in)
		if(own.portal_in.portal_id == id)
		{
			if(own.portal_out)
				Portal_Disconnect(own.portal_in, own.portal_out);
			Portal_Remove(own.portal_in, 0);
		}
	if(own.portal_out)
		if(own.portal_out.portal_id == id)
		{
			if(own.portal_in)
				Portal_Disconnect(own.portal_in, own.portal_out);
			Portal_Remove(own.portal_out, 0);
		}
}

entity Portal_Spawn(entity own, vector org, vector ang)
{
	entity portal;

	fixedmakevectors(ang);
	if(!CheckWireframeBox(own, org - 48 * v_right - 48 * v_up + 16 * v_forward, 96 * v_right, 96 * v_up, 96 * v_forward))
		return NULL;

	portal = new(portal);
	portal.aiment = own;
	setorigin(portal, org);
	portal.mangle = ang;
	portal.angles = ang;
	portal.angles_x = -portal.angles.x; // is a bmodel
	setthink(portal, Portal_Think);
	portal.nextthink = 0;
	portal.portal_activatetime = time + 0.1;
	portal.takedamage = DAMAGE_AIM;
	portal.event_damage = Portal_Damage;
	portal.fade_time = ((autocvar_g_balance_portal_lifetime >= 0) ? time + autocvar_g_balance_portal_lifetime : 0);
	SetResourceExplicit(portal, RES_HEALTH, autocvar_g_balance_portal_health);
	setmodel(portal, MDL_PORTAL);
	portal.savemodelindex = portal.modelindex;
	setcefc(portal, Portal_Customize);

	if(!Portal_FindSafeOrigin(portal))
	{
		delete(portal);
		return NULL;
	}

	setsize(portal, '-48 -48 -48', '48 48 48');
	Portal_MakeWaitingPortal(portal);

	return portal;
}

float Portal_SpawnInPortalAtTrace(entity own, vector dir, float portal_id_val)
{
	entity portal;
	vector ang;
	vector org;

	org = trace_endpos;
	ang = fixedvectoangles2(trace_plane_normal, dir);
	fixedmakevectors(ang);

	portal = Portal_Spawn(own, org, ang);
	if(!portal)
		return 0;

	portal.portal_id = portal_id_val;
	Portal_SetInPortal(own, portal);

	return 1;
}

float Portal_SpawnOutPortalAtTrace(entity own, vector dir, float portal_id_val)
{
	entity portal;
	vector ang;
	vector org;

	org = trace_endpos;
	ang = fixedvectoangles2(trace_plane_normal, dir);
	fixedmakevectors(ang);

	portal = Portal_Spawn(own, org, ang);
	if(!portal)
		return 0;

	portal.portal_id = portal_id_val;
	Portal_SetOutPortal(own, portal);

	return 1;
}
