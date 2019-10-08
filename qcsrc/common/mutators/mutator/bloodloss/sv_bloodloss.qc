#include "sv_bloodloss.qh"

float autocvar_g_bloodloss;
REGISTER_MUTATOR(bloodloss, autocvar_g_bloodloss);

.float bloodloss_timer;

MUTATOR_HOOKFUNCTION(bloodloss, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if(IS_PLAYER(player))
	if(GetResource(player, RES_HEALTH) <= autocvar_g_bloodloss && !IS_DEAD(player))
	{
		PHYS_INPUT_BUTTON_CROUCH(player) = true;

		if(time >= player.bloodloss_timer)
		{
			if(player.vehicle)
				vehicles_exit(player.vehicle, VHEF_RELEASE);
			if(player.event_damage)
				player.event_damage(player, player, player, 1, DEATH_ROT.m_id, DMG_NOWEP, player.origin, '0 0 0');
			player.bloodloss_timer = time + 0.5 + random() * 0.5;
		}
	}
}

MUTATOR_HOOKFUNCTION(bloodloss, PlayerJump)
{
	entity player = M_ARGV(0, entity);

	if(GetResource(player, RES_HEALTH) <= autocvar_g_bloodloss)
		return true;
}

MUTATOR_HOOKFUNCTION(bloodloss, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":bloodloss");
}

MUTATOR_HOOKFUNCTION(bloodloss, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Blood loss");
}
