#include "round_handler.qh"

#include <common/mapobjects/triggers.qh>
#include <common/scores.qh>
#include <common/util.qh>
#include <server/campaign.qh>
#include <server/command/vote.qh>
#include <server/scores.qh>
#include <server/world.qh>

void round_handler_Think(entity this)
{
	if (intermission_running)
	{
		round_handler_Reset(0);
		round_handler_Remove();
		return;
	}

	if (time < game_starttime)
	{
		round_handler_Reset(game_starttime);
		return;
	}

	game_stopped = false;

	if (this.wait)
	{
		this.wait = false;
		this.cnt = this.count + 1;  // init countdown
		round_starttime = time + this.count;
		reset_map(false);
	}

	if (this.cnt > 0)  // countdown running
	{
		if (this.canRoundStart() && !(autocvar_g_campaign && !campaign_bots_may_start))
		{
			if (this.cnt == this.count + 1) round_starttime = time + this.count;
			int f = this.cnt - 1;
			if (f == 0)
			{
				FOREACH_CLIENT((IS_PLAYER(it) || INGAME(it)), {
					GameRules_scoring_add(it, ROUNDS_PL, 1);
				});
				this.cnt = 0;
				this.round_endtime = (this.round_timelimit) ? time + this.round_timelimit : 0;
				this.nextthink = time;
				rounds_played++;
				if (this.roundStart) this.roundStart();
				return;
			}
			this.cnt = this.cnt - 1;
		}
		else
		{
			round_handler_Reset(0);
			round_starttime = -1; // can't start
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
			round_handler_ResetEndDelayTime();
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
	round_limit = the_round_timelimit;
}

// NOTE: this is only needed because if round_handler spawns at time 1
// game_starttime isn't initialized yet
void round_handler_FirstThink(entity this)
{
	round_starttime = max(time, game_starttime) + this.count;
	setthink(this, round_handler_Think);
	this.nextthink = max(time, game_starttime);
}

void round_handler_Spawn(bool() canRoundStart_func, bool() canRoundEnd_func, void() roundStart_func)
{
	if (round_handler)
	{
		backtrace("Can't spawn round_handler again!");
		return;
	}
	entity this = round_handler = new_pure(round_handler);

	setthink(this, round_handler_FirstThink);
	this.canRoundStart = canRoundStart_func;
	this.canRoundEnd = canRoundEnd_func;
	this.roundStart = roundStart_func;
	this.wait = false;
	round_handler_ResetEndDelayTime();
	round_handler_Init(5, 5, 180);
	this.nextthink = time;

	ScoreInfo_SetLabel_PlayerScore(SP_ROUNDS_PL, "rounds_pl", 0);
}

void round_handler_Reset(float next_think)
{
	entity this = round_handler;
	this.wait = false;
	round_handler_ResetEndDelayTime();
	if (this.count)
		if (this.cnt < this.count + 1) this.cnt = this.count + 1;
	this.nextthink = next_think;
	if (next_think)
	{
		if (next_think <= game_starttime) rounds_played = 0;
		round_starttime = next_think + this.count;
	}
}

void round_handler_Remove()
{
	delete(round_handler);
	round_handler = NULL;
}
