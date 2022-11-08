#include "accuracy.qh"

#include <common/constants.qh>
#include <common/net_linked.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <server/client.qh>
#include <server/damage.qh>
#include <server/mutators/_mod.qh>
#include <server/player.qh>
#include <server/world.qh>

int accuracy_byte(float n, float d)
{
	if (n <= 0) return 0;
	if (n > d) return 255;
	return 1 + rint(n * 100.0 / d);
}

bool accuracy_send(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_ACCURACY);

	entity a = this.owner;
	if (IS_SPEC(a)) a = a.enemy;
	a = CS(a).accuracy;

	if (to != a.owner)
		if (!autocvar_sv_accuracy_data_share && !CS_CVAR(a.owner).cvar_cl_accuracy_data_share)
			sf = 0;
	// note: zero sendflags can never be sent... so we can use that to say that we send no accuracy!
	WriteInt24_t(MSG_ENTITY, sf);
	if (sf == 0) return true;
	// note: we know that client and server agree about SendFlags...
	int f = 1;
	for (int w = 0; w <= WEP_LAST - WEP_FIRST; ++w) {
		if (sf & f) WriteByte(MSG_ENTITY, accuracy_byte(a.accuracy_hit[w], a.accuracy_fired[w]));
		f = (f == 0x800000) ? 1 : f * 2;
	}
	return true;
}

// init/free
void accuracy_init(entity e)
{
	entity a = CS(e).accuracy = new_pure(accuracy);
	a.owner = e;
	a.drawonlytoclient = e;
	Net_LinkEntity(a, false, 0, accuracy_send);
}

void accuracy_free(entity e)
{
	delete(CS(e).accuracy);
}

void accuracy_reset(entity e)
{
	entity a = CS(e).accuracy;
	if (!a) return;

	for (int i = 0; i < REGISTRY_MAX(Weapons); i++)
	{
		a.accuracy_frags[i] = 0;
		a.accuracy_hit[i] = 0;
		a.accuracy_fired[i] = 0;
		a.accuracy_cnt_hit[i] = 0;
		a.accuracy_cnt_fired[i] = 0;
	}
}

// force a resend of a player's accuracy stats
void accuracy_resend(entity e)
{
	CS(e).accuracy.SendFlags = 0xFFFFFF;
}

// update accuracy stats
//.float hit_time;
.float fired_time;

void accuracy_add(entity this, Weapon w, float fired, float hit)
{
	if (IS_INDEPENDENT_PLAYER(this)) return;
	entity a = CS(this).accuracy;
	if (!a) return;
	if (!hit && !fired) return;
	if (w == WEP_Null) return;
	int wepid = w.m_id;
	wepid -= WEP_FIRST;
	int b = accuracy_byte(a.accuracy_hit[wepid], a.accuracy_fired[wepid]);
	if (hit)    a.accuracy_hit  [wepid] += hit;
	if (fired)  a.accuracy_fired[wepid] += fired;

    if (hit && STAT(HIT_TIME, a) != time) { // only run this once per frame
        a.accuracy_cnt_hit[wepid] += 1;
        STAT(HIT_TIME, a) = time;
    }

    if (fired && a.fired_time != time) { // only run this once per frame
        a.accuracy_cnt_fired[wepid] += 1;
        a.fired_time = time;
    }

	if (b == accuracy_byte(a.accuracy_hit[wepid], a.accuracy_fired[wepid])) return; // no change
	int sf = 1 << (wepid % 24);
	a.SendFlags |= sf;
	FOREACH_CLIENT(IS_SPEC(it) && it.enemy == this, { CS(it).accuracy.SendFlags |= sf; });
}

bool accuracy_isgooddamage(entity attacker, entity targ)
{
	int mutator_check = MUTATOR_CALLHOOK(AccuracyTargetValid, attacker, targ);

	if (warmup_stage || game_stopped) return false;

	// damage to dead/frozen players is good only if it happens in the frame they get killed / frozen
	// so that stats for weapons that shoot multiple projectiles per shot are properly counted
	if (IS_DEAD(targ) && time > targ.death_time) return false;
	if (STAT(FROZEN, targ) && time > targ.freeze_time) return false;
	if (SAME_TEAM(attacker, targ)) return false;

	if (mutator_check == MUT_ACCADD_INVALID) return true;

	if (mutator_check != MUT_ACCADD_VALID) return false;
	if (!IS_CLIENT(targ) || !IS_CLIENT(attacker)) return false;

	return true;
}

bool accuracy_canbegooddamage(entity attacker)
{
	return !warmup_stage && IS_CLIENT(attacker);
}

REPLICATE(cvar_cl_accuracy_data_share, bool, "cl_accuracy_data_share");
REPLICATE(cvar_cl_accuracy_data_receive, bool, "cl_accuracy_data_receive");
