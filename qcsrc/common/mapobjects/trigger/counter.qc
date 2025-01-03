#include "counter.qh"

#ifdef SVQC
void counter_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;

	entity store = this;
	if(this.spawnflags & COUNTER_PER_PLAYER)
	{
		if(!IS_PLAYER(actor))
			return;
		entity mycounter = NULL;
		IL_EACH(g_counters, it.realowner == actor && it.owner == this,
		{
			mycounter = it;
			break;
		});
		if(!mycounter)
		{
			mycounter = new_pure(counter);
			IL_PUSH(g_counters, mycounter);
			mycounter.owner = this;
			mycounter.realowner = actor;
			mycounter.counter_cnt = 0;
			// NOTE: will be deleted when the player respawns or match resets
		}
		store = mycounter;
	}

	store.counter_cnt += 1;
	if (store.counter_cnt > this.count)
		return;

	bool doactivate = (this.spawnflags & COUNTER_FIRE_AT_COUNT);

	if (store.counter_cnt == this.count)
	{
		if(IS_PLAYER(actor) && !(this.spawnflags & SPAWNFLAG_NOMESSAGE))
			Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_SEQUENCE_COMPLETED);

		doactivate = true;

		if(this.respawntime)
		{
			setthink(store, counter_reset);
			store.nextthink = time + this.respawntime;
		}
	}
	else
	{
		if(IS_PLAYER(actor) && !(this.spawnflags & SPAWNFLAG_NOMESSAGE))
		{
			if((this.count - store.counter_cnt) >= 4)
				Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_SEQUENCE_COUNTER);
			else
				Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_SEQUENCE_COUNTER_FEWMORE, this.count - store.counter_cnt);
		}
	}

	if(doactivate)
		SUB_UseTargets(this, actor, trigger);
}

void counter_reset(entity this)
{
	setthink(this, func_null);
	this.nextthink = 0;
	this.counter_cnt = 0;
	this.active = ACTIVE_ACTIVE;

	// remove any per-player counters
	IL_EACH(g_counters, it.owner == this,
	{
		delete(it);
	});
}

/*QUAKED spawnfunc_trigger_counter (.5 .5 .5) ? nomessage COUNTER_FIRE_AT_COUNT
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, it will print "1 more.. " etc when triggered and "sequence complete" when finished.
If COUNTER_FIRE_AT_COUNT is set, it will also fire all of its targets at countdown, making it behave like trigger_mulitple with limited shots

If respawntime is set, it will re-enable itself after the time once the sequence has been completed

After the counter has been triggered "count" times (default 2), it will fire all of its targets.
*/
spawnfunc(trigger_counter)
{
	if (!this.count)
		this.count = 2;

	this.counter_cnt = 0;
	this.use = counter_use;
	this.reset = counter_reset;
	this.active = ACTIVE_ACTIVE;
}
#endif
