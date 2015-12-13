#ifndef IMPLEMENTATION
CLASS(PortoLaunch, Weapon)
/* ammotype  */ ATTRIB(PortoLaunch, ammo_field, .int, ammo_none)
/* impulse   */ ATTRIB(PortoLaunch, impulse, int, 0)
/* flags     */ ATTRIB(PortoLaunch, spawnflags, int, WEP_TYPE_OTHER | WEP_FLAG_SUPERWEAPON);
/* rating    */ ATTRIB(PortoLaunch, bot_pickupbasevalue, float, 0);
/* color     */ ATTRIB(PortoLaunch, wpcolor, vector, '0.5 0.5 0.5');
/* modelname */ ATTRIB(PortoLaunch, mdl, string, "porto");
#ifndef MENUQC
/* model     */ ATTRIB(PortoLaunch, m_model, Model, MDL_PORTO_ITEM);
#endif
/* crosshair */ ATTRIB(PortoLaunch, w_crosshair, string, "gfx/crosshairporto");
/* crosshair */ ATTRIB(PortoLaunch, w_crosshair_size, float, 0.6);
/* wepimg    */ ATTRIB(PortoLaunch, model2, string, "weaponporto");
/* refname   */ ATTRIB(PortoLaunch, netname, string, "porto");
/* wepname   */ ATTRIB(PortoLaunch, m_name, string, _("Port-O-Launch"));

#define X(BEGIN, P, END, class, prefix) \
	BEGIN(class) \
		P(class, prefix, animtime, float, BOTH) \
		P(class, prefix, lifetime, float, BOTH) \
		P(class, prefix, refire, float, BOTH) \
		P(class, prefix, secondary, float, NONE) \
		P(class, prefix, speed, float, BOTH) \
        P(class, prefix, switchdelay_drop, float, NONE) \
		P(class, prefix, switchdelay_raise, float, NONE) \
        P(class, prefix, weaponreplace, string,NONE) \
        P(class, prefix, weaponstartoverride, float, NONE) \
        P(class, prefix, weaponstart, float, NONE) \
        P(class, prefix, weaponthrowable, float, NONE) \
	END()
    W_PROPS(X, PortoLaunch, porto)
#undef X
ENDCLASS(PortoLaunch)
REGISTER_WEAPON(PORTO, porto, NEW(PortoLaunch));

#ifdef SVQC
.entity porto_current;
.vector porto_v_angle; // holds "held" view angles
.float porto_v_angle_held;
.vector right_vector;
.float porto_forbidden;
#endif
#endif
#ifdef IMPLEMENTATION
#ifdef SVQC
#include "../../triggers/trigger/jumppads.qh"

spawnfunc(weapon_porto) { weapon_defaultspawnfunc(this, WEP_PORTO); }

REGISTER_MUTATOR(porto_ticker, true);
MUTATOR_HOOKFUNCTION(porto_ticker, SV_StartFrame) {
	entity e;
	FOR_EACH_PLAYER(e)
		e.porto_forbidden = max(0, e.porto_forbidden - 1);
}

void W_Porto_Success()
{SELFPARAM();
	if(self.realowner == world)
	{
		objerror("Cannot succeed successfully: no owner\n");
		return;
	}

	self.realowner.porto_current = world;
	remove(self);
}

string W_ThrowNewWeapon(entity own, float wpn, float doreduce, vector org, vector velo);
void W_Porto_Fail(float failhard)
{SELFPARAM();
	if(self.realowner == world)
	{
		objerror("Cannot fail successfully: no owner\n");
		return;
	}

	// no portals here!
	if(self.cnt < 0)
	{
		Portal_ClearWithID(self.realowner, self.portal_id);
	}

	self.realowner.porto_current = world;

	if(self.cnt < 0 && !failhard && self.realowner.playerid == self.playerid && self.realowner.deadflag == DEAD_NO && !(self.realowner.weapons & WEPSET(PORTO)))
	{
		setsize(self, '-16 -16 0', '16 16 32');
		setorigin(self, self.origin + trace_plane_normal);
		if(move_out_of_solid(self))
		{
			self.flags = FL_ITEM;
			self.velocity = trigger_push_calculatevelocity(self.origin, self.realowner, 128);
			tracetoss(self, self);
			if(vlen(trace_endpos - self.realowner.origin) < 128)
			{
				W_ThrowNewWeapon(self.realowner, WEP_PORTO.m_id, 0, self.origin, self.velocity);
				Send_Notification(NOTIF_ONE, self.realowner, MSG_CENTER, CENTER_PORTO_FAILED);
			}
		}
	}
	remove(self);
}

void W_Porto_Remove(entity p)
{SELFPARAM();
	if(p.porto_current.realowner == p && p.porto_current.classname == "porto")
	{
		WITH(entity, self, p.porto_current, W_Porto_Fail(1));
	}
}

void W_Porto_Think()
{SELFPARAM();
	trace_plane_normal = '0 0 0';
	if(self.realowner.playerid != self.playerid)
		remove(self);
	else
		W_Porto_Fail(0);
}

void W_Porto_Touch()
{SELFPARAM();
	vector norm;

	// do not use PROJECTILE_TOUCH here
	// FIXME but DO handle warpzones!

	if(other.classname == "portal")
		return; // handled by the portal

	norm = trace_plane_normal;
	if(trace_ent.iscreature)
	{
		traceline(trace_ent.origin, trace_ent.origin + '0 0 2' * PL_MIN.z, MOVE_WORLDONLY, self);
		if(trace_fraction >= 1)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
			return;
		if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
			return;
	}

	if(self.realowner.playerid != self.playerid)
	{
		sound(self, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
		remove(self);
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SLICK || trace_dphitcontents & DPCONTENTS_PLAYERCLIP)
	{
		spamsound(self, CH_SHOTS, SND(PORTO_BOUNCE), VOL_BASE, ATTEN_NORM);
		// just reflect
		self.right_vector = self.right_vector - 2 * trace_plane_normal * (self.right_vector * trace_plane_normal);
		self.angles = vectoangles(self.velocity - 2 * trace_plane_normal * (self.velocity * trace_plane_normal));
	}
	else if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)
	{
		sound(self, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
		W_Porto_Fail(0);
		if(self.cnt < 0)
			Portal_ClearAll_PortalsOnly(self.realowner);
	}
	else if(self.cnt == 0)
	{
		// in-portal only
		if(Portal_SpawnInPortalAtTrace(self.realowner, self.right_vector, self.portal_id))
		{
			sound(self, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, self.realowner, MSG_CENTER, CENTER_PORTO_CREATED_IN);
			W_Porto_Success();
		}
		else
		{
			sound(self, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			W_Porto_Fail(0);
		}
	}
	else if(self.cnt == 1)
	{
		// out-portal only
		if(Portal_SpawnOutPortalAtTrace(self.realowner, self.right_vector, self.portal_id))
		{
			sound(self, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, self.realowner, MSG_CENTER, CENTER_PORTO_CREATED_OUT);
			W_Porto_Success();
		}
		else
		{
			sound(self, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			W_Porto_Fail(0);
		}
	}
	else if(self.effects & EF_RED)
	{
		self.effects += EF_BLUE - EF_RED;
		if(Portal_SpawnInPortalAtTrace(self.realowner, self.right_vector, self.portal_id))
		{
			sound(self, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Send_Notification(NOTIF_ONE, self.realowner, MSG_CENTER, CENTER_PORTO_CREATED_IN);
			self.right_vector = self.right_vector - 2 * trace_plane_normal * (self.right_vector * norm);
			self.angles = vectoangles(self.velocity - 2 * trace_plane_normal * (self.velocity * norm));
			CSQCProjectile(self, true, PROJECTILE_PORTO_BLUE, true); // change type
		}
		else
		{
			sound(self, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			trace_plane_normal = norm;
			Portal_ClearAll_PortalsOnly(self.realowner);
			W_Porto_Fail(0);
		}
	}
	else
	{
		if(self.realowner.portal_in.portal_id == self.portal_id)
		{
			if(Portal_SpawnOutPortalAtTrace(self.realowner, self.right_vector, self.portal_id))
			{
				sound(self, CH_SHOTS, SND_PORTO_CREATE, VOL_BASE, ATTEN_NORM);
				trace_plane_normal = norm;
				Send_Notification(NOTIF_ONE, self.realowner, MSG_CENTER, CENTER_PORTO_CREATED_OUT);
				W_Porto_Success();
			}
			else
			{
				sound(self, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
				Portal_ClearAll_PortalsOnly(self.realowner);
				W_Porto_Fail(0);
			}
		}
		else
		{
			sound(self, CH_SHOTS, SND_PORTO_UNSUPPORTED, VOL_BASE, ATTEN_NORM);
			Portal_ClearAll_PortalsOnly(self.realowner);
			W_Porto_Fail(0);
		}
	}
}

void W_Porto_Attack(float type)
{SELFPARAM();
	entity gren;

	W_SetupShot(self, false, 4, SND(PORTO_FIRE), CH_WEAPON_A, 0);
	// always shoot from the eye
	w_shotdir = v_forward;
	w_shotorg = self.origin + self.view_ofs + ((w_shotorg - self.origin - self.view_ofs) * v_forward) * v_forward;

	//Send_Effect(EFFECT_GRENADE_MUZZLEFLASH, w_shotorg, w_shotdir * 1000, 1);

	gren = new(porto);
	gren.cnt = type;
	gren.owner = gren.realowner = self;
	gren.playerid = self.playerid;
	gren.bot_dodge = true;
	gren.bot_dodgerating = 200;
	gren.movetype = MOVETYPE_BOUNCEMISSILE;
	PROJECTILE_MAKETRIGGER(gren);
	gren.effects = EF_RED;
	gren.scale = 4;
	setorigin(gren, w_shotorg);
	setsize(gren, '0 0 0', '0 0 0');

	gren.nextthink = time + WEP_CVAR_BOTH(porto, (type <= 0), lifetime);
	gren.think = W_Porto_Think;
	gren.touch = W_Porto_Touch;

	if(self.items & ITEM_Strength.m_itemid)
		W_SetupProjVelocity_Basic(gren, WEP_CVAR_BOTH(porto, (type <= 0), speed) * autocvar_g_balance_powerup_strength_force, 0);
	else
		W_SetupProjVelocity_Basic(gren, WEP_CVAR_BOTH(porto, (type <= 0), speed), 0);

	gren.angles = vectoangles(gren.velocity);
	gren.flags = FL_PROJECTILE;

	gren.portal_id = time;
	self.porto_current = gren;
	gren.playerid = self.playerid;
	fixedmakevectors(fixedvectoangles(gren.velocity));
	gren.right_vector = v_right;

	gren.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP;

	if(type > 0)
		CSQCProjectile(gren, true, PROJECTILE_PORTO_BLUE, true);
	else
		CSQCProjectile(gren, true, PROJECTILE_PORTO_RED, true);

	MUTATOR_CALLHOOK(EditProjectile, self, gren);
}

		METHOD(PortoLaunch, wr_aim, void(entity thiswep))
		{
			SELFPARAM();
			self.BUTTON_ATCK = false;
			self.BUTTON_ATCK2 = false;
			if(!WEP_CVAR(porto, secondary))
				if(bot_aim(WEP_CVAR_PRI(porto, speed), 0, WEP_CVAR_PRI(porto, lifetime), false))
					self.BUTTON_ATCK = true;
		}
		METHOD(PortoLaunch, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
		{
			if(WEP_CVAR(porto, secondary))
			{
				if(fire & 1)
				if(!actor.porto_current)
				if(!actor.porto_forbidden)
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(porto, refire)))
				{
					W_Porto_Attack(0);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(porto, animtime), w_ready);
				}

				if(fire & 2)
				if(!actor.porto_current)
				if(!actor.porto_forbidden)
				if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(porto, refire)))
				{
					W_Porto_Attack(1);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(porto, animtime), w_ready);
				}
			}
			else
			{
				if(actor.porto_v_angle_held)
				{
					if(!(fire & 2))
					{
						actor.porto_v_angle_held = 0;

						ClientData_Touch(actor);
					}
				}
				else
				{
					if(fire & 2)
					{
						actor.porto_v_angle = actor.v_angle;
						actor.porto_v_angle_held = 1;

						ClientData_Touch(actor);
					}
				}
				if(actor.porto_v_angle_held)
					makevectors(actor.porto_v_angle); // override the previously set angles

				if(fire & 1)
				if(!actor.porto_current)
				if(!actor.porto_forbidden)
				if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(porto, refire)))
				{
					W_Porto_Attack(-1);
					weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(porto, animtime), w_ready);
				}
			}
		}
		METHOD(PortoLaunch, wr_checkammo1, bool(entity this))
		{
			// always allow infinite ammo
			return true;
		}
		METHOD(PortoLaunch, wr_checkammo2, bool(entity this))
		{
			// always allow infinite ammo
			return true;
		}
		METHOD(PortoLaunch, wr_setup, void(entity thiswep))
		{
			SELFPARAM();
			self.ammo_field = ammo_none;
		}
		METHOD(PortoLaunch, wr_resetplayer, void(entity thiswep))
		{
			SELFPARAM();
			self.porto_current = world;
		}
#endif
#ifdef CSQC
		METHOD(PortoLaunch, wr_impacteffect, void(entity this)) {
			LOG_WARNING("Since when does Porto send DamageInfo?\n");
		}
#endif
#endif
