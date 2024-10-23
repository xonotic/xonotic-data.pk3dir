#include "voicescript.qh"
#ifdef SVQC
.entity voicescript; // attached voice script
.float voicescript_index; // index of next voice, or -1 to use the randomized ones
.float voicescript_nextthink; // time to play next voice
.float voicescript_voiceend; // time when this voice ends

void target_voicescript_clear(entity pl)
{
	pl.voicescript = NULL;
}

void target_voicescript_use(entity this, entity actor, entity trigger)
{
	if(this.active != ACTIVE_ACTIVE)
		return;
	if(actor.voicescript != this)
	{
		actor.voicescript = this;
		actor.voicescript_index = 0;
		actor.voicescript_nextthink = time + this.delay;
	}
}

void target_voicescript_next(entity pl)
{
	entity vs;
	float i, n, dt;

	vs = pl.voicescript;
	if(!vs)
		return;
	if(vs.active != ACTIVE_ACTIVE)
	{
		pl.voicescript = NULL;
		return;
	}
	if(vs.message == "")
		return;
	if (!IS_PLAYER(pl))
		return;
	if(game_stopped)
		return;

	if(time >= pl.voicescript_voiceend)
	{
		if(time >= pl.voicescript_nextthink)
		{
			// get the next voice...
			n = tokenize_console(vs.message);

			if(pl.voicescript_index < vs.cnt)
				i = pl.voicescript_index * 2;
			else if(n > vs.cnt * 2)
				i = ((pl.voicescript_index - vs.cnt) % ((n - vs.cnt * 2 - 1) / 2)) * 2 + vs.cnt * 2 + 1;
			else
				i = -1;

			if(i >= 0)
			{
				play2(pl, strcat(vs.netname, "/", argv(i), ".wav"));
				dt = stof(argv(i + 1));
				if(dt >= 0)
				{
					pl.voicescript_voiceend = time + dt;
					pl.voicescript_nextthink = pl.voicescript_voiceend + vs.wait * (0.5 + random());
				}
				else
				{
					pl.voicescript_voiceend = time - dt;
					pl.voicescript_nextthink = pl.voicescript_voiceend;
				}

				pl.voicescript_index += 1;
			}
			else
			{
				pl.voicescript = NULL; // stop trying then
			}
		}
	}
}

void target_voicescript_reset(entity this)
{
	this.active = ACTIVE_ACTIVE;
}

spawnfunc(target_voicescript)
{
	// netname: directory of the sound files
	// message: list of "sound file" duration "sound file" duration, a *, and again a list
	//          foo1 4.1 foo2 4.0 foo3 -3.1 * fool1 1.1 fool2 7.1 fool3 9.1 fool4 3.7
	//          Here, a - in front of the duration means that no delay is to be
	//          added after this message
	// wait: average time between messages
	// delay: initial delay before the first message

	float i, n;
	this.use = target_voicescript_use;
	this.active = ACTIVE_ACTIVE;
	this.reset = target_voicescript_reset;

	n = tokenize_console(this.message);
	this.cnt = n / 2;
	for(i = 0; i+1 < n; i += 2)
	{
		if(argv(i) == "*")
		{
			this.cnt = i / 2;
			++i;
		}
		precache_sound(strcat(this.netname, "/", argv(i), ".wav"));
	}
}
#endif
