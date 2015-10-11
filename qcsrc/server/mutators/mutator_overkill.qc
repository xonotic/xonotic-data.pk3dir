#include "mutator_overkill.qh"

#include "mutator.qh"

void W_Blaster_Attack(entity, float, float, float, float, float, float, float, float, float, float);
spawnfunc(weapon_hmg);
spawnfunc(weapon_rpc);

void ok_DecreaseCharge(entity ent, int wep)
{
	if(!ent.ok_use_ammocharge) return;

	entity wepent = get_weaponinfo(wep);

	if(wepent.weapon == 0)
		return; // dummy

	ent.ammo_charge[wep] -= max(0, cvar(sprintf("g_overkill_ammo_decharge_%s", wepent.netname)));
}

void ok_IncreaseCharge(entity ent, int wep)
{
	entity wepent = get_weaponinfo(wep);

	if(wepent.weapon == 0)
		return; // dummy

	if(ent.ok_use_ammocharge)
	if(!ent.BUTTON_ATCK) // not while attacking?
		ent.ammo_charge[wep] = min(autocvar_g_overkill_ammo_charge_limit, ent.ammo_charge[wep] + cvar(sprintf("g_overkill_ammo_charge_rate_%s", wepent.netname)) * frametime / W_TICSPERFRAME);
}

float ok_CheckWeaponCharge(entity ent, int wep)
{
	if(!ent.ok_use_ammocharge) return true;

	entity wepent = get_weaponinfo(wep);

	if(wepent.weapon == 0)
		return 0; // dummy

	return (ent.ammo_charge[wep] >= cvar(sprintf("g_overkill_ammo_decharge_%s", wepent.netname)));
}

MUTATOR_HOOKFUNCTION(ok_PlayerDamage_Calculate)
{
	if(IS_PLAYER(frag_attacker) && IS_PLAYER(frag_target))
	if(DEATH_ISWEAPON(frag_deathtype, WEP_BLASTER))
	{
		frag_damage = 0;

		if(frag_attacker != frag_target)
		if(frag_target.health > 0)
		if(frag_target.frozen == 0)
		if(frag_target.deadflag == DEAD_NO)
		{
			Send_Notification(NOTIF_ONE, frag_attacker, MSG_CENTER, CENTER_SECONDARY_NODAMAGE);
			frag_force = '0 0 0';
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ok_PlayerDamage_SplitHealthArmor)
{SELFPARAM();
	if(damage_take)
		self.ok_pauseregen_finished = max(self.ok_pauseregen_finished, time + 2);
	return false;
}

MUTATOR_HOOKFUNCTION(ok_PlayerDies)
{SELFPARAM();
	entity targ = ((frag_attacker) ? frag_attacker : frag_target);

	if(IS_MONSTER(self))
	{
		remove(other); // remove default item
		other = world;
	}

	setself(spawn());
	self.ok_item = true;
	self.noalign = true;
	self.pickup_anyway = true;
	spawnfunc_item_armor_small(this);
	self.movetype = MOVETYPE_TOSS;
	self.gravity = 1;
	self.reset = SUB_Remove;
	setorigin(self, frag_target.origin + '0 0 32');
	self.velocity = '0 0 200' + normalize(targ.origin - self.origin) * 500;
	self.classname = "droppedweapon"; // hax
	SUB_SetFade(self, time + 5, 1);
	setself(this);

	self.ok_lastwep = self.switchweapon;

	return false;
}

MUTATOR_HOOKFUNCTION(ok_PlayerRegen)
{SELFPARAM();
	// overkill's values are different, so use custom regen
	if(!self.frozen)
	{
		self.armorvalue = CalcRotRegen(self.armorvalue, autocvar_g_balance_armor_regenstable, autocvar_g_balance_armor_regen, autocvar_g_balance_armor_regenlinear, 1 * frametime * (time > self.ok_pauseregen_finished), 0, 0, 1, 1 * frametime * (time > self.pauserotarmor_finished), autocvar_g_balance_armor_limit);
		self.health = CalcRotRegen(self.health, autocvar_g_balance_health_regenstable, 0, 100, 1 * frametime * (time > self.ok_pauseregen_finished), 200, 0, autocvar_g_balance_health_rotlinear, 1 * frametime * (time > self.pauserothealth_finished), autocvar_g_balance_health_limit);

		float minf, maxf, limitf;

		maxf = autocvar_g_balance_fuel_rotstable;
		minf = autocvar_g_balance_fuel_regenstable;
		limitf = autocvar_g_balance_fuel_limit;

		self.ammo_fuel = CalcRotRegen(self.ammo_fuel, minf, autocvar_g_balance_fuel_regen, autocvar_g_balance_fuel_regenlinear, frametime * (time > self.pauseregen_finished) * ((self.items & ITEM_JetpackRegen.m_itemid) != 0), maxf, autocvar_g_balance_fuel_rot, autocvar_g_balance_fuel_rotlinear, frametime * (time > self.pauserotfuel_finished), limitf);
	}
	return true; // return true anyway, as frozen uses no regen
}

MUTATOR_HOOKFUNCTION(ok_ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(ok_PlayerPreThink)
{SELFPARAM();
	if(intermission_running || gameover)
		return false;

	if(self.deadflag != DEAD_NO || !IS_PLAYER(self) || self.frozen)
		return false;

	if(self.ok_lastwep)
	{
		self.switchweapon = self.ok_lastwep;
		self.ok_lastwep = 0;
	}

	ok_IncreaseCharge(self, self.weapon);

	if(self.BUTTON_ATCK2)
	if(!forbidWeaponUse(self) || self.weapon_blocked) // allow if weapon is blocked
	if(time >= self.jump_interval)
	{
		self.jump_interval = time + WEP_CVAR_PRI(blaster, refire) * W_WeaponRateFactor();
		makevectors(self.v_angle);

		int oldwep = self.weapon;
		self.weapon = WEP_BLASTER.m_id;
		W_Blaster_Attack(
			self,
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
		self.weapon = oldwep;
	}

	self.weapon_blocked = false;

	self.ok_ammo_charge = self.ammo_charge[self.weapon];

	if(self.ok_use_ammocharge)
	if(!ok_CheckWeaponCharge(self, self.weapon))
	{
		if(autocvar_g_overkill_ammo_charge_notice && time > self.ok_notice_time && self.BUTTON_ATCK && IS_REAL_CLIENT(self) && self.weapon == self.switchweapon)
		{
			//Send_Notification(NOTIF_ONE, self, MSG_CENTER, CENTER_OVERKILL_CHARGE);
			self.ok_notice_time = time + 2;
			play2(self, SND(DRYFIRE));
		}
		Weapon wpn = get_weaponinfo(self.weapon);
		if(self.weaponentity.state != WS_CLEAR)
			w_ready(wpn, self, self.BUTTON_ATCK, self.BUTTON_ATCK2);

		self.weapon_blocked = true;
	}

	self.BUTTON_ATCK2 = 0;

	return false;
}

MUTATOR_HOOKFUNCTION(ok_PlayerSpawn)
{SELFPARAM();
	if(autocvar_g_overkill_ammo_charge)
	{
		for(int i = WEP_FIRST; i <= WEP_LAST; ++i)
			self.ammo_charge[i] = autocvar_g_overkill_ammo_charge_limit;

		self.ok_use_ammocharge = 1;
		self.ok_notice_time = time;
	}
	else
		self.ok_use_ammocharge = 0;

	self.ok_pauseregen_finished = time + 2;

	return false;
}

void _spawnfunc_weapon_hmg() { SELFPARAM(); spawnfunc_weapon_hmg(this); }
void _spawnfunc_weapon_rpc() { SELFPARAM(); spawnfunc_weapon_rpc(this); }

MUTATOR_HOOKFUNCTION(ok_OnEntityPreSpawn)
{SELFPARAM();
	if(autocvar_g_powerups)
	if(autocvar_g_overkill_powerups_replace)
	{
		if(self.classname == "item_strength")
		{
			entity wep = spawn();
			setorigin(wep, self.origin);
			setmodel(wep, MDL_OK_HMG);
			wep.classname = "weapon_hmg";
			wep.ok_item = true;
			wep.noalign = self.noalign;
			wep.cnt = self.cnt;
			wep.team = self.team;
			wep.respawntime = autocvar_g_overkill_superguns_respawn_time;
			wep.pickup_anyway = true;
			wep.think = _spawnfunc_weapon_hmg;
			wep.nextthink = time + 0.1;
			return true;
		}

		if(self.classname == "item_invincible")
		{
			entity wep = spawn();
			setorigin(wep, self.origin);
			setmodel(wep, MDL_OK_RPC);
			wep.classname = "weapon_rpc";
			wep.ok_item = true;
			wep.noalign = self.noalign;
			wep.cnt = self.cnt;
			wep.team = self.team;
			wep.respawntime = autocvar_g_overkill_superguns_respawn_time;
			wep.pickup_anyway = true;
			wep.think = _spawnfunc_weapon_rpc;
			wep.nextthink = time + 0.1;
			return true;
		}
	}

	return false;
}

MUTATOR_HOOKFUNCTION(ok_ItemRemove)
{SELFPARAM();
	if(self.ok_item)
		return false;

	switch(self.items)
	{
		case ITEM_HealthMega.m_itemid: return !(autocvar_g_overkill_100h_anyway);
		case ITEM_ArmorMega.m_itemid: return !(autocvar_g_overkill_100a_anyway);
	}

	return true;
}

MUTATOR_HOOKFUNCTION(ok_SpectateCopy)
{SELFPARAM();
	self.ammo_charge[self.weapon] = other.ammo_charge[other.weapon];
	self.ok_use_ammocharge = other.ok_use_ammocharge;

	return false;
}

MUTATOR_HOOKFUNCTION(ok_StartItems)
{
	WepSet ok_start_items = (WEPSET(MACHINEGUN) | WEPSET(VORTEX) | WEPSET(SHOTGUN));

	if(WEP_RPC.weaponstart > 0) { ok_start_items |= WEPSET(RPC); }
	if(WEP_HMG.weaponstart > 0) { ok_start_items |= WEPSET(HMG); }

	start_items |= IT_UNLIMITED_WEAPON_AMMO;
	start_weapons = warmup_start_weapons = ok_start_items;

	return false;
}

MUTATOR_HOOKFUNCTION(ok_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":OK");
	return false;
}

MUTATOR_HOOKFUNCTION(ok_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", Overkill");
	return false;
}

MUTATOR_HOOKFUNCTION(ok_SetModname)
{
	modname = "Overkill";
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

	addstat(STAT_OK_AMMO_CHARGE, AS_FLOAT, ok_use_ammocharge);
	addstat(STAT_OK_AMMO_CHARGEPOOL, AS_FLOAT, ok_ammo_charge);

	WEP_RPC.spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;
	WEP_HMG.spawnflags &= ~WEP_FLAG_MUTATORBLOCKED;

	WEP_SHOTGUN.mdl = "ok_shotgun";
	WEP_MACHINEGUN.mdl = "ok_mg";
	WEP_VORTEX.mdl = "ok_sniper";
}

MUTATOR_DEFINITION(mutator_overkill)
{
	MUTATOR_HOOK(ForbidThrowCurrentWeapon, ok_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, ok_PlayerPreThink, CBC_ORDER_LAST);
	MUTATOR_HOOK(PlayerSpawn, ok_PlayerSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDamage_Calculate, ok_PlayerDamage_Calculate, CBC_ORDER_LAST);
	MUTATOR_HOOK(PlayerDamage_SplitHealthArmor, ok_PlayerDamage_SplitHealthArmor, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerDies, ok_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerRegen, ok_PlayerRegen, CBC_ORDER_ANY);
	MUTATOR_HOOK(OnEntityPreSpawn, ok_OnEntityPreSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, ok_ItemRemove, CBC_ORDER_ANY);
	MUTATOR_HOOK(MonsterDropItem, ok_PlayerDies, CBC_ORDER_ANY);
	MUTATOR_HOOK(SpectateCopy, ok_SpectateCopy, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, ok_StartItems, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsString, ok_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, ok_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetModname, ok_SetModname, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		ok_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		WEP_RPC.spawnflags |= WEP_FLAG_MUTATORBLOCKED;
		WEP_HMG.spawnflags |= WEP_FLAG_MUTATORBLOCKED;
	}

	return false;
}
