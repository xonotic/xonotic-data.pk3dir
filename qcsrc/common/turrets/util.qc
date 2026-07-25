#include "util.qh"

#ifdef SVQC

/**
* Update this.tur_shotorg by getting up2date bone info
* NOTICE this func overwrites the global v_forward, v_right and v_up vectors.
*/
float turret_tag_fire_update(entity this)
{
	if (!this.tur_head)
	{
		LOG_DEBUG("Call to turret_tag_fire_update with this.tur_head missing!");
		this.tur_shotorg = '0 0 0';
		return false;
	}

	this.tur_shotorg = gettaginfo(this.tur_head, gettagindex(this.tur_head, "tag_fire"));
	v_forward = normalize(v_forward);

	return true;
}

/// Railgun-like beam, but has thickness and suppots slowing of target
void FireImoBeam(entity this, vector start, vector end, vector smin, vector smax,
                 float bforce, float f_dmg, float f_velfactor, int deathtype)
{
	vector dir = normalize(end - start);
	vector force = dir * bforce;
	end += dir; // go a little bit into the wall because we need to hit this wall later

	// Trace multiple times until we hit a wall, each obstacle will be made non-solid.
	// Note down which entities were hit so we can damage them later
	entity o = this;
	do
	{
		WarpZone_tracebox_antilag(this, start, smin, smax, end, false, o, (CS(this).antilag_debug ? CS(this).antilag_debug : ANTILAG_LATENCY(this)));
		if (o && WarpZone_trace_firstzone)
		{
			o = NULL;
			continue;
		}

		// If it is NULL we can't hurt it so stop now
		if (trace_ent == NULL || trace_fraction == 1)
			break;

		// Make the entity non-solid so we can hit the next one
		IL_PUSH(g_railgunhit, trace_ent);
		trace_ent.railgunhit = true;
		trace_ent.railgunhitloc = trace_endpos;
		trace_ent.railgunhitsolidbackup = trace_ent.solid;
		trace_ent.railgundistance = vlen(WarpZone_UnTransformOrigin(WarpZone_trace_transform, trace_endpos) - start);
		trace_ent.railgunforce = WarpZone_TransformVelocity(WarpZone_trace_transform, force);

		if (trace_ent.solid == SOLID_BSP) // stop if this is a wall
			break;
		trace_ent.solid = SOLID_NOT; // make the entity non-solid
	}
	while (true);

	vector endpoint = trace_endpos;
	entity endent = trace_ent;
	float endq3surfaceflags = trace_dphitq3surfaceflags;

	// Find all the entities the trace hit and restore their solid state
	IL_EACH(g_railgunhit, it.railgunhit, it.solid = it.railgunhitsolidbackup);

	// Unlike the railgun, this does NOT check for targets close by

	// Find all the entities the trace hit and hurt them
	IL_EACH(g_railgunhit, it.railgunhit,
	{
		if (it.takedamage)
		{
			// Apply the damage
			// No falloff applied
			Damage(it, this, this, f_dmg, deathtype, DMG_NOWEP, it.railgunhitloc, it.railgunforce);
			// Slow down the target
			it.velocity *= f_velfactor;
		}

		// Reset fields before the list is cleared
		it.railgunhit = false;
		it.railgunhitloc = '0 0 0';
		it.railgunhitsolidbackup = SOLID_NOT;
		it.railgundistance = 0;
	});

	IL_CLEAR(g_railgunhit);

	// No accuracy, as a weapon entity is not attached

	trace_endpos = endpoint;
	trace_ent = endent;
	trace_dphitq3surfaceflags = endq3surfaceflags;
}

#ifdef TURRET_DEBUG
void marker_think(entity this)
{
	if (this.cnt && this.cnt < time)
	{
		setthink(this, SUB_Remove);
		this.nextthink = time;
		return;
	}

	++this.frame;
	if (this.frame > 29)
		this.frame = 0;

	this.nextthink = time;
}

void mark_error(vector where, float lifetime)
{
	entity err = new(error_marker);
	setmodel(err, MDL_MARKER);
	setorigin(err, where);
	set_movetype(err, MOVETYPE_NONE);
	setthink(err, marker_think);
	err.nextthink = time;
	err.skin = 0;
	if (lifetime)
		err.cnt = lifetime + time;
}

void mark_info(vector where, float lifetime)
{
	entity err = new(info_marker);
	setmodel(err, MDL_MARKER);
	setorigin(err, where);
	set_movetype(err, MOVETYPE_NONE);
	setthink(err, marker_think);
	err.nextthink = time;
	err.skin = 1;
	if (lifetime)
		err.cnt = lifetime + time;
}

entity mark_misc(vector where, float lifetime)
{
	entity err = new(mark_misc);
	setmodel(err, MDL_MARKER);
	setorigin(err, where);
	set_movetype(err, MOVETYPE_NONE);
	setthink(err, marker_think);
	err.nextthink = time;
	err.skin = 3;
	if (lifetime)
		err.cnt = lifetime + time;
	return err;
}

MODEL(TUR_C512, "models/turrets/c512.md3");

/// Paint a v_color colord circle on target onwho that fades away over f_time
void paint_target(entity onwho, float f_size, vector v_color, float f_time)
{
	entity e = spawn();
	setmodel(e, MDL_TUR_C512);
	e.scale = f_size / 512;
	//setsize(e, '0 0 0', '0 0 0');
	//setattachment(e, onwho, "");
	setorigin(e, onwho.origin + '0 0 1');
	e.alpha = 0.15;
	set_movetype(e, MOVETYPE_FLY);

	e.velocity = v_color * 32; // + '0 0 1' * 64;

	e.colormod = v_color;
	SUB_SetFade(e, time, f_time);
}

void paint_target2(entity onwho, float f_size, vector v_color, float f_time)
{
	entity e = spawn();
	setmodel(e, MDL_TUR_C512);
	e.scale = f_size / 512;
	setsize(e, '0 0 0', '0 0 0');

	setorigin(e, onwho.origin + '0 0 1');
	e.alpha = 0.15;
	set_movetype(e, MOVETYPE_FLY);

	e.velocity = v_color * 32; // + '0 0 1' * 64;
	e.avelocity.x = -128;

	e.colormod = v_color;
	SUB_SetFade(e, time, f_time);
}

void paint_target3(vector where, float f_size, vector v_color, float f_time)
{
	entity e = spawn();
	setmodel(e, MDL_TUR_C512);
	e.scale = f_size / 512;
	setsize(e, '0 0 0', '0 0 0');
	setorigin(e, where + '0 0 1');
	set_movetype(e, MOVETYPE_NONE);
	e.velocity = '0 0 0';
	e.colormod = v_color;
	SUB_SetFade(e, time, f_time);
}
#endif // TURRET_DEBUG

#endif // SVQC
