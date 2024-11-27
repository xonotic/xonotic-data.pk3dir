#include "sv_spawn_unique.qh"

REGISTER_MUTATOR(spawn_unique, expr_evaluate(autocvar_g_spawn_unique));

MUTATOR_HOOKFUNCTION(spawn_unique, Spawn_Score)
{
	entity player = M_ARGV(0, entity);
	entity spawn_spot = M_ARGV(1, entity);
	vector spawn_score = M_ARGV(2, vector);

	if(spawn_spot == player.su_last_point)
		spawn_score.x = 0.1; // extremely low priority but still selectable

	M_ARGV(2, vector) = spawn_score;
}

MUTATOR_HOOKFUNCTION(spawn_unique, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);
	entity spawn_spot = M_ARGV(1, entity);

	player.su_last_point = spawn_spot;
}
