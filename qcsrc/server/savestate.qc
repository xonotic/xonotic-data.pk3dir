#include "savestate.qh"

void SaveSaveState(entity player)
{
	if (player.savestate)
	{
		// reset loads since last save counter
		player.savestate.loadCounter = 0;

		// fields stored by personal checkpoint, copy them to this implementation
		player.savestate.origin = player.origin;
		player.savestate.v_angle = player.v_angle;
		player.savestate.angles = player.angles;
		player.savestate.velocity = player.velocity;
		player.savestate.oldvelocity = player.oldvelocity;
		SetResource(player.savestate, RES_ROCKETS, GetResource(player, RES_ROCKETS));
		SetResource(player.savestate, RES_BULLETS, GetResource(player, RES_BULLETS));
		SetResource(player.savestate, RES_CELLS, GetResource(player, RES_CELLS));
		SetResource(player.savestate, RES_PLASMA, GetResource(player, RES_PLASMA));
		SetResource(player.savestate, RES_SHELLS, GetResource(player, RES_SHELLS));
		SetResource(player.savestate, RES_FUEL, GetResource(player, RES_FUEL));
		SetResource(player.savestate, RES_HEALTH, max(1, GetResource(player, RES_HEALTH)));
		SetResource(player.savestate, RES_ARMOR, GetResource(player, RES_ARMOR));
		STAT(WEAPONS, player.savestate) = STAT(WEAPONS, player);
		StatusEffects_copy(player.statuseffects, player.savestate, 0);
		player.savestate.items = player.items;
		player.savestate.pauserotarmor_finished = player.pauserotarmor_finished;
		player.savestate.pauserothealth_finished = player.pauserothealth_finished;
		player.savestate.pauserotfuel_finished = player.pauserotfuel_finished;
		player.savestate.pauseregen_finished = player.pauseregen_finished;
		player.savestate.teleport_time = time;
	}
}

bool LoadSaveState(entity player)
{
	if (player.savestate)
	{
		// store a counterfor loads since last save
		player.savestate.loadCounter++;

		// restore player state
		player.origin = player.savestate.origin;
		player.v_angle = player.savestate.v_angle;
		player.angles = player.savestate.angles;
		player.fixangle = true;
		player.velocity = player.savestate.velocity;
		player.oldvelocity = player.savestate.oldvelocity;
		SetResource(player, RES_ROCKETS, GetResource(player.savestate, RES_ROCKETS));
		SetResource(player, RES_BULLETS, GetResource(player.savestate, RES_BULLETS));
		SetResource(player, RES_CELLS, GetResource(player.savestate, RES_CELLS));
		SetResource(player, RES_PLASMA, GetResource(player.savestate, RES_PLASMA));
		SetResource(player, RES_SHELLS, GetResource(player.savestate, RES_SHELLS));
		SetResource(player, RES_FUEL, GetResource(player.savestate, RES_FUEL));
		SetResource(player, RES_HEALTH, GetResource(player.savestate, RES_HEALTH));
		SetResource(player, RES_ARMOR, GetResource(player.savestate, RES_ARMOR));
		STAT(WEAPONS, player) = STAT(WEAPONS, player.savestate);
		StatusEffects_copy(player.savestate, player.statuseffects, player.savestate.teleport_time);
		StatusEffects_update(player);
		player.items = player.savestate.items;
		player.pauserotarmor_finished = time + player.savestate.pauserotarmor_finished - player.savestate.teleport_time;
		player.pauserothealth_finished = time + player.savestate.pauserothealth_finished - player.savestate.teleport_time;
		player.pauserotfuel_finished = time + player.savestate.pauserotfuel_finished - player.savestate.teleport_time;
		player.pauseregen_finished = time + player.savestate.pauseregen_finished - player.savestate.teleport_time;

		// successfully loaded savestate
		return true;
	}

	// did not succeed in loading a savestate
	return false;
}

void DeleteSaveState(entity player)
{
	if (player.savestate)
		delete(player.savestate);
}

