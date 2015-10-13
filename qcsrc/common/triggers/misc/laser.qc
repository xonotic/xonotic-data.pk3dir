#if defined(CSQC)
	#include "../../buffs/all.qh"
	#include "../../../lib/csqcmodel/interpolate.qh"
	#include "../../../client/main.qh"
	#include "../../../lib/csqcmodel/cl_model.qh"
#elif defined(MENUQC)
#elif defined(SVQC)
#endif

#ifdef SVQC
.float modelscale;
void misc_laser_aim()
{SELFPARAM();
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
{SELFPARAM();
	if(self.target != "")
		self.enemy = find(world, targetname, self.target);
}

.entity pusher;
void misc_laser_think()
{SELFPARAM();
	vector o;
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

				activator = self.enemy.pusher;
				WITH(entity, self, self.enemy, SUB_UseTargets());
			}
		}
		else
		{
			if(self.count)
			{
				self.count = 0;

				activator = self.enemy.pusher;
				WITH(entity, self, self.enemy, SUB_UseTargets());
			}
		}
	}

	if(self.dmg)
	{
		if(self.team)
			if(((self.spawnflags & 8) == 0) == (self.team != hitent.team))
				return;
		if(hitent.takedamage)
			Damage(hitent, self, self, ((self.dmg < 0) ? 100000 : (self.dmg * frametime)), DEATH_HURTTRIGGER.m_id, hitloc, '0 0 0');
	}
}

bool laser_SendEntity(entity this, entity to, float fl)
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
{SELFPARAM();
	self.state = !self.state;
	self.SendFlags |= 4;
	misc_laser_aim();
}

void laser_reset()
{SELFPARAM();
	if(self.spawnflags & 1)
		self.state = 1;
	else
		self.state = 0;
}

spawnfunc(misc_laser)
{
	if(self.mdl)
	{
		if(self.mdl == "none")
			self.cnt = -1;
		else
		{
			self.cnt = _particleeffectnum(self.mdl);
			if(self.cnt < 0)
				if(self.dmg)
					self.cnt = particleeffectnum(EFFECT_LASER_DEADLY);
		}
	}
	else if(!self.cnt)
	{
		if(self.dmg)
			self.cnt = particleeffectnum(EFFECT_LASER_DEADLY);
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
#elif defined(CSQC)

// a laser goes from origin in direction angles
// it has color 'colormod'
// and stops when something is in the way
entityclass(Laser);
class(Laser) .int cnt; // end effect
class(Laser) .vector colormod;
class(Laser) .int state; // on-off
class(Laser) .int count; // flags for the laser
class(Laser) .vector velocity;
class(Laser) .float alpha;
class(Laser) .float scale; // scaling factor of the thickness
class(Laser) .float modelscale; // scaling factor of the dlight

void Draw_Laser(entity this)
{
	if(!self.state)
		return;
	InterpolateOrigin_Do();
	if(self.count & 0x80)
	{
		if(self.count & 0x10)
		{
			trace_endpos = self.velocity;
			trace_dphitq3surfaceflags = 0;
		}
		else
			traceline(self.origin, self.velocity, 0, self);
	}
	else
	{
		if(self.count & 0x10)
		{
			makevectors(self.angles);
			trace_endpos = self.origin + v_forward * 1048576;
			trace_dphitq3surfaceflags = Q3SURFACEFLAG_SKY;
		}
		else
		{
			makevectors(self.angles);
			traceline(self.origin, self.origin + v_forward * 32768, 0, self);
			if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
				trace_endpos = self.origin + v_forward * 1048576;
		}
	}
	if(self.scale != 0)
	{
		if(self.alpha)
		{
			Draw_CylindricLine(self.origin, trace_endpos, self.scale, "particles/laserbeam", 0, time * 3, self.colormod, self.alpha, DRAWFLAG_NORMAL, view_origin);
		}
		else
		{
			Draw_CylindricLine(self.origin, trace_endpos, self.scale, "particles/laserbeam", 0, time * 3, self.colormod, 0.5, DRAWFLAG_ADDITIVE, view_origin);
		}
	}
	if (!(trace_dphitq3surfaceflags & (Q3SURFACEFLAG_SKY | Q3SURFACEFLAG_NOIMPACT)))
	{
		if(self.cnt >= 0)
			pointparticles(self.cnt, trace_endpos, trace_plane_normal, drawframetime * 1000);
		if(self.colormod != '0 0 0' && self.modelscale != 0)
			adddynamiclight(trace_endpos + trace_plane_normal * 1, self.modelscale, self.colormod * 5);
	}
}

void Ent_Laser()
{SELFPARAM();
	InterpolateOrigin_Undo();

	// 30 bytes, or 13 bytes for just moving
	int f = ReadByte();
	self.count = (f & 0xF0);

	if(self.count & 0x80)
		self.iflags = IFLAG_VELOCITY | IFLAG_ORIGIN;
	else
		self.iflags = IFLAG_ANGLES | IFLAG_ORIGIN;

	if(f & 1)
	{
		self.origin_x = ReadCoord();
		self.origin_y = ReadCoord();
		self.origin_z = ReadCoord();
		setorigin(self, self.origin);
	}
	if(f & 8)
	{
		self.colormod_x = ReadByte() / 255.0;
		self.colormod_y = ReadByte() / 255.0;
		self.colormod_z = ReadByte() / 255.0;
		if(f & 0x40)
			self.alpha = ReadByte() / 255.0;
		else
			self.alpha = 0;
		self.scale = 2;
		self.modelscale = 50;
		if(f & 0x20)
		{
			self.scale *= ReadByte() / 16.0; // beam radius
			self.modelscale *= ReadByte() / 16.0; // dlight radius
		}
		if((f & 0x80) || !(f & 0x10))
			self.cnt = ReadShort() - 1; // effect number
		else
			self.cnt = 0;
	}
	if(f & 2)
	{
		if(f & 0x80)
		{
			self.velocity_x = ReadCoord();
			self.velocity_y = ReadCoord();
			self.velocity_z = ReadCoord();
		}
		else
		{
			self.angles_x = ReadAngle();
			self.angles_y = ReadAngle();
		}
	}
	if(f & 4)
		self.state = ReadByte();
	InterpolateOrigin_Note();
	self.draw = Draw_Laser;
}
#endif
