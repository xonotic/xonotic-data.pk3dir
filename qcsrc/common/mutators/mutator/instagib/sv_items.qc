#include "sv_items.qh"

#include "items.qh"

/// \brief Time of ivisibility powerup in seconds.
float autocvar_g_instagib_invisibility_time;
/// \brief Time of speed powerup in seconds.
float autocvar_g_instagib_speed_time;

void powerup_invisibility_init(Pickup this, entity item)
{
	if(!item.strength_finished)
	{
		item.strength_finished = autocvar_g_instagib_invisibility_time;
	}
}


void powerup_speed_init(Pickup this, entity item)
{
	if(!item.invincible_finished)
	{
		item.invincible_finished = autocvar_g_instagib_speed_time;
	}
}
