#include "porto.qh"

#include <common/checkextension.qh>

#ifdef CSQC

STATIC_INIT(Porto)
{
	entity e = new_pure(porto);
	e.draw = Porto_Draw;
	IL_PUSH(g_drawables, e);
	e.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;
}

const int polyline_length = 16;
.vector polyline[polyline_length];
void Porto_Draw(entity this)
{
	if (spectatee_status || intermission == 1 || intermission == 2 || STAT(HEALTH) <= 0 || WEP_CVAR(WEP_PORTO, secondary)) return;

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		entity wepent = viewmodels[slot];

		if (wepent.activeweapon != WEP_PORTO) continue;

		vector pos = view_origin;
		vector dir = view_forward;
		makevectors(((autocvar_chase_active) ? warpzone_save_view_angles : view_angles));
		pos += v_right * -wepent.movedir.y
			+  v_up * wepent.movedir.z;

		if (wepent.angles_held_status)
		{
			makevectors(wepent.angles_held);
			dir = v_forward;
		}

		wepent.polyline[0] = pos;

		int portal_number = 0, portal1_idx = 1, portal_max = 2;
		int n = 1 + 2;  // 2 lines == 3 points
		for (int idx = 0; idx < n && idx < polyline_length - 1; )
		{
			traceline(pos, pos + 65536 * dir, true, this);
			dir = reflect(dir, trace_plane_normal);
			pos = trace_endpos;
			wepent.polyline[++idx] = pos;
			if ((trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) || (trace_dphitcontents & DPCONTENTS_PLAYERCLIP))
			{
				n += 1;
				continue;
			}
			if (trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			{
				n = max(2, idx);
				break;
			}
			// check size
			{
				vector ang = vectoangles2(trace_plane_normal, dir);
				ang.x = -ang.x;
				makevectors(ang);
				if (!CheckWireframeBox(this, pos - 48 * v_right - 48 * v_up + 16 * v_forward, 96 * v_right, 96 * v_up, 96 * v_forward))
				{
					n = max(2, idx);
					break;
				}
			}
			portal_number += 1;
			if (portal_number >= portal_max) break;
			if (portal_number == 1) portal1_idx = idx;
		}
		for (int idx = 0; idx < n - 1; ++idx)
		{
			vector p = wepent.polyline[idx], q = wepent.polyline[idx + 1];
			if (idx == 0) p -= view_up * 16;  // line from player
			vector rgb = (idx < portal1_idx) ? '1 0 0' : '0 0 1';
			Draw_CylindricLine(p, q, 4, "", 1, 0, rgb, 0.5, DRAWFLAG_NORMAL, view_origin);
		}
	}
}

#endif

#ifdef SVQC

#include <common/mapobjects/trigger/jumppads.qh>
#include <server/weapons/throwing.qh>

REGISTER_MUTATOR(porto_ticker, true);
MUTATOR_HOOKFUNCTION(porto_ticker, SV_StartFrame) {
	FOREACH_CLIENT(IS_PLAYER(it), it.porto_forbidden = max(0, it.porto_forbidden - 1));
}

void W_Porto_Success(entity this)
{
	if(this.realowner == NULL)
	{
		objerror(this, "Cannot succeed successfully: no owner\n");
		return;
	}

	this.realowner.porto_current = NULL;
	delete(this);
}

void W_Porto_Fail(entity this, float failhard)
{
	if(this.realowner == NULL)
	{
		objerror(this, "Cannot fail successfully: no owner\n");
		return;
	}

	// no portals here!
	if(this.cnt < 0)
	{
		Portal_ClearWithID(this.realowner, this.portal_id);
	}

	this.realowner.porto_current = NULL;

	if(this.cnt < 0 && !failhard && this.realowner.playerid == this.playerid && !IS_DEAD(this.realowner) && !(STAT(WEAPONS, this.realowner) & WEPSET(PORTO)))
	{
		// FIXME: item properties should be obtained from the registry
		setsize(this, ITEM_D_MINS, ITEM_D_MAXS);
		setorigin(this, this.origin + trace_plane_normal);
		if(nudgeoutofsolid_OrFallback(this))
		{
			this.flags = FL_ITEM;
			IL_PUSH(g_items, this);
			this.velocity = trigger_push_calculatevelocity(this.origin, this.realowner, 128, this);
			tracetoss(this, this);
			if(vdist(trace_endpos - this.realowner.origin, <, 128))
			{
				.entity weaponentity = this.weaponentity_fld;
				W_ThrowNewWeapon(this.realowner, WEP_PORTO.m_id, 0, this.origin, this.velocity, weaponentity);
				Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_FAILED);
			}
		}
	}
	delete(this);
}

void W_Porto_Remove(entity p)
{
	if(p.porto_current.realowner == p && p.porto_current.classname == "porto")
	{
		W_Porto_Fail(p.porto_current, 1);
	}
}

void W_Porto_Think(entity this)
{
	trace_plane_normal = '0 0 0';
	if(this.realowner.playerid != this.playerid)
		delete(this);
	else
		W_Porto_Fail(this, 0);
}

void W_Porto_Touch(entity this, entity toucher)
{
	vector norm;

	// do not use PROJECTILE_TOUCH here
	// FIXME but DO handle warpzones!

	if(toucher.classname == "portal")
		return; // handled by the portal

	norm = trace_plane_normal;
	if(trace_ent.iscreature)
	{
		// TODO: why not use entity size?
		traceline(trace_ent.origin, trace_ent.origin + '0 0 2' * PL_MIN_CONST.z, MOVE_WORLDONLY, this);
		if(trace_fraction >= 1)
			return;
		if((trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) || (trace_dphitcontents & DPCONTENTS_PLAYERCLIP))
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			return;
	}

	if(this.realowner.playerid != this.playerid)
	{
		sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
		delete(this);
	}
	else if((trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK) || (trace_dphitcontents & DPCONTENTS_PLAYERCLIP))
	{
		spamsound(this, CH_SHOTS, SND_PORTO_BOUNCE, VOL_BASE, ATTEN_NORM);
		// just reflect
		this.right_vector = this.right_vector - 2 * trace_plane_normal * (this.right_vector * trace_plane_normal);
		this.angles = vectoangles(this.velocity - 2 * trace_plane_normal * (this.velocity * trace_plane_normal));
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
		W_Porto_Fail(this, 0);
		if(this.cnt < 0)
			Portal_ClearAll_PortalsOnly(this.realowner);
	}
	else if(this.cnt == 0)
	{
		// in-portal only
		if(Portal_SpawnInPortalAtTrace(this.realowner, this.right_vector, this.portal_id))
		{
			sound(this, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_CREATED_IN);
			W_Porto_Success(this);
		}
		else
		{
			sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			W_Porto_Fail(this, 0);
		}
	}
	else if(this.cnt == 1)
	{
		// out-portal only
		if(Portal_SpawnOutPortalAtTrace(this.realowner, this.right_vector, this.portal_id))
		{
			sound(this, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_CREATED_OUT);
			W_Porto_Success(this);
		}
		else
		{
			sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			W_Porto_Fail(this, 0);
		}
	}
	else if(this.effects & EF_RED)
	{
		this.effects += EF_BLUE - EF_RED;
		if(Portal_SpawnInPortalAtTrace(this.realowner, this.right_vector, this.portal_id))
		{
			sound(this, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_CREATED_IN);
			this.right_vector = this.right_vector - 2 * trace_plane_normal * (this.right_vector * norm);
			this.angles = vectoangles(this.velocity - 2 * trace_plane_normal * (this.velocity * norm));
			CSQCProjectile(this, true, PROJECTILE_PORTO_BLUE, true); // change type
		}
		else
		{
			sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Portal_ClearAll_PortalsOnly(this.realowner);
			W_Porto_Fail(this, 0);
		}
	}
	else
	{
		if(this.realowner.portal_in.portal_id == this.portal_id)
		{
			if(Portal_SpawnOutPortalAtTrace(this.realowner, this.right_vector, this.portal_id))
			{
				sound(this, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
				trace_plane_normal = norm;
				Send_Notification(NOTIF_ONE, this.realowner, MSG_CENTER, CENTER_PORTO_CREATED_OUT);
				W_Porto_Success(this);
			}
			else
			{
				sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
				Portal_ClearAll_PortalsOnly(this.realowner);
				W_Porto_Fail(this, 0);
			}
		}
		else
		{
			sound(this, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			Portal_ClearAll_PortalsOnly(this.realowner);
			W_Porto_Fail(this, 0);
		}
	}
}

void W_Porto_Attack(Weapon thiswep, entity actor, .entity weaponentity, float type)
{
	entity gren;

	W_SetupShot(actor, weaponentity, false, 4, SND_PORTO_FIRE, CH_WEAPON_A, 0, thiswep.m_id); // TODO: does the deathtype even need to be set here? porto can't hurt people
	// always shoot from the eye
	w_shotdir = v_forward;
	w_shotorg = actor.origin + actor.view_ofs + ((w_shotorg - actor.origin - actor.view_ofs) * v_forward) * v_forward;

	//Send_Effect(EFFECT_GRENADE_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	gren = new(porto);
	gren.weaponentity_fld = weaponentity;
	gren.cnt = type;
	gren.owner = gren.realowner = actor;
	gren.playerid = actor.playerid;
	gren.bot_dodge = true;
	gren.bot_dodgerating = 200;
	set_movetype(gren, MOVETYPE_BOUNCEMISSILE);
	PROJECTILE_MAKETRIGGER(gren);
	gren.effects = EF_RED;
	gren.scale = 4;
	setorigin(gren, w_shotorg);
	setsize(gren, '0 0 0', '0 0 0');

	gren.nextthink = time + WEP_CVAR_BOTH(WEP_PORTO, (type <= 0), lifetime);
	setthink(gren, W_Porto_Think);
	settouch(gren, W_Porto_Touch);

	// TODO: handle as mutator effect
	if(StatusEffects_active(STATUSEFFECT_Strength, actor))
		W_SetupProjVelocity_Basic(gren, WEP_CVAR_BOTH(WEP_PORTO, (type <= 0), speed) * autocvar_g_balance_powerup_strength_force, 0);
	else
		W_SetupProjVelocity_Basic(gren, WEP_CVAR_BOTH(WEP_PORTO, (type <= 0), speed), 0);

	gren.angles = vectoangles(gren.velocity);
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	gren.portal_id = time;
	actor.porto_current = gren;
	gren.playerid = actor.playerid;
	fixedmakevectors(fixedvectoangles(gren.velocity));
	gren.right_vector = v_right;

	gren.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;

	if(type > 0)
		CSQCProjectile(gren, true, PROJECTILE_PORTO_BLUE, true);
	else
		CSQCProjectile(gren, true, PROJECTILE_PORTO_RED, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, gren);
}

METHOD(PortoLaunch, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	PHYS_INPUT_BUTTON_ATCK(actor) = false;
	PHYS_INPUT_BUTTON_ATCK2(actor) = false;
	if(!WEP_CVAR(WEP_PORTO, secondary))
		if(bot_aim(actor, weaponentity, WEP_CVAR_PRI(WEP_PORTO, speed), 0, WEP_CVAR_PRI(WEP_PORTO, lifetime), false, true))
			PHYS_INPUT_BUTTON_ATCK(actor) = true;
}

METHOD(PortoLaunch, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if(WEP_CVAR(WEP_PORTO, secondary))
	{
		if(fire & 1)
		if(!actor.porto_current)
		if(!actor.porto_forbidden)
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_PORTO, refire)))
		{
			W_Porto_Attack(thiswep, actor, weaponentity, 0);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_PORTO, animtime), w_ready);
		}

		if(fire & 2)
		if(!actor.porto_current)
		if(!actor.porto_forbidden)
		if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(WEP_PORTO, refire)))
		{
			W_Porto_Attack(thiswep, actor, weaponentity, 1);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(WEP_PORTO, animtime), w_ready);
		}
	}
	else
	{
		if(actor.(weaponentity).porto_v_angle_held)
		{
			if(!(fire & 2))
				actor.(weaponentity).porto_v_angle_held = 0;
		}
		else
		{
			if(fire & 2)
			{
				actor.(weaponentity).porto_v_angle = actor.v_angle;
				actor.(weaponentity).porto_v_angle_held = 1;
			}
		}
		if(actor.(weaponentity).porto_v_angle_held)
			makevectors(actor.(weaponentity).porto_v_angle); // override the previously set angles

		if(fire & 1)
		if(!actor.porto_current)
		if(!actor.porto_forbidden)
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_PORTO, refire)))
		{
			W_Porto_Attack(thiswep, actor, weaponentity, -1);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_PORTO, animtime), w_ready);
		}
	}
}

METHOD(PortoLaunch, wr_checkammo1, bool(entity thiswep, entity this, .entity weaponentity))
{
	// always allow infinite ammo
	return true;
}

METHOD(PortoLaunch, wr_checkammo2, bool(entity thiswep, entity this, .entity weaponentity))
{
	// always allow infinite ammo
	return true;
}

METHOD(PortoLaunch, wr_resetplayer, void(entity thiswep, entity actor))
{
	actor.porto_current = NULL;
}

#endif

#ifdef CSQC

METHOD(PortoLaunch, wr_impacteffect, void(entity this, entity actor)) {
	LOG_WARN("Since when does Porto send DamageInfo?");
}

#endif
#ifdef MENUQC

METHOD(PortoLaunch, describe, string(PortoLaunch this))
{
	TC(PortoLaunch, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s is a unique gun that creates one-way portals between flat surfaces on the map, that immediately teleport players and projectiles."), COLORED_NAME(this));
	PAR(_("The secondary fire is used to shoot the out-portal, while the primary fire shoots the in-portal."));
	PAR(_("It doesn't require ammo, but it is destroyed after some time."));
	PAR(_("The portals will close either after the player who shot them dies or after some time period."));
	PAR(_("The %s isn't often placed on maps, but if used well it can make for some interesting gameplay."), COLORED_NAME(this));
	PAR(W_Guide_Keybinds(this));
	return PAGE_TEXT;
}

#endif
