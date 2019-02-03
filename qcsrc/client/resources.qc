#include "resources.qh"
#include <common/items/item/ammo.qh>

/// \file
/// \brief Source file that contains implementation of the resource system.
/// \copyright GNU GPLv2 or any later version.

float GetResource(entity e, int res_type)
{
	return e.(GetResourceField(res_type));
}

void SetResource(entity e, int res_type, float amount)
{
	e.(GetResourceField(res_type)) = amount;
}

void TakeResource(entity receiver, int res_type, float amount)
{
	if (amount == 0)
	{
		return;
	}
	SetResource(receiver, res_type, GetResource(receiver, res_type) - amount);
}

void TakeResourceWithLimit(entity receiver, int res_type, float amount, float limit)
{
	if (amount == 0)
	{
		return;
	}
	float current_amount = GetResource(receiver, res_type);
	if (current_amount - amount < limit)
	{
		amount = limit + current_amount;
	}
	TakeResource(receiver, res_type, amount);
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
