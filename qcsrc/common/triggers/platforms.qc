void generic_plat_blocked()
{SELFPARAM();
#ifdef SVQC
	if(self.dmg && other.takedamage != DAMAGE_NO)
	{
		if(self.dmgtime2 < time)
		{
			Damage (other, self, self, self.dmg, DEATH_HURTTRIGGER.m_id, other.origin, '0 0 0');
			self.dmgtime2 = time + self.dmgtime;
		}

		// Gib dead/dying stuff
		if(other.deadflag != DEAD_NO)
			Damage (other, self, self, 10000, DEATH_HURTTRIGGER.m_id, other.origin, '0 0 0');
	}
#endif
}

void plat_spawn_inside_trigger()
{SELFPARAM();
	entity trigger;
	vector tmin, tmax;

	trigger = spawn();
	trigger.touch = plat_center_touch;
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.enemy = self;

#ifdef CSQC
	trigger.drawmask = MASK_NORMAL;
	trigger.trigger_touch = plat_center_touch;
	trigger.draw = trigger_draw_generic;
#endif

	tmin = self.absmin + '25 25 0';
	tmax = self.absmax - '25 25 -8';
	tmin_z = tmax_z - (self.pos1_z - self.pos2_z + 8);
	if (self.spawnflags & PLAT_LOW_TRIGGER)
		tmax_z = tmin_z + 8;

	if (self.size_x <= 50)
	{
		tmin_x = (self.mins_x + self.maxs_x) / 2;
		tmax_x = tmin_x + 1;
	}
	if (self.size_y <= 50)
	{
		tmin_y = (self.mins_y + self.maxs_y) / 2;
		tmax_y = tmin_y + 1;
	}

	if(tmin_x < tmax_x)
		if(tmin_y < tmax_y)
			if(tmin_z < tmax_z)
			{
				setsize (trigger, tmin, tmax);
				return;
			}

	// otherwise, something is fishy...
	remove(trigger);
	objerror("plat_spawn_inside_trigger: platform has odd size or lip, can't spawn");
}

void plat_hit_top()
{SELFPARAM();
	_sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	self.state = 1;

	self.SUB_THINK = plat_go_down;
	self.SUB_NEXTTHINK = self.SUB_LTIME + 3;
}

void plat_hit_bottom()
{SELFPARAM();
	_sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	self.state = 2;
}

void plat_go_down()
{SELFPARAM();
	_sound (self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_NORM);
	self.state = 3;
	SUB_CalcMove (self.pos2, TSPEED_LINEAR, self.speed, plat_hit_bottom);
}

void plat_go_up()
{SELFPARAM();
	_sound (self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_NORM);
	self.state = 4;
	SUB_CalcMove (self.pos1, TSPEED_LINEAR, self.speed, plat_hit_top);
}

void plat_center_touch()
{SELFPARAM();
#ifdef SVQC
	if (!other.iscreature)
		return;

	if (other.health <= 0)
		return;
#elif defined(CSQC)
	if (!IS_PLAYER(other))
		return;
	if(PHYS_DEAD(other))
		return;
#endif

	setself(self.enemy);
	if (self.state == 2)
		plat_go_up ();
	else if (self.state == 1)
		self.SUB_NEXTTHINK = self.SUB_LTIME + 1;
}

void plat_outside_touch()
{SELFPARAM();
#ifdef SVQC
	if (!other.iscreature)
		return;

	if (other.health <= 0)
		return;
#elif defined(CSQC)
	if (!IS_PLAYER(other))
		return;
#endif

	setself(self.enemy);
	if (self.state == 1)
		plat_go_down ();
}

void plat_trigger_use()
{SELFPARAM();
#ifdef SVQC
	if (self.think)
		return;		// already activated
#elif defined(CSQC)
	if(self.move_think)
		return;
#endif
	plat_go_down();
}


void plat_crush()
{SELFPARAM();
	if((self.spawnflags & 4) && (other.takedamage != DAMAGE_NO))
	{ // KIll Kill Kill!!
#ifdef SVQC
		Damage (other, self, self, 10000, DEATH_HURTTRIGGER.m_id, other.origin, '0 0 0');
#endif
	}
	else
	{
#ifdef SVQC
		if((self.dmg) && (other.takedamage != DAMAGE_NO))
		{   // Shall we bite?
			Damage (other, self, self, self.dmg, DEATH_HURTTRIGGER.m_id, other.origin, '0 0 0');
			// Gib dead/dying stuff
			if(other.deadflag != DEAD_NO)
				Damage (other, self, self, 10000, DEATH_HURTTRIGGER.m_id, other.origin, '0 0 0');
		}
#endif

		if (self.state == 4)
			plat_go_down ();
		else if (self.state == 3)
			plat_go_up ();
	// when in other states, then the plat_crush event came delayed after
	// plat state already had changed
	// this isn't a bug per se!
	}
}

void plat_use()
{SELFPARAM();
	self.use = func_null;
	if (self.state != 4)
		objerror ("plat_use: not in up state");
	plat_go_down();
}

.string sound1, sound2;

void plat_reset()
{SELFPARAM();
	IFTARGETED
	{
		setorigin (self, self.pos1);
		self.state = 4;
		self.use = plat_use;
	}
	else
	{
		setorigin (self, self.pos2);
		self.state = 2;
		self.use = plat_trigger_use;
	}

#ifdef SVQC
	self.SendFlags |= SF_TRIGGER_RESET;
#endif
}

.float platmovetype_start_default, platmovetype_end_default;
bool set_platmovetype(entity e, string s)
{
	// sets platmovetype_start and platmovetype_end based on a string consisting of two values

	int n = tokenize_console(s);
	if(n > 0)
		e.platmovetype_start = stof(argv(0));
	else
		e.platmovetype_start = 0;

	if(n > 1)
		e.platmovetype_end = stof(argv(1));
	else
		e.platmovetype_end = e.platmovetype_start;

	if(n > 2)
		if(argv(2) == "force")
			return true; // no checking, return immediately

	if(!cubic_speedfunc_is_sane(e.platmovetype_start, e.platmovetype_end))
	{
		objerror("Invalid platform move type; platform would go in reverse, which is not allowed.");
		return false;
	}

	return true;
}
