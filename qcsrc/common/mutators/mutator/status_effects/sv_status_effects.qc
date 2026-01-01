#include "sv_status_effects.qh"

METHOD(StatusEffect, m_active, bool(StatusEffect this, entity actor))
{
	TC(StatusEffect, this);
	if(!actor.statuseffects)
		return false; // safety net
	return (actor.statuseffects.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_ACTIVE);
}

METHOD(StatusEffect, m_tick, void(StatusEffect this, entity actor))
{
	StatusEffect data = actor.statuseffects;
	.int flg = statuseffect_flags[this.m_id];
	int oldflag = data.(flg);
	data.(flg) = BITSET(data.(flg), STATUSEFFECT_FLAG_PERSISTENT, this.m_persistent(this, actor));
	if(oldflag != data.(flg))
		StatusEffects_update(actor);

	if(data.(flg) & STATUSEFFECT_FLAG_PERSISTENT)
		return;
	if(time > actor.statuseffects.statuseffect_time[this.m_id])
	{
		this.m_remove(this, actor, STATUSEFFECT_REMOVE_TIMEOUT);
		return;
	}
}

METHOD(StatusEffect, m_apply, void(StatusEffect this, entity actor, float eff_time, float eff_flags))
{
	if(!actor.statuseffects)
		StatusEffects_new(actor);

	eff_flags |= STATUSEFFECT_FLAG_ACTIVE; // automatically enable active flag if applied (TODO?)
	actor.statuseffects.statuseffect_time[this.m_id] = eff_time; // TODO: add onto the existing time rather than replacing it?
	actor.statuseffects.statuseffect_flags[this.m_id] = eff_flags;
	StatusEffects_update(actor);
}

METHOD(StatusEffect, m_remove, void(StatusEffect this, entity actor, int removal_type))
{
	StatusEffect data = actor.statuseffects;
	if(!data)
		return;
	// NOTE: persistent effects do not make a sound on removal, this is intended as a workaround for #2620
	if(removal_type == STATUSEFFECT_REMOVE_NORMAL && !(data.statuseffect_flags[this.m_id] & STATUSEFFECT_FLAG_PERSISTENT) && this.m_active(this, actor))
		sound(actor, CH_TRIGGER, this.m_sound_rm, VOL_BASE, ATTEN_NORM);
	data.statuseffect_time[this.m_id] = 0;
	data.statuseffect_flags[this.m_id] = 0;
	StatusEffects_update(actor);
}

MUTATOR_HOOKFUNCTION(status_effects, SV_StartFrame)
{
	if(game_stopped)
		return;
	// TODO: explicitly only loop through entities with a valid statuseffects object
	// NOTE: due to the way vehicles work currently, this does not function correctly! effect does not tick while inside a vehicle
	IL_EACH(g_damagedbycontents, it.damagedbycontents,
	{
		if (it.move_movetype == MOVETYPE_NOCLIP || !it.statuseffects) continue;
		StatusEffects_tick(it);
	});
}

MUTATOR_HOOKFUNCTION(status_effects, PlayerDies)
{
	entity frag_target = M_ARGV(2, entity);

	StatusEffects_removeall(frag_target, STATUSEFFECT_REMOVE_NORMAL);
}

MUTATOR_HOOKFUNCTION(status_effects, MonsterDies)
{
	entity frag_target = M_ARGV(0, entity);

	StatusEffects_removeall(frag_target, STATUSEFFECT_REMOVE_NORMAL);
}

MUTATOR_HOOKFUNCTION(status_effects, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	// don't delete possible spectatee's effects!
	if(player.statuseffects && player.statuseffects.owner == player)
	{
		// just to get rid of the pickup sound
		StatusEffects_removeall(player, STATUSEFFECT_REMOVE_NORMAL);
	}

	return true;
}

MUTATOR_HOOKFUNCTION(status_effects, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	// don't delete spectatee's effects!
	if(player.statuseffects && player.statuseffects.owner == player)
	{
		// just to get rid of the pickup sound
		// no need to network updates, as there is no statuseffects object attached
		StatusEffects_removeall(player, STATUSEFFECT_REMOVE_NORMAL);
	}

	// spectator has their own ent
	StatusEffects_clearall(player.statuseffects_store);

	// don't delete spectatee's effects!
	if(player.statuseffects && player.statuseffects.owner == player)
		StatusEffects_delete(player);
}

MUTATOR_HOOKFUNCTION(status_effects, reset_map_global)
{
	FOREACH_CLIENT(IS_PLAYER(it) && it.statuseffects,
	{
		StatusEffects_removeall(it, STATUSEFFECT_REMOVE_NORMAL); // just to get rid of the pickup sound
		StatusEffects_clearall(it.statuseffects);
		StatusEffects_update(it);
	});
	return false;
}

MUTATOR_HOOKFUNCTION(status_effects, SpectateCopy)
{
	entity spectatee = M_ARGV(0, entity);
	entity client = M_ARGV(1, entity);

	client.statuseffects = spectatee.statuseffects;
}

MUTATOR_HOOKFUNCTION(status_effects, PutClientInServer)
{
	entity player = M_ARGV(0, entity);

	if(player.statuseffects && player.statuseffects.owner == player)
	{
		StatusEffects_clearall(player.statuseffects);
		StatusEffects_update(player);
	}
	else
	{
		StatusEffects_clearall(player.statuseffects_store);
		player.statuseffects = NULL;
	}
}
