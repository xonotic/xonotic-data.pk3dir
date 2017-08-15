#include "laser.qh"
#if defined(CSQC)
	#include <lib/csqcmodel/interpolate.qh>
	#include <client/main.qh>
	#include <lib/csqcmodel/cl_model.qh>
#elif defined(MENUQC)
#elif defined(SVQC)
#endif

REGISTER_NET_LINKED(ENT_CLIENT_LASER)

#ifdef SVQC
.float modelscale;
void misc_laser_aim(entity this)
{
	vector a;
	if(this.enemy)
	{
		if(this.spawnflags & 2)
		{
			if(this.enemy.origin != this.mangle)
			{
				this.mangle = this.enemy.origin;
				this.SendFlags |= 2;
			}
		}
		else
		{
			a = vectoangles(this.enemy.origin - this.origin);
			a_x = -a_x;
			if(a != this.mangle)
			{
				this.mangle = a;
				this.SendFlags |= 2;
			}
		}
	}
	else
	{
		if(this.angles != this.mangle)
		{
			this.mangle = this.angles;
			this.SendFlags |= 2;
		}
	}
	if(this.origin != this.oldorigin)
	{
		this.SendFlags |= 1;
		this.oldorigin = this.origin;
	}
}

void misc_laser_init(entity this)
{
	if(this.target != "")
		this.enemy = find(NULL, targetname, this.target);
}

.entity pusher;
void misc_laser_think(entity this)
{
	vector o;
	entity hitent;
	vector hitloc;

	this.nextthink = time;

	if(!this.state)
		return;

	misc_laser_aim(this);

	if(this.enemy)
	{
		o = this.enemy.origin;
		if (!(this.spawnflags & 2))
			o = this.origin + normalize(o - this.origin) * 32768;
	}
	else
	{
		makevectors(this.mangle);
		o = this.origin + v_forward * 32768;
	}

	if(this.dmg || this.enemy.target != "")
	{
		traceline(this.origin, o, MOVE_NORMAL, this);
	}
	hitent = trace_ent;
	hitloc = trace_endpos;

	if(this.enemy.target != "") // DETECTOR laser
	{
		if(trace_ent.iscreature)
		{
			this.pusher = hitent;
			if(!this.count)
			{
				this.count = 1;

				SUB_UseTargets(this.enemy, this.enemy.pusher, NULL);
			}
		}
		else
		{
			if(this.count)
			{
				this.count = 0;

				SUB_UseTargets(this.enemy, this.enemy.pusher, NULL);
			}
		}
	}

	if(this.dmg)
	{
		if(this.team)
			if(((this.spawnflags & 8) == 0) == (this.team != hitent.team))
				return;
		if(hitent.takedamage)
			Damage(hitent, this, this, ((this.dmg < 0) ? 100000 : (this.dmg * frametime)), DEATH_HURTTRIGGER.m_id, hitloc, '0 0 0');
	}
}

bool laser_SendEntity(entity this, entity to, float fl)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_LASER);
	fl = fl - (fl & 0xF0); // use that bit to indicate finite length laser
	if(this.spawnflags & 2)
		fl |= 0x80;
	if(this.alpha)
		fl |= 0x40;
	if(this.scale != 1 || this.modelscale != 1)
		fl |= 0x20;
	if(this.spawnflags & 4)
		fl |= 0x10;
	WriteByte(MSG_ENTITY, fl);
	if(fl & 1)
	{
		WriteCoord(MSG_ENTITY, this.origin_x);
		WriteCoord(MSG_ENTITY, this.origin_y);
		WriteCoord(MSG_ENTITY, this.origin_z);
	}
	if(fl & 8)
	{
		WriteByte(MSG_ENTITY, this.colormod_x * 255.0);
		WriteByte(MSG_ENTITY, this.colormod_y * 255.0);
		WriteByte(MSG_ENTITY, this.colormod_z * 255.0);
		if(fl & 0x40)
			WriteByte(MSG_ENTITY, this.alpha * 255.0);
		if(fl & 0x20)
		{
			WriteByte(MSG_ENTITY, bound(0, this.scale * 16.0, 255));
			WriteByte(MSG_ENTITY, bound(0, this.modelscale * 16.0, 255));
		}
		if((fl & 0x80) || !(fl & 0x10)) // effect doesn't need sending if the laser is infinite and has collision testing turned off
			WriteShort(MSG_ENTITY, this.cnt + 1);
	}
	if(fl & 2)
	{
		if(fl & 0x80)
		{
			WriteCoord(MSG_ENTITY, this.enemy.origin_x);
			WriteCoord(MSG_ENTITY, this.enemy.origin_y);
			WriteCoord(MSG_ENTITY, this.enemy.origin_z);
		}
		else
		{
			WriteAngle(MSG_ENTITY, this.mangle_x);
			WriteAngle(MSG_ENTITY, this.mangle_y);
		}
	}
	if(fl & 4)
		WriteByte(MSG_ENTITY, this.state);
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
void laser_use(entity this, entity actor, entity trigger)
{
	this.state = !this.state;
	this.SendFlags |= 4;
	misc_laser_aim(this);
}

void laser_reset(entity this)
{
	if(this.spawnflags & 1)
		this.state = 1;
	else
		this.state = 0;
}

spawnfunc(misc_laser)
{
	if(this.mdl)
	{
		if(this.mdl == "none")
			this.cnt = -1;
		else
		{
			this.cnt = _particleeffectnum(this.mdl);
			if(this.cnt < 0 && this.dmg)
                this.cnt = particleeffectnum(EFFECT_LASER_DEADLY);
		}
	}
	else if(!this.cnt)
	{
		if(this.dmg)
			this.cnt = particleeffectnum(EFFECT_LASER_DEADLY);
		else
			this.cnt = -1;
	}
	if(this.cnt < 0)
		this.cnt = -1;

	if(this.colormod == '0 0 0')
		if(!this.alpha)
			this.colormod = '1 0 0';
	if(this.message == "") this.message = "saw the light";
	if (this.message2 == "") this.message2 = "was pushed into a laser by";
	if(!this.scale) this.scale = 1;
	if(!this.modelscale) this.modelscale = 1;
	else if(this.modelscale < 0) this.modelscale = 0;
	setthink(this, misc_laser_think);
	this.nextthink = time;
	InitializeEntity(this, misc_laser_init, INITPRIO_FINDTARGET);

	this.mangle = this.angles;

	Net_LinkEntity(this, false, 0, laser_SendEntity);

	IFTARGETED
	{
		this.reset = laser_reset;
		this.reset(this);
		this.use = laser_use;
	}
	else
		this.state = 1;
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
	if(!this.state)
		return;
	InterpolateOrigin_Do(this);
	if(this.count & 0x80)
	{
		if(this.count & 0x10)
		{
			trace_endpos = this.velocity;
			trace_dphitq3surfaceflags = 0;
		}
		else
			traceline(this.origin, this.velocity, 0, this);
	}
	else
	{
		if(this.count & 0x10)
		{
			makevectors(this.angles);
			trace_endpos = this.origin + v_forward * 1048576;
			trace_dphitq3surfaceflags = Q3SURFACEFLAG_SKY;
		}
		else
		{
			makevectors(this.angles);
			traceline(this.origin, this.origin + v_forward * 32768, 0, this);
			if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
				trace_endpos = this.origin + v_forward * 1048576;
		}
	}
	if(this.scale != 0)
	{
		if(this.alpha)
		{
			Draw_CylindricLine(this.origin, trace_endpos, this.scale, "particles/laserbeam", 0, time * 3, this.colormod, this.alpha, DRAWFLAG_NORMAL, view_origin);
		}
		else
		{
			Draw_CylindricLine(this.origin, trace_endpos, this.scale, "particles/laserbeam", 0, time * 3, this.colormod, 0.5, DRAWFLAG_ADDITIVE, view_origin);
		}
	}
	if (!(trace_dphitq3surfaceflags & (Q3SURFACEFLAG_SKY | Q3SURFACEFLAG_NOIMPACT)))
	{
		if(this.cnt >= 0)
			__pointparticles(this.cnt, trace_endpos, trace_plane_normal, drawframetime * 1000);
		if(this.colormod != '0 0 0' && this.modelscale != 0)
			adddynamiclight(trace_endpos + trace_plane_normal * 1, this.modelscale, this.colormod * 5);
	}
}

NET_HANDLE(ENT_CLIENT_LASER, bool isnew)
{
	InterpolateOrigin_Undo(this);

	// 30 bytes, or 13 bytes for just moving
	int f = ReadByte();
	this.count = (f & 0xF0);

	if(this.count & 0x80)
		this.iflags = IFLAG_VELOCITY | IFLAG_ORIGIN;
	else
		this.iflags = IFLAG_ANGLES | IFLAG_ORIGIN;

	if(f & 1)
	{
		this.origin_x = ReadCoord();
		this.origin_y = ReadCoord();
		this.origin_z = ReadCoord();
		setorigin(this, this.origin);
	}
	if(f & 8)
	{
		this.colormod_x = ReadByte() / 255.0;
		this.colormod_y = ReadByte() / 255.0;
		this.colormod_z = ReadByte() / 255.0;
		if(f & 0x40)
			this.alpha = ReadByte() / 255.0;
		else
			this.alpha = 0;
		this.scale = 2;
		this.modelscale = 50;
		if(f & 0x20)
		{
			this.scale *= ReadByte() / 16.0; // beam radius
			this.modelscale *= ReadByte() / 16.0; // dlight radius
		}
		if((f & 0x80) || !(f & 0x10))
			this.cnt = ReadShort() - 1; // effect number
		else
			this.cnt = 0;
	}
	if(f & 2)
	{
		if(f & 0x80)
		{
			this.velocity_x = ReadCoord();
			this.velocity_y = ReadCoord();
			this.velocity_z = ReadCoord();
		}
		else
		{
			this.angles_x = ReadAngle();
			this.angles_y = ReadAngle();
		}
	}
	if(f & 4)
		this.state = ReadByte();

	return = true;

	InterpolateOrigin_Note(this);
	this.draw = Draw_Laser;
	if (isnew) IL_PUSH(g_drawables, this);
}
#endif
