#include "resources.qh"
#include <common/items/item/ammo.qh>

/// \file
/// \brief Source file that contains implementation of the resource system.
/// \copyright GNU GPLv2 or any later version.

float GetResourceAmount(entity e, int resource_type)
{
	.float resource_field = GetResourceField(resource_type);
	return e.(resource_field);
}

void SetResourceAmount(entity e, int resource_type, float amount)
{
	.float resource_field = GetResourceField(resource_type);
	e.(resource_field) = amount;
}

void TakeResource(entity receiver, int resource_type, float amount)
{
	if (amount == 0)
	{
		return;
	}
	SetResourceAmount(receiver, resource_type,
		GetResourceAmount(receiver, resource_type) - amount);
}

void TakeResourceWithLimit(entity receiver, int resource_type, float amount,
	float limit)
{
	if (amount == 0)
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
