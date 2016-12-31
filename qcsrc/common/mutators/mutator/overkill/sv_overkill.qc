#include "sv_overkill.qh"

#include "hmg.qh"
#include "rpc.qh"

bool autocvar_g_overkill_powerups_replace;
bool autocvar_g_overkill_ammo_charge;
float autocvar_g_overkill_ammo_charge_notice;
float autocvar_g_overkill_ammo_charge_limit;

bool autocvar_g_overkill_filter_healthmega;
bool autocvar_g_overkill_filter_armormedium;
bool autocvar_g_overkill_filter_armorbig;
bool autocvar_g_overkill_filter_armormega;

.float ok_lastwep;
.float ok_item;

.float ok_notice_time;
.float ammo_charge[Weapons_MAX];
.float ok_use_ammocharge = _STAT(OK_AMMO_CHARGE);
.float ok_ammo_charge = _STAT(OK_AMMO_CHARGEPOOL);

void(entity ent, float wep) ok_DecreaseCharge;

void ok_Initialize();

REGISTER_MUTATOR(ok, cvar("g_overkill") && !cvar("g_instagib") && !g_nexball && cvar_string("g_mod_balance") == "Overkill")
{
	MUTATOR_ONADD
	{
		ok_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		WEP_RPC.spawnflags |= WEP_FLAG_MUTATORBLOCKED;
		WEP_HMG.spawnflags |= WEP_FLAG_MUTATORBLOCKED;
	}
}

MUTATOR_HOOKFUNCTION(ok, W_DecreaseAmmo)
{
	entity actor = M_ARGV(0, entity);
	if (actor.ok_use_ammocharge)
	{
		ok_DecreaseCharge(actor, PS(actor).m_weapon.m_id);
		return true;
	}
}

MUTATOR_HOOKFUNCTION(ok, W_Reload)
{
	entity actor = M_ARGV(0, entity);
	return actor.ok_use_ammocharge;
}

void W_Blaster_Attack(entity, .entity, float, float, float, float, float, float, float, float, float, float);
spawnfunc(weapon_hmg);
spawnfunc(weapon_rpc);

void ok_DecreaseCharge(entity ent, int wep)
{
	if(!ent.ok_use_ammocharge) return;

	entity wepent = Weapons_from(wep);

	if (wepent == WEP_Null) return;  // dummy

	ent.ammo_charge[wep] -= max(0, cvar(sprintf("g_overkill_ammo_decharge_%s", wepent.netname)));
}

void ok_IncreaseCharge(entity ent, int wep)
{
	entity wepent = Weapons_from(wep);

	if (wepent == WEP_Null) return;  // dummy

	if(ent.ok_use_ammocharge)
	if(!PHYS_INPUT_BUTTON_ATCK(ent)) // not while attacking?
		ent.ammo_charge[wep] = min(autocvar_g_overkill_ammo_charge_limit, ent.ammo_charge[wep] + cvar(sprintf("g_overkill_ammo_charge_rate_%s", wepent.netname)) * frametime / W_TICSPERFRAME);
}

float ok_CheckWeaponCharge(entity ent, int wep)
{
	if(!ent.ok_use_ammocharge) return true;

	entity wepent = Weapons_from(wep);

	if(wepent == WEP_Null) return false;  // dummy

	return (ent.ammo_charge[wep] >= cvar(sprintf("g_overkill_ammo_decharge_%s", wepent.netname)));
}

MUTATOR_HOOKFUNCTION(ok, Damage_Calculate, CBC_ORDER_LAST)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);

	if(IS_PLAYER(frag_attacker) && (IS_PLAYER(frag_target) || IS_VEHICLE(frag_target) || IS_TURRET(frag_target)))
	if(DEATH_ISWEAPON(frag_deathtype, WEP_BLASTER))
	{
		if(frag_attacker != frag_target)
		if(!STAT(FROZEN, frag_target))
		if(!IS_DEAD(frag_target))
		{
			Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_SECONDARY_NODAMAGE);
			M_ARGV(6, vector) = '0 0 0'; // force
		}

		M_ARGV(4, float) = 0; // damage
	}
}

void ok_DropItem(entity this, entity targ)
{
	entity e = new(droppedweapon); // hax
	e.ok_item = true;
	e.noalign = true;
	e.pickup_anyway = true;
	e.spawnfunc_checked = true;
	spawnfunc_item_armor_small(e);
	if (!wasfreed(e)) { // might have been blocked by a mutator
        set_movetype(e, MOVETYPE_TOSS);
        e.gravity = 1;
        e.reset = SUB_Remove;
        setorigin(e, this.origin + '0 0 32');
        e.velocity = '0 0 200' + normalize(targ.origin - this.origin) * 500;
        SUB_SetFade(e, time + 5, 1);
	}
}

MUTATOR_HOOKFUNCTION(ok, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	entity targ = ((frag_attacker) ? frag_attacker : frag_target);

	ok_DropItem(frag_target, targ);

	frag_target.ok_lastwep = PS(frag_target).m_switchweapon.m_id;
}

MUTATOR_HOOKFUNCTION(ok, MonsterDropItem)
{
	entity mon = M_ARGV(0, entity);
	entity olditem = M_ARGV(1, entity);
	entity frag_attacker = M_ARGV(2, entity);

	delete(olditem);

	M_ARGV(1, entity) = NULL;

	ok_DropItem(mon, frag_attacker);
}

MUTATOR_HOOKFUNCTION(ok, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(ok, PlayerPreThink)
{
	if(gameover)
		return;

	entity player = M_ARGV(0, entity);

	if(IS_DEAD(player) || !IS_PLAYER(player) || STAT(FROZEN, player))
		return;

	if(player.ok_lastwep)
	{
		Weapon newwep = Weapons_from(player.ok_lastwep);
		if(player.ok_lastwep == WEP_HMG.m_id)
			newwep = WEP_MACHINEGUN;
		if(player.ok_lastwep == WEP_RPC.m_id)
			newwep = WEP_VORTEX;
		PS(player).m_switchweapon = newwep;
		player.ok_lastwep = 0;
	}

	ok_IncreaseCharge(player, PS(player).m_weapon.m_id);

	if(PHYS_INPUT_BUTTON_ATCK2(player))
	if( !forbidWeaponUse(player) || player.weapon_blocked // allow if weapon is blocked
		|| (round_handler_IsActive() && !round_handler_IsRoundStarted()) )
	if(time >= player.jump_interval)
	{
		player.jump_interval = time + WEP_CVAR_PRI(blaster, refire) * W_WeaponRateFactor(player);
		makevectors(player.v_angle);

		Weapon oldwep = PS(player).m_weapon;
		PS(player).m_weapon = WEP_BLASTER;
		W_Blaster_Attack(
			player,
			weaponentities[0], // TODO: unhardcode
			WEP_BLASTER.m_id | HITTYPE_SECONDARY,
			WEP_CVAR_SEC(vaporizer, shotangle),
			WEP_CVAR_SEC(vaporizer, damage),
			WEP_CVAR_SEC(vaporizer, edgedamage),
			WEP_CVAR_SEC(vaporizer, radius),
			WEP_CVAR_SEC(vaporizer, force),
			WEP_CVAR_SEC(vaporizer, speed),
			WEP_CVAR_SEC(vaporizer, spread),
			WEP_CVAR_SEC(vaporizer, delay),
			WEP_CVAR_SEC(vaporizer, lifetime)
		);
		PS(player).m_weapon = oldwep;
	}

	player.weapon_blocked = false;

	player.ok_ammo_charge = player.ammo_charge[PS(player).m_weapon.m_id];

	if(player.ok_use_ammocharge)
	if(!ok_CheckWeaponCharge(player, PS(player).m_weapon.m_id))
	{
		if(autocvar_g_overkill_ammo_charge_notice && time > player.ok_notice_time && PHYS_INPUT_BUTTON_ATCK(player) && IS_REAL_CLIENT(player) && PS(player).m_weapon == PS(player).m_switchweapon)
		{
			//Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_OVERKILL_CHARGE);
			player.ok_notice_time = time + 2;
			play2(player, SND(DRYFIRE));
		}
		Weapon wpn = PS(player).m_weapon;
		.entity weaponentity = weaponentities[0]; // TODO: unhardcode
		if(player.(weaponentity).state != WS_CLEAR)
			w_ready(wpn, player, weaponentity, PHYS_INPUT_BUTTON_ATCK(player) | (PHYS_INPUT_BUTTON_ATCK2(player) << 1));

		player.weapon_blocked = true;
	}

	PHYS_INPUT_BUTTON_ATCK2(player) = false;
}

MUTATOR_HOOKFUNCTION(ok, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if(autocvar_g_overkill_ammo_charge)
	{
		FOREACH(Weapons, it != WEP_Null, LAMBDA(player.ammo_charge[it.m_id] = autocvar_g_overkill_ammo_charge_limit));

		player.ok_use_ammocharge = 1;
		player.ok_notice_time = time;
	}
	else
		player.ok_use_ammocharge = 0;

	// if player changed their weapon while dead, don't switch to their death weapon
	if(player.impulse)
		player.ok_lastwep = 0;
}

void self_spawnfunc_weapon_hmg(entity this) { spawnfunc_weapon_hmg(this); }
void self_spawnfunc_weapon_rpc(entity this) { spawnfunc_weapon_rpc(this); }

MUTATOR_HOOKFUNCTION(ok, OnEntityPreSpawn)
{
	entity ent = M_ARGV(0, entity);

	if(autocvar_g_powerups)
	if(autocvar_g_overkill_powerups_replace)
	{
		if(ent.classname == "item_strength")
		{
			entity wep = new(weapon_hmg);
			setorigin(wep, ent.origin);
			setmodel(wep, MDL_OK_HMG);
			wep.ok_item = true;
			wep.noalign = ent.noalign;
			wep.cnt = ent.cnt;
			wep.team = ent.team;
			wep.respawntime = g_pickup_respawntime_superweapon;
			wep.pickup_anyway = true;
			wep.spawnfunc_checked = true;
			setthink(wep, self_spawnfunc_weapon_hmg);
			wep.nextthink = time + 0.1;
			return true;
		}
		else if(ent.classname == "item_invincible")
		{
			entity wep = new(weapon_rpc);
			setorigin(wep, ent.origin);
			setmodel(wep, MDL_OK_RPC);
			wep.ok_item = true;
			wep.noalign = ent.noalign;
			wep.cnt = ent.cnt;
			wep.team = ent.team;
			wep.respawntime = g_pickup_respawntime_superweapon;
			wep.pickup_anyway = true;
			wep.spawnfunc_checked = true;
			setthink(wep, self_spawnfunc_weapon_rpc);
			wep.nextthink = time + 0.1;
			return true;
		}
	}
}

MUTATOR_HOOKFUNCTION(ok, FilterItem)
{
	entity item = M_ARGV(0, entity);

	if(item.ok_item)
		return false;

	switch(item.itemdef)
	{
		case ITEM_HealthMega: return autocvar_g_overkill_filter_healthmega;
		case ITEM_ArmorMedium: return autocvar_g_overkill_filter_armormedium;
		case ITEM_ArmorBig: return autocvar_g_overkill_filter_armorbig;
		case ITEM_ArmorMega: return autocvar_g_overkill_filter_armormega;
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ok, SpectateCopy)
{
	entity spectatee = M_ARGV(0, entity);
	entity client = M_ARGV(1, entity);

	client.ammo_charge[PS(client).m_weapon.m_id] = spectatee.ammo_charge[PS(spectatee).m_weapon.m_id];
	client.ok_use_ammocharge = spectatee.ok_use_ammocharge;
}

MUTATOR_HOOKFUNCTION(ok, SetStartItems, CBC_ORDER_LAST)
{
	WepSet ok_start_items = (WEPSET(MACHINEGUN) | WEPSET(VORTEX) | WEPSET(SHOTGUN));

	if(WEP_RPC.weaponstart > 0) { ok_start_items |= WEPSET(RPC); }
	if(WEP_HMG.weaponstart > 0) { ok_start_items |= WEPSET(HMG); }

	start_items |= IT_UNLIMITED_WEAPON_AMMO;
	start_weapons = warmup_start_weapons = ok_start_items;
}

MUTATOR_HOOKFUNCTION(ok, SetWeaponArena)
{
	// turn weapon arena off
	M_ARGV(0, string) = "off";
}

MUTATOR_HOOKFUNCTION(ok, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":OK");
}

MUTATOR_HOOKFUNCTION(ok, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Overkill");
}

MUTATOR_HOOKFUNCTION(ok, SetModname)
{
	M_ARGV(0, string) = "Overkill";
	return true;
}

void ok_SetCvars()
{
	// hack to force overkill playermodels
	cvar_settemp("sv_defaultcharacter", "1");
	cvar_settemp("sv_defaultplayermodel", "models/ok_player/okrobot1.dpm models/ok_player/okrobot2.dpm models/ok_player/okrobot3.dpm models/ok_player/okrobot4.dpm models/ok_player/okmale1.dpm models/ok_player/okmale2.dpm models/ok_player/okmale3.dpm models/ok_player/okmale4.dpm");
	cvar_settemp("sv_defaultplayermodel_red", "models/ok_player/okrobot1.dpm models/ok_player/okrobot2.dpm models/ok_player/okrobot3.dpm models/ok_player/okrobot4.dpm");
	cvar_settemp("sv_defaultplayermodel_blue", "models/ok_player/okmale1.dpm models/ok_player/okmale2.dpm models/ok_player/okmale3.dpm models/ok_player/okmale4.dpm");
}

void ok_Initialize()
{
	ok_SetCvars();

	precache_all_playermodels("models/ok_player/*.dpm");

	WEP_RPC.spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;
	WEP_HMG.spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;

	WEP_SHOTGUN.mdl = "ok_shotgun";
	WEP_MACHINEGUN.mdl = "ok_mg";
	WEP_VORTEX.mdl = "ok_sniper";
}
