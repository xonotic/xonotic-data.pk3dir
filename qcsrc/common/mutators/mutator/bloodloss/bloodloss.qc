#include "bloodloss.qh"

#ifdef GAMEQC
#ifdef SVQC
REGISTER_MUTATOR(bloodloss, autocvar_g_bloodloss);
#elif defined(CSQC)
REGISTER_MUTATOR(bloodloss, true);
#endif

#ifdef SVQC
.float bloodloss_timer;

MUTATOR_HOOKFUNCTION(bloodloss, PlayerPreThink)
{
	entity player = M_ARGV(0, entity);

	if(game_stopped)
		return; // during intermission, the player's health changes to strange values for the engine, let's not cause damage during this phase!

	if(IS_PLAYER(player))
	if(GetResource(player, RES_HEALTH) <= autocvar_g_bloodloss && !IS_DEAD(player) && time >= player.bloodloss_timer)
	{
		if(player.vehicle)
			vehicles_exit(player.vehicle, VHEF_RELEASE); // TODO: boots player out of their vehicle each health rot tick!
		if(player.event_damage)
			player.event_damage(player, player, player, 1, DEATH_ROT.m_id, DMG_NOWEP, player.origin, '0 0 0');
		player.bloodloss_timer = time + 0.5 + random() * 0.5;
	}
}

MUTATOR_HOOKFUNCTION(bloodloss, PlayerCanCrouch)
{
	entity player = M_ARGV(0, entity);
	if(GetResource(player, RES_HEALTH) <= autocvar_g_bloodloss)
		M_ARGV(1, bool) = true; // do_crouch
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
#endif

#ifdef CSQC
MUTATOR_HOOKFUNCTION(bloodloss, PlayerCanCrouch)
{
	if(STAT(HEALTH) > 0 && STAT(HEALTH) <= STAT(BLOODLOSS))
		M_ARGV(1, bool) = true; // do_crouch
}
MUTATOR_HOOKFUNCTION(bloodloss, PlayerJump)
{
	if(STAT(HEALTH) > 0 && STAT(HEALTH) <= STAT(BLOODLOSS))
		return true;
}
#endif

#endif
#ifdef MENUQC
METHOD(MutatorBloodLoss, describe, string(MutatorBloodLoss this))
{
	TC(MutatorBloodLoss, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a mutator in which players below a certain health threshold (for example 25) will suffer blood loss."), COLORED_NAME(this));
	PAR(_("Blood loss makes players stunned, severely impairs their movement, and rapidly takes away health points until they either die or gain enough health to go above the health threshold."));
	return PAGE_TEXT;
}
#endif
