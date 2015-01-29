void generic_plat_blocked()
{
#ifdef SVQC
	if(self.dmg && other.takedamage != DAMAGE_NO)
	{
		if(self.dmgtime2 < time)
		{
			Damage (other, self, self, self.dmg, DEATH_HURTTRIGGER, other.origin, '0 0 0');
			self.dmgtime2 = time + self.dmgtime;
		}

		// Gib dead/dying stuff
		if(other.deadflag != DEAD_NO)
			Damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
	}
#endif
}

#ifdef SVQC
float plat_trigger_send(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_PLAT_TRIGGER);
	WriteShort(MSG_ENTITY, num_for_edict(self.enemy));

	WriteCoord(MSG_ENTITY, self.origin_x);
	WriteCoord(MSG_ENTITY, self.origin_y);
	WriteCoord(MSG_ENTITY, self.origin_z);

	WriteCoord(MSG_ENTITY, self.mins_x);
	WriteCoord(MSG_ENTITY, self.mins_y);
	WriteCoord(MSG_ENTITY, self.mins_z);
	WriteCoord(MSG_ENTITY, self.maxs_x);
	WriteCoord(MSG_ENTITY, self.maxs_y);
	WriteCoord(MSG_ENTITY, self.maxs_z);
	return TRUE;
}

void plat_spawn_inside_trigger()
{
	entity trigger;
	vector tmin, tmax;

	trigger = spawn();
	trigger.touch = plat_center_touch;
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.enemy = self;

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
				Net_LinkEntity(trigger, FALSE, 0, plat_trigger_send);
				return;
			}

	// otherwise, something is fishy...
	remove(trigger);
	objerror("plat_spawn_inside_trigger: platform has odd size or lip, can't spawn");
}
#elif defined(CSQC)
void ent_plat_trigger()
{
	float myenemy = ReadShort();
	self.origin_x = ReadCoord();
	self.origin_y = ReadCoord();
	self.origin_z = ReadCoord();
	setorigin(self, self.origin);

	self.mins_x = ReadCoord();
	self.mins_y = ReadCoord();
	self.mins_z = ReadCoord();
	self.maxs_x = ReadCoord();
	self.maxs_y = ReadCoord();
	self.maxs_z = ReadCoord();
	setsize(self, self.mins, self.maxs);

	self.enemy = findfloat(world, sv_entnum, myenemy);
	if(!self.enemy) { print("^1BAD BAD BAD!!!\n"); }
	self.drawmask = MASK_NORMAL;
	self.draw = trigger_draw_generic;
	self.trigger_touch = plat_center_touch;
	self.solid = SOLID_TRIGGER;
}
#endif

void plat_hit_top()
{
	sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	self.state = 1;
	self.think = plat_go_down;
	self.nextthink = self.ltime + 3;
}

void plat_hit_bottom()
{
	sound (self, CH_TRIGGER_SINGLE, self.noise1, VOL_BASE, ATTEN_NORM);
	self.state = 2;
}

void plat_go_down()
{
	sound (self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_NORM);
	self.state = 3;
	SUB_CalcMove (self.pos2, TSPEED_LINEAR, self.speed, plat_hit_bottom);
}

void plat_go_up()
{
	sound (self, CH_TRIGGER_SINGLE, self.noise, VOL_BASE, ATTEN_NORM);
	self.state = 4;
	SUB_CalcMove (self.pos1, TSPEED_LINEAR, self.speed, plat_hit_top);
}

void plat_center_touch()
{
#ifdef SVQC
	if (!other.iscreature)
		return;

	if (other.health <= 0)
		return;
#elif defined(CSQC)
	if (!IS_PLAYER(other))
		return;
#endif

#ifdef CSQC
	print("Got this far\n");
#endif

	self = self.enemy;
	if (self.state == 2)
		plat_go_up ();
	else if (self.state == 1)
		self.nextthink = self.ltime + 1;	// delay going down
}

void plat_outside_touch()
{
#ifdef SVQC
	if (!other.iscreature)
		return;

	if (other.health <= 0)
		return;
#elif defined(CSQC)
	if (!IS_PLAYER(other))
		return;
#endif

	self = self.enemy;
	if (self.state == 1)
		plat_go_down ();
}

void plat_trigger_use()
{
	if (self.think)
		return;		// already activated
	plat_go_down();
}


void plat_crush()
{
	if((self.spawnflags & 4) && (other.takedamage != DAMAGE_NO))
	{ // KIll Kill Kill!!
#ifdef SVQC
		Damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
#endif
	}
	else
	{
#ifdef SVQC
		if((self.dmg) && (other.takedamage != DAMAGE_NO))
		{   // Shall we bite?
			Damage (other, self, self, self.dmg, DEATH_HURTTRIGGER, other.origin, '0 0 0');
			// Gib dead/dying stuff
			if(other.deadflag != DEAD_NO)
				Damage (other, self, self, 10000, DEATH_HURTTRIGGER, other.origin, '0 0 0');
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
{
	self.use = func_null;
	if (self.state != 4)
		objerror ("plat_use: not in up state");
	plat_go_down();
}

.string sound1, sound2;

void plat_reset()
{
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

#ifdef SVQC
.float platmovetype_start_default, platmovetype_end_default;
float set_platmovetype(entity e, string s)
{
	// sets platmovetype_start and platmovetype_end based on a string consisting of two values

	float n;
	n = tokenize_console(s);
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
			return TRUE; // no checking, return immediately

	if(!cubic_speedfunc_is_sane(e.platmovetype_start, e.platmovetype_end))
	{
		objerror("Invalid platform move type; platform would go in reverse, which is not allowed.");
		return FALSE;
	}

	return TRUE;
}
#endif
