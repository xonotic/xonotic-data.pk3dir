#include "counter.qh"
#ifdef SVQC
void counter_use(entity this, entity actor, entity trigger)
{
	this.count -= 1;
	if (this.count < 0)
		return;

	if (this.count == 0)
	{
		if(IS_PLAYER(actor) && (this.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
			Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_SEQUENCE_COMPLETED);

		this.enemy = actor;
		multi_trigger(this);
	}
	else
	{
		if(IS_PLAYER(actor) && (this.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		if(this.count >= 4)
			Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_SEQUENCE_COUNTER);
		else
			Send_Notification(NOTIF_ONE, actor, MSG_CENTER, CENTER_SEQUENCE_COUNTER_FEWMORE, this.count);
	}
}

void counter_reset(entity this)
{
	this.count = this.cnt;
	multi_reset(this);
}

/*QUAKED spawnfunc_trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
*/
spawnfunc(trigger_counter)
{
	this.wait = -1;
	if (!this.count)
		this.count = 2;
	this.cnt = this.count;

	this.use = counter_use;
	this.reset = counter_reset;
}
#endif
