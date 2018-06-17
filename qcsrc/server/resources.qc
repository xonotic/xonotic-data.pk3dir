#include "resources.qh"

/// \file
/// \brief Source file that contains implementation of the resource system.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

#include "autocvars.qh"
#include "miscfunctions.qh"

float GetResourceLimit(entity e, int resource_type)
{
	if(!IS_PLAYER(e))
		return RESOURCE_LIMIT_NONE; // no limits on non-players

	float limit;
	switch (resource_type)
	{
		case RESOURCE_HEALTH:
		{
			limit = autocvar_g_balance_health_limit;
			break;
		}
		case RESOURCE_ARMOR:
		{
			limit = autocvar_g_balance_armor_limit;
			break;
		}
		case RESOURCE_SHELLS:
		{
			limit = g_pickup_shells_max;
			break;
		}
		case RESOURCE_BULLETS:
		{
			limit = g_pickup_nails_max;
			break;
		}
		case RESOURCE_ROCKETS:
		{
			limit = g_pickup_rockets_max;
			break;
		}
		case RESOURCE_CELLS:
		{
			limit = g_pickup_cells_max;
			break;
		}
		case RESOURCE_PLASMA:
		{
			limit = g_pickup_plasma_max;
			break;
		}
		case RESOURCE_FUEL:
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
	MUTATOR_CALLHOOK(GetResourceLimit, e, resource_type, limit);
	limit = M_ARGV(2, float);
	if (limit > RESOURCE_AMOUNT_HARD_LIMIT)
	{
		limit = RESOURCE_AMOUNT_HARD_LIMIT;
	}
	return limit;
}

float GetResourceAmount(entity e, int resource_type)
{
	.float resource_field = GetResourceField(resource_type);
	return e.(resource_field);
}

bool SetResourceAmountExplicit(entity e, int resource_type, float amount)
{
	.float resource_field = GetResourceField(resource_type);
	if (e.(resource_field) != amount)
	{
		e.(resource_field) = amount;
		return true;
	}
	return false;
}

void SetResourceAmount(entity e, int resource_type, float amount)
{
	bool forbid = MUTATOR_CALLHOOK(SetResourceAmount, e, resource_type, amount);
	if (forbid)
	{
		return;
	}
	resource_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	float max_amount = GetResourceLimit(e, resource_type); // TODO: should allow overriding these limits if cheats are enabled!
	float amount_wasted = 0;
	if (amount > max_amount && max_amount != RESOURCE_LIMIT_NONE)
	{
		amount_wasted = amount - max_amount;
		amount = max_amount;
	}
	bool changed = SetResourceAmountExplicit(e, resource_type, amount);
	if (changed)
	{
		MUTATOR_CALLHOOK(ResourceAmountChanged, e, resource_type, amount);
	}
	if (amount_wasted == 0)
	{
		return;
	}
	MUTATOR_CALLHOOK(ResourceWasted, e, resource_type, amount_wasted);
}

void GiveResource(entity receiver, int resource_type, float amount)
{
	if (amount <= 0)
	{
		return;
	}
	bool forbid = MUTATOR_CALLHOOK(GiveResource, receiver, resource_type,
		amount);
	if (forbid)
	{
		return;
	}
	resource_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	if (amount <= 0)
	{
		return;
	}
	SetResourceAmount(receiver, resource_type,
		GetResourceAmount(receiver, resource_type) + amount);
	switch (resource_type)
	{
		case RESOURCE_HEALTH:
		{
			receiver.pauserothealth_finished =
				max(receiver.pauserothealth_finished, time +
				autocvar_g_balance_pause_health_rot);
			return;
		}
		case RESOURCE_ARMOR:
		{
			receiver.pauserotarmor_finished =
				max(receiver.pauserotarmor_finished, time +
				autocvar_g_balance_pause_armor_rot);
			return;
		}
		case RESOURCE_FUEL:
		{
			receiver.pauserotfuel_finished = max(receiver.pauserotfuel_finished,
				time + autocvar_g_balance_pause_fuel_rot);
			return;
		}
	}
}

void GiveResourceWithLimit(entity receiver, int resource_type, float amount,
	float limit)
{
	if (amount <= 0)
	{
		return;
	}
	bool forbid = MUTATOR_CALLHOOK(GiveResourceWithLimit, receiver,
		resource_type, amount, limit);
	if (forbid)
	{
		return;
	}
	resource_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	limit = M_ARGV(3, float);
	if (amount <= 0)
	{
		return;
	}
	float current_amount = GetResourceAmount(receiver, resource_type);
	if (current_amount + amount > limit)
	{
		amount = limit - current_amount;
	}
	GiveResource(receiver, resource_type, amount);
}

void TakeResource(entity receiver, int resource_type, float amount)
{
	if (amount <= 0)
	{
		return;
	}
	bool forbid = MUTATOR_CALLHOOK(TakeResource, receiver, resource_type,
		amount);
	if (forbid)
	{
		return;
	}
	resource_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	if (amount <= 0)
	{
		return;
	}
	SetResourceAmount(receiver, resource_type,
		GetResourceAmount(receiver, resource_type) - amount);
}

void TakeResourceWithLimit(entity receiver, int resource_type, float amount,
	float limit)
{
	if (amount <= 0)
	{
		return;
	}
	bool forbid = MUTATOR_CALLHOOK(TakeResourceWithLimit, receiver,
		resource_type, amount, limit);
	if (forbid)
	{
		return;
	}
	resource_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	limit = M_ARGV(3, float);
	if (amount <= 0)
	{
		return;
	}
	float current_amount = GetResourceAmount(receiver, resource_type);
	if (current_amount - amount < limit)
	{
		amount = limit + current_amount;
	}
	TakeResource(receiver, resource_type, amount);
}

int GetResourceType(.float resource_field)
{
	switch (resource_field)
	{
		case health: { return RESOURCE_HEALTH; }
		case armorvalue: { return RESOURCE_ARMOR; }
		case ammo_shells: { return RESOURCE_SHELLS; }
		case ammo_nails: { return RESOURCE_BULLETS; }
		case ammo_rockets: { return RESOURCE_ROCKETS; }
		case ammo_cells: { return RESOURCE_CELLS; }
		case ammo_plasma: { return RESOURCE_PLASMA; }
		case ammo_fuel: { return RESOURCE_FUEL; }
	}
	error("GetResourceType: Invalid field.");
	return 0;
}

.float GetResourceField(int resource_type)
{
	switch (resource_type)
	{
		case RESOURCE_HEALTH: { return health; }
		case RESOURCE_ARMOR: { return armorvalue; }
		case RESOURCE_SHELLS: { return ammo_shells; }
		case RESOURCE_BULLETS: { return ammo_nails; }
		case RESOURCE_ROCKETS: { return ammo_rockets; }
		case RESOURCE_CELLS: { return ammo_cells; }
		case RESOURCE_PLASMA: { return ammo_plasma; }
		case RESOURCE_FUEL: { return ammo_fuel; }
	}
	error("GetResourceField: Invalid resource type.");
	return health;
}
