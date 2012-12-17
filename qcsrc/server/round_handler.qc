void round_handler_Think()
{
	entity e;
	float f;

	if(inWarmupStage || time < game_starttime)
	{
		self.nextthink = time + 1;
		return;
	}

	if(gameover)
	{
		round_handler_ResetCountdown();
		round_handler_Remove();
		return;
	}

	if(self.wait)
	{
		reset_map(TRUE);
		self.wait = FALSE;
		self.cnt = self.count + 1; // init countdown
	}

	if(self.cnt > 0) // countdown running
	{
		if(self.canRoundStart())
		{
			f = self.cnt - 1;
			if(f == 5) Announce("prepareforbattle");
			else if(f == 3) Announce("3");
			else if(f == 2) Announce("2");
			else if(f == 1) Announce("1");
			else if(f == 0)
			{
				Announce("begin");
				FOR_EACH_REALCLIENT(e)
					Send_CSQC_Centerprint_Generic(e, CPID_ROUND_STARTING, "^1Begin!", 1, 0);
				self.cnt = 0;
				self.nextthink = time;
				return;
			}

			FOR_EACH_REALCLIENT(e)
				Send_CSQC_Centerprint_Generic(e, CPID_ROUND_STARTING, "Round will start in %d", 1, f);
			self.cnt = self.cnt - 1;
		}
		else
		{
			round_handler_ResetCountdown();
		}
		self.nextthink = time + 1; // canRoundStart every second
	}
	else
	{
		if(self.canRoundEnd())
		{
			// schedule a new round
			self.wait = TRUE;
			self.nextthink = time + self.delay;
		}
		else
		{
			self.nextthink = time; // canRoundEnd every frame
		}
	}
}

void round_handler_Spawn(float() canRoundStart_func, float() canRoundEnd_func, float the_delay, float the_count)
{
	if(round_handler)
	{
		backtrace("Can't spawn round_handler again!");
		return;
	}
	round_handler = spawn();
	round_handler.classname = "round_handler";

	round_handler.think = round_handler_Think;
	round_handler.canRoundStart = canRoundStart_func;
	round_handler.canRoundEnd = canRoundEnd_func;
	round_handler.delay = (the_delay > 0) ? the_delay : 0;
	round_handler.count = fabs(floor(the_count));
	round_handler.wait = FALSE;
	round_handler.cnt = round_handler.count + 1;
	round_handler.nextthink = time;
}

float round_handler_IsActive()
{
	return (round_handler && !inWarmupStage && time > game_starttime);
}

float round_handler_AwaitingNextRound()
{
	return (round_handler.wait);
}

float round_handler_CountdownRunning()
{
	return (!round_handler.wait && round_handler.cnt);
}

float round_handler_IsRoundStarted()
{
	return (!round_handler.wait && !round_handler.cnt);
}

void round_handler_ResetCountdown()
{
	entity e;
	if(round_handler.count)
	if(round_handler.cnt < round_handler.count + 1)
	{
		FOR_EACH_REALCLIENT(e)
			Send_CSQC_Centerprint_Generic_Expire(e, CPID_ROUND_STARTING);
		round_handler.cnt = round_handler.count + 1;
	}
}

void round_handler_Remove()
{
	remove(round_handler);
	round_handler = world;
}

