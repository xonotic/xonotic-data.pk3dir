#include "sv_mayhem.qh"

float autocvar_g_mayhem_fraglimit;
float autocvar_g_mayhem_visual_score_limit;
float mayhempointmultiplier;

bool autocvar_g_mayhem_regenerate;
string autocvar_g_mayhem_weaponarena;
bool autocvar_g_mayhem_powerups;
bool autocvar_g_mayhem_selfdamage;
int autocvar_g_mayhem_scoringmethod;
float autocvar_g_mayhem_scoringmethod_damage_weight;
float autocvar_g_mayhem_scoringmethod_frag_weight;
bool autocvar_g_mayhem_pickup_items;
bool autocvar_g_mayhem_pickup_items_remove_weapons_and_ammo;
bool autocvar_g_mayhem_unlimited_ammo;

float autocvar_g_mayhem_start_health = 200;
float autocvar_g_mayhem_start_armor = 200;
float autocvar_g_mayhem_start_ammo_shells = 60;
float autocvar_g_mayhem_start_ammo_nails = 320;
float autocvar_g_mayhem_start_ammo_rockets = 160;
float autocvar_g_mayhem_start_ammo_cells = 180;
float autocvar_g_mayhem_start_ammo_plasma = 180;
float autocvar_g_mayhem_start_ammo_fuel = 0;

void mayhem_DelayedInit(entity this)
{
	return;
}

void mayhem_Initialize()
{
	if(autocvar_g_mayhem_visual_score_limit > 0 && autocvar_g_mayhem_fraglimit > 0)
		mayhempointmultiplier = autocvar_g_mayhem_visual_score_limit / autocvar_g_mayhem_fraglimit;

	GameRules_limit_score(autocvar_g_mayhem_visual_score_limit);

	InitializeEntity(NULL, mayhem_DelayedInit, INITPRIO_GAMETYPE);
}

MUTATOR_HOOKFUNCTION(mayhem, Scores_CountFragsRemaining)
{
	// announce remaining frags
	return true;
}

MUTATOR_HOOKFUNCTION(mayhem, SetStartItems)
{
	start_items       &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);
	if(!cvar("g_use_ammunition") || autocvar_g_mayhem_unlimited_ammo)
		start_items |= IT_UNLIMITED_AMMO;

	start_health       = warmup_start_health       = autocvar_g_mayhem_start_health;
	start_armorvalue   = warmup_start_armorvalue   = autocvar_g_mayhem_start_armor;
	start_ammo_shells  = warmup_start_ammo_shells  = autocvar_g_mayhem_start_ammo_shells;
	start_ammo_nails   = warmup_start_ammo_nails   = autocvar_g_mayhem_start_ammo_nails;
	start_ammo_rockets = warmup_start_ammo_rockets = autocvar_g_mayhem_start_ammo_rockets;
	start_ammo_cells   = warmup_start_ammo_cells   = autocvar_g_mayhem_start_ammo_cells;
	start_ammo_plasma  = warmup_start_ammo_plasma  = autocvar_g_mayhem_start_ammo_plasma;
	start_ammo_fuel    = warmup_start_ammo_fuel    = autocvar_g_mayhem_start_ammo_fuel;
}

//this hook also enables rotting, as players spawn with more hp and armor than what default rot limits are set to this is a bad idea as of now
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
	
	//enable powerups if forced globally or global accepts gamemodes to have powerups according to their own settings
	if (autocvar_g_powerups == 1 || (autocvar_g_powerups == -1 && autocvar_g_mayhem_powerups == 1)){
		if (item.itemdef.instanceOfPowerup){
			return false;
		} 
	}
	//disabled powerups if forced off globally or in this gamemode
	if (autocvar_g_powerups == 0 || autocvar_g_mayhem_powerups == 0){
		if (item.itemdef.instanceOfPowerup){
			return true; 
		} 
	}
	//remove all items if items are forced off globally
	if (autocvar_g_pickup_items == 0){
		return true;
	}
	//if items are switched on in this gamemode allow the removal of weapons and ammo still
	if ((autocvar_g_mayhem_pickup_items == 1 && autocvar_g_mayhem_pickup_items_remove_weapons_and_ammo == 1) && autocvar_g_pickup_items <= 0){
		if (item.itemdef.instanceOfAmmo || item.itemdef.instanceOfWeaponPickup){
			return true;
		}
	}
	//remove items if not globally set to follow mode's settings and locally set off
	if (autocvar_g_pickup_items == -1 && autocvar_g_mayhem_pickup_items == 0){
		return true;
	}
	return false;
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
	switch(autocvar_g_mayhem_scoringmethod)
	{
		//frags only
		case 2:
		{
			return;
		}
		
		//damage only
		case 3:
		{
			entity frag_attacker = M_ARGV(1, entity);
			entity frag_target = M_ARGV(2, entity);
			float frag_deathtype = M_ARGV(6, float);
			float frag_damage = M_ARGV(7, float);
			float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
			float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));

			float excess = max(0, frag_damage - damage_take - damage_save);

			if (frag_target != frag_attacker && IS_PLAYER(frag_attacker))
				GameRules_scoring_add_team(frag_attacker, SCORE, (frag_damage - excess) * mayhempointmultiplier * (1/(start_health + start_armorvalue)));
			
			if (frag_target == frag_attacker && IS_PLAYER(frag_attacker))
				GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * mayhempointmultiplier * (1/(start_health + start_armorvalue)));
		
			//handle (environmental hazard) suiciding, check first if player has a registered attacker who most likely pushed them there to avoid punishing pushed players as pushers are already rewarded
			//deathtypes:
			//kill = suicide, drown = drown in water/liquid, hurttrigger = out of the map void or hurt triggers inside maps like electric sparks
			//camp = campcheck, lava = lava, slime = slime
			//team change / rebalance suicides are currently not included
			if (!IS_PLAYER(frag_attacker) && (
				frag_deathtype == DEATH_KILL.m_id ||
				frag_deathtype == DEATH_DROWN.m_id ||
				frag_deathtype == DEATH_HURTTRIGGER.m_id ||
				frag_deathtype == DEATH_CAMP.m_id ||
				frag_deathtype == DEATH_LAVA.m_id ||
				frag_deathtype == DEATH_SLIME.m_id ||
				frag_deathtype == DEATH_SWAMP.m_id))
					GameRules_scoring_add_team(frag_target, SCORE, (-1 * (start_health + start_armorvalue)) * mayhempointmultiplier * (1/(start_health + start_armorvalue)));
			return;
		}
		
		//combined damage and frags
		default:
		case 1:
		{
			entity frag_attacker = M_ARGV(1, entity);
			entity frag_target = M_ARGV(2, entity);
			float frag_deathtype = M_ARGV(6, float);
			float frag_damage = M_ARGV(7, float);
			float damage_take = bound(0, M_ARGV(4, float), GetResource(frag_target, RES_HEALTH));
			float damage_save = bound(0, M_ARGV(5, float), GetResource(frag_target, RES_ARMOR));

			float excess = max(0, frag_damage - damage_take - damage_save);

			//non-friendly fire
			if (frag_target != frag_attacker && IS_PLAYER(frag_attacker))
				GameRules_scoring_add_team(frag_attacker, SCORE, (frag_damage - excess) * autocvar_g_mayhem_scoringmethod_damage_weight * mayhempointmultiplier * (1/(start_health + start_armorvalue)));
			
			//friendly fire aka self damage
			if (frag_target == frag_attacker && IS_PLAYER(frag_attacker))
				GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * autocvar_g_mayhem_scoringmethod_damage_weight * mayhempointmultiplier * (1/(start_health + start_armorvalue)));
		
			//handle (environmental hazard) suiciding, check first if player has a registered attacker who most likely pushed them there to avoid punishing pushed players as pushers are already rewarded
			//deathtypes:
			//kill = suicide, drown = drown in water/liquid, hurttrigger = out of the map void or hurt triggers inside maps like electric sparks
			//camp = campcheck, lava = lava, slime = slime
			//team change / rebalance suicides are currently not included
			if (!IS_PLAYER(frag_attacker) && (
				frag_deathtype == DEATH_KILL.m_id ||
				frag_deathtype == DEATH_DROWN.m_id ||
				frag_deathtype == DEATH_HURTTRIGGER.m_id ||
				frag_deathtype == DEATH_CAMP.m_id ||
				frag_deathtype == DEATH_LAVA.m_id ||
				frag_deathtype == DEATH_SLIME.m_id ||
				frag_deathtype == DEATH_SWAMP.m_id))
					GameRules_scoring_add_team(frag_target, SCORE, (-1 * (frag_damage - excess)) * autocvar_g_mayhem_scoringmethod_damage_weight * mayhempointmultiplier * (1/(start_health + start_armorvalue)));
			return;
		}
	}
}

MUTATOR_HOOKFUNCTION(mayhem, GiveFragsForKill, CBC_ORDER_FIRST)
{
	entity frag_attacker = M_ARGV(0, entity);
	entity frag_target = M_ARGV(1, entity);
	
	if(frag_target == frag_attacker){
		switch(autocvar_g_mayhem_scoringmethod)
		{
			//frags only
			case 2:
			{
															//fix 999 score from 30 kills for example
				M_ARGV(2, float) = -1 * mayhempointmultiplier * 1.0001;
				return true;
			}

			//damage only
			case 3:
			{
				M_ARGV(2, float) = 0;
				return true;
			}

			//combined damage and frags
			default:
			case 1:
			{
				M_ARGV(2, float) = -autocvar_g_mayhem_scoringmethod_frag_weight * mayhempointmultiplier * 1.0001;
				return true;
			}
		}
	} else {
		switch(autocvar_g_mayhem_scoringmethod)
		{
			//frags only
			case 2:
			{
															//fix 999 score from 30 kills for example
				M_ARGV(2, float) = 1 * mayhempointmultiplier * 1.0001;
				return true;
			}

			//damage only
			case 3:
			{
				M_ARGV(2, float) = 0;
				return true;
			}

			//combined damage and frags
			default:
			case 1:
			{
				M_ARGV(2, float) = autocvar_g_mayhem_scoringmethod_frag_weight * mayhempointmultiplier * 1.0001;
				return true;
			}
		}
	}
}
