#include "aim.qh"

#include <common/physics/player.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/weapons/_all.qh>
#include <server/bot/default/bot.qh>
#include <server/bot/default/cvars.qh>
#include <server/mutators/_mod.qh>
#include <server/weapons/weaponsystem.qh>

// traces multiple trajectories to find one that will impact the target
// 'end' vector is the place it aims for,
// returns true only if it hit targ (don't target non-solid entities)

float findtrajectorywithleading(vector org, vector m1, vector m2, entity targ, float shotspeed, float shotspeedupward, float maxtime, float shotdelay, entity ignore)
{
	float c, savesolid, shottime;
	vector dir, end, v, o;
	if (shotspeed < 1)
		return false; // could cause division by zero if calculated
	if (targ.solid < SOLID_BBOX) // SOLID_NOT and SOLID_TRIGGER
		return false; // could never hit it
	if (!tracetossent)
		tracetossent = new(tracetossent);
	tracetossent.owner = ignore;
	setsize(tracetossent, m1, m2);
	savesolid = targ.solid;
	targ.solid = SOLID_NOT;
	o = (targ.absmin + targ.absmax) * 0.5;
	shottime = ((vlen(o - org) / shotspeed) + shotdelay);
	v = targ.velocity * shottime + o;
	tracebox(o, targ.mins, targ.maxs, v, false, targ);
	v = trace_endpos;
	end = v + (targ.mins + targ.maxs) * 0.5;
	float shotdistance = max(0.001, vlen(end - org));
	if ((shotdistance / shotspeed + 0.2) > maxtime)
	{
		// out of range
		targ.solid = savesolid;
		return false;
	}

	if (!tracetossfaketarget)
		tracetossfaketarget = new(tracetossfaketarget);
	tracetossfaketarget.solid = savesolid;
	set_movetype(tracetossfaketarget, targ.move_movetype);
	_setmodel(tracetossfaketarget, targ.model); // no low precision
	tracetossfaketarget.model = targ.model;
	tracetossfaketarget.modelindex = targ.modelindex;
	setsize(tracetossfaketarget, targ.mins, targ.maxs);
	setorigin(tracetossfaketarget, v);

	c = 0;
	// TODO: Consider changing this back to `/ shotdistance` after https://github.com/graphitemaster/gmqcc/issues/210.
	dir = (end - org) * (1 / shotdistance); // same as dir = normalize(end - org); but cheaper
	vector test_dir = dir;
	vector test_dir_normalized = dir;
	while (c < 10) // 10 traces
	{
		setorigin(tracetossent, org); // reset
		tracetossent.velocity = findtrajectory_velocity = test_dir_normalized * shotspeed + shotspeedupward * '0 0 1';
		tracetoss(tracetossent, ignore); // love builtin functions...
		if (trace_ent == tracetossfaketarget) // done
		{
			targ.solid = savesolid;

			// make it disappear
			tracetossfaketarget.solid = SOLID_NOT;
			set_movetype(tracetossfaketarget, MOVETYPE_NONE);
			tracetossfaketarget.model = "";
			tracetossfaketarget.modelindex = 0;
			// relink to remove it from physics considerations
			setorigin(tracetossfaketarget, v);

			return true;
		}
		test_dir.z += 0.1; // aim up a little more
		test_dir_normalized = normalize(test_dir);
		c = c + 1;
	}
	targ.solid = savesolid;

	// make it disappear
	tracetossfaketarget.solid = SOLID_NOT;
	set_movetype(tracetossfaketarget, MOVETYPE_NONE);
	tracetossfaketarget.model = "";
	tracetossfaketarget.modelindex = 0;
	// relink to remove it from physics considerations
	setorigin(tracetossfaketarget, v);

	// leave a valid one even if it won't reach
	findtrajectory_velocity = dir * shotspeed + shotspeedupward * '0 0 1';
	return false;
}

bool bot_shouldattack(entity this, entity targ)
{
	if (targ.team == this.team)
	{
		if (targ == this)
			return false;
		if (teamplay)
		if (targ.team != 0)
			return false;
	}

	if(teamplay)
	{
		if(targ.team==0)
			return false;
	}
	else if (autocvar_bot_ignore_bots && IS_BOT_CLIENT(targ))
		return false;

	if (!targ.takedamage)
		return false;
	if (IS_DEAD(targ))
		return false;
	if (PHYS_INPUT_BUTTON_CHAT(targ) && !autocvar_bot_typefrag)
		return false;
	if(targ.flags & FL_NOTARGET)
		return false;
	if(targ.alpha <= 0.1 && targ.alpha != 0)
		return false; // invisible via alpha

	if(MUTATOR_CALLHOOK(BotShouldAttack, this, targ))
		return false;

	return true;
}

// this function should be called after bot_aim so the aim is reset the next frame
void bot_aim_reset(entity this)
{
	this.bot_mouseaim = this.v_angle;
	this.bot_olddesiredang = this.v_angle;
	this.bot_aimdir_executed = true;
	this.bot_badaimtime = 0;
	this.bot_aimthinktime = time;
	this.bot_prevaimtime = time;
	this.bot_1st_order_aimfilter = '0 0 0';
	this.bot_2nd_order_aimfilter = '0 0 0';
	this.bot_3th_order_aimfilter = '0 0 0';
	this.bot_4th_order_aimfilter = '0 0 0';
	this.bot_5th_order_aimfilter = '0 0 0';
	this.bot_firetimer = 0;
}

void bot_aimdir(entity this, vector v, float maxfiredeviation)
{
	float dist, delta_t, blend;
	vector desiredang, diffang;

	this.bot_aimdir_executed = true;

	//dprint("aim ", this.netname, ": old:", vtos(this.v_angle));
	// make sure v_angle is sane first
	this.v_angle_y = this.v_angle.y - floor(this.v_angle.y / 360) * 360;
	this.v_angle_z = 0;

	// make work bot_aim_reset even if called before this function
	if (this.bot_prevaimtime == time)
		return;

	// if skill is high enough bots will not have any aim smoothing or aim errors
	if (SUPERBOT)
	{
		this.v_angle = vectoangles(normalize(v));

		this.v_angle.x *= -1;

		makevectors(this.v_angle);
		shotorg = this.origin + this.view_ofs;
		shotdir = v_forward;

		// bot will fire on the next tick
		this.bot_firetimer = time + 0.001;
		return;
	}

	// invalid aim dir (can happen when bot overlaps target)
	if(!v) return;

	float skill_save = skill;
	// allow turning in a more natural way when bot is walking
	if (!this.enemy)
		skill = max(4, skill);

	// get the desired angles to aim at
	//dprint(" at:", vtos(v));
	//v = normalize(v);
	//te_lightning2(NULL, this.origin + this.view_ofs, this.origin + this.view_ofs + v * 200);
	if (time >= this.bot_badaimtime)
	{
		this.bot_badaimtime = max(this.bot_badaimtime + 0.2 + 0.3 * random(), time);
		int f = bound(0, 1 - 0.1 * (skill + this.bot_offsetskill), 1);
		this.bot_badaimoffset = randomvec() * f * autocvar_bot_ai_aimskill_offset;
		this.bot_badaimoffset.x *= 0.7; // smaller vertical offset
	}
	float enemy_factor = ((this.enemy) ? 5 : 2);
	// apply enemy_factor every frame so that the bigger offset is applied instantly when the bot aims to a new target
	desiredang = vectoangles(v) + this.bot_badaimoffset * enemy_factor;
	//dprint(" desired:", vtos(desiredang));
	if (desiredang.x >= 180)
		desiredang.x = desiredang.x - 360;
	desiredang.x = bound(-90, 0 - desiredang.x, 90);
	desiredang.z = this.v_angle.z;
	//dprint(" / ", vtos(desiredang));

	//// pain throws off aim
	//if (this.bot_painintensity)
	//{
	//	// shake from pain
	//	desiredang = desiredang + randomvec() * this.bot_painintensity * 0.2;
	//}

	// calculate turn angles
	diffang = (desiredang - this.bot_olddesiredang);
	// wrap yaw turn
	diffang.y = diffang.y - floor(diffang.y / 360) * 360;
	if (diffang.y >= 180)
		diffang.y = diffang.y - 360;
	this.bot_olddesiredang = desiredang;
	//dprint(" diff:", vtos(diffang));

	delta_t = time-this.bot_prevaimtime;
	this.bot_prevaimtime = time;
	// Here we will try to anticipate the comming aiming direction
	this.bot_1st_order_aimfilter= this.bot_1st_order_aimfilter
		+ (diffang * (1 / delta_t)    - this.bot_1st_order_aimfilter) * bound(0, autocvar_bot_ai_aimskill_order_filter_1st,1);
	this.bot_2nd_order_aimfilter= this.bot_2nd_order_aimfilter
		+ (this.bot_1st_order_aimfilter - this.bot_2nd_order_aimfilter) * bound(0, autocvar_bot_ai_aimskill_order_filter_2nd,1);
	this.bot_3th_order_aimfilter= this.bot_3th_order_aimfilter
		+ (this.bot_2nd_order_aimfilter - this.bot_3th_order_aimfilter) * bound(0, autocvar_bot_ai_aimskill_order_filter_3th,1);
	this.bot_4th_order_aimfilter= this.bot_4th_order_aimfilter
		+ (this.bot_3th_order_aimfilter - this.bot_4th_order_aimfilter) * bound(0, autocvar_bot_ai_aimskill_order_filter_4th,1);
	this.bot_5th_order_aimfilter= this.bot_5th_order_aimfilter
		+ (this.bot_4th_order_aimfilter - this.bot_5th_order_aimfilter) * bound(0, autocvar_bot_ai_aimskill_order_filter_5th,1);

	//blend = (bound(0,skill,10)*0.1)*((1-bound(0,skill,10)*0.05) ** 2.5)*5.656854249; //Plot formule before changing !
	blend = bound(0,skill+this.bot_aimskill,10)*0.1;
	desiredang = desiredang + blend *
	(
		  this.bot_1st_order_aimfilter * autocvar_bot_ai_aimskill_order_mix_1st
		+ this.bot_2nd_order_aimfilter * autocvar_bot_ai_aimskill_order_mix_2nd
		+ this.bot_3th_order_aimfilter * autocvar_bot_ai_aimskill_order_mix_3th
		+ this.bot_4th_order_aimfilter * autocvar_bot_ai_aimskill_order_mix_4th
		+ this.bot_5th_order_aimfilter * autocvar_bot_ai_aimskill_order_mix_5th
	);
	desiredang.x = bound(-90, desiredang.x, 90);

	// calculate turn angles
	diffang = desiredang - this.bot_mouseaim;
	// wrap yaw turn
	diffang.y = diffang.y - floor(diffang.y / 360) * 360;
	if (diffang.y >= 180)
		diffang.y = diffang.y - 360;
	//dprint(" diff:", vtos(diffang));

	if (time >= this.bot_aimthinktime)
	{
		this.bot_aimthinktime = max(this.bot_aimthinktime + 0.5 - 0.05*(skill+this.bot_thinkskill), time);
		this.bot_mouseaim = this.bot_mouseaim + diffang * (1-random()*0.1*bound(1,10-(skill+this.bot_thinkskill),10));
	}

	//this.v_angle = this.v_angle + diffang * bound(0, r * frametime * (skill * 0.5 + 2), 1);

	diffang = this.bot_mouseaim - desiredang;
	// wrap yaw turn
	diffang.y = diffang.y - floor(diffang.y / 360) * 360;
	if (diffang.y >= 180)
		diffang.y = diffang.y - 360;
	desiredang = desiredang + diffang * bound(0,autocvar_bot_ai_aimskill_think,1);

	// calculate turn angles
	diffang = desiredang - this.v_angle;
	// wrap yaw turn
	diffang.y = diffang.y - floor(diffang.y / 360) * 360;
	if (diffang.y >= 180)
		diffang.y = diffang.y - 360;
	//dprint(" diff:", vtos(diffang));

	// jitter tracking
	dist = vlen(diffang);
	//diffang = diffang + randomvec() * (dist * 0.05 * (3.5 - bound(0, skill, 3)));

	// turn
	float r, fixedrate, blendrate;
	fixedrate = autocvar_bot_ai_aimskill_fixedrate / bound(1,dist,1000);
	blendrate = autocvar_bot_ai_aimskill_blendrate;
	r = max(fixedrate, blendrate);
	//this.v_angle = this.v_angle + diffang * bound(frametime, r * frametime * (2+skill*skill*0.05-random()*0.05*(10-skill)), 1);
	r = bound(delta_t, r * delta_t * (2 + ((skill + this.bot_mouseskill) ** 3) * 0.005 - random()), 1);
	this.v_angle += diffang * (r + (1 - r) * bound(0, 1 - autocvar_bot_ai_aimskill_mouse, 1));
	this.v_angle_z = 0;
	this.v_angle_y = this.v_angle.y - floor(this.v_angle.y / 360) * 360;
	//dprint(" turn:", vtos(this.v_angle));

	skill = skill_save;

	if (maxfiredeviation <= 0)
		return;

	if (!autocvar_bot_ai_aimskill_firetolerance)
	{
		this.bot_firetimer = time + 0.2;
		return;
	}

	makevectors(this.v_angle);
	shotorg = this.origin + this.view_ofs;
	shotdir = v_forward;

	// decide whether to fire this time
	// v is the calculated trajectory, shotdir is bot view direction
	// NOTE: checking if (v * shotdir > cos(maxfiredeviation * DEG2RAD)) would be cheaper
	// but it gets evaluated to true even if v and shotdir have nearly opposite direction
	vector deviation = vectoangles(v) - vectoangles(shotdir);
	while (deviation.x < -180) deviation.x += 360; while (deviation.x > 180) deviation.x -= 360;
	while (deviation.y < -180) deviation.y += 360; while (deviation.y > 180) deviation.y -= 360;
	if (fabs(deviation.x) < maxfiredeviation && fabs(deviation.y) < maxfiredeviation)
	{
		traceline(shotorg, shotorg + shotdir * 1000, false, NULL);
		if (vdist(trace_endpos - shotorg, <, 500 + 500 * bound(0, skill + this.bot_aggresskill, 10))
			|| random() * random() > bound(0, (skill + this.bot_aggresskill) * 0.05, 1))
		{
			this.bot_firetimer = time + bound(0.1, 0.5 - (skill + this.bot_aggresskill) * 0.05, 0.5);
		}
	}
}

vector bot_shotlead(vector targorigin, vector targvelocity, float shotspeed, float shotdelay)
{
	// Try to add code here that predicts gravity effect here, no clue HOW to though ... well not yet atleast...
	return targorigin + targvelocity * (shotdelay + vlen(targorigin - shotorg) / shotspeed);
}

bool bot_aim(entity this, .entity weaponentity, float shotspeed, float shotspeedupward, float maxshottime, bool applygravity, bool shot_accurate)
{
	float hf, distanceratio;
	vector v;
	hf = this.dphitcontentsmask;
	this.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_CORPSE;

	float speed_factor = W_WeaponSpeedFactor(this);
	shotspeed *= speed_factor;
	shotspeedupward *= speed_factor;
	if (!shotspeed)
	{
		LOG_TRACE("bot_aim: WARNING: weapon ", this.(weaponentity).m_weapon.m_name, " shotspeed is zero!");
		shotspeed = 1000000;
	}
	if (!maxshottime)
	{
		LOG_TRACE("bot_aim: WARNING: weapon ", this.(weaponentity).m_weapon.m_name, " maxshottime is zero!");
		maxshottime = 1;
	}
	makevectors(this.v_angle);
	shotorg = this.origin + this.view_ofs;
	shotdir = v_forward;
	vector enemy_org = (this.enemy.absmin + this.enemy.absmax) * 0.5;
	v = bot_shotlead(enemy_org, this.enemy.velocity, shotspeed, this.bot_aimlatency);

	// this formula was created starting from empiric values of distance and max hit angle
	// with a player as target (32 qu wide) from the center of it right in front of the bot
	//  distance: 32  50    75   100  150  200  300  400  500
	//   max ang: 44  24  15.1  10.5  6.5  4.9  3.1  2.3  1.8
	float dist = max(10, vlen(v - shotorg));
	float maxfiredeviation = 1000 / (dist - 9) - 0.35;

	float f = (shot_accurate) ? 1 : 1.6;
	f += bound(0, (10 - (skill + this.bot_aimskill)) * 0.3, 3);
	maxfiredeviation = min(90, maxfiredeviation * f);

	if (applygravity && this.enemy)
	{
		if (!findtrajectorywithleading(shotorg, '0 0 0', '0 0 0', this.enemy, shotspeed, shotspeedupward, maxshottime, 0, this))
		{
			this.dphitcontentsmask = hf;
			return false;
		}

		bot_aimdir(this, findtrajectory_velocity - shotspeedupward * '0 0 1', maxfiredeviation);
	}
	else
	{
		bot_aimdir(this, v - shotorg, maxfiredeviation);
		//dprint("AIM: ");dprint(vtos(enemy_org));dprint(" + ");dprint(vtos(this.enemy.velocity));dprint(" * ");dprint(ftos(this.bot_aimlatency + vlen(this.enemy.origin - shotorg) / shotspeed));dprint(" = ");dprint(vtos(v));dprint(" : aimdir = ");dprint(vtos(normalize(v - shotorg)));dprint(" : ");dprint(vtos(shotdir));dprint("\n");
		//traceline(shotorg, shotorg + shotdir * 10000, false, this);
		//if (trace_ent.takedamage)
		//if (trace_fraction < 1)
		//if (!bot_shouldattack(this, trace_ent))
		//	return false;
		traceline(shotorg, enemy_org, false, this);
		if (trace_fraction < 1)
		if (trace_ent != this.enemy)
		if (!bot_shouldattack(this, trace_ent))
		{
			this.dphitcontentsmask = hf;
			return false;
		}
	}

	if (time > this.bot_firetimer)
	{
		this.dphitcontentsmask = hf;
		return false;
	}

	//if (r > maxshottime * shotspeed)
	//	return false;
	this.dphitcontentsmask = hf;
	return true;
}
