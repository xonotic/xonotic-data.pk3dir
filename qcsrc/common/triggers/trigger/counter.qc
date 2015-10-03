#ifdef SVQC
void counter_use()
{SELFPARAM();
	self.count -= 1;
	if (self.count < 0)
		return;

	if (self.count == 0)
	{
		if(IS_PLAYER(activator) && (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
			Send_Notification(NOTIF_ONE, activator, MSG_CENTER, CENTER_SEQUENCE_COMPLETED);

		self.enemy = activator;
		multi_trigger ();
	}
	else
	{
		if(IS_PLAYER(activator) && (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0)
		if(self.count >= 4)
			Send_Notification(NOTIF_ONE, activator, MSG_CENTER, CENTER_SEQUENCE_COUNTER);
		else
			Send_Notification(NOTIF_ONE, activator, MSG_CENTER, CENTER_SEQUENCE_COUNTER_FEWMORE, self.count);
	}
}

void counter_reset()
{SELFPARAM();
	self.count = self.cnt;
	multi_reset();
}

/*QUAKED spawnfunc_trigger_counter (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
*/
spawnfunc(trigger_counter)
{
	self.wait = -1;
	if (!self.count)
		self.count = 2;
	self.cnt = self.count;

	self.use = counter_use;
	self.reset = counter_reset;
}
#endif
