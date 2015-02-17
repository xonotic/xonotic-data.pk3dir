#ifdef SVQC
.float modelscale;
void misc_laser_aim()
{
	vector a;
	if(self.enemy)
	{
		if(self.spawnflags & 2)
		{
			if(self.enemy.origin != self.mangle)
			{
				self.mangle = self.enemy.origin;
				self.SendFlags |= 2;
			}
		}
		else
		{
			a = vectoangles(self.enemy.origin - self.origin);
			a_x = -a_x;
			if(a != self.mangle)
			{
				self.mangle = a;
				self.SendFlags |= 2;
			}
		}
	}
	else
	{
		if(self.angles != self.mangle)
		{
			self.mangle = self.angles;
			self.SendFlags |= 2;
		}
	}
	if(self.origin != self.oldorigin)
	{
		self.SendFlags |= 1;
		self.oldorigin = self.origin;
	}
}

void misc_laser_init()
{
	if(self.target != "")
		self.enemy = find(world, targetname, self.target);
}

.entity pusher;
void misc_laser_think()
{
	vector o;
	entity oldself;
	entity hitent;
	vector hitloc;

	self.nextthink = time;

	if(!self.state)
		return;

	misc_laser_aim();

	if(self.enemy)
	{
		o = self.enemy.origin;
		if (!(self.spawnflags & 2))
			o = self.origin + normalize(o - self.origin) * 32768;
	}
	else
	{
		makevectors(self.mangle);
		o = self.origin + v_forward * 32768;
	}

	if(self.dmg || self.enemy.target != "")
	{
		traceline(self.origin, o, MOVE_NORMAL, self);
	}
	hitent = trace_ent;
	hitloc = trace_endpos;

	if(self.enemy.target != "") // DETECTOR laser
	{
		if(trace_ent.iscreature)
		{
			self.pusher = hitent;
			if(!self.count)
			{
				self.count = 1;

				oldself = self;
				self = self.enemy;
				activator = self.pusher;
				SUB_UseTargets();
				self = oldself;
			}
		}
		else
		{
			if(self.count)
			{
				self.count = 0;

				oldself = self;
				self = self.enemy;
				activator = self.pusher;
				SUB_UseTargets();
				self = oldself;
			}
		}
	}

	if(self.dmg)
	{
		if(self.team)
			if(((self.spawnflags & 8) == 0) == (self.team != hitent.team))
				return;
		if(hitent.takedamage)
			Damage(hitent, self, self, ((self.dmg < 0) ? 100000 : (self.dmg * frametime)), DEATH_HURTTRIGGER, hitloc, '0 0 0');
	}
}

float laser_SendEntity(entity to, float fl)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_LASER);
	fl = fl - (fl & 0xF0); // use that bit to indicate finite length laser
	if(self.spawnflags & 2)
		fl |= 0x80;
	if(self.alpha)
		fl |= 0x40;
	if(self.scale != 1 || self.modelscale != 1)
		fl |= 0x20;
	if(self.spawnflags & 4)
		fl |= 0x10;
	WriteByte(MSG_ENTITY, fl);
	if(fl & 1)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
	}
	if(fl & 8)
	{
		WriteByte(MSG_ENTITY, self.colormod_x * 255.0);
		WriteByte(MSG_ENTITY, self.colormod_y * 255.0);
		WriteByte(MSG_ENTITY, self.colormod_z * 255.0);
		if(fl & 0x40)
			WriteByte(MSG_ENTITY, self.alpha * 255.0);
		if(fl & 0x20)
		{
			WriteByte(MSG_ENTITY, bound(0, self.scale * 16.0, 255));
			WriteByte(MSG_ENTITY, bound(0, self.modelscale * 16.0, 255));
		}
		if((fl & 0x80) || !(fl & 0x10)) // effect doesn't need sending if the laser is infinite and has collision testing turned off
			WriteShort(MSG_ENTITY, self.cnt + 1);
	}
	if(fl & 2)
	{
		if(fl & 0x80)
		{
			WriteCoord(MSG_ENTITY, self.enemy.origin_x);
			WriteCoord(MSG_ENTITY, self.enemy.origin_y);
			WriteCoord(MSG_ENTITY, self.enemy.origin_z);
		}
		else
		{
			WriteAngle(MSG_ENTITY, self.mangle_x);
			WriteAngle(MSG_ENTITY, self.mangle_y);
		}
	}
	if(fl & 4)
		WriteByte(MSG_ENTITY, self.state);
	return 1;
}

/*QUAKED spawnfunc_misc_laser (.5 .5 .5) ? START_ON DEST_IS_FIXED
Any object touching the beam will be hurt
Keys:
"target"
 spawnfunc_target_position where the laser ends
"mdl"
 name of beam end effect to use
"colormod"
 color of the beam (default: red)
"dmg"
 damage per second (-1 for a laser that kills immediately)
*/
void laser_use()
{
	self.state = !self.state;
	self.SendFlags |= 4;
	misc_laser_aim();
}

void laser_reset()
{
	if(self.spawnflags & 1)
		self.state = 1;
	else
		self.state = 0;
}

void spawnfunc_misc_laser()
{
	if(self.mdl)
	{
		if(self.mdl == "none")
			self.cnt = -1;
		else
		{
			self.cnt = particleeffectnum(self.mdl);
			if(self.cnt < 0)
				if(self.dmg)
					self.cnt = particleeffectnum("laser_deadly");
		}
	}
	else if(!self.cnt)
	{
		if(self.dmg)
			self.cnt = particleeffectnum("laser_deadly");
		else
			self.cnt = -1;
	}
	if(self.cnt < 0)
		self.cnt = -1;

	if(self.colormod == '0 0 0')
		if(!self.alpha)
			self.colormod = '1 0 0';
	if(self.message == "")
		self.message = "saw the light";
	if (self.message2 == "")
		self.message2 = "was pushed into a laser by";
	if(!self.scale)
		self.scale = 1;
	if(!self.modelscale)
		self.modelscale = 1;
	else if(self.modelscale < 0)
		self.modelscale = 0;
	self.think = misc_laser_think;
	self.nextthink = time;
	InitializeEntity(self, misc_laser_init, INITPRIO_FINDTARGET);

	self.mangle = self.angles;

	Net_LinkEntity(self, false, 0, laser_SendEntity);

	IFTARGETED
	{
		self.reset = laser_reset;
		laser_reset();
		self.use = laser_use;
	}
	else
		self.state = 1;
}
#endif
