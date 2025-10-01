#include "sv_resources.qh"

/// \file
/// \brief Source file that contains implementation of the resource system.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

#include <common/resources/resources.qh>
#include <server/mutators/_mod.qh>
#include <server/world.qh>

float GetResourceLimit(entity e, Resource res_type)
{
	if(!IS_PLAYER(e))
		return RES_LIMIT_NONE; // no limits on non-players

	float limit;
	// TODO: registry handles
	switch (res_type)
	{
		case RES_HEALTH:
		{
			limit = autocvar_g_balance_health_limit;
			break;
		}
		case RES_ARMOR:
		{
			limit = autocvar_g_balance_armor_limit;
			break;
		}
		case RES_SHELLS:
		{
			limit = autocvar_g_pickup_shells_max;
			break;
		}
		case RES_BULLETS:
		{
			limit = autocvar_g_pickup_nails_max;
			break;
		}
		case RES_ROCKETS:
		{
			limit = autocvar_g_pickup_rockets_max;
			break;
		}
		case RES_CELLS:
		{
			limit = autocvar_g_pickup_cells_max;
			break;
		}
		case RES_FUEL:
		{
			limit = autocvar_g_balance_fuel_limit;
			break;
		}
		default:
		{
			error("GetResourceLimit: Invalid resource type.");
			return 0;
		}
	}
	MUTATOR_CALLHOOK(GetResourceLimit, e, res_type, limit);
	limit = M_ARGV(9, float);
	if (limit > RES_AMOUNT_HARD_LIMIT)
	{
		limit = RES_AMOUNT_HARD_LIMIT;
	}
	return limit;
}

float GetResource(entity e, Resource res_type)
{
	return e.(GetResourceField(res_type));
}

bool SetResourceExplicit(entity e, Resource res_type, float amount)
{
	.float res_field = GetResourceField(res_type);
	if (e.(res_field) != amount)
	{
		e.(res_field) = amount;
		return true;
	}
	return false;
}

void SetResource(entity e, Resource res_type, float amount)
{
	bool forbid = MUTATOR_CALLHOOK(SetResource, e, res_type, amount);
	if (forbid)
	{
		return;
	}
	res_type = M_ARGV(8, entity);
	amount = M_ARGV(9, float);
	float max_amount = GetResourceLimit(e, res_type); // TODO: should allow overriding these limits if cheats are enabled!
	float amount_wasted = 0;
	if (amount > max_amount && max_amount != RES_LIMIT_NONE)
	{
		amount_wasted = amount - max_amount;
		amount = max_amount;
	}
	bool changed = SetResourceExplicit(e, res_type, amount);
	if (changed)
	{
		MUTATOR_CALLHOOK(ResourceAmountChanged, e, res_type, amount);
	}
	if (amount_wasted == 0)
	{
		return;
	}
	MUTATOR_CALLHOOK(ResourceWasted, e, res_type, amount_wasted);
}

void GiveResource(entity receiver, Resource res_type, float amount)
{
	if (amount <= 0)
	{
		return;
	}
	bool forbid = MUTATOR_CALLHOOK(GiveResource, receiver, res_type, amount);
	if (forbid)
	{
		return;
	}
	res_type = M_ARGV(8, entity);
	amount = M_ARGV(9, float);
	if (amount <= 0)
	{
		return;
	}
	SetResource(receiver, res_type, GetResource(receiver, res_type) + amount);
	// TODO: registry handles
	switch (res_type)
	{
		case RES_HEALTH:
		{
			receiver.pauserothealth_finished =
				max(receiver.pauserothealth_finished, time +
				autocvar_g_balance_pause_health_rot);
			return;
		}
		case RES_ARMOR:
		{
			receiver.pauserotarmor_finished =
				max(receiver.pauserotarmor_finished, time +
				autocvar_g_balance_pause_armor_rot);
			return;
		}
		case RES_FUEL:
		{
			receiver.pauserotfuel_finished = max(receiver.pauserotfuel_finished,
				time + autocvar_g_balance_pause_fuel_rot);
			return;
		}
	}
}

void GiveResourceWithLimit(entity receiver, Resource res_type, float amount, float limit)
{
	if (amount <= 0)
	{
		return;
	}
	bool forbid = MUTATOR_CALLHOOK(GiveResourceWithLimit, receiver, res_type, amount, limit);
	if (forbid)
	{
		return;
	}
	res_type = M_ARGV(8, entity);
	amount = M_ARGV(9, float);
	limit = M_ARGV(10, float);
	if (amount <= 0)
	{
		return;
	}
	float current_amount = GetResource(receiver, res_type);
	if (current_amount + amount > limit && limit != RES_LIMIT_NONE)
	{
		amount = limit - current_amount;
	}
	GiveResource(receiver, res_type, amount);
}

void TakeResource(entity receiver, Resource res_type, float amount)
{
	if (amount <= 0)
	{
		return;
	}
	bool forbid = MUTATOR_CALLHOOK(TakeResource, receiver, res_type, amount);
	if (forbid)
	{
		return;
	}
	res_type = M_ARGV(8, entity);
	amount = M_ARGV(9, float);
	if (amount <= 0)
	{
		return;
	}
	SetResource(receiver, res_type, GetResource(receiver, res_type) - amount);
}

void TakeResourceWithLimit(entity receiver, Resource res_type, float amount, float limit)
{
	if (amount <= 0)
	{
		return;
	}
	bool forbid = MUTATOR_CALLHOOK(TakeResourceWithLimit, receiver, res_type, amount, limit);
	if (forbid)
	{
		return;
	}
	res_type = M_ARGV(8, entity);
	amount = M_ARGV(9, float);
	limit = M_ARGV(10, float);
	if (amount <= 0)
	{
		return;
	}
	float current_amount = GetResource(receiver, res_type);
	if (current_amount - amount < -limit)
	{
		amount = -limit + current_amount;
	}
	TakeResource(receiver, res_type, amount);
}

int GetAmmoConsumption(entity wpn)
{
	if (wpn.ammo_type == RES_NONE) return 0;
	switch (wpn)
	{
		case WEP_ARC:        return WEP_CVAR(WEP_ARC,        beam_ammo);
		case WEP_DEVASTATOR: return WEP_CVAR(WEP_DEVASTATOR, ammo);
		case WEP_MACHINEGUN: return WEP_CVAR(WEP_MACHINEGUN, sustained_ammo);
		case WEP_MINE_LAYER: return WEP_CVAR(WEP_MINE_LAYER, ammo);
		case WEP_SEEKER:     return WEP_CVAR(WEP_SEEKER,     tag_ammo);
		default:             return WEP_CVAR_PRI(wpn, ammo);
	}
}
