#include "util.qh"

#ifdef SVQC

/*
* Update this.tur_shotorg by getting up2date bone info
* NOTICE this func overwrites the global v_forward, v_right and v_up vectors.
*/
float turret_tag_fire_update(entity this)
{
	if(!this.tur_head)
	{
		LOG_DEBUG("Call to turret_tag_fire_update with this.tur_head missing!");
		this.tur_shotorg = '0 0 0';
		return false;
	}

	this.tur_shotorg = gettaginfo(this.tur_head, gettagindex(this.tur_head, "tag_fire"));
	v_forward = normalize(v_forward);

	return true;
}

/*
* Railgun-like beam, but has thickness and suppots slowing of target
*/
void FireImoBeam(entity this, vector start, vector end, vector smin, vector smax,
				  float bforce, float f_dmg, float f_velfactor, int deathtype)

{
	vector hitloc, force, endpoint, dir;
	entity ent;

	dir = normalize(end - start);
	force = dir * bforce;

	// go a little bit into the wall because we need to hit this wall later
	end = end + dir;

	// trace multiple times until we hit a wall, each obstacle will be made unsolid.
	// note down which entities were hit so we can damage them later
	while (1)
	{
		tracebox(start, smin, smax, end, false, this);

		// if it is NULL we can't hurt it so stop now
		if (trace_ent == NULL || trace_fraction == 1)
			break;

		if (trace_ent.solid == SOLID_BSP)
			break;

		// make the entity non-solid so we can hit the next one
		trace_ent.railgunhit = true;
		trace_ent.railgunhitloc = end;
		trace_ent.railgunhitsolidbackup = trace_ent.solid;

		// stop if this is a wall

		// make the entity non-solid
		trace_ent.solid = SOLID_NOT;
	}

	endpoint = trace_endpos;

	// find all the entities the railgun hit and restore their solid state
	ent = findfloat(NULL, railgunhit, true);
	while (ent)
	{
		// restore their solid type
		ent.solid = ent.railgunhitsolidbackup;
		ent = findfloat(ent, railgunhit, true);
	}

	// find all the entities the railgun hit and hurt them
	ent = findfloat(NULL, railgunhit, true);
	while (ent)
	{
		// get the details we need to call the damage function
		hitloc = ent.railgunhitloc;
		ent.railgunhitloc = '0 0 0';
		ent.railgunhitsolidbackup = SOLID_NOT;
		ent.railgunhit = false;

		// apply the damage
		if (ent.takedamage)
		{
			Damage (ent, this, this, f_dmg, deathtype, DMG_NOWEP, hitloc, force);
			ent.velocity = ent.velocity * f_velfactor;
			//ent.alpha = 0.25 + random() * 0.75;
		}

		// advance to the next entity
		ent = findfloat(ent, railgunhit, true);
	}
	trace_endpos = endpoint;
}

#ifdef TURRET_DEBUG
void marker_think(entity this)
{
	if(this.cnt)
	if(this.cnt < time)
	{
		setthink(this, SUB_Remove);
		this.nextthink = time;
		return;
	}

	this.frame += 1;
	if(this.frame > 29)
		this.frame = 0;

	this.nextthink = time;
}

void mark_error(vector where,float lifetime)
{
	entity err = new(error_marker);
	setmodel(err, MDL_MARKER);
	setorigin(err, where);
	set_movetype(err, MOVETYPE_NONE);
	setthink(err, marker_think);
	err.nextthink = time;
	err.skin = 0;
	if(lifetime)
		err.cnt = lifetime + time;
}

void mark_info(vector where,float lifetime)
{
	entity err = new(info_marker);
	setmodel(err, MDL_MARKER);
	setorigin(err, where);
	set_movetype(err, MOVETYPE_NONE);
	setthink(err, marker_think);
	err.nextthink = time;
	err.skin = 1;
	if(lifetime)
		err.cnt = lifetime + time;
}

entity mark_misc(vector where,float lifetime)
{
	entity err = new(mark_misc);
	setmodel(err, MDL_MARKER);
	setorigin(err, where);
	set_movetype(err, MOVETYPE_NONE);
	setthink(err, marker_think);
	err.nextthink = time;
	err.skin = 3;
	if(lifetime)
		err.cnt = lifetime + time;
	return err;
}

MODEL(TUR_C512, "models/turrets/c512.md3");

/*
* Paint a v_color colord circle on target onwho
* that fades away over f_time
*/
void paint_target(entity onwho, float f_size, vector v_color, float f_time)
{
	entity e;

	e = spawn();
	setmodel(e, MDL_TUR_C512); // precision set above
	e.scale = (f_size/512);
	//setsize(e, '0 0 0', '0 0 0');
	//setattachment(e,onwho,"");
	setorigin(e, onwho.origin + '0 0 1');
	e.alpha = 0.15;
	set_movetype(e, MOVETYPE_FLY);

	e.velocity = (v_color * 32); // + '0 0 1' * 64;

	e.colormod = v_color;
	SUB_SetFade(e,time,f_time);
}

void paint_target2(entity onwho, float f_size, vector v_color, float f_time)
{
	entity e;

	e = spawn();
	setmodel(e, MDL_TUR_C512); // precision set above
	e.scale = (f_size/512);
	setsize(e, '0 0 0', '0 0 0');

	setorigin(e, onwho.origin + '0 0 1');
	e.alpha = 0.15;
	set_movetype(e, MOVETYPE_FLY);

	e.velocity = (v_color * 32); // + '0 0 1' * 64;
	e.avelocity_x = -128;

	e.colormod = v_color;
	SUB_SetFade(e,time,f_time);
}

void paint_target3(vector where, float f_size, vector v_color, float f_time)
{
	entity e;
	e = spawn();
	setmodel(e, MDL_TUR_C512); // precision set above
	e.scale = (f_size/512);
	setsize(e, '0 0 0', '0 0 0');
	setorigin(e, where + '0 0 1');
	set_movetype(e, MOVETYPE_NONE);
	e.velocity = '0 0 0';
	e.colormod = v_color;
	SUB_SetFade(e,time,f_time);
}
#endif

#endif
