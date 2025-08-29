#include "sv_keyhunt.qh"

#include <common/checkextension.qh>
#include <server/command/vote.qh>
#include <server/gamelog.qh>
#include <server/damage.qh>
#include <server/items/items.qh>
#include <common/mapobjects/triggers.qh>

float autocvar_g_balance_keyhunt_damageforcescale;
float autocvar_g_balance_keyhunt_delay_collect;
float autocvar_g_balance_keyhunt_delay_damage_return;
float autocvar_g_balance_keyhunt_delay_return;
float autocvar_g_balance_keyhunt_delay_round;
float autocvar_g_balance_keyhunt_delay_tracking;
float autocvar_g_balance_keyhunt_return_when_unreachable;
float autocvar_g_balance_keyhunt_dropvelocity;
float autocvar_g_balance_keyhunt_maxdist;
float autocvar_g_balance_keyhunt_protecttime;

vector autocvar_g_balance_keyhunt_carrier_damage;
vector autocvar_g_balance_keyhunt_carrier_force;
vector autocvar_g_balance_keyhunt_noncarrier_damage;
vector autocvar_g_balance_keyhunt_noncarrier_force;

int autocvar_g_balance_keyhunt_score_capture;
int autocvar_g_balance_keyhunt_score_carrierfrag;
int autocvar_g_balance_keyhunt_score_collect;
int autocvar_g_balance_keyhunt_score_destroyed;
int autocvar_g_balance_keyhunt_score_destroyed_ownfactor;
int autocvar_g_balance_keyhunt_score_push;
float autocvar_g_balance_keyhunt_throwvelocity;

//int autocvar_g_keyhunt_teams;
int autocvar_g_keyhunt_teams_override;

// #define KH_PLAYER_USE_ATTACHMENT
// TODO? no model exists for this
// #define KH_PLAYER_USE_CARRIEDMODEL

#ifdef KH_PLAYER_USE_ATTACHMENT
const vector KH_PLAYER_ATTACHMENT_DIST_ROTATED = '0 -4 0';
const vector KH_PLAYER_ATTACHMENT_DIST = '4 0 0';
const vector KH_PLAYER_ATTACHMENT = '0 0 0';
const vector KH_PLAYER_ATTACHMENT_ANGLES = '0 0 0';
const string KH_PLAYER_ATTACHMENT_BONE = "";
#else
const float KH_KEY_ZSHIFT = 22;
const float KH_KEY_XYDIST = 24;
const float KH_KEY_XYSPEED = 45;
#endif
const float KH_KEY_WP_ZSHIFT = 20;

const vector KH_KEY_MIN = '-25 -25 -46'; // 0.8.6 used '-10 -10 -46' with sv_legacy_bbox_expand 1 and FL_ITEM
const vector KH_KEY_MAX = '25 25 4';     // 0.8.6 used '10 10 3'     with sv_legacy_bbox_expand 1 and FL_ITEM
const float KH_KEY_BRIGHTNESS = 2;

bool kh_no_radar_circles;

// kh_state
//     bits  0- 4: team of key 1, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits  5- 9: team of key 2, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits 10-14: team of key 3, or 0 for no such key, or 30 for dropped, or 31 for self
//     bits 15-19: team of key 4, or 0 for no such key, or 30 for dropped, or 31 for self
.float siren_time;  // time delay the siren

int kh_Team_ByID(int t)
{
	if(t == 0) return NUM_TEAM_1;
	if(t == 1) return NUM_TEAM_2;
	if(t == 2) return NUM_TEAM_3;
	if(t == 3) return NUM_TEAM_4;
	return 0;
}

entity kh_controller;
int kh_teams;
int kh_interferemsg_team;
float kh_interferemsg_time;
.entity kh_next, kh_prev; // linked list
.float kh_droptime;
.int kh_dropperteam;
.entity previous_owner; // also used on ka balls
.int kh_previous_owner_playerid;

int kh_key_dropped, kh_key_carried;

int kh_Key_AllOwnedByWhichTeam();

const int ST_KH_CAPS = 1;
void kh_ScoreRules(int teams)
{
	GameRules_scoring(teams, SFL_SORT_PRIO_PRIMARY, SFL_SORT_PRIO_PRIMARY, {
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
	if(view.kh_next && IS_SPEC(player))
		return false; // we don't want spectators of key carriers to see the attached waypoint on the top of their screen
	if(IS_SPEC(player) || warmup_stage || SAME_TEAM(player, this.owner))
		return true;
	if(IS_INVISIBLE(this.owner))
		return false; // hide the waypointsprite if the owner is invisible

	return kh_tracking_enabled;
}

bool kh_Key_waypointsprite_visible_for_player(entity this, entity player, entity view)
{
	// always show the dropped key waypoint while in warmup or spectating
	if(this.owner && !this.owner.owner && (IS_SPEC(player) || warmup_stage))
		return true;
	if(!kh_tracking_enabled)
		return false;

	return !this.owner || !this.owner.owner; // draw only when key is not owned
}

void kh_update_state()
{
	entity key;
	int f;
	int s = 0;
	FOR_EACH_KH_KEY(key)
	{
		if(key.owner)
			f = key.team;
		else
			f = 30;
		s |= (32 ** key.count) * f;
	}

	FOREACH_CLIENT(true, { STAT(OBJECTIVE_STATUS, it) = s; });

	FOR_EACH_KH_KEY(key)
	{
		if(key.owner)
			STAT(OBJECTIVE_STATUS, key.owner) |= (32 ** key.count) * 31;
	}
	//print(ftos((nextent(NULL)).kh_state), "\n");
}




var kh_Think_t kh_Controller_Thinkfunc;
void kh_Controller_SetThink(float t, kh_Think_t func)  // runs occasionaly
{
	kh_Controller_Thinkfunc = func;
	kh_controller.cnt = ceil(t);
	if(t == 0)
		kh_controller.nextthink = time; // force
}
void kh_WaitForPlayers();
void kh_Controller_Think(entity this)  // called a lot
{
	if(game_stopped)
		return;
	if(this.cnt > 0)
	{
		if(getthink(this) != kh_WaitForPlayers)
			this.cnt -= 1;
	}
	else if(this.cnt == 0)
	{
		this.cnt -= 1;
		kh_Controller_Thinkfunc();
	}
	this.nextthink = time + 1;
}

// frags f: take from cvar * f
// frags 0: no frags
// field where the decimal part of SCORE is accumulated (shared with other gametypes)
.float float2int_decimal_fld;
void kh_Scores_Event(entity player, entity key, string what, float frags_player, float frags_owner)  // update the score when a key is captured
{
	string s;
	if(game_stopped)
		return;

	if(frags_player)
		GameRules_scoring_add_team_float2int(player, SCORE, frags_player, float2int_decimal_fld, 1);

	if(key && key.owner && frags_owner)
		GameRules_scoring_add_team_float2int(key.owner, SCORE, frags_owner, float2int_decimal_fld, 1);

	if(!autocvar_sv_eventlog)  //output extra info to the console or text file
		return;

	s = strcat(":keyhunt:", what, ":", ftos(player.playerid), ":", ftos(frags_player));

	if(key && key.owner)
		s = strcat(s, ":", ftos(key.owner.playerid));
	else
		s = strcat(s, ":0");

	s = strcat(s, ":", ftos(frags_owner), ":");

	if(key)
		s = strcat(s, key.netname);

	GameLogEcho(s);
}

vector kh_AttachedOrigin(entity e)  // runs when a team captures the flag, it can run 2 or 3 times.
{
	if(e.tag_entity)
	{
		makevectors(e.tag_entity.angles);
		return e.tag_entity.origin + e.origin.x * v_forward - e.origin.y * v_right + e.origin.z * v_up;
	}
	else
		return e.origin;
}

void kh_Key_Attach(entity key)  // runs when a player picks up a key and several times when a key is assigned to a player at the start of a round
{
	key.solid = SOLID_NOT; // before setorigin to prevent area grid linking
#ifdef KH_PLAYER_USE_ATTACHMENT
	entity first = key.owner.kh_next;
	if(key == first)
	{
		setattachment(key, key.owner, KH_PLAYER_ATTACHMENT_BONE);
		if(key.kh_next)
		{
			setattachment(key.kh_next, key, "");
			setorigin(key, key.kh_next.origin - 0.5 * KH_PLAYER_ATTACHMENT_DIST);
			setorigin(key.kh_next, KH_PLAYER_ATTACHMENT_DIST_ROTATED);
			key.kh_next.angles = '0 0 0';
		}
		else
			setorigin(key, KH_PLAYER_ATTACHMENT);
		key.angles = KH_PLAYER_ATTACHMENT_ANGLES;
	}
	else
	{
		setattachment(key, key.kh_prev, "");
		if(key.kh_next)
			setattachment(key.kh_next, key, "");
		setorigin(key, KH_PLAYER_ATTACHMENT_DIST_ROTATED);
		setorigin(first, first.origin - 0.5 * KH_PLAYER_ATTACHMENT_DIST);
		key.angles = '0 0 0';
	}
#else
	setattachment(key, key.owner, "");
	setorigin(key, '0 0 1' * KH_KEY_ZSHIFT);  // fixing x, y in think
	key.angles_y -= key.owner.angles.y;
#endif
	key.flags = 0;
	if(IL_CONTAINS(g_items, key))
		IL_REMOVE(g_items, key);
	set_movetype(key, MOVETYPE_NONE);
	key.team = key.owner.team;
	key.nextthink = time;
	key.damageforcescale = 0;
	key.takedamage = DAMAGE_NO;
	key.modelindex = kh_key_carried;
	navigation_dynamicgoal_unset(key);
}

void kh_Key_Detach(entity key) // runs every time a key is dropped or lost. Runs several times times when all the keys are captured
{
	key.solid = SOLID_TRIGGER; // before setorigin to ensure area grid linking
#ifdef KH_PLAYER_USE_ATTACHMENT
	entity first = key.owner.kh_next;
	if(key == first)
	{
		if(key.kh_next)
		{
			setattachment(key.kh_next, key.owner, KH_PLAYER_ATTACHMENT_BONE);
			setorigin(key.kh_next, key.origin + 0.5 * KH_PLAYER_ATTACHMENT_DIST);
			key.kh_next.angles = KH_PLAYER_ATTACHMENT_ANGLES;
		}
	}
	else
	{
		if(key.kh_next)
			setattachment(key.kh_next, key.kh_prev, "");
		setorigin(first, first.origin + 0.5 * KH_PLAYER_ATTACHMENT_DIST);
	}
	// in any case:
	setattachment(key, NULL, "");
	setorigin(key, key.owner.origin + '0 0 1' * (STAT(PL_MIN, key.owner).z - KH_KEY_MIN_z));
	key.angles = key.owner.angles;
#else
	setorigin(key, key.owner.origin + key.origin.z * '0 0 1');
	setattachment(key, NULL, "");
	key.angles_y += key.owner.angles.y;
#endif
	key.flags = FL_ITEM;
	if(!IL_CONTAINS(g_items, key))
		IL_PUSH(g_items, key);
	set_movetype(key, MOVETYPE_TOSS);
	nudgeoutofsolid_OrFallback(key); // a key has a bigger bbox than a player
	key.pain_finished = time + autocvar_g_balance_keyhunt_delay_return;
	key.damageforcescale = autocvar_g_balance_keyhunt_damageforcescale;
	key.takedamage = DAMAGE_YES;
	// let key.team stay
	key.modelindex = kh_key_dropped;
	navigation_dynamicgoal_set(key, key.owner);
	key.previous_owner = key.owner;
	key.kh_previous_owner_playerid = key.owner.playerid;
}

void kh_Key_AssignTo(entity key, entity player)  // runs every time a key is picked up or assigned. Runs prior to kh_key_attach
{
	if(key.owner == player)
		return;

	int ownerteam0 = kh_Key_AllOwnedByWhichTeam();

	if(key.owner)
	{
		kh_Key_Detach(key);

		// remove from linked list
		if(key.kh_next)
			key.kh_next.kh_prev = key.kh_prev;
		key.kh_prev.kh_next = key.kh_next;
		key.kh_next = NULL;
		key.kh_prev = NULL;

		if(key.owner.kh_next == NULL)
		{
			// No longer a key carrier
			if(!kh_no_radar_circles)
				WaypointSprite_Ping(key.owner.waypointsprite_attachedforcarrier);
			WaypointSprite_DetachCarrier(key.owner);
		}
	}

	key.owner = player;

	if(player)
	{
		// insert into linked list
		key.kh_next = player.kh_next;
		key.kh_prev = player;
		player.kh_next = key;
		if(key.kh_next)
			key.kh_next.kh_prev = key;

		kh_Key_Attach(key);

		if(key.kh_next == NULL)
		{
			// player is now a key carrier
			entity wp = WaypointSprite_AttachCarrier(WP_Null, player, RADARICON_FLAGCARRIER);
			wp.colormod = colormapPaletteColor(player.team - 1, 0);
			player.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = kh_KeyCarrier_waypointsprite_visible_for_player;
			WaypointSprite_UpdateRule(player.waypointsprite_attachedforcarrier, player.team, SPRITERULE_TEAMPLAY);
			if(player.team == NUM_TEAM_1)
				WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, WP_KeyCarrierRed, WP_KeyCarrierFriend, WP_KeyCarrierRed);
			else if(player.team == NUM_TEAM_2)
				WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, WP_KeyCarrierBlue, WP_KeyCarrierFriend, WP_KeyCarrierBlue);
			else if(player.team == NUM_TEAM_3)
				WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, WP_KeyCarrierYellow, WP_KeyCarrierFriend, WP_KeyCarrierYellow);
			else if(player.team == NUM_TEAM_4)
				WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, WP_KeyCarrierPink, WP_KeyCarrierFriend, WP_KeyCarrierPink);
			if(!kh_no_radar_circles)
				WaypointSprite_Ping(player.waypointsprite_attachedforcarrier);
		}
	}

	// moved that here, also update if there's no player
	kh_update_state();

	key.pusher = NULL;

	int ownerteam = kh_Key_AllOwnedByWhichTeam();
	if(ownerteam != ownerteam0)
	{
		entity k;
		if(ownerteam != -1)
		{
			kh_interferemsg_time = time + 0.2;
			kh_interferemsg_team = player.team;

			// audit all key carrier sprites, update them to "Run here"
			FOR_EACH_KH_KEY(k)
			{
				if (!k.owner) continue;
				entity first = WP_Null;
				FOREACH(Waypoints, it.netname == k.owner.waypointsprite_attachedforcarrier.model1, { first = it; break; });
				entity third = WP_Null;
				FOREACH(Waypoints, it.netname == k.owner.waypointsprite_attachedforcarrier.model3, { third = it; break; });
				WaypointSprite_UpdateSprites(k.owner.waypointsprite_attachedforcarrier, first, WP_KeyCarrierFinish, third);
			}
		}
		else
		{
			kh_interferemsg_time = 0;

			// audit all key carrier sprites, update them to "Key Carrier"
			FOR_EACH_KH_KEY(k)
			{
				if (!k.owner) continue;
				entity first = WP_Null;
				FOREACH(Waypoints, it.netname == k.owner.waypointsprite_attachedforcarrier.model1, { first = it; break; });
				entity third = WP_Null;
				FOREACH(Waypoints, it.netname == k.owner.waypointsprite_attachedforcarrier.model3, { third = it; break; });
				WaypointSprite_UpdateSprites(k.owner.waypointsprite_attachedforcarrier, first, WP_KeyCarrierFriend, third);
			}
		}
	}
}

void kh_Key_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if(this.owner)
		return;
	if(ITEM_DAMAGE_NEEDKILL(deathtype))
	{
		this.pain_finished = bound(time, time + autocvar_g_balance_keyhunt_delay_damage_return, this.pain_finished);
		return;
	}
	if(force == '0 0 0')
		return;
	if(time > this.pushltime)
		if(IS_PLAYER(attacker))
			this.team = attacker.team;
}

void kh_Key_Collect(entity key, entity player)  //a player picks up a dropped key
{
	sound(player, CH_TRIGGER, SND_KH_COLLECT, VOL_BASE, ATTEN_NORM);

	if(key.kh_dropperteam != player.team)
	{
		kh_Scores_Event(player, key, "collect", autocvar_g_balance_keyhunt_score_collect, 0);
		GameRules_scoring_add(player, KH_PICKUPS, 1);
	}
	key.kh_dropperteam = 0;
	int realteam = kh_Team_ByID(key.count);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_PICKUP), player.netname);

	kh_Key_AssignTo(key, player); // this also updates .kh_state
}

void kh_Key_Touch(entity this, entity toucher)  // runs many, many times when a key has been dropped and can be picked up
{
	if(game_stopped)
		return;

	if(this.owner) // already carried
		return;

	if(ITEM_TOUCH_NEEDKILL())
	{
		this.pain_finished = bound(time, time + autocvar_g_balance_keyhunt_delay_damage_return, this.pain_finished);
		return;
	}

	if (!IS_PLAYER(toucher))
		return;
	if(IS_DEAD(toucher))
		return;
	if(IS_INDEPENDENT_PLAYER(toucher))
		return;
	if(toucher == this.enemy)
		if(time < this.kh_droptime + autocvar_g_balance_keyhunt_delay_collect)
			return;  // you just dropped it!
	kh_Key_Collect(this, toucher);
}

void kh_Key_Remove(entity key)  // runs after when all the keys have been collected or when a key has been dropped for more than X seconds
{
	entity o = key.owner;
	kh_Key_AssignTo(key, NULL);
	if(o) // it was attached
		WaypointSprite_Kill(key.waypointsprite_attachedforcarrier);
	else // it was dropped
		WaypointSprite_DetachCarrier(key);

	// remove key from key list
	if (kh_worldkeylist == key)
		kh_worldkeylist = kh_worldkeylist.kh_worldkeynext;
	else
	{
		o = kh_worldkeylist;
		while (o)
		{
			if (o.kh_worldkeynext == key)
			{
				o.kh_worldkeynext = o.kh_worldkeynext.kh_worldkeynext;
				break;
			}
			o = o.kh_worldkeynext;
		}
	}

	delete(key);

	kh_update_state();
}

void kh_FinishRound()  // runs when a team captures the keys
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
}

void nades_GiveBonus(entity player, float score);

void kh_WinnerTeam(int winner_team)  // runs when a team wins
{
	// all key carriers get some points
	entity key;
	float score = (NumTeams(kh_teams) - 1) * autocvar_g_balance_keyhunt_score_capture;
	DistributeEvenly_Init(score, NumTeams(kh_teams));
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
		if(key.owner.kh_next == key)
		{
			if(!first)
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

		if(!first)
		{
			// TODO: this effect has been replaced due to a possible crash it causes
			// see https://gitlab.com/xonotic/darkplaces/issues/123
			//te_lightning2(NULL, lastorigin, thisorigin);
			Send_Effect(EFFECT_TR_NEXUIZPLASMA, lastorigin, thisorigin, 1);
		}
		lastorigin = thisorigin;
		if(first)
			firstorigin = thisorigin;
		first = false;
	}
	if(NumTeams(kh_teams) > 2)
	{
		//te_lightning2(NULL, lastorigin, firstorigin); // TODO see above
		Send_Effect(EFFECT_TR_NEXUIZPLASMA, lastorigin, firstorigin, 1);
	}
	midpoint = midpoint * (1 / NumTeams(kh_teams));
	te_customflash(midpoint, 1000, 1, Team_ColorRGB(winner_team) * 0.5 + '0.5 0.5 0.5');  // make the color >=0.5 in each component

	play2all(SND(KH_CAPTURE));
	kh_FinishRound();
}

void kh_LoserTeam(int loser_team, entity lostkey)  // runs when a player pushes a flag carrier off the map
{
	float f;
	entity attacker = NULL;
	if(lostkey.pusher)
		if(lostkey.pusher.team != loser_team)
			if(IS_PLAYER(lostkey.pusher))
				attacker = lostkey.pusher;

	if(attacker)
	{
		if(lostkey.previous_owner)
			kh_Scores_Event(lostkey.previous_owner, NULL, "pushed", 0, -autocvar_g_balance_keyhunt_score_push);
			// don't actually GIVE them the -nn points, just log
		kh_Scores_Event(attacker, NULL, "push", autocvar_g_balance_keyhunt_score_push, 0);
		GameRules_scoring_add(attacker, KH_PUSHES, 1);
		//centerprint(attacker, "Your push is the best!"); // does this really need to exist?
	}
	else
	{
		int players = 0;
		float of = autocvar_g_balance_keyhunt_score_destroyed_ownfactor;

		FOREACH_CLIENT(IS_PLAYER(it) && it.team != loser_team, { ++players; });

		entity key;
		int keys = 0;
		FOR_EACH_KH_KEY(key)
			if(key.owner && key.team != loser_team)
				++keys;

		if(lostkey.previous_owner)
			kh_Scores_Event(lostkey.previous_owner, NULL, "destroyed", 0, -autocvar_g_balance_keyhunt_score_destroyed);
			// don't actually GIVE them the -nn points, just log

		if(lostkey.previous_owner.playerid == lostkey.kh_previous_owner_playerid)
			GameRules_scoring_add(lostkey.previous_owner, KH_DESTRUCTIONS, 1);

		DistributeEvenly_Init(autocvar_g_balance_keyhunt_score_destroyed, keys * of + players);

		FOR_EACH_KH_KEY(key)
			if(key.owner && key.team != loser_team)
			{
				f = DistributeEvenly_Get(of);
				kh_Scores_Event(key.owner, NULL, "destroyed_holdingkey", f, 0);
			}

		int fragsleft = DistributeEvenly_Get(players);

		// Now distribute these among all other teams...
		int j = NumTeams(kh_teams) - 1;
		for(int i = 0; i < NumTeams(kh_teams); ++i)
		{
			int thisteam = kh_Team_ByID(i);
			if(thisteam == loser_team) // bad boy, no cookie - this WILL happen
				continue;

			players = 0;
			FOREACH_CLIENT(IS_PLAYER(it) && it.team == thisteam, { ++players; });

			DistributeEvenly_Init(fragsleft, j);
			fragsleft = DistributeEvenly_Get(j - 1);
			DistributeEvenly_Init(DistributeEvenly_Get(1), players);

			FOREACH_CLIENT(IS_PLAYER(it) && it.team == thisteam, {
				f = DistributeEvenly_Get(1);
				kh_Scores_Event(it, NULL, "destroyed", f, 0);
			});

			--j;
		}
	}

	int realteam = kh_Team_ByID(lostkey.count);
	Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, APP_TEAM_NUM(loser_team, CENTER_ROUND_TEAM_LOSS));
	if(attacker)
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_PUSHED), attacker.netname, lostkey.previous_owner.netname);
	else
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_DESTROYED), lostkey.previous_owner.netname);

	play2all(SND(KH_DESTROY));
	te_tarexplosion(lostkey.origin);

	kh_FinishRound();
}

void kh_Key_Think(entity this)  // runs all the time
{
	if(game_stopped)
		return;

	if(this.owner)
	{
#ifndef KH_PLAYER_USE_ATTACHMENT
		makevectors('0 1 0' * (this.cnt + (time % 360) * KH_KEY_XYSPEED));
		setorigin(this, v_forward * KH_KEY_XYDIST + '0 0 1' * this.origin.z);
#endif
	}

	// if in nodrop or time over, end the round
	if(!this.owner)
		if(time > this.pain_finished)
			kh_LoserTeam(this.team, this);

	if(this.owner)
	if(kh_Key_AllOwnedByWhichTeam() != -1)
	{
		if(this.siren_time < time)
		{
			sound(this.owner, CH_TRIGGER, SND_KH_ALARM, VOL_BASE, ATTEN_NORM);  // play a simple alarm
			this.siren_time = time + 2.5;  // repeat every 2.5 seconds
		}

		entity key;
		vector p = this.owner.origin;
		FOR_EACH_KH_KEY(key)
			if(vdist(key.owner.origin - p, >, autocvar_g_balance_keyhunt_maxdist))
				goto not_winning;
		kh_WinnerTeam(this.team);
LABEL(not_winning)
	}

	if(kh_interferemsg_time && time > kh_interferemsg_time)
	{
		kh_interferemsg_time = 0;
		FOREACH_CLIENT(IS_PLAYER(it), {
			if(it.team == kh_interferemsg_team)
			{
				if(it.kh_next)
					Send_Notification(NOTIF_ONE, it, MSG_CENTER, CENTER_KEYHUNT_MEET);
				else
					Send_Notification(NOTIF_ONE, it, MSG_CENTER, CENTER_KEYHUNT_HELP);
			}
			else
				Send_Notification(NOTIF_ONE, it, MSG_CENTER, APP_TEAM_NUM(kh_interferemsg_team, CENTER_KEYHUNT_INTERFERE));
		});
	}

	this.nextthink = time + 0.05;
}

void key_reset(entity this)
{
	kh_Key_AssignTo(this, NULL);
	kh_Key_Remove(this);
}

void kh_Key_Spawn(entity initial_owner, float _angle, float i)  // runs every time a new flag is created, ie after all the keys have been collected
{
	entity key = new(item_kh_key);
	key.count = i;
	settouch(key, kh_Key_Touch);
	setthink(key, kh_Key_Think);
	key.nextthink = time;
	key.cnt = _angle;
	key.angles = '0 360 0' * random();
	key.event_damage = kh_Key_Damage;
	key.takedamage = DAMAGE_YES;
	key.damagedbytriggers = autocvar_g_balance_keyhunt_return_when_unreachable;
	key.damagedbycontents = autocvar_g_balance_keyhunt_return_when_unreachable;
	key.modelindex = kh_key_dropped;
	key.model = "key";
	key.kh_dropperteam = 0;
	key.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY | DPCONTENTS_PLAYERCLIP | DPCONTENTS_BOTCLIP;
	setsize(key, KH_KEY_MIN, KH_KEY_MAX);
	key.colormod = Team_ColorRGB(initial_owner.team) * KH_KEY_BRIGHTNESS;
	key.reset = key_reset;
	navigation_dynamicgoal_init(key, false);

	switch(initial_owner.team)
	{
		case NUM_TEAM_1:
			key.netname = "^1red key";
			break;
		case NUM_TEAM_2:
			key.netname = "^4blue key";
			break;
		case NUM_TEAM_3:
			key.netname = "^3yellow key";
			break;
		case NUM_TEAM_4:
			key.netname = "^6pink key";
			break;
		default:
			key.netname = "NETGIER key";
			break;
	}

	// link into key list
	key.kh_worldkeynext = kh_worldkeylist;
	kh_worldkeylist = key;

	Send_Notification(NOTIF_ONE, initial_owner, MSG_CENTER, APP_TEAM_NUM(initial_owner.team, CENTER_KEYHUNT_START));

	WaypointSprite_Spawn(WP_KeyDropped, 0, 0, key, '0 0 1' * KH_KEY_WP_ZSHIFT, NULL, key.team, key, waypointsprite_attachedforcarrier, false, RADARICON_FLAG);
	key.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = kh_Key_waypointsprite_visible_for_player;

	kh_Key_AssignTo(key, initial_owner);
}

// -1 when no team completely owns all keys yet
int kh_Key_AllOwnedByWhichTeam()  // constantly called. check to see if all the keys are owned by the same team
{
	entity key;
	int teem = -1;
	int keys = NumTeams(kh_teams);
	FOR_EACH_KH_KEY(key)
	{
		if(!key.owner)
			return -1;
		if(teem == -1)
			teem = key.team;
		else if(teem != key.team)
			return -1;
		--keys;
	}
	if(keys != 0)
		return -1;
	return teem;
}

void kh_Key_DropOne(entity key)
{
	// prevent collecting this one for some time
	entity player = key.owner;

	key.kh_droptime = time;
	key.enemy = player;

	kh_Scores_Event(player, key, "dropkey", 0, 0);
	GameRules_scoring_add(player, KH_LOSSES, 1);
	int realteam = kh_Team_ByID(key.count);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_DROP), player.netname);

	kh_Key_AssignTo(key, NULL);
	makevectors(player.v_angle);
	key.velocity = W_CalculateProjectileVelocity(player, player.velocity, autocvar_g_balance_keyhunt_throwvelocity * v_forward, false);
	key.pusher = NULL;
	key.pushltime = time + autocvar_g_balance_keyhunt_protecttime;
	key.kh_dropperteam = key.team;

	sound(player, CH_TRIGGER, SND_KH_DROP, VOL_BASE, ATTEN_NORM);
}

void kh_Key_DropAll(entity player, float suicide) // runs whenever a player dies
{
	if(player.kh_next)
	{
		entity mypusher = NULL;
		if(player.pusher)
			if(time < player.pushltime)
				mypusher = player.pusher;

		entity key;
		while((key = player.kh_next))
		{
			kh_Scores_Event(player, key, "losekey", 0, 0);
			GameRules_scoring_add(player, KH_LOSSES, 1);
			int realteam = kh_Team_ByID(key.count);
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_LOST), player.netname);
			kh_Key_AssignTo(key, NULL);
			makevectors('-1 0 0' * (45 + 45 * random()) + '0 360 0' * random());
			key.velocity = W_CalculateProjectileVelocity(player, player.velocity, autocvar_g_balance_keyhunt_dropvelocity * v_forward, false);
			key.pusher = mypusher;
			key.pushltime = time + autocvar_g_balance_keyhunt_protecttime;
			if(suicide)
				key.kh_dropperteam = player.team;
		}
		sound(player, CH_TRIGGER, SND_KH_DROP, VOL_BASE, ATTEN_NORM);
	}
}

int kh_GetMissingTeams()
{
	int missing_teams = 0;
	for(int i = 0; i < NumTeams(kh_teams); ++i)
	{
		int teem = kh_Team_ByID(i);
		int players = 0;
		FOREACH_CLIENT(IS_PLAYER(it), {
			if(!IS_DEAD(it) && !PHYS_INPUT_BUTTON_CHAT(it) && it.team == teem)
				++players;
		});
		if (!players)
			missing_teams |= BIT(i);
	}
	return missing_teams;
}

void kh_WaitForPlayers()  // delay start of the round until enough players are present
{
	static int prev_missing_teams_mask;
	if(time < game_starttime)
	{
		if (prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		kh_Controller_SetThink(game_starttime - time + 0.1, kh_WaitForPlayers);
		return;
	}

	int missing_teams_mask = kh_GetMissingTeams();
	if(!missing_teams_mask)
	{
		if(prev_missing_teams_mask > 0)
			Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
		prev_missing_teams_mask = -1;
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_KEYHUNT_ROUNDSTART, autocvar_g_balance_keyhunt_delay_round);
		kh_Controller_SetThink(autocvar_g_balance_keyhunt_delay_round, kh_StartRound);
	}
	else
	{
		if(player_count == 0)
		{
			if(prev_missing_teams_mask > 0)
				Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_TEAMS);
			prev_missing_teams_mask = -1;
		}
		else
		{
			if(prev_missing_teams_mask != missing_teams_mask)
			{
				Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_MISSING_TEAMS, missing_teams_mask);
				prev_missing_teams_mask = missing_teams_mask;
			}
		}
		kh_Controller_SetThink(1, kh_WaitForPlayers);
	}
}

void kh_EnableTrackingDevice()  // runs after each round
{
	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_KEYHUNT);
	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_KEYHUNT_OTHER);

	kh_tracking_enabled = true;
}

void kh_StartRound()  // runs at the start of each round
{
	if(time < game_starttime)
	{
		kh_Controller_SetThink(game_starttime - time + 0.1, kh_WaitForPlayers);
		return;
	}

	if(kh_GetMissingTeams())
	{
		kh_Controller_SetThink(1, kh_WaitForPlayers);
		return;
	}

	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_KEYHUNT);
	Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_KEYHUNT_OTHER);

	for(int i = 0; i < NumTeams(kh_teams); ++i)
	{
		int teem = kh_Team_ByID(i);
		int players = 0;
		entity my_player = NULL;
		FOREACH_CLIENT(IS_PLAYER(it), {
			if(!IS_DEAD(it) && !PHYS_INPUT_BUTTON_CHAT(it) && it.team == teem)
			{
				++players;
				if(random() * players <= 1)
					my_player = it;
			}
		});
		kh_Key_Spawn(my_player, 360 * i / NumTeams(kh_teams), i);
	}

	kh_tracking_enabled = false;
	if(autocvar_g_balance_keyhunt_delay_tracking >= 0)
	{
		Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_KEYHUNT_SCAN, autocvar_g_balance_keyhunt_delay_tracking);
		kh_Controller_SetThink(autocvar_g_balance_keyhunt_delay_tracking, kh_EnableTrackingDevice);
	}
}

float kh_HandleFrags(entity attacker, entity targ, float f)  // adds to the player score
{
	if(attacker == targ)
		return f;

	if(targ.kh_next)
	{
		if(attacker.team == targ.team)
		{
			int nk = 0;
			for(entity k = targ.kh_next; k != NULL; k = k.kh_next)
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

void kh_Initialize()  // sets up th KH environment
{
	// setup variables
	kh_teams = autocvar_g_keyhunt_teams_override;
	if(kh_teams < 2)
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
}

void kh_finalize()
{
	// to be called before intermission
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
	if (!key_wp)
	if (!key_wp.waypointsprite_visible_for_player(key_wp, this, WaypointSprite_getviewentity(this)))
	{ // has no waypoint, or waypoint not visible
		if (!checkpvs(this.origin + this.view_ofs, e)) // key cannot be seen
			return false;
	}
	return true;
}

void havocbot_goalrating_kh(entity this, float ratingscale_team, float ratingscale_dropped, float ratingscale_enemy)
{
	for (entity head = kh_worldkeylist; head; head = head.kh_worldkeynext)
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
	if(IS_DEAD(this))
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

		if(kh_Key_AllOwnedByWhichTeam() == this.team)
			havocbot_goalrating_kh(this, 10, 0.1, 0.05); // bring home
		else
			havocbot_goalrating_kh(this, 4, 4, 0.5); // play defensively

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_kh_defense(entity this)
{
	if(IS_DEAD(this))
		return;

	if (this.kh_next)
	{
		LOG_TRACE("changing role to carrier");
		this.havocbot_role = havocbot_role_kh_carrier;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 20;
	if (time > this.havocbot_role_timeout)
	{
		LOG_TRACE("changing role to freelancer");
		this.havocbot_role = havocbot_role_kh_freelancer;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		float key_owner_team;
		navigation_goalrating_start(this);

		key_owner_team = kh_Key_AllOwnedByWhichTeam();
		if(key_owner_team == this.team)
			havocbot_goalrating_kh(this, 10, 0.1, 0.05); // defend key carriers
		else if(key_owner_team == -1)
			havocbot_goalrating_kh(this, 4, 1, 0.05); // play defensively
		else
			havocbot_goalrating_kh(this, 0.1, 0.1, 5); // ATTACK ANYWAY

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_kh_offense(entity this)
{
	if(IS_DEAD(this))
		return;

	if (this.kh_next)
	{
		LOG_TRACE("changing role to carrier");
		this.havocbot_role = havocbot_role_kh_carrier;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 20;
	if (time > this.havocbot_role_timeout)
	{
		LOG_TRACE("changing role to freelancer");
		this.havocbot_role = havocbot_role_kh_freelancer;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (navigation_goalrating_timeout(this))
	{
		float key_owner_team;

		navigation_goalrating_start(this);

		key_owner_team = kh_Key_AllOwnedByWhichTeam();
		if(key_owner_team == this.team)
			havocbot_goalrating_kh(this, 10, 0.1, 0.05); // defend anyway
		else if(key_owner_team == -1)
			havocbot_goalrating_kh(this, 0.1, 1, 2); // play offensively
		else
			havocbot_goalrating_kh(this, 0.1, 0.1, 5); // ATTACK! EMERGENCY!

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}

void havocbot_role_kh_freelancer(entity this)
{
	if(IS_DEAD(this))
		return;

	if (this.kh_next)
	{
		LOG_TRACE("changing role to carrier");
		this.havocbot_role = havocbot_role_kh_carrier;
		this.havocbot_role_timeout = 0;
		return;
	}

	if (!this.havocbot_role_timeout)
		this.havocbot_role_timeout = time + random() * 10 + 10;
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
		if(key_owner_team == this.team)
			havocbot_goalrating_kh(this, 10, 0.1, 0.05); // defend anyway
		else if(key_owner_team == -1)
			havocbot_goalrating_kh(this, 1, 10, 2); // prefer dropped keys
		else
			havocbot_goalrating_kh(this, 0.1, 0.1, 5); // ATTACK ANYWAY

		navigation_goalrating_end(this);

		navigation_goalrating_timeout_set(this);
	}
}


// register this as a mutator

MUTATOR_HOOKFUNCTION(kh, Damage_Calculate) // for changing damage and force values that are applied to players
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

	if(frag_target == frag_attacker)
		kh_Key_DropAll(frag_target, true);
	else if(IS_PLAYER(frag_attacker))
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

MUTATOR_HOOKFUNCTION(kh, TeamBalance_CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(0, float) = kh_teams;
	return true;
}

MUTATOR_HOOKFUNCTION(kh, PlayerUseKey)
{
	entity player = M_ARGV(0, entity);

	if(MUTATOR_RETURNVALUE == 0)
	{
		entity k = player.kh_next;
		if(k)
		{
			kh_Key_DropOne(k);
			return true;
		}
	}
}

MUTATOR_HOOKFUNCTION(kh, HavocBot_ChooseRole)
{
    entity bot = M_ARGV(0, entity);

	if(IS_DEAD(bot))
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
	if(player.kh_next)
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
