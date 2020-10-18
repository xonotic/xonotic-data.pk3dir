#include "laser.qh"
#if defined(CSQC)
	#include <lib/csqcmodel/interpolate.qh>
	#include <lib/csqcmodel/cl_model.qh>
#elif defined(MENUQC)
#elif defined(SVQC)
#endif

REGISTER_NET_LINKED(ENT_CLIENT_LASER)

#ifdef SVQC
void misc_laser_aim(entity this)
{
	vector a;
	if(this.enemy)
	{
		if(this.spawnflags & LASER_FINITE)
		{
			if(this.enemy.origin != this.mangle)
			{
				this.mangle = this.enemy.origin;
				this.SendFlags |= SF_LASER_UPDATE_TARGET;
			}
		}
		else
		{
			a = vectoangles(this.enemy.origin - this.origin);
			a_x = -a_x;
			if(a != this.mangle)
			{
				this.mangle = a;
				this.SendFlags |= SF_LASER_UPDATE_TARGET;
			}
		}
	}
	else
	{
		if(this.angles != this.mangle)
		{
			this.mangle = this.angles;
			this.SendFlags |= SF_LASER_UPDATE_TARGET;
		}
	}
	if(this.origin != this.oldorigin)
	{
		this.SendFlags |= SF_LASER_UPDATE_ORIGIN;
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

	if(this.active == ACTIVE_NOT)
		return;

	misc_laser_aim(this);

	if(this.enemy)
	{
		o = this.enemy.origin;
		if (!(this.spawnflags & LASER_FINITE))
			o = this.origin + normalize(o - this.origin) * LASER_BEAM_MAXLENGTH;
	}
	else
	{
		makevectors(this.mangle);
		o = this.origin + v_forward * LASER_BEAM_MAXLENGTH;
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
			if(((this.spawnflags & LASER_INVERT_TEAM) == 0) == (this.team != hitent.team))
				return;
		if(hitent.takedamage)
			Damage(hitent, this, this, ((this.dmg < 0) ? 100000 : (this.dmg * frametime)), DEATH_HURTTRIGGER.m_id, DMG_NOWEP, hitloc, '0 0 0');
	}
}

bool laser_SendEntity(entity this, entity to, float sendflags)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_LASER);
	sendflags = sendflags & 0x0F; // use that bit to indicate finite length laser
	if(this.spawnflags & LASER_FINITE)
		sendflags |= SF_LASER_FINITE;
	if(this.alpha)
		sendflags |= SF_LASER_ALPHA;
	if(this.scale != 1 || this.modelscale != 1)
		sendflags |= SF_LASER_SCALE;
	if(this.spawnflags & LASER_NOTRACE)
		sendflags |= SF_LASER_NOTRACE;
	WriteByte(MSG_ENTITY, sendflags);
	if(sendflags & SF_LASER_UPDATE_ORIGIN)
	{
		WriteVector(MSG_ENTITY, this.origin);
	}
	if(sendflags & SF_LASER_UPDATE_EFFECT)
	{
		WriteByte(MSG_ENTITY, this.beam_color.x * 255.0);
		WriteByte(MSG_ENTITY, this.beam_color.y * 255.0);
		WriteByte(MSG_ENTITY, this.beam_color.z * 255.0);
		if(sendflags & SF_LASER_ALPHA)
			WriteByte(MSG_ENTITY, this.alpha * 255.0);
		if(sendflags & SF_LASER_SCALE)
		{
			WriteByte(MSG_ENTITY, bound(0, this.scale * 16.0, 255));
			WriteByte(MSG_ENTITY, bound(0, this.modelscale * 16.0, 255));
		}
		if((sendflags & SF_LASER_FINITE) || !(sendflags & SF_LASER_NOTRACE)) // effect doesn't need sending if the laser is infinite and has collision testing turned off
			WriteShort(MSG_ENTITY, this.cnt);
	}
	if(sendflags & SF_LASER_UPDATE_TARGET)
	{
		if(sendflags & SF_LASER_FINITE)
		{
			WriteVector(MSG_ENTITY, this.enemy.origin);
		}
		else
		{
			WriteAngleVector2D(MSG_ENTITY, this.mangle);
		}
	}
	if(sendflags & SF_LASER_UPDATE_ACTIVE)
		WriteByte(MSG_ENTITY, this.active);
	return true;
}

/*QUAKED spawnfunc_misc_laser (.5 .5 .5) ? START_ON DEST_IS_FIXED
Any object touching the beam will be hurt
Keys:
"target"
 spawnfunc_target_position where the laser ends
"mdl"
 name of beam end effect to use
"beam_color"
 color of the beam (default: red)
"dmg"
 damage per second (-1 for a laser that kills immediately)
*/

void laser_setactive(entity this, int act)
{
	int old_status = this.active;
	if(act == ACTIVE_TOGGLE)
	{
		if(this.active == ACTIVE_ACTIVE)
		{
			this.active = ACTIVE_NOT;
		}
		else
		{
			this.active = ACTIVE_ACTIVE;
		}
	}
	else
	{
		this.active = act;
	}

	if (this.active != old_status)
	{
		this.SendFlags |= SF_LASER_UPDATE_ACTIVE;
		misc_laser_aim(this);
	}
}

void laser_use(entity this, entity actor, entity trigger)
{
	this.setactive(this, ACTIVE_TOGGLE);
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

	if(!this.beam_color && this.colormod)
	{
		LOG_WARN("misc_laser uses legacy field 'colormod', please use 'beam_color' instead");
		this.beam_color = this.colormod;
	}

	if(this.beam_color == '0 0 0')
	{
		if(!this.alpha)
			this.beam_color = '1 0 0';
	}

	if(this.message == "")
	{
		this.message = "saw the light";
	}
	if (this.message2 == "")
	{
		this.message2 = "was pushed into a laser by";
	}
	if(!this.scale)
	{
		this.scale = 1;
	}
	if(!this.modelscale)
	{
		this.modelscale = 1;
	}
	else if(this.modelscale < 0)
	{
		this.modelscale = 0;
	}
	setthink(this, misc_laser_think);
	this.nextthink = time;
	InitializeEntity(this, misc_laser_init, INITPRIO_FINDTARGET);

	this.mangle = this.angles;

	Net_LinkEntity(this, false, 0, laser_SendEntity);

	this.setactive = laser_setactive;

	if(this.targetname && this.targetname != "")
	{
		// backwards compatibility
		this.use = laser_use;
	}

	this.reset = generic_netlinked_reset;
	this.reset(this);
}
#elif defined(CSQC)

void Draw_Laser(entity this)
{
	if(this.active == ACTIVE_NOT)
		return;
	InterpolateOrigin_Do(this);
	if(this.count & SF_LASER_FINITE)
	{
		if(this.count & SF_LASER_NOTRACE)
		{
			trace_endpos = this.velocity;
			trace_dphitq3surfaceflags = 0;
		}
		else
			traceline(this.origin, this.velocity, 0, this);
	}
	else
	{
		if(this.count & SF_LASER_NOTRACE)
		{
			makevectors(this.angles);
			trace_endpos = this.origin + v_forward * LASER_BEAM_MAXWORLDSIZE;
			trace_dphitq3surfaceflags = Q3SURFACEFLAG_SKY;
		}
		else
		{
			makevectors(this.angles);
			traceline(this.origin, this.origin + v_forward * LASER_BEAM_MAXLENGTH, 0, this);
			if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY)
				trace_endpos = this.origin + v_forward * LASER_BEAM_MAXWORLDSIZE;
		}
	}
	if(this.scale != 0)
	{
		if(this.alpha)
		{
			Draw_CylindricLine(this.origin, trace_endpos, this.scale, "particles/laserbeam", 0, time * 3, this.beam_color, this.alpha, DRAWFLAG_NORMAL, view_origin);
		}
		else
		{
			Draw_CylindricLine(this.origin, trace_endpos, this.scale, "particles/laserbeam", 0, time * 3, this.beam_color, 0.5, DRAWFLAG_ADDITIVE, view_origin);
		}
	}
	if (!(trace_dphitq3surfaceflags & (Q3SURFACEFLAG_SKY | Q3SURFACEFLAG_NOIMPACT)))
	{
		if(this.cnt >= 0)
			__pointparticles(this.cnt, trace_endpos, trace_plane_normal, drawframetime * 1000);
		if(this.beam_color != '0 0 0' && this.modelscale != 0)
			adddynamiclight(trace_endpos + trace_plane_normal * 1, this.modelscale, this.beam_color * 5);
	}
}

NET_HANDLE(ENT_CLIENT_LASER, bool isnew)
{
	InterpolateOrigin_Undo(this);

	// 30 bytes, or 13 bytes for just moving
	int sendflags = ReadByte();
	this.count = (sendflags & 0xF0);

	if(this.count & SF_LASER_FINITE)
		this.iflags = IFLAG_VELOCITY | IFLAG_ORIGIN;
	else
		this.iflags = IFLAG_ANGLES | IFLAG_ORIGIN;

	if(sendflags & SF_LASER_UPDATE_ORIGIN)
	{
		this.origin = ReadVector();
		setorigin(this, this.origin);
	}
	if(sendflags & SF_LASER_UPDATE_EFFECT)
	{
		this.beam_color.x = ReadByte() / 255.0;
		this.beam_color.y = ReadByte() / 255.0;
		this.beam_color.z = ReadByte() / 255.0;
		if(sendflags & SF_LASER_ALPHA)
			this.alpha = ReadByte() / 255.0;
		else
			this.alpha = 0;
		this.scale = 2; // NOTE: why 2?
		this.modelscale = 50; // NOTE: why 50?
		if(sendflags & SF_LASER_SCALE)
		{
			this.scale *= ReadByte() / 16.0; // beam radius
			this.modelscale *= ReadByte() / 16.0; // dlight radius
		}
		if((sendflags & SF_LASER_FINITE) || !(sendflags & SF_LASER_NOTRACE))
			this.cnt = ReadShort(); // effect number
		else
			this.cnt = 0;
	}
	if(sendflags & SF_LASER_UPDATE_TARGET)
	{
		if(sendflags & SF_LASER_FINITE)
		{
			this.velocity = ReadVector();
		}
		else
		{
			this.angles = ReadAngleVector2D();
		}
	}
	if(sendflags & SF_LASER_UPDATE_ACTIVE)
		this.active = ReadByte();

	return = true;

	InterpolateOrigin_Note(this);
	this.draw = Draw_Laser;
	if (isnew) IL_PUSH(g_drawables, this);
}
#endif
