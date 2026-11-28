#include "sv_keyhunt.qh"

#include "sv_key.qh"

#include <common/checkextension.qh>
#include <common/mapobjects/triggers.qh>
#include <common/mutators/mutator/nades/sv_nades.qh>
#include <server/command/vote.qh>
#include <server/gamelog.qh>
#include <server/damage.qh>
#include <server/items/items.qh>

float autocvar_g_balance_keyhunt_delay_round;
float autocvar_g_balance_keyhunt_delay_tracking;

vector autocvar_g_balance_keyhunt_carrier_damage;
vector autocvar_g_balance_keyhunt_carrier_force;
vector autocvar_g_balance_keyhunt_noncarrier_damage;
vector autocvar_g_balance_keyhunt_noncarrier_force;

int autocvar_g_balance_keyhunt_score_capture;
int autocvar_g_balance_keyhunt_score_carrierfrag;
int autocvar_g_balance_keyhunt_score_destroyed;
int autocvar_g_balance_keyhunt_score_destroyed_ownfactor;
int autocvar_g_balance_keyhunt_score_push;

//int autocvar_g_keyhunt_teams;
int autocvar_g_keyhunt_teams_override;

// TODO? no model exists for this
//#define KH_PLAYER_USE_CARRIEDMODEL

// kh_state
//     bits  0- 4: team of key 1, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits  5- 9: team of key 2, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits 10-14: team of key 3, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits 15-19: team of key 4, or 0 for no such key, or 30 for dropped, or 31 for self

bool kh_KeyStatuses_SendEntity(entity this, entity to, int sf)
{
	WriteHeader(MSG_ENTITY, ENT_CLIENT_KH_KEYSTATUSES);
	WriteByte(MSG_ENTITY, sf);
	if (sf & SF_KH_KEYS)
	{
		entity key;
		int keys = 0;
		FOR_EACH_KH_KEY(key)
			++keys;
		WriteByte(MSG_ENTITY, keys); // NOTE: should always be == team_count in CSQC, but that updates late (FIXME)
		FOR_EACH_KH_KEY(key)
		{
			if (key.owner) // for each owned key, network the ownership then the team index
			{
				WriteByte(MSG_ENTITY, etof(key.owner)); // won't be 0
				WriteByte(MSG_ENTITY, key.count); // key's actual team. 0 is red, etc.
			}
			else // ... otherwise just network 0 to indicate it has no owner
				WriteByte(MSG_ENTITY, 0);
		}
	}
	return true;
}

entity keyStatuses;
void kh_KeyStatuses_Init()
{
	if (keyStatuses)
	{
		backtrace("Can't spawn keyStatuses again!");
		return;
	}
	Net_LinkEntity(keyStatuses = new_pure(keyStatuses), false, 0, kh_KeyStatuses_SendEntity);
}

void kh_KeyStatuses_SendKeys()
{
	keyStatuses.SendFlags |= SF_KH_KEYS;
}

const int ST_KH_CAPS = 1;
void kh_ScoreRules(int teams)
{
	GameRules_scoring(teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY,
	{
		field_team(ST_KH_CAPS, "caps", SFL_SORT_PRIO_SECONDARY);
		field(SP_KH_CAPS, "caps", SFL_SORT_PRIO_SECONDARY);
		field(SP_KH_PUSHES, "pushes", 0);
		field(SP_KH_DESTRUCTIONS, "destructions", SFL_LOWER_IS_BETTER);
		field(SP_KH_PICKUPS, "pickups", 0);
		field(SP_KH_KCKILLS, "kckills", 0);
		field(SP_KH_LOSSES, "losses", SFL_LOWER_IS_BETTER);
	});
}

bool kh_KeyCarrier_waypointsprite_visible_for_player(entity this, entity player, entity view)  // runs all the time
{
	if (view.kh_next && IS_SPEC(player))
		return false; // we don't want spectators of key carriers to see the attached waypoint on the top of their screen
	if (IS_SPEC(player) || warmup_stage || SAME_TEAM(player, this.owner))
		return true;
	if (IS_INVISIBLE(this.owner))
		return false; // hide the waypointsprite if the owner is invisible

	return kh_tracking_enabled;
}

bool kh_Key_waypointsprite_visible_for_player(entity this, entity player, entity view)
{
	// always show the dropped key waypoint while in warmup or spectating
	if (this.owner && !this.owner.owner && (IS_SPEC(player) || warmup_stage))
		return true;
	if (!kh_tracking_enabled)
		return false;

	return !this.owner || !this.owner.owner; // draw only when key is not owned
}

entity kh_controller;
var kh_Think_t kh_Controller_Thinkfunc;
void kh_Controller_SetThink(float t, kh_Think_t func)  // runs occasionaly
{
	kh_Controller_Thinkfunc = func;
	kh_controller.cnt = ceil(t);
	if (t == 0)
		kh_controller.nextthink = time; // force
}
void kh_WaitForPlayers();
void kh_Controller_Think(entity this)  // called a lot
{
	if (game_stopped)
		return;
	if (this.cnt > 0)
	{
		if (getthink(this) != kh_WaitForPlayers)
			--this.cnt;
	}
	else if (this.cnt == 0)
	{
		--this.cnt;
		kh_Controller_Thinkfunc();
	}
	this.nextthink = time + 1;
}

// frags f: take from cvar * f
// frags 0: no frags
/// Field where the decimal part of SCORE is accumulated (shared with other gametypes)
.float float2int_decimal_fld;
/// Update the score when a key is captured
void kh_Scores_Event(entity player, entity key, string what, float frags_player, float frags_owner)
{
	if (game_stopped)
		return;

	if (frags_player)
		GameRules_scoring_add_team_float2int(player, SCORE, frags_player, float2int_decimal_fld, 1);

	if (key && key.owner && frags_owner)
		GameRules_scoring_add_team_float2int(key.owner, SCORE, frags_owner, float2int_decimal_fld, 1);

	if (!autocvar_sv_eventlog)  //output extra info to the console or text file
		return;

	string s = strcat(":keyhunt:", what, ":", itos(player.playerid), ":", ftos(frags_player));
	if (key && key.owner)
		s = strcat(s, ":", itos(key.owner.playerid));
	else
		s = strcat(s, ":0");
	s = strcat(s, ":", ftos(frags_owner), ":");
	if (key)
		s = strcat(s, key.netname);

	GameLogEcho(s);
}

/// Runs when a team captures the flag, it can run 2 or 3 times
vector kh_AttachedOrigin(entity e)
{
	if (e.tag_entity)
	{
		makevectors(e.tag_entity.angles);
		return e.tag_entity.origin + e.origin.x * v_forward - e.origin.y * v_right + e.origin.z * v_up;
	}
	return e.origin;
}

/// Runs when a team captures the keys
void kh_FinishRound()
{
	// prepare next round
	kh_interferemsg_time = 0;
	entity key;

	kh_no_radar_circles = true;
	FOR_EACH_KH_KEY(key)
		kh_Key_Remove(key);
	kh_no_radar_circles = false;

	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_KEYHUNT_ROUNDSTART, autocvar_g_balance_keyhunt_delay_round);
	kh_Controller_SetThink(autocvar_g_balance_keyhunt_delay_round, kh_StartRound);
	keyStatuses.SendFlags = SF_KH_RESET;
}

/// Runs when a team wins
void kh_WinnerTeam(int winner_team)
{
	// all key carriers get some points
	entity key;
	float score = (AVAILABLE_TEAMS - 1) * autocvar_g_balance_keyhunt_score_capture;
	DistributeEvenly_Init(score, AVAILABLE_TEAMS);
	// twice the score for 3 team games, three times the score for 4 team games!
	// note: for a win by destroying the key, this should NOT be applied
	FOR_EACH_KH_KEY(key)
	{
		float f = DistributeEvenly_Get(1);
		kh_Scores_Event(key.owner, key, "capture", f, 0);
		GameRules_scoring_add_team(key.owner, KH_CAPS, 1);
		nades_GiveBonus(key.owner, autocvar_g_nades_bonus_score_high);
	}

	bool first = true;
	string keyowner = "";
	FOR_EACH_KH_KEY(key)
		if (key.owner.kh_next == key)
		{
			if (!first)
				keyowner = strcat(keyowner, ", ");
			keyowner = key.owner.netname;
			first = false;
		}

	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(winner_team, CENTER_ROUND_TEAM_WIN));
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(winner_team, INFO_KEYHUNT_CAPTURE), keyowner);

	first = true;
	vector firstorigin = '0 0 0', lastorigin = '0 0 0', midpoint = '0 0 0';
	FOR_EACH_KH_KEY(key)
	{
		vector thisorigin = kh_AttachedOrigin(key);
		//dprint("Key origin: ", vtos(thisorigin), "\n");
		midpoint += thisorigin;

		if (!first)
		{
			// TODO: this effect has been replaced due to a possible crash it causes
			// see https://gitlab.com/xonotic/darkplaces/issues/123
			//te_lightning2(NULL, lastorigin, thisorigin);
			Send_Effect(EFFECT_TR_NEXUIZPLASMA, lastorigin, thisorigin, 1);
		}
		lastorigin = thisorigin;
		if (first)
			firstorigin = thisorigin;
		first = false;
	}
	if (AVAILABLE_TEAMS > 2)
	{
		//te_lightning2(NULL, lastorigin, firstorigin); // TODO see above
		Send_Effect(EFFECT_TR_NEXUIZPLASMA, lastorigin, firstorigin, 1);
	}
	midpoint = midpoint * (1 / AVAILABLE_TEAMS);
	te_customflash(midpoint, 1000, 1, Team_ColorRGB(winner_team) * 0.5 + '0.5 0.5 0.5');  // make the color >=0.5 in each component

	play2all(SND(KH_CAPTURE));
	kh_FinishRound();
}

// Runs when a player pushes a flag carrier off the map
void kh_LoserTeam(int loser_team, entity lostkey)
{
	float f;
	entity attacker = NULL;
	if (lostkey.pusher
	&&  lostkey.pusher.team != loser_team
	&& IS_PLAYER(lostkey.pusher))
		attacker = lostkey.pusher;

	if (attacker)
	{
		if (lostkey.previous_owner)
			kh_Scores_Event(lostkey.previous_owner, NULL, "pushed", 0, -autocvar_g_balance_keyhunt_score_push);
			// don't actually GIVE them the -nn points, just log
		kh_Scores_Event(attacker, NULL, "push", autocvar_g_balance_keyhunt_score_push, 0);
		GameRules_scoring_add(attacker, KH_PUSHES, 1);
		//centerprint(attacker, "Your push is the best!"); // does this really need to exist?
	}
	else
	{
		int players = 0;
		FOREACH_CLIENT(IS_PLAYER(it) && it.team != loser_team, ++players);

		entity key;
		int keys = 0;
		FOR_EACH_KH_KEY(key)
			if (key.owner && key.team != loser_team)
				++keys;

		if (lostkey.previous_owner)
			kh_Scores_Event(lostkey.previous_owner, NULL, "destroyed", 0, -autocvar_g_balance_keyhunt_score_destroyed);
			// don't actually GIVE them the -nn points, just log

		if (lostkey.previous_owner.playerid == lostkey.kh_previous_owner_playerid)
			GameRules_scoring_add(lostkey.previous_owner, KH_DESTRUCTIONS, 1);

		DistributeEvenly_Init(autocvar_g_balance_keyhunt_score_destroyed, keys * autocvar_g_balance_keyhunt_score_destroyed_ownfactor + players);

		FOR_EACH_KH_KEY(key)
			if (key.owner && key.team != loser_team)
			{
				f = DistributeEvenly_Get(autocvar_g_balance_keyhunt_score_destroyed_ownfactor);
				kh_Scores_Event(key.owner, NULL, "destroyed_holdingkey", f, 0);
			}

		int fragsleft = DistributeEvenly_Get(players);

		// Now distribute these among all other teams...
		int j = AVAILABLE_TEAMS - 1;
		for (int i = 0; i < AVAILABLE_TEAMS; ++i)
		{
			int thisteam = kh_Key_TeamByID(i);
			if (thisteam == loser_team) // bad boy, no cookie - this WILL happen
				continue;

			players = 0;
			FOREACH_CLIENT(IS_PLAYER(it) && it.team == thisteam, ++players);

			DistributeEvenly_Init(fragsleft, j);
			fragsleft = DistributeEvenly_Get(j - 1);
			DistributeEvenly_Init(DistributeEvenly_Get(1), players);

			FOREACH_CLIENT(IS_PLAYER(it) && it.team == thisteam,
			{
				f = DistributeEvenly_Get(1);
				kh_Scores_Event(it, NULL, "destroyed", f, 0);
			});

			--j;
		}
	}

	int realteam = kh_Key_TeamByID(lostkey.count);
	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(loser_team, CENTER_ROUND_TEAM_LOSS));
	if (attacker)
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_PUSHED), attacker.netname, lostkey.previous_owner.netname);
	else
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_DESTROYED), lostkey.previous_owner.netname);

	play2all(SND(KH_DESTROY));
	te_tarexplosion(lostkey.origin);

	kh_FinishRound();
}

int kh_GetMissingTeams()
{
	int missing_teams = 0;
	int tm, players;
	for (int i = 0; i < AVAILABLE_TEAMS; ++i)
	{
		tm = kh_Key_TeamByID(i);
		players = 0;
		FOREACH_CLIENT(IS_PLAYER(it),
		{
			if (!IS_DEAD(it) && !PHYS_INPUT_BUTTON_CHAT(it) && it.team == tm)
				++players;
		});
		if (!players)
			missing_teams |= BIT(i);
	}
	return missing_teams;
}

/// Delay start of the round until enough players are present
void kh_WaitForPlayers()
{
	missing_teams_mask = kh_GetMissingTeams();
	if (time < game_starttime)
	{
		kh_Controller_SetThink(game_starttime - time + 0.1, kh_WaitForPlayers);
		return;
	}

	if (!missing_teams_mask)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_KEYHUNT_ROUNDSTART, autocvar_g_balance_keyhunt_delay_round);
		kh_Controller_SetThink(autocvar_g_balance_keyhunt_delay_round, kh_StartRound);
	}
	else
		kh_Controller_SetThink(1, kh_WaitForPlayers);
}

/// Runs after each round
void kh_EnableTrackingDevice()
{
	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_KEYHUNT);
	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_KEYHUNT_OTHER);

	kh_tracking_enabled = true;
}

/// Runs at the start of each round
void kh_StartRound()
{
	if (time < game_starttime)
	{
		kh_Controller_SetThink(game_starttime - time + 0.1, kh_WaitForPlayers);
		return;
	}
	if (kh_GetMissingTeams())
	{
		kh_Controller_SetThink(1, kh_WaitForPlayers);
		return;
	}

	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_KEYHUNT);
	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_KEYHUNT_OTHER);

	entity my_player;
	int tm, players;
	for (int i = 0; i < AVAILABLE_TEAMS; ++i)
	{
		tm = kh_Key_TeamByID(i);
		players = 0;
		my_player = NULL;
		FOREACH_CLIENT(IS_PLAYER(it),
		{
			if (!IS_DEAD(it) && !PHYS_INPUT_BUTTON_CHAT(it) && it.team == tm)
			{
				++players;
				if (random() * players <= 1)
					my_player = it;
			}
		});
		kh_Key_Spawn(my_player, 360 * i / AVAILABLE_TEAMS, i, kh_Key_waypointsprite_visible_for_player);
	}

	kh_tracking_enabled = false;
	if (autocvar_g_balance_keyhunt_delay_tracking >= 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_KEYHUNT_SCAN, autocvar_g_balance_keyhunt_delay_tracking);
		kh_Controller_SetThink(autocvar_g_balance_keyhunt_delay_tracking, kh_EnableTrackingDevice);
	}
}

/// Adds to the player score
float kh_HandleFrags(entity attacker, entity targ, float f)
{
	if (attacker == targ)
		return f;

	if (targ.kh_next)
	{
		if (attacker.team == targ.team)
		{
			int nk = 0;
			for (entity k = targ.kh_next; k != NULL; k = k.kh_next)
				++nk;
			kh_Scores_Event(attacker, targ.kh_next, "carrierfrag", -nk * autocvar_g_balance_keyhunt_score_collect, 0);
		}
		else
		{
			kh_Scores_Event(attacker, targ.kh_next, "carrierfrag", autocvar_g_balance_keyhunt_score_carrierfrag-1, 0);
			GameRules_scoring_add(attacker, KH_KCKILLS, 1);
			// the frag gets added later
		}
	}

	return f;
}

/// Sets up th KH environment
void kh_Initialize()
{
	// setup variables
	int kh_teams = autocvar_g_keyhunt_teams_override;
	if (kh_teams < 2)
		kh_teams = cvar("g_keyhunt_teams"); // read the cvar directly as it gets written earlier in the same frame
	kh_teams = BITS(bound(2, kh_teams, 4));

	// use a temp entity to avoid linking kh_controller to the world with setmodel
	entity tmp_ent = spawn();
	setmodel(tmp_ent, MDL_KH_KEY);
	kh_key_dropped = tmp_ent.modelindex;

#ifdef KH_PLAYER_USE_CARRIEDMODEL
	setmodel(tmp_ent, MDL_KH_KEY_CARRIED);
	kh_key_carried = tmp_ent.modelindex;
#else
	kh_key_carried = kh_key_dropped;
#endif

	delete(tmp_ent);

	// make a KH entity for controlling the game
	kh_controller = new_pure(kh_controller);
	setthink(kh_controller, kh_Controller_Think);
	kh_Controller_SetThink(0, kh_WaitForPlayers);

	kh_ScoreRules(kh_teams);
	kh_KeyStatuses_Init();
}

/// To be called before intermission
void kh_finalize()
{
	kh_FinishRound();
	delete(kh_controller);
	kh_controller = NULL;
}

// legacy bot role

void(entity this) havocbot_role_kh_carrier;
void(entity this) havocbot_role_kh_defense;
void(entity this) havocbot_role_kh_offense;
void(entity this) havocbot_role_kh_freelancer;


bool kh_waypointsprite_visible_for_bot(entity this, entity e)
{
	entity key_wp = e.waypointsprite_attachedforcarrier;
	if (!key_wp // has no waypoint
	&&  !key_wp.waypointsprite_visible_for_player(key_wp, this, WaypointSprite_getviewentity(this)) // waypoint not visible
	&& !checkpvs(this.origin + this.view_ofs, e)) // key cannot be seen
		return false;

	return true;
}

void havocbot_goalrating_kh(entity this, float ratingscale_team, float ratingscale_dropped, float ratingscale_enemy)
{
	entity head;
	FOR_EACH_KH_KEY(head)
	{
		if (head.owner)
		{
			if (head.owner == this || !kh_waypointsprite_visible_for_bot(this, head.owner))
				continue;
			if (SAME_TEAM(head, this))
				navigation_routerating(this, head.owner, ratingscale_team * 10000, 100000);
			else
				navigation_routerating(this, head.owner, ratingscale_enemy * 10000, 100000);
		}
		else
		{
			if (!kh_waypointsprite_visible_for_bot(this, head))
				continue;
			navigation_routerating(this, head, ratingscale_dropped * 10000, 100000);
		}
	}

	havocbot_goalrating_items(this, 80000, this.origin, 10000);
}

void havocbot_role_kh_carrier(entity this)
{
	if (IS_DEAD(this))
		return;

	if (!(this.kh_next))
	{
		LOG_TRACE("changing role to freelancer");
		this.havocbot_role = havocbot_role_kh_freelancer;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		if (kh_Key_AllOwnedByWhichTeam() == this.team)
			havocbot_goalrating_kh(this, 10, 0.1, 0.05); // bring home
		else
			havocbot_goalrating_kh(this, 4, 4, 0.5); // play defensively

		navigation_goalrating_end(this);
		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_kh_defense(entity this)
{
	if (IS_DEAD(this))
		return;

	if (this.kh_next)
	{
		LOG_TRACE("changing role to carrier");
		this.havocbot_role = havocbot_role_kh_carrier;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 20; // + 10 to 30
	if (time > this.havocbot_role_timeout)
	{
		LOG_TRACE("changing role to freelancer");
		this.havocbot_role = havocbot_role_kh_freelancer;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		int key_owner_team = kh_Key_AllOwnedByWhichTeam();
		if (key_owner_team == this.team)
			havocbot_goalrating_kh(this, 10, 0.1, 0.05); // defend key carriers
		else if (key_owner_team == -1)
			havocbot_goalrating_kh(this, 4, 1, 0.05); // play defensively
		else
			havocbot_goalrating_kh(this, 0.1, 0.1, 5); // ATTACK ANYWAY

		navigation_goalrating_end(this);
		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_kh_offense(entity this)
{
	if (IS_DEAD(this))
		return;

	if (this.kh_next)
	{
		LOG_TRACE("changing role to carrier");
		this.havocbot_role = havocbot_role_kh_carrier;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 20; // + 10 to 30
	if (time > this.havocbot_role_timeout)
	{
		LOG_TRACE("changing role to freelancer");
		this.havocbot_role = havocbot_role_kh_freelancer;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		int key_owner_team = kh_Key_AllOwnedByWhichTeam();
		if (key_owner_team == this.team)
			havocbot_goalrating_kh(this, 10, 0.1, 0.05); // defend anyway
		else if (key_owner_team == -1)
			havocbot_goalrating_kh(this, 0.1, 1, 2); // play offensively
		else
			havocbot_goalrating_kh(this, 0.1, 0.1, 5); // ATTACK! EMERGENCY!

		navigation_goalrating_end(this);
		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_kh_freelancer(entity this)
{
	if (IS_DEAD(this))
		return;

	if (this.kh_next)
	{
		LOG_TRACE("changing role to carrier");
		this.havocbot_role = havocbot_role_kh_carrier;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 10; // + 0 to 20
	if (time > this.havocbot_role_timeout)
	{
		if (random() < 0.5)
		{
			LOG_TRACE("changing role to offense");
			this.havocbot_role = havocbot_role_kh_offense;
		}
		else
		{
			LOG_TRACE("changing role to defense");
			this.havocbot_role = havocbot_role_kh_defense;
		}
		this.havocbot_role_timeout = 0;
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		navigation_goalrating_start(this);

		int key_owner_team = kh_Key_AllOwnedByWhichTeam();
		if (key_owner_team == this.team)
			havocbot_goalrating_kh(this, 10, 0.1, 0.05); // defend anyway
		else if (key_owner_team == -1)
			havocbot_goalrating_kh(this, 1, 10, 2); // prefer dropped keys
		else
			havocbot_goalrating_kh(this, 0.1, 0.1, 5); // ATTACK ANYWAY

		navigation_goalrating_end(this);
		navigation_goalrating_timeout_set(this);
	}
}


// Mutator functions

// For changing damage and force values that are applied to players
MUTATOR_HOOKFUNCTION(kh, Damage_Calculate)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	// as a gametype rule, only apply scaling to player versus player combat
	if (!IS_PLAYER(frag_attacker) || !IS_PLAYER(frag_target))
		return;

	if (frag_attacker.kh_next != NULL) // if the attacker is a key carrier
	{
		if (frag_target == frag_attacker) // damage done to themselves
		{
			M_ARGV(4, float) *= autocvar_g_balance_keyhunt_carrier_damage.x;
			M_ARGV(6, vector) *= autocvar_g_balance_keyhunt_carrier_force.x;
		}
		else if (frag_target.kh_next != NULL) // damage done to other key carriers
		{
			M_ARGV(4, float) *= autocvar_g_balance_keyhunt_carrier_damage.y;
			M_ARGV(6, vector) *= autocvar_g_balance_keyhunt_carrier_force.y;
		}
		else // damage done to noncarriers
		{
			M_ARGV(4, float) *= autocvar_g_balance_keyhunt_carrier_damage.z;
			M_ARGV(6, vector) *= autocvar_g_balance_keyhunt_carrier_force.z;
		}
	}
	else
	{
		if (frag_target == frag_attacker) // damage done to themselves
		{
			M_ARGV(4, float) *= autocvar_g_balance_keyhunt_noncarrier_damage.x;
			M_ARGV(6, vector) *= autocvar_g_balance_keyhunt_noncarrier_force.x;
		}
		else if (frag_target.kh_next != NULL) // damage done to key carriers
		{
			M_ARGV(4, float) *= autocvar_g_balance_keyhunt_noncarrier_damage.y;
			M_ARGV(6, vector) *= autocvar_g_balance_keyhunt_noncarrier_force.y;
		}
		else // damage done to other noncarriers
		{
			M_ARGV(4, float) *= autocvar_g_balance_keyhunt_noncarrier_damage.z;
			M_ARGV(6, vector) *= autocvar_g_balance_keyhunt_noncarrier_force.z;
		}
	}
}

MUTATOR_HOOKFUNCTION(kh, ClientDisconnect)
{
	entity player = M_ARGV(0, entity);

	kh_Key_DropAll(player, true);
}

MUTATOR_HOOKFUNCTION(kh, MakePlayerObserver)
{
	entity player = M_ARGV(0, entity);

	kh_Key_DropAll(player, true);
}

MUTATOR_HOOKFUNCTION(kh, PlayerDies)
{
	entity frag_attacker = M_ARGV(1, entity);
	entity frag_target = M_ARGV(2, entity);

	if (frag_target == frag_attacker)
		kh_Key_DropAll(frag_target, true);
	else if (IS_PLAYER(frag_attacker))
		kh_Key_DropAll(frag_target, false);
	else
		kh_Key_DropAll(frag_target, true);
}

MUTATOR_HOOKFUNCTION(kh, GiveFragsForKill, CBC_ORDER_FIRST)
{
	entity frag_attacker = M_ARGV(0, entity);
	entity frag_target = M_ARGV(1, entity);
	float frag_score = M_ARGV(2, float);
	M_ARGV(2, float) = kh_HandleFrags(frag_attacker, frag_target, frag_score);
}

MUTATOR_HOOKFUNCTION(kh, MatchEnd)
{
	kh_finalize();
}

MUTATOR_HOOKFUNCTION(kh, PlayerUseKey)
{
	entity player = M_ARGV(0, entity);

	if (MUTATOR_RETURNVALUE == 0)
	{
		entity k = player.kh_next;
		if (k)
		{
			kh_Key_DropOne(k);
			return true;
		}
	}
}

MUTATOR_HOOKFUNCTION(kh, HavocBot_ChooseRole)
{
	entity bot = M_ARGV(0, entity);

	if (IS_DEAD(bot))
		return true;

	float r = random() * 3;
	if (r < 1)
		bot.havocbot_role = havocbot_role_kh_offense;
	else if (r < 2)
		bot.havocbot_role = havocbot_role_kh_defense;
	else
		bot.havocbot_role = havocbot_role_kh_freelancer;

	return true;
}

MUTATOR_HOOKFUNCTION(kh, LogDeath_AppendItemCodes)
{
	entity player = M_ARGV(0, entity);
	if (player.kh_next)
		M_ARGV(1, string) = strcat(M_ARGV(1, string), "K"); // item codes
}

MUTATOR_HOOKFUNCTION(kh, DropSpecialItems)
{
	entity frag_target = M_ARGV(0, entity);

	kh_Key_DropAll(frag_target, false);
}

MUTATOR_HOOKFUNCTION(kh, reset_map_global)
{
	kh_WaitForPlayers(); // takes care of killing the "missing teams" message
}

MUTATOR_HOOKFUNCTION(kh, PreferPlayerScore_Clear)
{
	return true;
}
