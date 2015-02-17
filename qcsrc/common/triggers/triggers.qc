void SUB_DontUseTargets() { }

void() SUB_UseTargets;

void DelayThink()
{
	activator = self.enemy;
	SUB_UseTargets ();
	remove(self);
}

void FixSize(entity e)
{
	e.mins_x = rint(e.mins_x);
	e.mins_y = rint(e.mins_y);
	e.mins_z = rint(e.mins_z);

	e.maxs_x = rint(e.maxs_x);
	e.maxs_y = rint(e.maxs_y);
	e.maxs_z = rint(e.maxs_z);
}

void trigger_setnextthink(entity e, float dtime)
{
#ifdef CSQC
	e.nextthink = time + dtime;
#else
	e.nextthink = dtime;
#endif
}

/*
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*/
void SUB_UseTargets()
{
	entity t, stemp, otemp, act;
	string s;
	float i;

//
// check for a delay
//
	if (self.delay)
	{
	// create a temp object to fire at a later time
		t = spawn();
		t.classname = "DelayedUse";
		t.nextthink = time + self.delay;
		t.think = DelayThink;
		t.enemy = activator;
		t.message = self.message;
		t.killtarget = self.killtarget;
		t.target = self.target;
		t.target2 = self.target2;
		t.target3 = self.target3;
		t.target4 = self.target4;
		return;
	}


//
// print the message
//
#ifdef SVQC
	if(self)
	if(IS_PLAYER(activator) && self.message != "")
	if(IS_REAL_CLIENT(activator))
	{
		centerprint(activator, self.message);
		if (self.noise == "")
			play2(activator, "misc/talk.wav");
	}

//
// kill the killtagets
//
	s = self.killtarget;
	if (s != "")
	{
		for(t = world; (t = find(t, targetname, s)); )
			remove(t);
	}
#endif

//
// fire targets
//
	act = activator;
	stemp = self;
	otemp = other;

	if(stemp.target_random)
		RandomSelection_Init();

	for(i = 0; i < 4; ++i)
	{
		switch(i)
		{
			default:
			case 0: s = stemp.target; break;
			case 1: s = stemp.target2; break;
			case 2: s = stemp.target3; break;
			case 3: s = stemp.target4; break;
		}
		if (s != "")
		{
			for(t = world; (t = find(t, targetname, s)); )
			if(t.use)
			{
				if(stemp.target_random)
				{
					RandomSelection_Add(t, 0, string_null, 1, 0);
				}
				else
				{
					self = t;
					other = stemp;
					activator = act;
					self.use();
				}
			}
		}
	}

	if(stemp.target_random && RandomSelection_chosen_ent)
	{
		self = RandomSelection_chosen_ent;
		other = stemp;
		activator = act;
		self.use();
	}

	activator = act;
	self = stemp;
	other = otemp;
}

#ifdef CSQC
void trigger_touch_generic(void() touchfunc)
{
	entity e;
	for(e = findradius((self.absmin + self.absmax) * 0.5, vlen(self.absmax - self.absmin) * 0.5 + 1); e; e = e.chain)
	if(e.isplayermodel)
	{
		vector emin = e.absmin, emax = e.absmax;
		if(self.solid == SOLID_BSP)
		{
			emin -= '1 1 1';
			emax += '1 1 1';
		}
		if(boxesoverlap(emin, emax, self.absmin, self.absmax)) // quick
		if(WarpZoneLib_BoxTouchesBrush(emin, emax, self, e)) // accurate
		{
			other = e;
			touchfunc();
		}
	}
}
void trigger_draw_generic()
{
	float dt = time - self.move_time;
	self.move_time = time;
	if(dt <= 0) { return; }

	setorigin(self, self.origin + self.velocity * frametime);

	if(self.trigger_touch) { trigger_touch_generic(self.trigger_touch); }
}
#endif
