#include "sv_key.qh"

#include <common/mutators/mutator/waypoints/waypointsprites.qh>
#include <common/notifications/all.qh>


float autocvar_g_balance_keyhunt_damageforcescale;
float autocvar_g_balance_keyhunt_delay_collect;
float autocvar_g_balance_keyhunt_delay_damage_return;
float autocvar_g_balance_keyhunt_delay_return;
float autocvar_g_balance_keyhunt_return_when_unreachable;
float autocvar_g_balance_keyhunt_dropvelocity;
float autocvar_g_balance_keyhunt_throwvelocity;
float autocvar_g_balance_keyhunt_protecttime;
float autocvar_g_balance_keyhunt_maxdist;

int autocvar_g_balance_keyhunt_score_collect;

//#define KH_PLAYER_USE_ATTACHMENT

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

.entity kh_next, kh_prev; // linked list
.float kh_droptime;
.int kh_dropperteam;
.float siren_time; ///< time delay the siren


int kh_Key_TeamByID(int t)
{
	if (t == 0) return NUM_TEAM_1;
	if (t == 1) return NUM_TEAM_2;
	if (t == 2) return NUM_TEAM_3;
	if (t == 3) return NUM_TEAM_4;
	return 0;
}

/// Constantly called. check to see if all the keys are owned by the same team.
/// Returns -1 when no team completely owns all keys yet
int kh_Key_AllOwnedByWhichTeam()
{
	entity key;
	int tm = -1;
	int keys = AVAILABLE_TEAMS;
	FOR_EACH_KH_KEY(key)
	{
		if (!key.owner)
			return -1;
		if (tm == -1)
			tm = key.team;
		else if (tm != key.team)
			return -1;
		--keys;
	}
	if (keys != 0)
		return -1;
	return tm;
}

/// Runs when a player picks up a key and several times when a key is assigned to a player at the start of a round
void kh_Key_Attach(entity key)
{
	key.solid = SOLID_NOT; // before setorigin to prevent area grid linking
#ifdef KH_PLAYER_USE_ATTACHMENT
	entity first = key.owner.kh_next;
	if (key == first)
	{
		setattachment(key, key.owner, KH_PLAYER_ATTACHMENT_BONE);
		if (key.kh_next)
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
		if (key.kh_next)
			setattachment(key.kh_next, key, "");
		setorigin(key, KH_PLAYER_ATTACHMENT_DIST_ROTATED);
		setorigin(first, first.origin - 0.5 * KH_PLAYER_ATTACHMENT_DIST);
		key.angles = '0 0 0';
	}
#else
	setattachment(key, key.owner, "");
	setorigin(key, vec3(0, 0, KH_KEY_ZSHIFT));  // fixing x, y in think
	key.angles.y -= key.owner.angles.y;
#endif
	key.flags = 0;
	if (IL_CONTAINS(g_items, key))
		IL_REMOVE(g_items, key);
	set_movetype(key, MOVETYPE_NONE);
	key.team = key.owner.team;
	key.nextthink = time;
	key.damageforcescale = 0;
	key.takedamage = DAMAGE_NO;
	key.modelindex = kh_key_carried;
	navigation_dynamicgoal_unset(key);

	kh_KeyStatuses_SendKeys();
}

/// Runs every time a key is dropped or lost. Runs several times times when all the keys are captured
void kh_Key_Detach(entity key)
{
	key.solid = SOLID_TRIGGER; // before setorigin to ensure area grid linking
#ifdef KH_PLAYER_USE_ATTACHMENT
	entity first = key.owner.kh_next;
	if (key == first)
	{
		if (key.kh_next)
		{
			setattachment(key.kh_next, key.owner, KH_PLAYER_ATTACHMENT_BONE);
			setorigin(key.kh_next, key.origin + 0.5 * KH_PLAYER_ATTACHMENT_DIST);
			key.kh_next.angles = KH_PLAYER_ATTACHMENT_ANGLES;
		}
	}
	else
	{
		if (key.kh_next)
			setattachment(key.kh_next, key.kh_prev, "");
		setorigin(first, first.origin + 0.5 * KH_PLAYER_ATTACHMENT_DIST);
	}
	// in any case:
	setattachment(key, NULL, "");
	setorigin(key, key.owner.origin + '0 0 1' * (STAT(PL_MIN, key.owner).z - KH_KEY_MIN.z));
	key.angles = key.owner.angles;
#else
	setorigin(key, key.owner.origin + key.origin.z * '0 0 1');
	setattachment(key, NULL, "");
	key.angles.y += key.owner.angles.y;
#endif
	key.flags = FL_ITEM;
	if (!IL_CONTAINS(g_items, key))
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

	kh_KeyStatuses_SendKeys();
}

/// Runs every time a key is picked up or assigned. Runs prior to kh_key_Attach
void kh_Key_AssignTo(entity key, entity player)
{
	if (key.owner == player)
		return;

	int ownerteam0 = kh_Key_AllOwnedByWhichTeam();

	if (key.owner)
	{
		kh_Key_Detach(key);

		// remove from linked list
		if (key.kh_next)
			key.kh_next.kh_prev = key.kh_prev;
		key.kh_prev.kh_next = key.kh_next;
		key.kh_next = NULL;
		key.kh_prev = NULL;

		if (key.owner.kh_next == NULL)
		{
			// No longer a key carrier
			if (!kh_no_radar_circles)
				WaypointSprite_Ping(key.owner.waypointsprite_attachedforcarrier);
			WaypointSprite_DetachCarrier(key.owner);
		}
	}

	key.owner = player;
	kh_KeyStatuses_SendKeys();

	if (player)
	{
		// insert into linked list
		key.kh_next = player.kh_next;
		key.kh_prev = player;
		player.kh_next = key;
		if (key.kh_next)
			key.kh_next.kh_prev = key;

		kh_Key_Attach(key);

		if (key.kh_next == NULL)
		{
			// player is now a key carrier
			entity wp = WaypointSprite_AttachCarrier(WP_Null, player, RADARICON_FLAGCARRIER);
			wp.colormod = colormapPaletteColor(player.team - 1, 0);
			player.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = kh_KeyCarrier_waypointsprite_visible_for_player;
			WaypointSprite_UpdateRule(player.waypointsprite_attachedforcarrier, player.team, SPRITERULE_TEAMPLAY);
			if (player.team == NUM_TEAM_1)
				WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, WP_KeyCarrierRed, WP_KeyCarrierFriend, WP_KeyCarrierRed);
			else if (player.team == NUM_TEAM_2)
				WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, WP_KeyCarrierBlue, WP_KeyCarrierFriend, WP_KeyCarrierBlue);
			else if (player.team == NUM_TEAM_3)
				WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, WP_KeyCarrierYellow, WP_KeyCarrierFriend, WP_KeyCarrierYellow);
			else if (player.team == NUM_TEAM_4)
				WaypointSprite_UpdateSprites(player.waypointsprite_attachedforcarrier, WP_KeyCarrierPink, WP_KeyCarrierFriend, WP_KeyCarrierPink);
			if (!kh_no_radar_circles)
				WaypointSprite_Ping(player.waypointsprite_attachedforcarrier);
		}
	}

	key.pusher = NULL;

	int ownerteam = kh_Key_AllOwnedByWhichTeam();
	if (ownerteam == ownerteam0)
		return;

	if (ownerteam != -1)
	{
		kh_interferemsg_time = time + 0.2;
		kh_interferemsg_team = player.team;
	}
	else
		kh_interferemsg_time = 0;

	// Audit all key carrier sprites
	entity k, first, third;
	FOR_EACH_KH_KEY(k)
	{
		if (!k.owner)
			continue;
		first = WP_Null;
		third = WP_Null;
		FOREACH(Waypoints, it.netname == k.owner.waypointsprite_attachedforcarrier.model1, { first = it; break; });
		FOREACH(Waypoints, it.netname == k.owner.waypointsprite_attachedforcarrier.model3, { third = it; break; });

		// Update to "Run here" if ownerteam != -1, otherwise "Key Carrier"
		WaypointSprite_UpdateSprites(k.owner.waypointsprite_attachedforcarrier, first, (ownerteam != -1 ? WP_KeyCarrierFinish : WP_KeyCarrierFriend), third);
	}
}

void kh_Key_Damage(entity this, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	if (this.owner)
		return;
	if (ITEM_DAMAGE_NEEDKILL(deathtype))
	{
		this.pain_finished = bound(time, time + autocvar_g_balance_keyhunt_delay_damage_return, this.pain_finished);
		return;
	}
	if (force == '0 0 0')
		return;
	if (time > this.pushltime
	&& IS_PLAYER(attacker))
		this.team = attacker.team;
}

/// Runs when a player picks up a dropped key
void kh_Key_Collect(entity key, entity player)
{
	sound(player, CH_TRIGGER, SND_KH_COLLECT, VOL_BASE, ATTEN_NORM);

	if (key.kh_dropperteam != player.team)
	{
		kh_Scores_Event(player, key, "collect", autocvar_g_balance_keyhunt_score_collect, 0);
		GameRules_scoring_add(player, KH_PICKUPS, 1);
	}
	key.kh_dropperteam = 0;
	int realteam = kh_Key_TeamByID(key.count);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_PICKUP), player.netname);

	kh_Key_AssignTo(key, player); // this also updates .kh_state
}

/// Runs many, many times when a key has been dropped and can be picked up
void kh_Key_Touch(entity this, entity toucher)
{
	if (game_stopped
	|| this.owner) // already carried
		return;

	if (ITEM_TOUCH_NEEDKILL())
	{
		this.pain_finished = bound(time, time + autocvar_g_balance_keyhunt_delay_damage_return, this.pain_finished);
		return;
	}

	if (!IS_PLAYER(toucher)
	|| IS_DEAD(toucher)
	|| IS_INDEPENDENT_PLAYER(toucher))
		return;

	if (toucher == this.enemy
	&& time < this.kh_droptime + autocvar_g_balance_keyhunt_delay_collect)
		return;  // you just dropped it!

	kh_Key_Collect(this, toucher);
}

/// Runs after all the keys have been collected, or when a key has been dropped for more than X seconds
void kh_Key_Remove(entity key)
{
	entity o = key.owner;
	kh_Key_AssignTo(key, NULL);
	if (o) // it was attached
		WaypointSprite_Kill(key.waypointsprite_attachedforcarrier);
	else // it was dropped
		WaypointSprite_DetachCarrier(key);

	// remove key from key list
	if (kh_worldkeylist == key)
		kh_worldkeylist = kh_worldkeylist.kh_worldkeynext;
	else
		FOR_EACH_KH_KEY(o)
			if (o.kh_worldkeynext == key)
			{
				o.kh_worldkeynext = o.kh_worldkeynext.kh_worldkeynext;
				break;
			}

	delete(key);
}

void kh_Key_Think(entity this)  // runs all the time
{
	if (game_stopped)
		return;

#ifndef KH_PLAYER_USE_ATTACHMENT
	if (this.owner)
	{
		makevectors(vec2(0, this.cnt + (time % 360) * KH_KEY_XYSPEED));
		setorigin(this, v_forward * KH_KEY_XYDIST + '0 0 1' * this.origin.z);
	}
#endif

	// if in nodrop or time over, end the round
	if (!this.owner
	&& time > this.pain_finished)
		kh_LoserTeam(this.team, this);

	if (this.owner
	&& kh_Key_AllOwnedByWhichTeam() != -1)
	{
		if (this.siren_time < time)
		{
			sound(this.owner, CH_TRIGGER, SND_KH_ALARM, VOL_BASE, ATTEN_NORM);  // play a simple alarm
			this.siren_time = time + 2.5;  // repeat every 2.5 seconds
		}

		entity key;
		vector p = this.owner.origin;
		bool winning = true;
		FOR_EACH_KH_KEY(key)
			if (vdist(key.owner.origin - p, >, autocvar_g_balance_keyhunt_maxdist))
			{
				winning = false;
				break;
			}
		if (winning)
			kh_WinnerTeam(this.team);
	}

	if (kh_interferemsg_time && time > kh_interferemsg_time)
	{
		kh_interferemsg_time = 0;
		FOREACH_CLIENT(IS_PLAYER(it),
		{
			if (it.team == kh_interferemsg_team)
			{
				if (it.kh_next)
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

void kh_Key_Reset(entity this)
{
	kh_Key_AssignTo(this, NULL);
	kh_Key_Remove(this);
}

/// Runs every time a new flag is created, i.e. after all the keys have been collected
void kh_Key_Spawn(entity initial_owner, float _angle, int i, bool(entity, entity, entity) waypointsprite_visible_for_player_func)
{
	entity key = new(item_kh_key);
	key.count = i;
	settouch(key, kh_Key_Touch);
	setthink(key, kh_Key_Think);
	key.nextthink = time;
	key.cnt = _angle;
	key.angles = vec2(0, 360 * random());
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
	key.reset = kh_Key_Reset;
	navigation_dynamicgoal_init(key, false);

	switch (initial_owner.team)
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

	WaypointSprite_Spawn(WP_KeyDropped, 0, 0, key, vec3(0, 0, KH_KEY_WP_ZSHIFT), NULL, key.team, key, waypointsprite_attachedforcarrier, false, RADARICON_FLAG);
	key.waypointsprite_attachedforcarrier.waypointsprite_visible_for_player = waypointsprite_visible_for_player_func;

	kh_Key_AssignTo(key, initial_owner);
}

void kh_Key_DropOne(entity key)
{
	// prevent collecting this one for some time
	entity player = key.owner;

	key.kh_droptime = time;
	key.enemy = player;

	kh_Scores_Event(player, key, "dropkey", 0, 0);
	GameRules_scoring_add(player, KH_LOSSES, 1);
	int realteam = kh_Key_TeamByID(key.count);
	Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_DROP), player.netname);

	kh_Key_AssignTo(key, NULL);
	makevectors(player.v_angle);
	key.velocity = W_CalculateProjectileVelocity(player, player.velocity, autocvar_g_balance_keyhunt_throwvelocity * v_forward, false);
	key.pusher = NULL;
	key.pushltime = time + autocvar_g_balance_keyhunt_protecttime;
	key.kh_dropperteam = key.team;

	sound(player, CH_TRIGGER, SND_KH_DROP, VOL_BASE, ATTEN_NORM);
}

/// Runs whenever a player dies
void kh_Key_DropAll(entity player, float suicide)
{
	if (player.kh_next == NULL)
		return;

	entity mypusher = NULL;
	if (player.pusher
	&& time < player.pushltime)
		mypusher = player.pusher;

	entity key;
	int realteam;
	while ((key = player.kh_next))
	{
		kh_Scores_Event(player, key, "losekey", 0, 0);
		GameRules_scoring_add(player, KH_LOSSES, 1);
		realteam = kh_Key_TeamByID(key.count);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(realteam, INFO_KEYHUNT_LOST), player.netname);
		kh_Key_AssignTo(key, NULL);
		makevectors(vec2(-45 * (1 + random()), 360 * random()));
		key.velocity = W_CalculateProjectileVelocity(player, player.velocity, autocvar_g_balance_keyhunt_dropvelocity * v_forward, false);
		key.pusher = mypusher;
		key.pushltime = time + autocvar_g_balance_keyhunt_protecttime;
		if (suicide)
			key.kh_dropperteam = player.team;
	}
	sound(player, CH_TRIGGER, SND_KH_DROP, VOL_BASE, ATTEN_NORM);
}
