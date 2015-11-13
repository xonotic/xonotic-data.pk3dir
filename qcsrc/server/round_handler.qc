#include "round_handler.qh"

#include "command/vote.qh"
#include "../common/util.qh"

void round_handler_Think()
{
	SELFPARAM();

	if (time < game_starttime)
	{
		round_handler_Reset(game_starttime);
		return;
	}

	if (gameover)
	{
		round_handler_Reset(0);
		round_handler_Remove();
		return;
	}

	if (this.wait)
	{
		this.wait = false;
		this.cnt = this.count + 1;  // init countdown
		round_starttime = time + this.count;
		reset_map(true);
	}

	if (this.cnt > 0)  // countdown running
	{
		if (this.canRoundStart())
		{
			if (this.cnt == this.count + 1) round_starttime = time + this.count;
			int f = this.cnt - 1;
			if (f == 0)
			{
				this.cnt = 0;
				this.round_endtime = (this.round_timelimit) ? time + this.round_timelimit : 0;
				this.nextthink = time;
				if (this.roundStart) this.roundStart();
				return;
			}
			this.cnt = this.cnt - 1;
		}
		else
		{
			round_handler_Reset(0);
		}
		this.nextthink = time + 1;  // canRoundStart every second
	}
	else
	{
		if (this.canRoundEnd())
		{
			// schedule a new round
			this.wait = true;
			this.nextthink = time + this.delay;
		}
		else
		{
			this.nextthink = time;  // canRoundEnd every frame
		}
	}
}

void round_handler_Init(float the_delay, float the_count, float the_round_timelimit)
{
	entity this = round_handler;
	this.delay = (the_delay > 0) ? the_delay : 0;
	this.count = fabs(floor(the_count));
	this.cnt = this.count + 1;
	this.round_timelimit = (the_round_timelimit > 0) ? the_round_timelimit : 0;
}

// NOTE: this is only needed because if round_handler spawns at time 1
// gamestarttime isn't initialized yet
void round_handler_FirstThink()
{
	SELFPARAM();
	round_starttime = max(time, game_starttime) + this.count;
	this.think = round_handler_Think;
	this.nextthink = max(time, game_starttime);
}

void round_handler_Spawn(float() canRoundStart_func, float() canRoundEnd_func, void() roundStart_func)
{
	if (round_handler)
	{
		backtrace("Can't spawn round_handler again!");
		return;
	}
	entity this = round_handler = new(round_handler);

	this.think = round_handler_FirstThink;
	this.canRoundStart = canRoundStart_func;
	this.canRoundEnd = canRoundEnd_func;
	this.roundStart = roundStart_func;
	this.wait = false;
	round_handler_Init(5, 5, 180);
	this.nextthink = time;
}

void round_handler_Reset(float next_think)
{
	entity this = round_handler;
	this.wait = false;
	if (this.count)
		if (this.cnt < this.count + 1) this.cnt = this.count + 1;
	this.nextthink = next_think;
	round_starttime = (next_think) ? (next_think + this.count) : -1;
}

void round_handler_Remove()
{
	remove(round_handler);
	round_handler = world;
}
