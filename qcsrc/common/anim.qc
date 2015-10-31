void setanim(entity e, vector anim, bool looping, bool override, int restart)
{
	if (!anim) return;  // no animation was given to us! We can't use this.

	if (anim.x == e.animstate_startframe)
	{
		if (anim.y == e.animstate_numframes)
		{
			if (anim.z == e.animstate_framerate)
			{
				if (!restart) return;
				if (restart > 0 && anim.y == 1)  // ZYM animation
					BITXOR_ASSIGN(e.effects, EF_RESTARTANIM_BIT);
			}
		}
	}
	e.animstate_startframe = anim.x;
	e.animstate_numframes = anim.y;
	e.animstate_framerate = anim.z;
	e.animstate_starttime = servertime - 0.1 * frametime;  // shift it a little bit into the past to prevent float inaccuracy hiccups
	e.animstate_endtime = e.animstate_starttime + e.animstate_numframes / e.animstate_framerate;
	e.animstate_looping = looping;
	e.animstate_override = override;
	e.frame = e.animstate_startframe;
	e.frame1time = servertime;
}

void updateanim(entity e)
{
	if (time >= e.animstate_endtime)
	{
		if (e.animstate_looping)
		{
			e.animstate_starttime = e.animstate_endtime;
			e.animstate_endtime = e.animstate_starttime + e.animstate_numframes / e.animstate_framerate;
		}
		e.animstate_override = false;
	}
	e.frame = e.animstate_startframe + bound(0, (time - e.animstate_starttime) * e.animstate_framerate,
		e.animstate_numframes - 1);
	// print(ftos(time), " -> ", ftos(e.frame), "\n");
}
