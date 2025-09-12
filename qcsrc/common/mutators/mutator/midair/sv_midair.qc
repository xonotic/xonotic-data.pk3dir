#include "sv_midair.qh"

string autocvar_g_midair;
float autocvar_g_midair_shieldtime;
float autocvar_g_midair_damagemultiplier;
float autocvar_g_midair_damageforcescale;

REGISTER_MUTATOR(midair, expr_evaluate(autocvar_g_midair));

.float midair_shieldtime;

MUTATOR_HOOKFUNCTION(midair, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if(IS_PLAYER(frag_attacker) && IS_PLAYER(frag_target))
	{
		if(time < frag_target.midair_shieldtime)
			M_ARGV(4, float) = 0;
		else
			M_ARGV(4, float) *= autocvar_g_midair_damagemultiplier;
		if(autocvar_g_midair_damageforcescale)
			M_ARGV(6, vector) *= autocvar_g_midair_damageforcescale;
	}
}

MUTATOR_HOOKFUNCTION(midair, PlayerPowerups)
{
	entity player = M_ARGV(0, entity);

	if(time >= game_starttime)
	if(IS_ONGROUND(player))
	{
		player.effects |= (EF_ADDITIVE | EF_FULLBRIGHT);
		player.midair_shieldtime = max(player.midair_shieldtime, time + autocvar_g_midair_shieldtime);
	}
}

MUTATOR_HOOKFUNCTION(midair, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);

	if(IS_BOT_CLIENT(player))
		player.bot_moveskill = 0; // disable bunnyhopping
}

MUTATOR_HOOKFUNCTION(midair, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":midair");
}

MUTATOR_HOOKFUNCTION(midair, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Midair");
}
