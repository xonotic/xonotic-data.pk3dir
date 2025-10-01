#include "vaporizer.qh"

#ifdef GAMEQC
REGISTER_NET_TEMP(TE_CSQC_VAPORBEAMPARTICLE)
#endif

#if defined(SVQC)
void SendCSQCVaporizerBeamParticle(entity player, int hit) {
	vector v;
	v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	WriteHeader(MSG_BROADCAST, TE_CSQC_VAPORBEAMPARTICLE);
	WriteVector(MSG_BROADCAST, w_shotorg);
	WriteVector(MSG_BROADCAST, v);
	WriteByte(MSG_BROADCAST, hit);
	WriteByte(MSG_BROADCAST, etof(player));
}
#elif defined(CSQC)
bool autocvar_cl_vaporizerbeam_teamcolor = true;
bool autocvar_cl_vaporizerbeam_particle = false;
float autocvar_cl_vaporizerbeam_lifetime = 0.8;
float autocvar_cl_vaporizerbeam_colorboost = 0.7;

string Draw_VaporizerBeam_trace_callback_tex;
float Draw_VaporizerBeam_trace_callback_rnd;
vector Draw_VaporizerBeam_trace_callback_rgb;
float Draw_VaporizerBeam_trace_callback_a;

void Draw_VaporizerBeam_trace_callback(vector start, vector hit, vector end)
{
	float i;
	vector vorg;
	vorg = WarpZone_TransformOrigin(WarpZone_trace_transform, view_origin);
	for(i = 0; i < Draw_VaporizerBeam_trace_callback_a; ++i)
		Draw_CylindricLine(hit, start, 8, Draw_VaporizerBeam_trace_callback_tex, 0.25, Draw_VaporizerBeam_trace_callback_rnd, Draw_VaporizerBeam_trace_callback_rgb, min(1, Draw_VaporizerBeam_trace_callback_a - i), DRAWFLAG_NORMAL, vorg);
	Draw_VaporizerBeam_trace_callback_rnd += 0.25 * vlen(hit - start) / 8;
}

.vector vorg1, vorg2;
void VaporizerBeam_Draw(entity this)
{
	//draw either the old v2.3 beam or the new beam
	particles_alphamin = particles_alphamax = particles_fade = 1;

	string tex = "particles/lgbeam";
	if(this.cnt)
		tex = "particles/gauntletbeam";
	vector rgb = WEP_VAPORIZER.m_color;
	if(autocvar_cl_vaporizerbeam_teamcolor)
		rgb = colormapPaletteColor(entcs_GetClientColors(this.sv_entnum - 1) & 0x0F, true);

	rgb *= (1 + autocvar_cl_vaporizerbeam_colorboost);

	float fail = (this.nextthink - time);

	Draw_VaporizerBeam_trace_callback_tex = tex;
	Draw_VaporizerBeam_trace_callback_rnd = 0;
	Draw_VaporizerBeam_trace_callback_rgb = rgb;
	Draw_VaporizerBeam_trace_callback_a = bound(0, fail, 1);
	WarpZone_TraceBox_ThroughZone(this.vorg1, '0 0 0', '0 0 0', this.vorg2, MOVE_NOTHING, NULL, NULL, Draw_VaporizerBeam_trace_callback);
	Draw_VaporizerBeam_trace_callback_tex = string_null;

	/*if(!MUTATOR_CALLHOOK(Particles_VaporizerBeam, this.vorg1, this.vorg2))
	if(autocvar_cl_particles_oldvortexbeam)
		WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(EFFECT_VORTEX_BEAM_OLD), this.vorg1, this.vorg2, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);
	else
		WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(EFFECT_VORTEX_BEAM), this.vorg1, this.vorg2, 1, PARTICLES_USEALPHA | PARTICLES_USEFADE);*/
}

NET_HANDLE(TE_CSQC_VAPORBEAMPARTICLE, bool isNew)
{
	Net_Accept(vortex_beam);
	setthink(this, SUB_Remove);
	this.nextthink = time + bound(0, autocvar_cl_vaporizerbeam_lifetime, 10);
	this.draw = VaporizerBeam_Draw;
	if (isNew) IL_PUSH(g_drawables, this);
	this.drawmask = MASK_NORMAL;

	this.vorg1 = ReadVector();
	this.vorg2 = ReadVector();
	this.cnt = ReadByte();
	int myowner = ReadByte();
	this.owner = playerslots[myowner - 1];
	this.sv_entnum = myowner;

	//pointparticles(EFFECT_VORTEX_MUZZLEFLASH, this.vorg1, normalize(this.vorg2 - this.vorg1) * 1000, 1);

	if(autocvar_cl_vaporizerbeam_particle)
	{
		vector rgb = WEP_VAPORIZER.m_color;
		if(autocvar_cl_vaporizerbeam_teamcolor)
			rgb = colormapPaletteColor(entcs_GetClientColors(this.sv_entnum - 1) & 0x0F, true);

		particles_colormin = particles_colormax = rgb;
		WarpZone_TrailParticles_WithMultiplier(NULL, particleeffectnum(((this.cnt) ? EFFECT_VAPORIZER_BEAM_HIT : EFFECT_VAPORIZER_BEAM)), this.vorg1, this.vorg2, 1, PARTICLES_USECOLOR);
		this.draw = func_null;
		this.drawmask = MASK_NORMAL;
		delete(this);
	}

	return true;
}
#endif

#ifdef SVQC

void W_RocketMinsta_Explosion(entity actor, .entity weaponentity, vector loc)
{
	if(accuracy_canbegooddamage(actor))
		accuracy_add(actor, WEP_DEVASTATOR, autocvar_g_rm_damage, 0, 0); // add to fired
	entity dmgent = spawn();
	dmgent.owner = dmgent.realowner = actor;
	setorigin(dmgent, loc);
	RadiusDamage (dmgent, actor, autocvar_g_rm_damage, autocvar_g_rm_edgedamage, autocvar_g_rm_radius, NULL, NULL, autocvar_g_rm_force, WEP_DEVASTATOR.m_id | HITTYPE_SPLASH, weaponentity, NULL);
	delete(dmgent);
}

void W_Vaporizer_Attack(Weapon thiswep, entity actor, .entity weaponentity)
{
	bool flying = IsFlying(actor); // do this BEFORE to make the trace values from FireRailgunBullet last
	float vaporizer_damage = ((WEP_CVAR_PRI(WEP_VAPORIZER, damage) > 0) ? WEP_CVAR_PRI(WEP_VAPORIZER, damage) : 10000);

	W_SetupShot(actor, weaponentity, true, 0, SND_Null, CH_WEAPON_A, vaporizer_damage, thiswep.m_id);
	// handle sound separately so we can change the volume
	// added bonus: no longer plays the strength sound (strength gives no bonus to instakill anyway)
	sound (actor, CH_WEAPON_A, SND_VAPORIZER_FIRE, VOL_BASE * 0.8, ATTEN_NORM);

	yoda = 0;
	impressive_hits = 0;
	FireRailgunBullet(actor, weaponentity, w_shotorg, w_shotorg + w_shotdir * max_shot_distance, vaporizer_damage, true, WEP_CVAR_PRI(WEP_VAPORIZER, force), WEP_CVAR_PRI(WEP_VAPORIZER, damagefalloff_mindist), WEP_CVAR_PRI(WEP_VAPORIZER, damagefalloff_maxdist), WEP_CVAR_PRI(WEP_VAPORIZER, damagefalloff_halflife), WEP_CVAR_PRI(WEP_VAPORIZER, damagefalloff_forcehalflife), thiswep.m_id);

	// do this now, as goodhits is disabled below
	vector v = WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos);
	W_MuzzleFlash(thiswep, actor, weaponentity, w_shotorg, normalize(v - w_shotorg));
	SendCSQCVaporizerBeamParticle(actor, impressive_hits);

	if(yoda && flying)
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_YODA);
	if(impressive_hits && actor.vaporizer_lasthit)
	{
		Send_Notification(NOTIF_ONE, actor, MSG_ANNCE, ANNCE_ACHIEVEMENT_IMPRESSIVE);
		impressive_hits = 0; // only every second time
	}

	actor.vaporizer_lasthit = impressive_hits;

	if(autocvar_g_rm)
	if(!(trace_dphitq3surfaceflags & (Q3SURFACEFLAG_SKY | Q3SURFACEFLAG_NOIMPACT)))
		W_RocketMinsta_Explosion(actor, weaponentity, trace_endpos);

	W_DecreaseAmmo(thiswep, actor, ((autocvar_g_instagib) ? 1 : WEP_CVAR_PRI(WEP_VAPORIZER, ammo)), weaponentity);
}

void W_RocketMinsta_Laser_Damage(entity this, entity directhitentity)
{
	int laser_count = max(1, this.rm_laser_count);
	float laser_force = autocvar_g_rm_laser_force / laser_count;
	float laser_damage = autocvar_g_rm_laser_damage / laser_count;
	RadiusDamage(this, this.realowner, laser_damage, laser_damage, autocvar_g_rm_laser_radius, NULL, NULL, laser_force, this.projectiledeathtype, this.weaponentity_fld, directhitentity);
}

void W_RocketMinsta_Laser_Explode(entity this, entity directhitentity)
{
	if(directhitentity.takedamage == DAMAGE_AIM)
		if(IS_PLAYER(directhitentity))
			if(DIFF_TEAM(this.realowner, directhitentity))
				if(!IS_DEAD(directhitentity))
					if(IsFlying(directhitentity))
						Send_Notification(NOTIF_ONE, this.realowner, MSG_ANNCE, ANNCE_ACHIEVEMENT_ELECTROBITCH);

	this.event_damage = func_null;
	this.takedamage = DAMAGE_NO;
	W_RocketMinsta_Laser_Damage(this, directhitentity);
	delete(this);
}

void W_RocketMinsta_Laser_Explode_use(entity this, entity actor, entity trigger)
{
	W_RocketMinsta_Laser_Explode(this, trigger); // we probably don't want trigger used here, but this matches closest to old behaviour
}

void W_RocketMinsta_Laser_Touch(entity this, entity toucher)
{
	PROJECTILE_TOUCH(this, toucher);
	//W_RocketMinsta_Laser_Explode ();
	W_RocketMinsta_Laser_Damage(this, toucher);
	delete(this);
}

// mode 0 fires many projectiles
// mode 1 fires 1 projectile
void W_RocketMinsta_Attack(entity actor, .entity weaponentity, int mode)
{
	makevectors(actor.v_angle);

	entity proj;
	int laser_count = max(1, autocvar_g_rm_laser_count);
	int total = (mode == 0) ? laser_count : 1;
	Sound snd = (mode == 0) ? SND_CRYLINK_FIRE : SND_ELECTRO_FIRE2; // WEAPONTODO multiple references to other weapons here!
	W_SetupShot_ProjectileSize(actor, weaponentity, '0 0 -3', '0 0 -3', false, 2, snd, CH_WEAPON_A, autocvar_g_rm_laser_damage, WEP_ELECTRO.m_id);

	// uses electro effects
	W_MuzzleFlash(WEP_ELECTRO, actor, weaponentity, w_shotorg, w_shotdir);

	for (int counter = 0; counter < total; ++counter)
	{
		proj = new(plasma_prim);
		proj.owner = proj.realowner = actor;
		proj.bot_dodge = true;
		proj.bot_dodgerating = autocvar_g_rm_laser_damage;
		proj.use = W_RocketMinsta_Laser_Explode_use;
		setthink(proj, adaptor_think2use_hittype_splash);
		proj.nextthink = time + autocvar_g_rm_laser_lifetime;
		PROJECTILE_MAKETRIGGER(proj);
		proj.projectiledeathtype = WEP_ELECTRO.m_id;
		proj.weaponentity_fld = weaponentity;
		setorigin(proj, w_shotorg);

		proj.rm_laser_count = total;

		//W_SetupProjectileVelocity(proj, autocvar_g_rm_laser_speed, spread * (rndspread ? random() : 1) * autocvar_g_rm_laser_speed);

		set_movetype(proj, MOVETYPE_BOUNCEMISSILE);
		if (mode == 0)
		{
			float spread = autocvar_g_rm_laser_spread * (autocvar_g_rm_laser_spread_random ? random() : 1);
			//W_SETUPPROJECTILEVELOCITY(proj, g_balance_minstanex_laser);
			proj.velocity = (w_shotdir + (((counter + 0.5) / total) * 2 - 1) * v_right * spread) * cvar("g_rm_laser_speed");
			proj.velocity.z += cvar("g_rm_laser_zspread") * (random() - 0.5);
		}
		else
			proj.velocity = w_shotdir * autocvar_g_rm_laser_speed;
		proj.velocity = W_CalculateProjectileVelocity(actor, actor.velocity, proj.velocity, true);
		proj.angles = vectoangles(proj.velocity);
		settouch(proj, W_RocketMinsta_Laser_Touch);
		setsize(proj, '0 0 -3', '0 0 -3');
		proj.flags = FL_PROJECTILE;
		IL_PUSH(g_projectiles, proj);
		IL_PUSH(g_bot_dodge, proj);
		proj.missile_flags = MIF_SPLASH;

		CSQCProjectile(proj, true, PROJECTILE_ROCKETMINSTA_LASER, true);

		MUTATOR_CALLHOOK(EditProjectile, actor, proj);
	}
}

METHOD(Vaporizer, wr_aim, void(entity thiswep, entity actor, .entity weaponentity))
{
	if((actor.items & IT_UNLIMITED_AMMO) || GetResource(actor, thiswep.ammo_type) > 0)
		PHYS_INPUT_BUTTON_ATCK(actor) = bot_aim(actor, weaponentity, 1000000, 0, 1, false, true);
	else
		PHYS_INPUT_BUTTON_ATCK2(actor) = bot_aim(actor, weaponentity, WEP_CVAR_PRI(WEP_BLASTER, speed), 0, WEP_CVAR_PRI(WEP_BLASTER, lifetime), false, true);
}

METHOD(Vaporizer, wr_think, void(entity thiswep, entity actor, .entity weaponentity, int fire))
{
	float vaporizer_ammo = ((autocvar_g_instagib) ? 1 : WEP_CVAR_PRI(WEP_VAPORIZER, ammo));
	// if the laser uses load, we also consider its ammo for reloading
	if (WEP_CVAR(WEP_VAPORIZER, reload_ammo)
	&& WEP_CVAR_PRI(WEP_BLASTER, ammo)
	&& actor.(weaponentity).clip_load < min(vaporizer_ammo, WEP_CVAR_PRI(WEP_BLASTER, ammo)))
	{ // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
		actor.(weaponentity).hagar_load = false; // rocket minsta exclusive var
		return;
	}
	if(WEP_CVAR(WEP_VAPORIZER, reload_ammo)
	&& actor.(weaponentity).clip_load < vaporizer_ammo)
	{ // forced reload
		thiswep.wr_reload(thiswep, actor, weaponentity);
		actor.(weaponentity).hagar_load = false; // rocket minsta exclusive var
		return;
	}

	if((fire & 1) && (GetResource(actor, RES_CELLS) || !autocvar_g_rm) && !weaponLocked(actor))
	{
		if(weapon_prepareattack(thiswep, actor, weaponentity, false, WEP_CVAR_PRI(WEP_VAPORIZER, refire)))
		{
			W_Vaporizer_Attack(thiswep, actor, weaponentity);
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, WEP_CVAR_PRI(WEP_VAPORIZER, animtime), w_ready);
		}
	}

	if((fire & 2) || ((fire & 1) && !GetResource(actor, RES_CELLS) && autocvar_g_rm))
	{
		if((autocvar_g_rm && autocvar_g_rm_laser) || autocvar_g_rm_laser == 2)
		{
			bool rapid = autocvar_g_rm_laser_rapid;
			//hagar_load was previously named held_down
			if(actor.(weaponentity).jump_interval <= time && !actor.(weaponentity).hagar_load)
			{
				if(rapid)
					actor.(weaponentity).hagar_load = true;
				actor.(weaponentity).jump_interval = time + autocvar_g_rm_laser_refire;
				actor.(weaponentity).jump_interval2 = time + autocvar_g_rm_laser_rapid_delay;
				impressive_hits = 0;
				W_RocketMinsta_Attack(actor, weaponentity, 0);
			}
			else if(rapid && actor.(weaponentity).jump_interval2 <= time && actor.(weaponentity).hagar_load)
			{
				actor.(weaponentity).jump_interval2 = time + autocvar_g_rm_laser_rapid_refire;
				impressive_hits = 0;
				W_RocketMinsta_Attack(actor, weaponentity, 1);
				//weapon_thinkf(actor, WFRAME_FIRE2, autocvar_g_rm_laser_rapid_animtime, w_ready);
			}
		}
		else if (actor.(weaponentity).jump_interval <= time)
		{
			// handle refire manually, so that primary and secondary can be fired without conflictions (important for instagib)
			actor.(weaponentity).jump_interval = time + WEP_CVAR_PRI(WEP_BLASTER, refire) * W_WeaponRateFactor(actor);

			// decrease ammo for the laser?
			if(WEP_CVAR_PRI(WEP_BLASTER, ammo))
				W_DecreaseAmmo(thiswep, actor, WEP_CVAR_PRI(WEP_BLASTER, ammo), weaponentity);

			makevectors(actor.v_angle);
			W_Blaster_Attack(actor, weaponentity);

			// now do normal refire
			weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, WEP_CVAR_PRI(WEP_BLASTER, animtime), w_ready);
		}
	}
	else
		actor.(weaponentity).hagar_load = false;
}

METHOD(Vaporizer, wr_setup, void(entity thiswep, entity actor, .entity weaponentity))
{
	actor.vaporizer_lasthit = 0;
}

METHOD(Vaporizer, wr_checkammo1, bool(entity thiswep, entity actor, .entity weaponentity))
{
	float vaporizer_ammo = ((autocvar_g_instagib) ? 1 : WEP_CVAR_PRI(WEP_VAPORIZER, ammo));
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= vaporizer_ammo;
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= vaporizer_ammo;
	return ammo_amount;
}

METHOD(Vaporizer, wr_checkammo2, bool(entity thiswep, entity actor, .entity weaponentity))
{
	if(!WEP_CVAR_PRI(WEP_BLASTER, ammo))
		return true;
	float ammo_amount = GetResource(actor, thiswep.ammo_type) >= WEP_CVAR_PRI(WEP_BLASTER, ammo);
	ammo_amount += actor.(weaponentity).(weapon_load[thiswep.m_id]) >= WEP_CVAR_PRI(WEP_BLASTER, ammo);
	return ammo_amount;
}

METHOD(Vaporizer, wr_resetplayer, void(entity thiswep, entity actor))
{
	actor.vaporizer_lasthit = 0;
}

METHOD(Vaporizer, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
	float vaporizer_ammo = ((autocvar_g_instagib) ? 1 : WEP_CVAR_PRI(WEP_VAPORIZER, ammo));
	float used_ammo;
	if(WEP_CVAR_PRI(WEP_BLASTER, ammo))
		used_ammo = min(vaporizer_ammo, WEP_CVAR_PRI(WEP_BLASTER, ammo));
	else
		used_ammo = vaporizer_ammo;

	W_Reload(actor, weaponentity, used_ammo, SND_RELOAD);
}

METHOD(Vaporizer, wr_suicidemessage, Notification(entity thiswep))
{
	return WEAPON_THINKING_WITH_PORTALS;
}

METHOD(Vaporizer, wr_killmessage, Notification(entity thiswep))
{
	return WEAPON_VAPORIZER_MURDER;
}

#endif
#ifdef CSQC

METHOD(Vaporizer, wr_impacteffect, void(entity thiswep, entity actor))
{
	vector org2 = w_org + w_backoff * 2;
	pointparticles(EFFECT_VORTEX_IMPACT, org2, '0 0 0', 1);
	if(!w_issilent)
		sound(actor, CH_SHOTS, SND_VAPORIZER_IMPACT, VOL_BASE, ATTN_NORM);
}

METHOD(Vaporizer, wr_init, void(entity thiswep))
{
	if(autocvar_cl_reticle && autocvar_cl_reticle_weapon)
	{
		precache_pic("gfx/reticle_nex");
	}
}

METHOD(Vaporizer, wr_zoom, bool(entity thiswep, entity actor))
{
	if(button_zoom || zoomscript_caught)
	{
		return true;
	}
	else
	{
		// no weapon specific image for this weapon
		return false;
	}
}

#endif
#ifdef MENUQC
#include <common/mutators/mutator/instagib/instagib.qh>
#include <common/mutators/mutator/instagib/items.qh>
#include <common/items/item/ammo.qh>
#include "blaster.qh"

METHOD(Vaporizer, describe, string(Vaporizer this))
{
	TC(Vaporizer, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s is a unique weapon, firing a deadly beam of energy dealing a huge amount of damage. "
	      "In %s, the beam has the ability to instantly kill enemies with a single shot, unless they have an %s."), COLORED_NAME(this), COLORED_NAME(MUTATOR_mutator_instagib), COLORED_NAME(ITEM_ExtraLife));
	PAR(_("The secondary fire shoots a laser identical to that fired by the %s, with strong knockback."), COLORED_NAME(WEP_BLASTER));
	PAR(_("It is a superweapon, so isn't often found in game, except in %s where all players spawn with it."), COLORED_NAME(MUTATOR_mutator_instagib));
	PAR(_("It consumes some %s ammo with each shot."), COLORED_NAME(ITEM_Cells));
	PAR(W_Guide_Keybinds(this));
	PAR(W_Guide_DPS_onlyOne(this.netname, "primary"));
	return PAGE_TEXT;
}

#endif
