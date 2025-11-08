#include "hook.qh"

#ifdef SVQC

void W_Hook_ExplodeThink(entity this)
{
	float dt, dmg_remaining_next, f;

	dt = time - this.teleport_time;
	dmg_remaining_next = (bound(0, 1 - dt / this.dmg_duration, 1) ** this.dmg_power);

	f = this.dmg_last - dmg_remaining_next;
	this.dmg_last = dmg_remaining_next;

	RadiusDamage(this, this.realowner, this.dmg * f, this.dmg_edge * f, this.dmg_radius, this.realowner, NULL, this.dmg_force * f, this.projectiledeathtype, this.weaponentity_fld, NULL);
	this.projectiledeathtype |= HITTYPE_SPAM;
	//RadiusDamage(this, NULL, this.dmg * f, this.dmg_edge * f, this.dmg_radius, NULL, NULL, this.dmg_force * f, this.projectiledeathtype, NULL);

	if(dt < this.dmg_duration)
		this.nextthink = time + 0.05; // soon
	else
		delete(this);
}

void W_Hook_Explode2(entity this)
{
	this.event_damage = func_null;
	settouch(this, func_null);
	this.effects |= EF_NODRAW;

	setthink(this, W_Hook_ExplodeThink);
	this.nextthink = time;
	this.dmg = WEP_CVAR_SEC(WEP_HOOK, damage);
	this.dmg_edge = WEP_CVAR_SEC(WEP_HOOK, edgedamage);
	this.dmg_radius = WEP_CVAR_SEC(WEP_HOOK, radius);
	this.dmg_force = WEP_CVAR_SEC(WEP_HOOK, force);
	this.dmg_power = WEP_CVAR_SEC(WEP_HOOK, power);
	this.dmg_duration = WEP_CVAR_SEC(WEP_HOOK, duration);
	this.teleport_time = time;
	this.dmg_last = 1;
	set_movetype(this, MOVETYPE_NONE);
}

void W_Hook_Explode2_use(entity this, entity actor, entity trigger)
{
	W_Hook_Explode2(this);
}

void W_Hook_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(GetResource(this, RES_HEALTH) <= 0)
		return;

	if(!W_CheckProjectileDamage(inflictor.realowner, this.realowner, deathtype, -1)) // no exceptions
		return; // g_projectiles_damage says to halt

	SetResourceExplicit(this, RES_HEALTH, GetResource(this, RES_HEALTH));

	if(GetResource(this, RES_HEALTH) <= 0)
		W_PrepareExplosionByDamage(this, this.realowner, W_Hook_Explode2);
}

void W_Hook_Touch2(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	this.use(this, NULL, NULL);
}

void W_Hook_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	//W_DecreaseAmmo(thiswep, actor, WEP_CVAR_SEC(WEP_HOOK, ammo)); // WEAPONTODO: Figure out how to handle ammo with hook secondary (gravitybomb)
	W_SetupShot(actor, weaponentity, false, 4, SND_HOOKBOMB_FIRE, CH_WEAPON_A, WEP_CVAR_SEC(WEP_HOOK, damage), WEP_HOOK.m_id | HITTYPE_SECONDARY);

	entity gren = new(hookbomb);
	gren.owner = gren.realowner = actor;
	gren.bot_dodge = true;
	gren.bot_dodgerating = WEP_CVAR_SEC(WEP_HOOK, damage);
	set_movetype(gren, MOVETYPE_TOSS);
	PROJECTILE_MAKETRIGGER(gren);
	gren.projectiledeathtype = WEP_HOOK.m_id | HITTYPE_SECONDARY;
	gren.weaponentity_fld = weaponentity;
	setorigin(gren, w_shotorg);
	setsize(gren, '0 0 0', '0 0 0');

	gren.nextthink = time + WEP_CVAR_SEC(WEP_HOOK, lifetime);
	setthink(gren, adaptor_think2use_hittype_splash);
	gren.use = W_Hook_Explode2_use;
	settouch(gren, W_Hook_Touch2);

	gren.takedamage = DAMAGE_YES;
	SetResourceExplicit(gren, RES_HEALTH, WEP_CVAR_SEC(WEP_HOOK, health));
	gren.damageforcescale = WEP_CVAR_SEC(WEP_HOOK, damageforcescale);
	gren.event_damage = W_Hook_Damage;
	gren.damagedbycontents = true;
	IL_PUSH(g_damagedbycontents, gren);
	gren.missile_flags = MIF_SPLASH | MIF_ARC;

	gren.velocity = '0 0 1' * WEP_CVAR_SEC(WEP_HOOK, speed);
	if (autocvar_g_projectiles_newton_style)
		gren.velocity = gren.velocity + actor.velocity;

	gren.gravity = WEP_CVAR_SEC(WEP_HOOK, gravity);
	//W_SetupProjVelocity_Basic(gren); // just falling down!

	gren.angles = '0 0 0';
	gren.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, gren);
	IL_PUSH(g_bot_dodge, gren);

	CSQCProjectile(gren, true, PROJECTILE_HOOKBOMB, true);

	MUTATOR_CALLHOOK(EditProjectile, actor, gren);
}

METHOD(Hook, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	if (fire & 1)
	{
		if(!actor.(weaponentity).hook)
		if(!(actor.(weaponentity).hook_state & HOOK_WAITING_FOR_RELEASE))
		if(time > actor.(weaponentity).hook_refire)
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, -1))
		{
			W_DecreaseAmmo(thiswep, actor, thiswep.ammo_factor * WEP_CVAR_PRI(WEP_HOOK, ammo), weaponentity);
			actor.(weaponentity).hook_state |= HOOK_FIRING;
			actor.(weaponentity).hook_state |= HOOK_WAITING_FOR_RELEASE;
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_HOOK, animtime), w_ready);
		}
	}
	else
	{
		actor.(weaponentity).hook_state |= HOOK_REMOVING;
		actor.(weaponentity).hook_state &= ~HOOK_WAITING_FOR_RELEASE;
	}

	if(fire & 2)
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, true, WEP_CVAR_SEC(WEP_HOOK, refire)))
		{
			W_Hook_Attack2(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_SEC(WEP_HOOK, animtime), w_ready);
		}
	}

	if(actor.(weaponentity).hook)
	{
		// if hooked, no bombs, and increase the timer
		actor.(weaponentity).hook_refire = max(actor.(weaponentity).hook_refire, time + WEP_CVAR_PRI(WEP_HOOK, refire) * W_WeaponRateFactor(actor));

		// hook also inhibits health regeneration, but only for 1 second
		if(!(actor.items & IT_UNLIMITED_AMMO))
			actor.pauseregen_finished = max(actor.pauseregen_finished, time + autocvar_g_balance_pause_fuel_regen);
	}

	if(actor.(weaponentity).hook && actor.(weaponentity).hook.state == 1)
	{
		float hooked_time_max = WEP_CVAR_PRI(WEP_HOOK, hooked_time_max);
		if(hooked_time_max > 0)
		{
			if(time > actor.(weaponentity).hook_time_hooked + hooked_time_max)
				actor.(weaponentity).hook_state |= HOOK_REMOVING;
		}

		float hooked_fuel = thiswep.ammo_factor * WEP_CVAR_PRI(WEP_HOOK, hooked_ammo);
		if(hooked_fuel > 0)
		{
			if(time > actor.(weaponentity).hook_time_fueldecrease)
			{
				if(!(actor.items & IT_UNLIMITED_AMMO))
				{
					if(GetResource(actor, RES_FUEL) >= (time - actor.(weaponentity).hook_time_fueldecrease) * hooked_fuel)
					{
						W_DecreaseAmmo(thiswep, actor, (time - actor.(weaponentity).hook_time_fueldecrease) * hooked_fuel, weaponentity);
						actor.(weaponentity).hook_time_fueldecrease = time;
						// decrease next frame again
					}
					else
					{
						SetResource(actor, RES_FUEL, 0);
						actor.(weaponentity).hook_state |= HOOK_REMOVING;
						if(actor.(weaponentity).m_weapon != WEP_Null) // offhand
							W_SwitchWeapon_Force(actor, w_getbestweapon(actor, weaponentity), weaponentity);
					}
				}
			}
		}
	}
	else
	{
		actor.(weaponentity).hook_time_hooked = time;
		actor.(weaponentity).hook_time_fueldecrease = time + WEP_CVAR_PRI(WEP_HOOK, hooked_time_free);
	}

	actor.(weaponentity).hook_state = BITSET(actor.(weaponentity).hook_state, HOOK_PULLING, (!PHYS_INPUT_BUTTON_CROUCH(actor) || !autocvar_g_balance_grapplehook_crouchslide));

	if (actor.(weaponentity).hook_state & HOOK_FIRING)
	{
		if (actor.(weaponentity).hook)
			RemoveHook(actor.(weaponentity).hook);
		FireGrapplingHook(actor, weaponentity);
		actor.(weaponentity).hook_state &= ~HOOK_FIRING;
		actor.(weaponentity).hook_refire = max(actor.(weaponentity).hook_refire, time + autocvar_g_balance_grapplehook_refire * W_WeaponRateFactor(actor));
	}
	else if (actor.(weaponentity).hook_state & HOOK_REMOVING)
	{
		if (actor.(weaponentity).hook)
			RemoveHook(actor.(weaponentity).hook);
		actor.(weaponentity).hook_state &= ~HOOK_REMOVING;
	}
}

METHOD(Hook, wr_setup, void(entity thiswep, entity actor, .entity weaponentity))
{
	actor.(weaponentity).hook_state &= ~HOOK_WAITING_FOR_RELEASE;
}

METHOD(Hook, wr_checkammo1, bool(Hook thiswep, entity actor, .entity weaponentity))
{
	if (!thiswep.ammo_factor) return true;

	if(actor.(weaponentity).hook)
		return GetResource(actor, RES_FUEL) > 0;

	return GetResource(actor, RES_FUEL) >= WEP_CVAR_PRI(WEP_HOOK, ammo);
}

METHOD(Hook, wr_checkammo2, bool(Hook thiswep, entity actor, .entity weaponentity))
{
	// infinite ammo for now
	return true; // actor.ammo_cells >= WEP_CVAR_SEC(WEP_HOOK, ammo); // WEAPONTODO: see above
}

METHOD(Hook, wr_resetplayer, void(entity thiswep, entity actor))
{
	RemoveGrapplingHooks(actor);
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		actor.(weaponentity).hook_time = 0;
		actor.(weaponentity).hook_refire = time;
	}
}

METHOD(Hook, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_HOOK_MURDER;
}

#endif
#ifdef CSQC

METHOD(Hook, wr_impacteffect, void(entity thiswep, entity actor))
{
	// the hook bomb uses a negative w_backoff factor because it explodes slightly below the floor, unlike other projectiles
	vector org2 = w_org + w_backoff * -2;
	pointparticles(EFFECT_HOOK_EXPLODE, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_HOOKBOMB_IMPACT, VOL_BASE, ATTN_NORM);
}

#endif

#ifdef CSQC
#include <lib/csqcmodel/interpolate.qh>
#include <lib/warpzone/common.qh>

float autocvar_cl_grapplehook_alpha = 1;

void Draw_CylindricLine(vector from, vector to, float thickness, string texture, float aspect, float shift, vector rgb, float theAlpha, float drawflag, vector vieworg);

entityclass(Hook);
classfield(Hook) .vector origin;
classfield(Hook) .vector velocity;
classfield(Hook) .float HookSilent;
classfield(Hook) .float HookRange;

string Draw_GrapplingHook_trace_callback_tex;
float Draw_GrapplingHook_trace_callback_rnd;
vector Draw_GrapplingHook_trace_callback_rgb;
float Draw_GrapplingHook_trace_callback_a;
void Draw_GrapplingHook_trace_callback(vector start, vector hit, vector end)
{
	float i;
	vector vorg;
	vorg = WarpZone_TransformOrigin(WarpZone_trace_transform, view_origin);
	for(i = 0; i < Draw_GrapplingHook_trace_callback_a; ++i)
		Draw_CylindricLine(hit, start, 8, Draw_GrapplingHook_trace_callback_tex, 0.25, Draw_GrapplingHook_trace_callback_rnd, Draw_GrapplingHook_trace_callback_rgb, min(1, Draw_GrapplingHook_trace_callback_a - i), DRAWFLAG_NORMAL, vorg);
	Draw_GrapplingHook_trace_callback_rnd += 0.25 * vlen(hit - start) / 8;
}

classfield(Hook) .float teleport_time;
void Draw_GrapplingHook(entity this)
{
	vector a, b;
	string tex;
	vector rgb;

	if(this.teleport_time)
	if(time > this.teleport_time)
	{
		sound (this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, ATTEN_NORM); // safeguard
		this.teleport_time = 0;
	}

	InterpolateOrigin_Do(this);

	int s = W_GunAlign(viewmodels[this.cnt], STAT(GUNALIGN)) - 1;
	vector vs = hook_shotorigin[s];

	if((this.owner.sv_entnum == player_localentnum - 1))
	{
		if(autocvar_chase_active)
			a = csqcplayer.origin + csqcplayer.view_ofs;
		else
			a = view_origin + view_forward * vs.x + view_right * -vs.y + view_up * vs.z;
		b = this.origin;
	}
	else
	{
		a = this.velocity;
		b = this.origin;
	}

	int t = entcs_GetTeamColor(this.owner.sv_entnum);

	float intensity = autocvar_cl_grapplehook_alpha;
	float offset = 0;
	switch(t)
	{
		case NUM_TEAM_1: tex = "particles/hook_red"; rgb = '1 0.3 0.3'; break;
		case NUM_TEAM_2: tex = "particles/hook_blue"; rgb = '0.3 0.3 1'; break;
		case NUM_TEAM_3: tex = "particles/hook_yellow"; rgb = '1 1 0.3'; break;
		case NUM_TEAM_4: tex = "particles/hook_pink"; rgb = '1 0.3 1'; break;
		default: tex = "particles/hook_white"; rgb = entcs_GetColor(this.sv_entnum - 1); break;
	}

	MUTATOR_CALLHOOK(DrawGrapplingHook, this, tex, rgb, t);
	tex = M_ARGV(1, string);
	rgb = M_ARGV(2, vector);

	Draw_GrapplingHook_trace_callback_tex = tex;
	Draw_GrapplingHook_trace_callback_rnd = offset;
	Draw_GrapplingHook_trace_callback_rgb = rgb;
	Draw_GrapplingHook_trace_callback_a = intensity;
	WarpZone_TraceBox_ThroughZone(a, '0 0 0', '0 0 0', b, MOVE_NOTHING, NULL, NULL, Draw_GrapplingHook_trace_callback);
	Draw_GrapplingHook_trace_callback_tex = string_null;

	vector atrans = WarpZone_TransformOrigin(WarpZone_trace_transform, a);

	if(vdist(trace_endpos - atrans, >, 0.5))
	{
		setorigin(this, trace_endpos); // hook endpoint!
		this.angles = vectoangles(trace_endpos - atrans);
		this.drawmask = MASK_NORMAL;
	}
	else
	{
		this.drawmask = 0;
	}
}

void Remove_GrapplingHook(entity this)
{
	sound (this, CH_SHOTS_SINGLE, SND_Null, VOL_BASE, ATTEN_NORM);

	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		entity wep = viewmodels[slot];
		if(wep.hook == this)
			wep.hook = NULL;
	}
}

NET_HANDLE(ENT_CLIENT_HOOK, bool bIsNew)
{
	int sf = ReadByte();

	this.HookSilent = (sf & 0x80);
	this.iflags = IFLAG_VELOCITY | IFLAG_ORIGIN;

	InterpolateOrigin_Undo(this);

	if(sf & 1)
	{
		int myowner = ReadByte();
		int slot = ReadByte();
		this.owner = playerslots[myowner - 1];
		this.sv_entnum = myowner;
		if(myowner == player_localentnum)
			viewmodels[slot].hook = this;
		this.cnt = slot;
		this.HookRange = 0;
	}
	if(sf & 2)
	{
		this.origin = ReadVector();
		setorigin(this, this.origin);
	}
	if(sf & 4)
	{
		this.velocity = ReadVector();
	}

	InterpolateOrigin_Note(this);

	if(bIsNew || !this.teleport_time)
	{
		this.draw = Draw_GrapplingHook;
		IL_PUSH(g_drawables, this);
		this.entremove = Remove_GrapplingHook;

		setmodel(this, MDL_HOOK);
		this.drawmask = MASK_NORMAL;
	}

	this.teleport_time = time + 10;
	return true;
}

// TODO: hook: temporarily transform this.origin for drawing the model along warpzones!
#endif
#ifdef MENUQC
#include <common/items/item/ammo.qh>
#include <common/mutators/mutator/hook/hook.qh>

METHOD(Hook, describe, string(Hook this))
{
	TC(Hook, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s is a unique weapon, firing a chain forwards which pulls you in once it latches onto something."), COLORED_NAME(this));
	PAR(_("The secondary fire usually drops a gravity bomb that affects enemies, also releasing light and smoke sort of like a flashbang."));
	PAR(_("It usually requires %s ammo to work, consuming it both when initially firing the hook, and after a couple seconds as it reels you in."), COLORED_NAME(ITEM_Fuel));
	PAR(_("The %s allows reaching previously unreachable places on maps and zooming around the map at high speeds, "
	      "making both surprise ambushes and miraculous escapes possible."), COLORED_NAME(this));
	PAR(_("It isn't available very often on maps, unless the %s mutator is active, in which all players have it on their offhand, used with %s."), COLORED_NAME(MUTATOR_hook), strcat("^3", _("hook"), "^7"));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlySecondary(this.netname, "secondary"));
	return PAGE_TEXT;
}

#endif
