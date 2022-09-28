#include "sv_offhand_blaster.qh"

string autocvar_g_offhand_blaster = "0";

REGISTER_MUTATOR(offhand_blaster, expr_evaluate(autocvar_g_offhand_blaster));

MUTATOR_HOOKFUNCTION(offhand_blaster, BuildMutatorsString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ":offhand_blaster");
}

MUTATOR_HOOKFUNCTION(offhand_blaster, BuildMutatorsPrettyString)
{
	M_ARGV(0, string) = strcat(M_ARGV(0, string), ", Offhand blaster");
}

MUTATOR_HOOKFUNCTION(offhand_blaster, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);
	player.offhand = OFFHAND_BLASTER;
}
