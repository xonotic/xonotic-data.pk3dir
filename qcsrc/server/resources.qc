#include "resources.qh"

/// \file
/// \brief Source file that contains implementation of the resource system.
/// \author Lyberta
/// \copyright GNU GPLv2 or any later version.

#include "autocvars.qh"
#include "miscfunctions.qh"

float GetResourceLimit(entity e, int res_type)
{
	if(!IS_PLAYER(e))
		return RES_LIMIT_NONE; // no limits on non-players

	float limit;
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
			limit = g_pickup_shells_max;
			break;
		}
		case RES_BULLETS:
		{
			limit = g_pickup_nails_max;
			break;
		}
		case RES_ROCKETS:
		{
			limit = g_pickup_rockets_max;
			break;
		}
		case RES_CELLS:
		{
			limit = g_pickup_cells_max;
			break;
		}
		case RES_PLASMA:
		{
			limit = g_pickup_plasma_max;
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
	limit = M_ARGV(2, float);
	if (limit > RES_AMOUNT_HARD_LIMIT)
	{
		limit = RES_AMOUNT_HARD_LIMIT;
	}
	return limit;
}

float GetResource(entity e, int res_type)
{
	return e.(GetResourceField(res_type));
}

bool SetResourceExplicit(entity e, int res_type, float amount)
{
	.float res_field = GetResourceField(res_type);
	if (e.(res_field) != amount)
	{
		e.(res_field) = amount;
		return true;
	}
	return false;
}

void SetResource(entity e, int res_type, float amount)
{
	bool forbid = MUTATOR_CALLHOOK(SetResource, e, res_type, amount);
	if (forbid)
	{
		return;
	}
	res_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
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

void GiveResource(entity receiver, int res_type, float amount)
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
	res_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	if (amount <= 0)
	{
		return;
	}
	SetResource(receiver, res_type, GetResource(receiver, res_type) + amount);
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

void GiveResourceWithLimit(entity receiver, int res_type, float amount, float limit)
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
	res_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	limit = M_ARGV(3, float);
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

void TakeResource(entity receiver, int res_type, float amount)
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
	res_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	if (amount <= 0)
	{
		return;
	}
	SetResource(receiver, res_type, GetResource(receiver, res_type) - amount);
}

void TakeResourceWithLimit(entity receiver, int res_type, float amount, float limit)
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
	res_type = M_ARGV(1, int);
	amount = M_ARGV(2, float);
	limit = M_ARGV(3, float);
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

void GiveOrTakeResource(entity receiver, int res_type, float amount)
{
	if(amount < 0)
	{
		TakeResource(receiver, res_type, amount * -1);
	}
	else
	{
		GiveResource(receiver, res_type, amount);
	}
}

void GiveOrTakeResourceWithLimit(entity receiver, int res_type, float amount, float limit)
{
	if(amount < 0)
	{
		TakeResourceWithLimit(receiver, res_type, amount * -1, limit);
	}
	else
	{
		GiveResourceWithLimit(receiver, res_type, amount, limit);
	}
}

int GetResourceType(.float res_field)
{
	switch (res_field)
	{
		case health: { return RES_HEALTH; }
		case armorvalue: { return RES_ARMOR; }
		case ammo_shells: { return RES_SHELLS; }
		case ammo_nails: { return RES_BULLETS; }
		case ammo_rockets: { return RES_ROCKETS; }
		case ammo_cells: { return RES_CELLS; }
		case ammo_plasma: { return RES_PLASMA; }
		case ammo_fuel: { return RES_FUEL; }
	}
	error("GetResourceType: Invalid field.");
	return 0;
}

.float GetResourceField(int res_type)
{
	switch (res_type)
	{
		case RES_HEALTH: { return health; }
		case RES_ARMOR: { return armorvalue; }
		case RES_SHELLS: { return ammo_shells; }
		case RES_BULLETS: { return ammo_nails; }
		case RES_ROCKETS: { return ammo_rockets; }
		case RES_CELLS: { return ammo_cells; }
		case RES_PLASMA: { return ammo_plasma; }
		case RES_FUEL: { return ammo_fuel; }
	}
	error("GetResourceField: Invalid resource type.");
	return health;
}
