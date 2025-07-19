#include "sv_weapon.qh"

void W_Nexball_Attack(Weapon thiswep, entity actor, .entity weaponentity, float t);
void W_Nexball_Attack2(Weapon thiswep, entity actor, .entity weaponentity);
vector trigger_push_calculatevelocity(vector org, entity tgt, float ht, entity pushed_entity);

METHOD(BallStealer, wr_think, void(BallStealer thiswep, entity actor, .entity weaponentity, int fire))
{
    TC(BallStealer, thiswep);
    if(fire & 1)
        if(weapon_prepareattack(thiswep, actor, weaponentity, false, autocvar_g_balance_nexball_primary_refire))
            if(autocvar_g_nexball_basketball_meter)
            {
                if(actor.ballcarried && !STAT(NB_METERSTART, actor))
                    STAT(NB_METERSTART, actor) = time;
                else
                    weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, autocvar_g_balance_nexball_primary_animtime, w_ready);
            }
            else
            {
                W_Nexball_Attack(thiswep, actor, weaponentity, -1);
                weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, autocvar_g_balance_nexball_primary_animtime, w_ready);
            }
    if(fire & 2)
        if(weapon_prepareattack(thiswep, actor, weaponentity, true, autocvar_g_balance_nexball_secondary_refire))
        {
            W_Nexball_Attack2(thiswep, actor, weaponentity);
            weapon_thinkf(actor, weaponentity, WFRAME_FIRE2, autocvar_g_balance_nexball_secondary_animtime, w_ready);
        }

    if(!(fire & 1) && STAT(NB_METERSTART, actor) && actor.ballcarried)
    {
        W_Nexball_Attack(thiswep, actor, weaponentity, time - STAT(NB_METERSTART, actor));
        // DropBall or stealing will set metertime back to 0
        weapon_thinkf(actor, weaponentity, WFRAME_FIRE1, autocvar_g_balance_nexball_primary_animtime, w_ready);
    }
}

METHOD(BallStealer, wr_setup, void(BallStealer this, entity actor, .entity weaponentity))
{
    TC(BallStealer, this);
    //weapon_setup(WEP_PORTO.m_id);
}

METHOD(BallStealer, wr_reload, void(entity thiswep, entity actor, .entity weaponentity))
{
    TC(BallStealer, thiswep);
}

METHOD(BallStealer, wr_checkammo1, bool(BallStealer this, entity actor, .entity weaponentity))
{
    TC(BallStealer, this);
    return true;
}

METHOD(BallStealer, wr_checkammo2, bool(BallStealer this, entity actor, .entity weaponentity))
{
    TC(BallStealer, this);
    return true;
}

void W_Nexball_Think(entity this)
{
	//dprint("W_Nexball_Think\n");
	//vector new_dir = steerlib_arrive(this.enemy.origin, 2500);
	vector new_dir = normalize(this.enemy.origin + '0 0 50' - this.origin);
	vector old_dir = normalize(this.velocity);
	float _speed = vlen(this.velocity);
	vector new_vel = normalize(old_dir + (new_dir * autocvar_g_nexball_safepass_turnrate)) * _speed;
	//vector new_vel = (new_dir * autocvar_g_nexball_safepass_turnrate

	this.velocity = new_vel;

	this.nextthink = time;
}

void W_Nexball_Touch(entity this, entity toucher)
{
	entity ball, attacker;
	attacker = this.owner;
	//this.think = func_null;
	//this.enemy = NULL;

	PROJECTILE_TOUCH(this, toucher);
	// TODO: mutator hook to prevent picking up objectives
	if(attacker.team != toucher.team || autocvar_g_nexball_basketball_teamsteal)
		if((ball = toucher.ballcarried) && !IS_DEAD(toucher) && (IS_PLAYER(attacker)))
		{
			toucher.velocity = toucher.velocity + normalize(this.velocity) * toucher.damageforcescale * autocvar_g_balance_nexball_secondary_force;
			UNSET_ONGROUND(toucher);
			if(!attacker.ballcarried && !IS_DEAD(attacker))
			{
				LogNB("stole", attacker);
				_sound(toucher, CH_TRIGGER, ball.noise2, VOL_BASE, ATTEN_NORM);

				if(SAME_TEAM(attacker, toucher) && time > CS(attacker).teamkill_complain)
				{
					CS(attacker).teamkill_complain = time + 5;
					CS(attacker).teamkill_soundtime = time + 0.4;
					CS(attacker).teamkill_soundsource = toucher;
				}

				GiveBall(attacker, toucher.ballcarried);
			}
		}
	delete(this);
}

void W_Nexball_Attack(Weapon thiswep, entity actor, .entity weaponentity, float t)
{
	entity ball;
	float mul, mi, ma;
	if(!(ball = actor.ballcarried))
		return;

	W_SetupShot(actor, weaponentity, false, 4, SND_NB_SHOOT1, CH_WEAPON_A, 0, WEP_PORTO.m_id); // TODO: use ballstealer weapon here? we don't want duplicates in the scoreboard
	tracebox(w_shotorg, BALL_MINS, BALL_MAXS, w_shotorg, MOVE_WORLDONLY, NULL);
	if(trace_startsolid)
	{
		if(STAT(NB_METERSTART, actor))
			STAT(NB_METERSTART, actor) = 0; // Shot failed, hide the power meter
		return;
	}

	//Calculate multiplier
	if(t < 0)
		mul = 1;
	else
	{
		mi = autocvar_g_nexball_basketball_meter_minpower;
		ma = max(mi, autocvar_g_nexball_basketball_meter_maxpower); // avoid confusion
		//One triangle wave period with 1 as max
		mul = 2 * (t % g_nexball_meter_period) / g_nexball_meter_period;
		if(mul > 1)
			mul = 2 - mul;
		mul = mi + (ma - mi) * mul; // range from the minimal power to the maximal power
	}

	DropBall(ball, w_shotorg, W_CalculateProjectileVelocity(actor, actor.velocity, w_shotdir * autocvar_g_balance_nexball_primary_speed * mul, false));


	//TODO: use the speed_up cvar too ??
}

void W_Nexball_Attack2(Weapon thiswep, entity actor, .entity weaponentity)
{
	if(actor.ballcarried.enemy)
	{
		entity _ball = actor.ballcarried;
		W_SetupShot(actor, weaponentity, false, 4, SND_NB_SHOOT1, CH_WEAPON_A, 0, WEP_PORTO.m_id | HITTYPE_SECONDARY); // TODO: use the ball stealer weapon here? probably don't want duplicates
		DropBall(_ball, w_shotorg, trigger_push_calculatevelocity(_ball.origin, _ball.enemy, 32, _ball));
		setthink(_ball, W_Nexball_Think);
		_ball.nextthink = time;
		return;
	}

	if(!autocvar_g_nexball_tackling)
		return;

	W_SetupShot(actor, weaponentity, false, 2, SND_NB_SHOOT2, CH_WEAPON_A, 0, WEP_PORTO.m_id);
	entity missile = new(ballstealer);

	missile.owner = actor;

	set_movetype(missile, MOVETYPE_FLY);
	PROJECTILE_MAKETRIGGER(missile);

	//setmodel(missile, "models/elaser.mdl");  // precision set below
	setsize(missile, '0 0 0', '0 0 0');
	setorigin(missile, w_shotorg);

	W_SetupProjVelocity_Basic(missile, autocvar_g_balance_nexball_secondary_speed, 0);
	missile.angles = vectoangles(missile.velocity);
	settouch(missile, W_Nexball_Touch);
	setthink(missile, SUB_Remove);
	missile.nextthink = time + autocvar_g_balance_nexball_secondary_lifetime; //FIXME: use a distance instead?

	missile.effects = EF_BRIGHTFIELD | EF_LOWPRECISION;
	missile.flags = FL_PROJECTILE;
	IL_PUSH(g_projectiles, missile);
	IL_PUSH(g_bot_dodge, missile);

	CSQCProjectile(missile, true, PROJECTILE_ELECTRO, true);
}
