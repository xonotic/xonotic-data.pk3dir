#include "cl_resources.qh"

#include <common/items/item/ammo.qh>
#include <common/resources/resources.qh>

/// \file
/// \brief Source file that contains implementation of the resource system.
/// \copyright GNU GPLv2 or any later version.

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
	SetResourceExplicit(e, res_type, amount);
}

void TakeResource(entity receiver, Resource res_type, float amount)
{
	if (amount == 0)
	{
		return;
	}
	SetResource(receiver, res_type, GetResource(receiver, res_type) - amount);
}

void TakeResourceWithLimit(entity receiver, Resource res_type, float amount, float limit)
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
