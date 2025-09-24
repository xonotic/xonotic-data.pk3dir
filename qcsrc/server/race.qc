#include "race.qh"

#include <common/deathtypes/all.qh>
#include <common/gametypes/_mod.qh>
#include <common/gametypes/rules.qh>
#include <common/mapobjects/subs.qh>
#include <common/mapobjects/triggers.qh>
#include <common/mutators/mutator/waypoints/waypointsprites.qh>
#include <common/net_linked.qh>
#include <common/notifications/all.qh>
#include <common/playerstats.qh>
#include <common/state.qh>
#include <common/stats.qh>
#include <common/vehicles/sv_vehicles.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/weapon/porto.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>
#include <server/bot/api.qh>
#include <server/cheats.qh>
#include <server/client.qh>
#include <server/command/getreplies.qh>
#include <server/damage.qh>
#include <server/gamelog.qh>
#include <server/intermission.qh>
#include <server/main.qh>
#include <server/mutators/_mod.qh>
#include <server/portals.qh>
#include <server/scores.qh>
#include <server/spawnpoints.qh>
#include <server/weapons/common.qh>
#include <server/world.qh>

.string stored_netname; // TODO: store this information independently of race-based gametypes

string uid2name(string myuid)
{
	string s = db_get(ServerProgsDB, strcat("/uid2name/", myuid));

	// FIXME remove this later after 0.6 release
	// convert old style broken records to correct style
	if(s == "")
	{
		s = db_get(ServerProgsDB, strcat("uid2name", myuid));
		if(s != "")
		{
			db_put(ServerProgsDB, strcat("/uid2name/", myuid), s);
			db_remove(ServerProgsDB, strcat("uid2name", myuid));
		}
	}

	if(s == "")
		s = "^1Unregistered Player";
	return s;
}

void write_recordmarker(entity pl, float tstart, float dt)
{
	GameLogEcho(strcat(":recordset:", ftos(pl.playerid), ":", ftos(dt)));
	// also write a marker into demo files for demotc-race-record-extractor to find
	stuffcmd(pl,
		sprintf("//%s RECORD SET %s %f %f\n", strconv(2, 0, 0, GetGametype()),
			TIME_ENCODED_TOSTRING(TIME_ENCODE(dt), false), tstart, dt));
}

IntrusiveList g_race_targets;
IntrusiveList g_racecheckpoints;

float race_readTime(string map, float pos)
{
	return stof(db_get(ServerProgsDB, strcat(map, record_type, "time", ftos(pos))));
}

string race_readUID(string map, float pos)
{
	return db_get(ServerProgsDB, strcat(map, record_type, "crypto_idfp", ftos(pos)));
}

float race_readPos(string map, float t)
{
	for(int i = 1; i <= RANKINGS_CNT; ++i)
	{
		int mytime = race_readTime(map, i);
		if(!mytime || mytime > t)
			return i;
	}

	return 0; // pos is zero if unranked
}

void race_writeTime(string map, float t, string myuid)
{
	float newpos;
	newpos = race_readPos(map, t);

	float i, prevpos = 0;
	for(i = 1; i <= RANKINGS_CNT; ++i)
	{
		if(race_readUID(map, i) == myuid)
			prevpos = i;
	}
	if (prevpos)
	{
		// player improved their existing record, only have to iterate on ranks between new and old recs
		for (i = prevpos; i > newpos; --i)
		{
			db_put(ServerProgsDB, strcat(map, record_type, "time", ftos(i)), ftos(race_readTime(map, i - 1)));
			db_put(ServerProgsDB, strcat(map, record_type, "crypto_idfp", ftos(i)), race_readUID(map, i - 1));
		}
	}
	else
	{
		// player has no ranked record yet
		for (i = RANKINGS_CNT; i > newpos; --i)
		{
			float other_time = race_readTime(map, i - 1);
			if (other_time) {
				db_put(ServerProgsDB, strcat(map, record_type, "time", ftos(i)), ftos(other_time));
				db_put(ServerProgsDB, strcat(map, record_type, "crypto_idfp", ftos(i)), race_readUID(map, i - 1));
			}
		}
	}

	// store new time itself
	db_put(ServerProgsDB, strcat(map, record_type, "time", ftos(newpos)), ftos(t));
	db_put(ServerProgsDB, strcat(map, record_type, "crypto_idfp", ftos(newpos)), myuid);
}

string race_readName(string map, float pos)
{
	return uid2name(db_get(ServerProgsDB, strcat(map, record_type, "crypto_idfp", ftos(pos))));
}

void race_checkAndWriteName(entity player)
{
	if(CS_CVAR(player).cvar_cl_allow_uidtracking == 1 && CS_CVAR(player).cvar_cl_allow_uid2name == 1)
	{
		if (!player.stored_netname)
			player.stored_netname = strzone(uid2name(player.crypto_idfp));
		if(player.stored_netname != player.netname)
		{
			db_put(ServerProgsDB, strcat("/uid2name/", player.crypto_idfp), player.netname);
			strcpy(player.stored_netname, player.netname);
		}
	}
}


const float MAX_CHECKPOINTS = 255;

.float race_penalty;
.float race_penalty_accumulator;
.string race_penalty_reason;
.float race_checkpoint; // player: next checkpoint that has to be reached
.entity race_lastpenalty;

.entity sprite;

float race_checkpoint_records[MAX_CHECKPOINTS];
float race_checkpoint_recordspeeds[MAX_CHECKPOINTS];
string race_checkpoint_recordholders[MAX_CHECKPOINTS];
float race_checkpoint_lasttimes[MAX_CHECKPOINTS];
float race_checkpoint_lastlaps[MAX_CHECKPOINTS];
entity race_checkpoint_lastplayers[MAX_CHECKPOINTS];

.float race_checkpoint_record[MAX_CHECKPOINTS];
.float race_checkpoint_recordspeed[MAX_CHECKPOINTS];

float race_highest_checkpoint;
float race_timed_checkpoint;

float defrag_ents;
float defragcpexists;

float race_NextCheckpoint(float f)
{
	if(f >= race_highest_checkpoint)
		return 0;
	else
		return f + 1;
}

float race_PreviousCheckpoint(float f)
{
	if(f == -1)
		return 0;
	else if(f == 0)
		return race_highest_checkpoint;
	else
		return f - 1;
}

// encode as:
//   0 = common start/finish
// 254 = start
// 255 = finish
float race_CheckpointNetworkID(float f)
{
	if(race_timed_checkpoint)
	{
		if(f == 0)
			return 254; // start
		else if(f == race_timed_checkpoint)
			return 255; // finish
	}
	return f;
}

void race_SendNextCheckpoint(entity e, float spec) // qualifying only
{
	if(!e.race_laptime)
		return;

	int cp = e.race_checkpoint;
	float recordtime;
	float recordspeed;
	float myrecordtime = e.race_checkpoint_record[cp];
	float myrecordspeed = e.race_checkpoint_recordspeed[cp];
	string recordholder;
	if (autocvar_g_race_cptimes_onlyself) {
		recordtime = myrecordtime;
		recordspeed = myrecordspeed;
		recordholder = "";
	} else {
		recordtime = race_checkpoint_records[cp];
		recordspeed = race_checkpoint_recordspeeds[cp];
		recordholder = race_checkpoint_recordholders[cp];

		if(recordholder == e.netname)
			recordholder = "";
	}

	if(!IS_REAL_CLIENT(e))
		return;

	if(!spec)
		msg_entity = e;
	WRITESPECTATABLE_MSG_ONE(msg_entity, {
		WriteHeader(MSG_ONE, TE_CSQC_RACE);
		if(spec)
		{
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_NEXT_SPEC_QUALIFYING);
			//WriteCoord(MSG_ONE, e.race_laptime - e.race_penalty_accumulator);
			WriteCoord(MSG_ONE, time - e.race_movetime - e.race_penalty_accumulator);
		}
		else
			WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_NEXT_QUALIFYING);
		WriteByte(MSG_ONE, race_CheckpointNetworkID(cp)); // checkpoint the player will be at next
		WriteInt24_t(MSG_ONE, recordtime);
		if(!spec)
			WriteInt24_t(MSG_ONE, myrecordtime);
		WriteString(MSG_ONE, recordholder);
		// All speeds networked as floats to have decimal precision
		WriteFloat(MSG_ONE, recordspeed);
		if(!spec)
			WriteFloat(MSG_ONE, myrecordspeed);
	});
}

void race_send_recordtime(float msg)
{
	// send the server best time
	WriteHeader(msg, TE_CSQC_RACE);
	WriteByte(msg, RACE_NET_SERVER_RECORD);
	WriteInt24_t(msg, race_readTime(GetMapname(), 1));
}

void race_send_speedaward(float msg)
{
	// send the best speed of the round
	WriteHeader(msg, TE_CSQC_RACE);
	WriteByte(msg, RACE_NET_SPEED_AWARD);
	WriteInt24_t(msg, floor(speedaward_speed+0.5));
	WriteString(msg, speedaward_holder);
}

void race_send_speedaward_alltimebest(float msg)
{
	// send the best speed
	WriteHeader(msg, TE_CSQC_RACE);
	WriteByte(msg, RACE_NET_SPEED_AWARD_BEST);
	WriteInt24_t(msg, floor(speedaward_alltimebest+0.5));
	WriteString(msg, speedaward_alltimebest_holder);
}

void race_send_rankings_cnt(float msg)
{
	WriteHeader(msg, TE_CSQC_RACE);
	WriteByte(msg, RACE_NET_RANKINGS_CNT);
	int m = min(RANKINGS_CNT, autocvar_g_cts_send_rankings_cnt);
	WriteByte(msg, m);
}

void race_SendRanking(float pos, float prevpos, float del, float msg)
{
	WriteHeader(msg, TE_CSQC_RACE);
	WriteByte(msg, RACE_NET_SERVER_RANKINGS);
	WriteShort(msg, pos);
	WriteShort(msg, prevpos);
	WriteShort(msg, del);
	WriteString(msg, race_readName(GetMapname(), pos));
	WriteInt24_t(msg, race_readTime(GetMapname(), pos));
}

void race_SpeedAwardFrame(entity player)
{
	if (IS_OBSERVER(player))
		return;

	if(vdist(player.velocity - player.velocity_z * '0 0 1', >, speedaward_speed))
	{
		speedaward_speed = vlen(player.velocity - player.velocity_z * '0 0 1');
		speedaward_holder = player.netname;
		speedaward_uid = player.crypto_idfp;
		speedaward_lastupdate = time;
	}
	if (speedaward_speed > speedaward_lastsent && (time - speedaward_lastupdate > 1 || intermission_running))
	{
		race_send_speedaward(MSG_ALL);
		speedaward_lastsent = speedaward_speed;
		if (speedaward_speed > speedaward_alltimebest && speedaward_uid != "")
		{
			speedaward_alltimebest = speedaward_speed;
			speedaward_alltimebest_holder = speedaward_holder;
			speedaward_alltimebest_uid = speedaward_uid;
			db_put(ServerProgsDB, strcat(GetMapname(), record_type, "speed/speed"), ftos(speedaward_alltimebest));
			db_put(ServerProgsDB, strcat(GetMapname(), record_type, "speed/crypto_idfp"), speedaward_alltimebest_uid);
			race_send_speedaward_alltimebest(MSG_ALL);
		}
	}
}

void race_SendAll(entity player, bool only_rankings)
{
	if(!IS_REAL_CLIENT(player))
		return;

	msg_entity = player;
	if (!only_rankings)
	{
		race_send_recordtime(MSG_ONE);
		race_send_speedaward(MSG_ONE);

		speedaward_alltimebest = stof(db_get(ServerProgsDB, strcat(GetMapname(), record_type, "speed/speed")));
		speedaward_alltimebest_holder = uid2name(db_get(ServerProgsDB, strcat(GetMapname(), record_type, "speed/crypto_idfp")));
		race_send_speedaward_alltimebest(MSG_ONE);
	}

	int m = min(RANKINGS_CNT, autocvar_g_cts_send_rankings_cnt);
	race_send_rankings_cnt(MSG_ONE);
	for (int i = 1; i <= m; ++i)
		race_SendRanking(i, 0, 0, MSG_ONE);
}

void race_SendStatus(float id, entity e)
{
	if(!IS_REAL_CLIENT(e))
		return;

	float msg;
	if (id == 0)
		msg = MSG_ONE;
	else
		msg = MSG_ALL;
	msg_entity = e;
	WRITESPECTATABLE_MSG_ONE(msg_entity, {
		WriteHeader(msg, TE_CSQC_RACE);
		WriteByte(msg, RACE_NET_SERVER_STATUS);
		WriteShort(msg, id);
		WriteString(msg, e.netname);
	});
}

void race_setTime(string map, float t, string myuid, string mynetname, entity e, bool showmessage)
{
	// netname only used TEMPORARILY for printing
	int newpos = race_readPos(map, t);

	int player_prevpos = 0;
	for(int i = 1; i <= RANKINGS_CNT; ++i)
	{
		if(race_readUID(map, i) == myuid)
			player_prevpos = i;
	}

	float oldrec;
	string oldrec_holder;
	if (player_prevpos && (player_prevpos < newpos || !newpos))
	{
		oldrec = race_readTime(GetMapname(), player_prevpos);
		race_SendStatus(0, e); // "fail"
		if(showmessage)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_FAIL_RANKED, mynetname, player_prevpos, t, oldrec);
		return;
	}
	else if (!newpos)
	{
		// no ranking, time worse than the worst ranked
		oldrec = race_readTime(GetMapname(), RANKINGS_CNT);
		race_SendStatus(0, e); // "fail"
		if(showmessage)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_FAIL_UNRANKED, mynetname, RANKINGS_CNT, t, oldrec);
		return;
	}

	// if we didn't hit a return yet, we have a new record!

	// if the player does not have a UID we can unfortunately not store the record, as the rankings system relies on UIDs
	if(myuid == "")
	{
		if(showmessage)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_NEW_MISSING_UID, mynetname, t);
		return;
	}

	if(CS_CVAR(e).cvar_cl_allow_uidtracking != 1 || CS_CVAR(e).cvar_cl_allow_uid2name != 1
	   || uid2name(myuid) == "^1Unregistered Player")
	{
		if(showmessage)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_NEW_MISSING_NAME, mynetname, t);
		return;
	}

	oldrec = race_readTime(GetMapname(), newpos);
	oldrec_holder = race_readName(GetMapname(), newpos);

	// store new ranking
	race_writeTime(GetMapname(), t, myuid);

	if (newpos == 1 && showmessage)
	{
		write_recordmarker(e, time - TIME_DECODE(t), TIME_DECODE(t));
		race_send_recordtime(MSG_ALL);
	}

	race_SendRanking(newpos, player_prevpos, 0, MSG_ALL);
	strcpy(rankings_reply, getrankings());

	if(newpos == player_prevpos)
	{
		if(showmessage)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_NEW_IMPROVED, mynetname, newpos, t, oldrec);
		if(newpos == 1) { race_SendStatus(3, e); } // "new server record"
		else { race_SendStatus(1, e); } // "new time"
	}
	else if(oldrec == 0)
	{
		if(showmessage)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_NEW_SET, mynetname, newpos, t);
		if(newpos == 1) { race_SendStatus(3, e); } // "new server record"
		else { race_SendStatus(2, e); } // "new rank"
	}
	else
	{
		if(showmessage)
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_NEW_BROKEN, mynetname, oldrec_holder, newpos, t, oldrec);
		if(newpos == 1) { race_SendStatus(3, e); } // "new server record"
		else { race_SendStatus(2, e); } // "new rank"
	}
}

void race_deleteTime(string map, float pos)
{
	for(int i = pos; i <= RANKINGS_CNT; ++i)
	{
		string therank = ftos(i);
		if (i == RANKINGS_CNT)
		{
			db_remove(ServerProgsDB, strcat(map, record_type, "time", therank));
			db_remove(ServerProgsDB, strcat(map, record_type, "crypto_idfp", therank));
		}
		else
		{
			db_put(ServerProgsDB, strcat(map, record_type, "time", therank), ftos(race_readTime(GetMapname(), i+1)));
			db_put(ServerProgsDB, strcat(map, record_type, "crypto_idfp", therank), race_readUID(GetMapname(), i+1));
		}
	}

	race_SendRanking(pos, 0, 1, MSG_ALL);
	if(pos == 1)
		race_send_recordtime(MSG_ALL);

	strcpy(rankings_reply, getrankings());
}

void race_SendTime(entity e, float cp, float t, float tvalid)
{
	if(g_race_qualifying)
		t += e.race_penalty_accumulator;

	t = TIME_ENCODE(t); // make integer

	if(tvalid)
	if(cp == race_timed_checkpoint) // finish line
	if (!CS(e).race_completed)
	{
		int s = GameRules_scoring_add(e, RACE_FASTEST, 0);
		if(!s || t < s)
			GameRules_scoring_add(e, RACE_FASTEST, t - s);
		if(!g_race_qualifying)
		{
			s = GameRules_scoring_add(e, RACE_TIME, 0);
			int snew = TIME_ENCODE(time - game_starttime);
			GameRules_scoring_add(e, RACE_TIME, snew - s);
			int l = GameRules_scoring_add_team(e, RACE_LAPS, 1);

			if(autocvar_fraglimit)
				if(l >= autocvar_fraglimit)
					race_StartCompleting();

			if(race_completing)
			{
				CS(e).race_completed = 1;
				MAKE_INDEPENDENT_PLAYER(e);
				if(e.bot_attack)
					IL_REMOVE(g_bot_targets, e);
				e.bot_attack = false;
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_FINISHED, e.netname);
				ClientData_Touch(e);
			}
		}
	}

	if(g_race_qualifying)
	{
		float recordtime;
		float recordtimespeed;
		string recordholder;

		if(tvalid)
		{
			if (autocvar_g_race_cptimes_onlyself)
			{
				// return their own checkpoint time
				recordtime = e.race_checkpoint_record[cp];
				recordtimespeed = e.race_checkpoint_recordspeed[cp];
				recordholder = "";
			}
			else
			{
				recordtime = race_checkpoint_records[cp];
				recordtimespeed = race_checkpoint_recordspeeds[cp];
				// make a tempstring copy, as we'll possibly strunzone it
				recordholder = strcat(race_checkpoint_recordholders[cp]);

				if(recordholder == e.netname)
					recordholder = "";
			}

			if(t != 0)
			{
				if(cp == race_timed_checkpoint)
				{
					race_setTime(GetMapname(), t, e.crypto_idfp, e.netname, e, true);
					MUTATOR_CALLHOOK(Race_FinalCheckpoint, e);
				}

				if(t < recordtime || recordtime == 0)
				{
					race_checkpoint_records[cp] = t;
					race_checkpoint_recordspeeds[cp] = vlen(vec2(e.velocity));
					strcpy(race_checkpoint_recordholders[cp], e.netname);
					if(g_race_qualifying)
						FOREACH_CLIENT(IS_PLAYER(it) && IS_REAL_CLIENT(it) && it.race_checkpoint == cp, { race_SendNextCheckpoint(it, 0); });
				}

			}
		}
		else
		{
			// dummies
			t = 0;
			recordtime = 0;
			recordtimespeed = 0;
			recordholder = "";
		}

		if(IS_REAL_CLIENT(e))
		{
			if(g_race_qualifying)
			{
				FOREACH_CLIENT(IS_REAL_CLIENT(it),
				{
					if(it == e || (IS_SPEC(it) && it.enemy == e))
					{
						msg_entity = it;
						WriteHeader(MSG_ONE, TE_CSQC_RACE);
						WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_QUALIFYING);
						WriteByte(MSG_ONE, race_CheckpointNetworkID(cp)); // checkpoint the player now is at
						WriteInt24_t(MSG_ONE, t); // time to that checkpoint
						WriteInt24_t(MSG_ONE, recordtime); // previously best time
						WriteInt24_t(MSG_ONE, ((tvalid) ? it.race_checkpoint_record[cp] : 0)); // previously best time
						WriteString(MSG_ONE, recordholder); // record holder
						// All speeds networked as floats to have decimal precision
						WriteFloat(MSG_ONE, vlen(vec2(e.velocity))); // speed of cp hit
						WriteFloat(MSG_ONE, recordtimespeed); // speed of previous best cp hit
						WriteFloat(MSG_ONE, ((tvalid) ? it.race_checkpoint_recordspeed[cp] : 0)); // speed of my previous best cp hit
					}
				});
			}
		}
		// check if new pb should be set for a checkpoint
		if(tvalid)
		{
			float myrecordtime = e.race_checkpoint_record[cp];
			if(t != 0)
				if(t < myrecordtime || myrecordtime == 0)
				{
					e.race_checkpoint_record[cp] = t;
					e.race_checkpoint_recordspeed[cp] = vlen(vec2(e.velocity));
				}
		}
	}
	else // RACE! Not Qualifying
	{
		float mylaps, lother, othtime;
		entity oth = race_checkpoint_lastplayers[cp];
		if(oth)
		{
			mylaps = GameRules_scoring_add(e, RACE_LAPS, 0);
			lother = race_checkpoint_lastlaps[cp];
			othtime = race_checkpoint_lasttimes[cp];
		}
		else
			mylaps = lother = othtime = 0;

		if(IS_REAL_CLIENT(e))
		{
			msg_entity = e;
			WRITESPECTATABLE_MSG_ONE(msg_entity, {
				WriteHeader(MSG_ONE, TE_CSQC_RACE);
				WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_RACE);
				WriteByte(MSG_ONE, race_CheckpointNetworkID(cp)); // checkpoint the player now is at
				if(e == oth)
				{
					WriteInt24_t(MSG_ONE, 0);
					WriteByte(MSG_ONE, 0);
					WriteByte(MSG_ONE, 0);
				}
				else
				{
					WriteInt24_t(MSG_ONE, TIME_ENCODE(time - race_checkpoint_lasttimes[cp]));
					WriteByte(MSG_ONE, mylaps - lother);
					WriteByte(MSG_ONE, etof(oth)); // record holder
				}
			});
		}

		race_checkpoint_lastplayers[cp] = e;
		race_checkpoint_lasttimes[cp] = time;
		race_checkpoint_lastlaps[cp] = mylaps;

		if(IS_REAL_CLIENT(oth))
		{
			msg_entity = oth;
			WRITESPECTATABLE_MSG_ONE(msg_entity, {
				WriteHeader(MSG_ONE, TE_CSQC_RACE);
				WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_HIT_RACE_BY_OPPONENT);
				WriteByte(MSG_ONE, race_CheckpointNetworkID(cp)); // checkpoint the player now is at
				if(e == oth)
				{
					WriteInt24_t(MSG_ONE, 0);
					WriteByte(MSG_ONE, 0);
					WriteByte(MSG_ONE, 0);
				}
				else
				{
					WriteInt24_t(MSG_ONE, TIME_ENCODE(time - othtime));
					WriteByte(MSG_ONE, lother - mylaps);
					WriteByte(MSG_ONE, etof(e) - 1); // record holder
				}
			});
		}
	}
}

void race_ClearTime(entity e)
{
	e.race_checkpoint = 0;
	e.race_laptime = 0;
	e.race_movetime = e.race_movetime_frac = e.race_movetime_count = 0;
	e.race_penalty_accumulator = 0;
	e.race_lastpenalty = NULL;

	if(!IS_REAL_CLIENT(e))
		return;

	msg_entity = e;
	WRITESPECTATABLE_MSG_ONE(msg_entity, {
		WriteHeader(MSG_ONE, TE_CSQC_RACE);
		WriteByte(MSG_ONE, RACE_NET_CHECKPOINT_CLEAR); // next
	});
}

void checkpoint_passed(entity this, entity player)
{
	if(IS_VEHICLE(player) && player.owner)
		player = player.owner;

	if(player.personal && autocvar_g_allow_checkpoints)
		return; // practice mode!

	if(player.classname == "porto")
	{
		// do not allow portalling through checkpoints
		trace_plane_normal = normalize(-1 * player.velocity);
		W_Porto_Fail(player, 0);
		return;
	}

	string oldmsg; // used twice

	/*
	 * Trigger targets
	 */
	if (!((this.spawnflags & 2) && (IS_PLAYER(player))))
	{
		oldmsg = this.message;
		this.message = "";
		SUB_UseTargets(this, player, player);
		this.message = oldmsg;
	}

	if (!IS_PLAYER(player))
		return;

	/*
	 * Remove unauthorized equipment
	 */
	Portal_ClearAll(player);

	player.porto_forbidden = 2; // decreased by 1 each StartFrame

	if(defrag_ents)
	{
		if(this.race_checkpoint == -2)
		{
			// duplicate targetname target_checkpoints get the same cp nr
			IL_EACH(g_race_targets, it.classname == "target_checkpoint" && it.targetname == this.targetname, {
				if(it.race_checkpoint >= 0)
					this.race_checkpoint = it.race_checkpoint;
			});
			if(this.race_checkpoint == -2)
				this.race_checkpoint = player.race_checkpoint;
		}

		int cp_amount = 0, largest_cp_id = 0;
		IL_EACH(g_race_targets, it.classname == "target_checkpoint",
		{
			cp_amount += 1;
			if(it.race_checkpoint > largest_cp_id) // update the finish id if someone hit a new checkpoint
			{
				if(!largest_cp_id)
				{
					IL_EACH(g_race_targets, it.classname == "target_checkpoint",
					{
						if(it.race_checkpoint == -2) // set defragcpexists to -1 so that the cp id file will be rewritten when someone finishes
							defragcpexists = -1;
					});
				}

				largest_cp_id = it.race_checkpoint;
				IL_EACH(g_race_targets, it.classname == "target_stopTimer",
				{
					it.race_checkpoint = largest_cp_id + 1; // finish line
				});
				race_highest_checkpoint = largest_cp_id + 1;
				race_timed_checkpoint = largest_cp_id + 1;
			}
		});

		if(!cp_amount)
		{
			IL_EACH(g_race_targets, it.classname == "target_stopTimer",
			{
				it.race_checkpoint = 1;
			});
			race_highest_checkpoint = 1;
			race_timed_checkpoint = 1;
		}
	}

	if((player.race_checkpoint == -1 && this.race_checkpoint == 0) || (player.race_checkpoint == this.race_checkpoint))
	{
		if(this.race_penalty)
		{
			if(player.race_lastpenalty != this)
			{
				player.race_lastpenalty = this;
				race_ImposePenaltyTime(player, this.race_penalty, this.race_penalty_reason);
			}
		}

		if(player.race_penalty)
			return;

		/*
		 * Trigger targets
		 */
		if(this.spawnflags & 2)
		{
			oldmsg = this.message;
			this.message = "";
			SUB_UseTargets(this, player, player); // TODO: should we be using other for the trigger here?
			this.message = oldmsg;
		}

		if(player.race_respawn_checkpoint != this.race_checkpoint || !player.race_started)
			player.race_respawn_spotref = this; // this is not a spot but a CP, but spawnpoint selection will deal with that
		player.race_respawn_checkpoint = this.race_checkpoint;
		player.race_checkpoint = race_NextCheckpoint(this.race_checkpoint);
		player.race_started = 1;

		race_SendTime(player, this.race_checkpoint, player.race_movetime, boolean(player.race_laptime));

		if(!this.race_checkpoint) // start line
		{
			player.race_laptime = time;
			player.race_movetime = player.race_movetime_frac = player.race_movetime_count = 0;
			player.race_penalty_accumulator = 0;
			player.race_lastpenalty = NULL;
		}

		if(g_race_qualifying)
			race_SendNextCheckpoint(player, 0);

		if(defrag_ents && defragcpexists < 0 && this.classname == "target_stopTimer")
		{
			float fh;
			defragcpexists = fh = fopen(strcat("maps/", GetMapname(), ".defragcp"), FILE_WRITE);
			if(fh >= 0)
			{
				IL_EACH(g_race_targets, it.classname == "target_checkpoint",
				{
					fputs(fh, strcat(it.targetname, " ", ftos(it.race_checkpoint), "\n"));
				});
			}
			fclose(fh);
		}
	}
	else if(player.race_checkpoint == race_NextCheckpoint(this.race_checkpoint))
	{
		// ignored
	}
	else
	{
		if(this.spawnflags & 4)
			Damage (player, this, this, 10000, DEATH_HURTTRIGGER.m_id, DMG_NOWEP, player.origin, '0 0 0');
	}
}

void checkpoint_touch(entity this, entity toucher)
{
	EXACTTRIGGER_TOUCH(this, toucher);
	checkpoint_passed(this, toucher);
}

void checkpoint_use(entity this, entity actor, entity trigger)
{
	if(trigger.classname == "info_player_deathmatch") // a spawn, a spawn
		return;

	checkpoint_passed(this, actor);
}

bool race_waypointsprite_visible_for_player(entity this, entity player, entity view)
{
	entity own = this.owner;
	if(this.realowner)
		own = this.realowner; // target support

	if(view.race_checkpoint == -1 || own.race_checkpoint == -2)
		return true;
	else if(view.race_checkpoint == own.race_checkpoint)
		return true;
	else
		return false;
}

void defrag_waypointsprites(entity targeted, entity checkpoint, int recursionlevel)
{
	// bones_was_here: spawn a waypoint for every entity with a bmodel
	// that directly or indirectly targets this checkpoint
	// (anything a player could touch or shoot to activate this cp)

	// spam a few warnings so that larger link chain loops can be found
	if (recursionlevel > 400)
	{
		LOG_WARNF("df cp wp loop: ^4\"target\" ^3\"%s\"^7, ^4\"targetname\" ^3\"%s\"^7",
			targeted.classname,
			targeted.targetname);
	}
	// avoid a stack overflow
	if (recursionlevel > 420)
	{
		LOG_WARNF("Aborted creating defrag checkpoint waypointsprites for ^2%s^7 due to a loop",
			checkpoint.classname);
		return;
	}

	entity s = WP_RaceCheckpoint;
	if (checkpoint.classname == "target_startTimer")
		s = WP_RaceStart;
	else if (checkpoint.classname == "target_stopTimer")
		s = WP_RaceFinish;

	for (entity t = findchain(target, targeted.targetname); t; t = t.chain)
	{
		if (t.modelindex)
		{
			WaypointSprite_SpawnFixed(s, (t.absmin + t.absmax) * 0.5, t, sprite, RADARICON_NONE);
			t.sprite.realowner = checkpoint;
			t.sprite.waypointsprite_visible_for_player = race_waypointsprite_visible_for_player;
		}

		if (t.targetname && t != checkpoint)
			defrag_waypointsprites(t, checkpoint, ++recursionlevel);
	}
}

void trigger_race_checkpoint_verify(entity this)
{
	static bool have_verified;
	if (have_verified) return;
	have_verified = true;

	int qual = g_race_qualifying;

	int pl_race_checkpoint = 0;
	int pl_race_place = 0;

	if (g_race) {
		for (int i = 0; i <= race_highest_checkpoint; ++i) {
			pl_race_checkpoint = race_NextCheckpoint(i);

			// race only (middle of the race)
			g_race_qualifying = 0;
			pl_race_place = 0;
			if (!Spawn_FilterOutBadSpots(this, findchain(classname, "info_player_deathmatch"), 0, false, true)) {
				error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(pl_race_place), " (used for respawning in race) - bailing out"));
			}

			if (i == 0) {
				// qualifying only
				g_race_qualifying = 1;
				pl_race_place = race_lowest_place_spawn;
				if (!Spawn_FilterOutBadSpots(this, findchain(classname, "info_player_deathmatch"), 0, false, true)) {
					error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(pl_race_place), " (used for qualifying) - bailing out"));
				}

				// race only (initial spawn)
				g_race_qualifying = 0;
				for (int p = 1; p <= race_highest_place_spawn; ++p) {
					pl_race_place = p;
					if (!Spawn_FilterOutBadSpots(this, findchain(classname, "info_player_deathmatch"), 0, false, true)) {
						error(strcat("Checkpoint ", ftos(i), " misses a spawnpoint with race_place==", ftos(pl_race_place), " (used for initially spawning in race) - bailing out"));
					}
				}
			}
		}
	} else if (!defrag_ents) {
		// qualifying only
		pl_race_checkpoint = race_NextCheckpoint(0);
		g_race_qualifying = 1;
		pl_race_place = race_lowest_place_spawn;
		if (!Spawn_FilterOutBadSpots(this, findchain(classname, "info_player_deathmatch"), 0, false, true)) {
			error(strcat("Checkpoint 0 misses a spawnpoint with race_place==", ftos(pl_race_place), " (used for qualifying) - bailing out"));
		}
	} else {
		pl_race_checkpoint = race_NextCheckpoint(0);
		g_race_qualifying = 1;
		pl_race_place = 0; // there's only one spawn on defrag maps

		// check if a defragcp file already exists, then read it and apply the checkpoint order
		float fh;
		float len;
		bool broken_defragcp = false;
		string l;

		defragcpexists = fh = fopen(strcat("maps/", GetMapname(), ".defragcp"), FILE_READ);
		if (fh >= 0) {
			while ((l = fgets(fh))) {
				len = tokenize_console(l);
				if (len != 2) {
					broken_defragcp = true;
					break;
				}
				for (entity cp = NULL; (cp = find(cp, classname, "target_checkpoint"));) {
					if (argv(0) == cp.targetname) {
						if(cp.race_checkpoint != -2 && cp.race_checkpoint != stof(argv(1))) {
							broken_defragcp = true; // cp had been previously set with diff order nr defragcp file is broken
							break;
						}
						cp.race_checkpoint = stof(argv(1));
					}
				}
				if(broken_defragcp) break; // no point to keep going we'll rebuild the whole order
			}
			fclose(fh);
			if(broken_defragcp) {
				// something's wrong in the defrag cp file, set defragcpexists to -1 so that it will be rewritten when someone finishes
				// also clear any set cp order to make sure map is completable
				defragcpexists = -1;
				for (entity cp = NULL; (cp = find(cp, classname, "target_checkpoint"));) {
					cp.race_checkpoint = -2;
				}
			}
		}
	}

	g_race_qualifying = qual;

	if (race_timed_checkpoint) {
		if (defrag_ents) {
			IL_EACH(g_race_targets, it.classname == "target_checkpoint" || it.classname == "target_startTimer" || it.classname == "target_stopTimer",
			{
				defrag_waypointsprites(it, it, 0);

				if(it.classname == "target_checkpoint") {
					if(it.race_checkpoint == -2)
						defragcpexists = -1; // something's wrong with the defrag cp file or it has not been written yet, set defragcpexists to -1 so that it will be rewritten when someone finishes
				}
			});
			if (defragcpexists != -1) {
				float largest_cp_id = 0;
				for (entity cp = NULL; (cp = find(cp, classname, "target_checkpoint"));) {
					if (cp.race_checkpoint > largest_cp_id) {
						largest_cp_id = cp.race_checkpoint;
					}
				}
				for (entity cp = NULL; (cp = find(cp, classname, "target_stopTimer"));) {
					cp.race_checkpoint = largest_cp_id + 1; // finish line
				}
				race_highest_checkpoint = largest_cp_id + 1;
				race_timed_checkpoint = largest_cp_id + 1;
			} else {
				for (entity cp = NULL; (cp = find(cp, classname, "target_stopTimer"));) {
					cp.race_checkpoint = 255; // finish line
				}
				race_highest_checkpoint = 255;
				race_timed_checkpoint = 255;
			}
		} else {
			IL_EACH(g_racecheckpoints, it.sprite,
			{
				if (it.race_checkpoint == 0) {
					WaypointSprite_UpdateSprites(it.sprite, WP_RaceStart, WP_Null, WP_Null);
				} else if (it.race_checkpoint == race_timed_checkpoint) {
					WaypointSprite_UpdateSprites(it.sprite, WP_RaceFinish, WP_Null, WP_Null);
				}
			});
		}
	}

	if (defrag_ents) { /* The following hack shall be removed when per-player trigger_multiple.wait is implemented for cts */
		for (entity trigger = NULL; (trigger = find(trigger, classname, "trigger_multiple")); ) {
			for (entity targ = NULL; (targ = find(targ, targetname, trigger.target)); ) {
				if (targ.classname == "target_checkpoint" || targ.classname == "target_startTimer" || targ.classname == "target_stopTimer") {
					trigger.wait = 0;
					trigger.delay = 0;
					targ.wait = 0;
					targ.delay = 0;

                    // These just make the game crash on some maps with oddly shaped triggers.
                    // (on the other hand they used to fix the case when two players ran through a checkpoint at once,
                    // and often one of them just passed through without being registered. Hope it's fixed  in a better way now.
                    // (happened on item triggers too)
                    //
					//targ.wait = -2;
					//targ.delay = 0;

					//setsize(targ, trigger.mins, trigger.maxs);
					//setorigin(targ, trigger.origin);
					//remove(trigger);
				}
            }
        }
	}
}

vector trigger_race_checkpoint_spawn_evalfunc(entity this, entity player, entity spot, vector current)
{
	if(g_race_qualifying)
	{
		// spawn at first
		if(this.race_checkpoint != 0)
			return '-1 0 0';
		if(spot.race_place != race_lowest_place_spawn)
			return '-1 0 0';
	}
	else
	{
		if(this.race_checkpoint != player.race_respawn_checkpoint)
			return '-1 0 0';
		// try reusing the previous spawn
		if(this == player.race_respawn_spotref || spot == player.race_respawn_spotref)
			current.x += SPAWN_PRIO_RACE_PREVIOUS_SPAWN;
		if(this.race_checkpoint == 0)
		{
			int pl = player.race_place;
			if(pl > race_highest_place_spawn)
				pl = 0;
			if(pl == 0 && !player.race_started)
				pl = race_highest_place_spawn; // use last place if they have not even touched finish yet
			if(spot.race_place != pl)
				return '-1 0 0';
		}
	}
	return current;
}

spawnfunc(trigger_race_checkpoint)
{
	vector o;
	if(!g_race && !g_cts) { delete(this); return; }

	EXACTTRIGGER_INIT;

	this.use = checkpoint_use;
	if (!(this.spawnflags & 1))
		settouch(this, checkpoint_touch);

	o = (this.absmin + this.absmax) * 0.5;
	tracebox(o, PL_MIN_CONST, PL_MAX_CONST, o - '0 0 1' * (o.z - this.absmin.z), MOVE_NORMAL, this);
	waypoint_spawnforitem_force(this, trace_endpos);
	this.nearestwaypointtimeout = -1;

	if(this.message == "")
		this.message = "went backwards";
	if (this.message2 == "")
		this.message2 = "was pushed backwards by";
	if (this.race_penalty_reason == "")
		this.race_penalty_reason = "missing a checkpoint";

	this.race_checkpoint = this.cnt;

	if(this.race_checkpoint > race_highest_checkpoint)
	{
		race_highest_checkpoint = this.race_checkpoint;
		if(this.spawnflags & 8)
			race_timed_checkpoint = this.race_checkpoint;
		else
			race_timed_checkpoint = 0;
	}

	if(!this.race_penalty)
	{
		if(this.race_checkpoint)
			WaypointSprite_SpawnFixed(WP_RaceCheckpoint, o, this, sprite, RADARICON_NONE);
		else
			WaypointSprite_SpawnFixed(WP_RaceStartFinish, o, this, sprite, RADARICON_NONE);
	}

	this.sprite.waypointsprite_visible_for_player = race_waypointsprite_visible_for_player;
	this.spawn_evalfunc = trigger_race_checkpoint_spawn_evalfunc;

	if (!g_racecheckpoints)
		g_racecheckpoints = IL_NEW();
	IL_PUSH(g_racecheckpoints, this);

	// trigger_race_checkpoint_verify checks this list too
	if (!g_race_targets)
		g_race_targets = IL_NEW();

	InitializeEntity(this, trigger_race_checkpoint_verify, INITPRIO_FINDTARGET);
}

void target_checkpoint_setup(entity this)
{
	if(!g_race && !g_cts) { delete(this); return; }
	defrag_ents = 1;

	// if this is targeted, then it probably isn't a trigger
	bool is_trigger = this.targetname == "";

	if(is_trigger)
		EXACTTRIGGER_INIT;

	this.use = checkpoint_use;
	if (is_trigger && !(this.spawnflags & 1))
		settouch(this, checkpoint_touch);

	vector org = this.origin;

	// bots should only pathfind to this if it is a valid touchable trigger
	if(is_trigger)
	{
		org = (this.absmin + this.absmax) * 0.5;
		tracebox(org, PL_MIN_CONST, PL_MAX_CONST, org - '0 0 1' * (org.z - this.absmin.z), MOVE_NORMAL, this);
		waypoint_spawnforitem_force(this, trace_endpos);
		this.nearestwaypointtimeout = -1;
	}

	if(this.message == "")
		this.message = "went backwards";
	if (this.message2 == "")
		this.message2 = "was pushed backwards by";
	if (this.race_penalty_reason == "")
		this.race_penalty_reason = "missing a checkpoint";

	if(this.classname == "target_startTimer")
		this.race_checkpoint = 0;
	else
		this.race_checkpoint = -2;

	race_timed_checkpoint = 1;

	if (!g_race_targets)
		g_race_targets = IL_NEW();
	IL_PUSH(g_race_targets, this);

	// trigger_race_checkpoint_verify checks this list too
	if (!g_racecheckpoints)
		g_racecheckpoints = IL_NEW();

	InitializeEntity(this, trigger_race_checkpoint_verify, INITPRIO_FINDTARGET);
}

spawnfunc(target_checkpoint)
{
	// xonotic defrag entity
	target_checkpoint_setup(this);
}

// compatibility entity names
spawnfunc(target_startTimer) { target_checkpoint_setup(this); }
spawnfunc(target_stopTimer) { target_checkpoint_setup(this); }

void race_AbandonRaceCheck(entity p)
{
	if(race_completing && !CS(p).race_completed)
	{
		CS(p).race_completed = 1;
		MAKE_INDEPENDENT_PLAYER(p);
		Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_RACE_ABANDONED, p.netname);
		ClientData_Touch(p);
	}
}

void race_StartCompleting()
{
	race_completing = 1;
	FOREACH_CLIENT(IS_PLAYER(it) && IS_DEAD(it), { race_AbandonRaceCheck(it); });
}

void race_PreparePlayer(entity this)
{
	race_ClearTime(this);
	this.race_place = 0;
	this.race_started = 0;
	this.race_respawn_checkpoint = 0;
	this.race_respawn_spotref = NULL;
}

void race_RetractPlayer(entity this)
{
	if(!g_race && !g_cts)
		return;
	if(this.race_respawn_checkpoint == 0 || this.race_respawn_checkpoint == race_timed_checkpoint)
		race_ClearTime(this);
	this.race_checkpoint = this.race_respawn_checkpoint;
}

spawnfunc(info_player_race)
{
	if(!g_race && !g_cts) { delete(this); return; }
	++race_spawns;
	spawnfunc_info_player_deathmatch(this);

	if(this.race_place > race_highest_place_spawn)
		race_highest_place_spawn = this.race_place;
	if(this.race_place < race_lowest_place_spawn)
		race_lowest_place_spawn = this.race_place;
}

void race_ClearPlayerRecords(entity player)
{
	for(int i = 0; i < MAX_CHECKPOINTS; ++i)
	{
		player.race_checkpoint_record[i] = 0;
		player.race_checkpoint_recordspeed[i] = 0;
	}
}

void race_ClearRecords()
{
	for(int j = 0; j < MAX_CHECKPOINTS; ++j)
	{
		race_checkpoint_records[j] = 0;
		race_checkpoint_recordspeeds[j] = 0;
		strfree(race_checkpoint_recordholders[j]);
	}

	FOREACH_CLIENT(true, {
		float p = it.race_place;
		race_PreparePlayer(it);
		it.race_place = p;
	});
}

void race_ImposePenaltyTime(entity pl, float penalty, string reason)
{
	if(g_race_qualifying)
	{
		pl.race_penalty_accumulator += penalty;
		if(IS_REAL_CLIENT(pl))
		{
			msg_entity = pl;
			WRITESPECTATABLE_MSG_ONE(msg_entity, {
				WriteHeader(MSG_ONE, TE_CSQC_RACE);
				WriteByte(MSG_ONE, RACE_NET_PENALTY_QUALIFYING);
				WriteShort(MSG_ONE, TIME_ENCODE(penalty));
				WriteString(MSG_ONE, reason);
			});
		}
	}
	else
	{
		pl.race_penalty = time + penalty;
		if(IS_REAL_CLIENT(pl))
		{
			msg_entity = pl;
			WRITESPECTATABLE_MSG_ONE(msg_entity, {
				WriteHeader(MSG_ONE, TE_CSQC_RACE);
				WriteByte(MSG_ONE, RACE_NET_PENALTY_RACE);
				WriteShort(MSG_ONE, TIME_ENCODE(penalty));
				WriteString(MSG_ONE, reason);
			});
		}
	}
}

void penalty_touch(entity this, entity toucher)
{
	EXACTTRIGGER_TOUCH(this, toucher);
	if(toucher.race_lastpenalty != this)
	{
		toucher.race_lastpenalty = this;
		race_ImposePenaltyTime(toucher, this.race_penalty, this.race_penalty_reason);
	}
}

void penalty_use(entity this, entity actor, entity trigger)
{
	race_ImposePenaltyTime(actor, this.race_penalty, this.race_penalty_reason);
}

spawnfunc(trigger_race_penalty)
{
	// TODO: find out why this wasnt done:
	//if(!g_cts && !g_race) { remove(this); return; }

	EXACTTRIGGER_INIT;

	this.use = penalty_use;
	if (!(this.spawnflags & 1))
		settouch(this, penalty_touch);

	if (this.race_penalty_reason == "")
		this.race_penalty_reason = "missing a checkpoint";
	if (!this.race_penalty)
		this.race_penalty = 5;
}

float race_GetFractionalLapCount(entity e)
{
	// interesting metrics (idea by KrimZon) to maybe sort players in the
	// scoreboard, immediately updates when overtaking
	//
	// requires the track to be built so you never get farther away from the
	// next checkpoint, though, and current Xonotic race maps are not built that
	// way
	//
	// also, this code is slow and would need optimization (i.e. "next CP"
	// links on CP entities)

	float l;
	l = GameRules_scoring_add(e, RACE_LAPS, 0);
	if(CS(e).race_completed)
		return l; // not fractional

	vector o0, o1;
	float bestfraction, fraction;
	entity lastcp;
	float nextcpindex, lastcpindex;

	nextcpindex = max(e.race_checkpoint, 0);
	lastcpindex = e.race_respawn_checkpoint;
	lastcp = e.race_respawn_spotref;

	if(nextcpindex == lastcpindex)
		return l; // finish

	bestfraction = 1;
	IL_EACH(g_racecheckpoints, true,
	{
		if(it.race_checkpoint != lastcpindex)
			continue;
		if(lastcp)
			if(it != lastcp)
				continue;
		o0 = (it.absmin + it.absmax) * 0.5;
		IL_EACH(g_racecheckpoints, true,
		{
			if(it.race_checkpoint != nextcpindex)
				continue;
			o1 = (it.absmin + it.absmax) * 0.5;
			if(o0 == o1)
				continue;
			fraction = bound(0.0001, vlen(e.origin - o1) / vlen(o0 - o1), 1);
			if(fraction < bestfraction)
				bestfraction = fraction;
		});
	});

	// we are at CP "nextcpindex - bestfraction"
	// race_timed_checkpoint == 4: then nextcp==4 means 0.9999x, nextcp==0 means 0.0000x
	// race_timed_checkpoint == 0: then nextcp==0 means 0.9999x
	float c, nc;
	nc = race_highest_checkpoint + 1;
	c = ((nextcpindex - race_timed_checkpoint + nc + nc - 1) % nc) + 1 - bestfraction;

	return l + c / nc;
}
