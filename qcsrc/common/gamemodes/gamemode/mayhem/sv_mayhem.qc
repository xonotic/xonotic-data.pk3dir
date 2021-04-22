#include "sv_mayhem.qh"

bool autocvar_g_mayhem_regenerate;
string autocvar_g_mayhem_weaponarena;
bool autocvar_g_mayhem_powerups;
bool autocvar_g_mayhem_selfdamage;
bool autocvar_g_mayhem_frags2score;
bool autocvar_g_mayhem_damage2score;
float autocvar_g_mayhem_damage2score_multiplier;

MUTATOR_HOOKFUNCTION(mayhem, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	start_health       = warmup_start_health       = cvar("g_mayhem_start_health");
	start_armorvalue   = warmup_start_armorvalue   = cvar("g_mayhem_start_armor");
	start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_mayhem_start_ammo_shells");
	start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_mayhem_start_ammo_nails");
	start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_mayhem_start_ammo_rockets");
	start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_mayhem_start_ammo_cells");
	start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_mayhem_start_ammo_plasma");
	start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_mayhem_start_ammo_fuel");
}

MUTATOR_HOOKFUNCTION(mayhem, PlayerRegen)
{
	if(autocvar_g_mayhem_regenerate)
		return false;
	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, ForbidThrowCurrentWeapon)
{
	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, SetWeaponArena)
{
	if (M_ARGV(0, string) == "0" || M_ARGV(0, string) == "")
		M_ARGV(0, string) = autocvar_g_mayhem_weaponarena;
}

MUTATOR_HOOKFUNCTION(mayhem, FilterItem)
{
	entity item = M_ARGV(0, entity);
	if (autocvar_g_powerups == 1){
		if (item.flags & FL_POWERUP){
			return false;
		} 
	}
	else if (autocvar_g_powerups == -1){
		if (item.flags & FL_POWERUP){
			if (autocvar_g_mayhem_powerups){
				return false;
			} 
		} 
	}
	if (autocvar_g_pickup_items <= 0)
		return true;
}

MUTATOR_HOOKFUNCTION(mayhem, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);
	float frag_deathtype = M_ARGV(3, float);
	float frag_damage = M_ARGV(4, float);

	if ((autocvar_g_mayhem_selfdamage == 0 && frag_target == frag_attacker) || frag_deathtype == DEATH_FALL.m_id)
		frag_damage = 0;

	M_ARGV(4, float) = frag_damage;
}

MUTATOR_HOOKFUNCTION(mayhem, PlayerDamage_SplitHealthArmor)
{
	if(autocvar_g_mayhem_damage2score){
		entity frag_attacker = M_ARGV(1, entity);
		entity frag_target = M_ARGV(2, entity);
		float frag_damage = M_ARGV(7, float);
		float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
		float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));

		float excess = max(0, frag_damage - damage_take - damage_save);

		if (frag_target != frag_attacker && IS_PLAYER(frag_attacker))
			GameRules_scoring_add_team(frag_attacker, SCORE, (frag_damage - excess) * autocvar_g_mayhem_damage2score_multiplier);
	}
}

MUTATOR_HOOKFUNCTION(mayhem, GiveFragsForKill, CBC_ORDER_FIRST)
{
	if(!autocvar_g_mayhem_frags2score){
		M_ARGV(2, float) = 0;
		return true;
	}
}
