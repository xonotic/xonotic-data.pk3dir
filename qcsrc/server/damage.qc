#include "damage.qh"

#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/effects/all.qh>
#include <common/gametypes/_mod.qh>
#include <common/gametypes/rules.qh>
#include <common/items/_mod.qh>
#include <common/mapobjects/defs.qh>
#include <common/mapobjects/triggers.qh>
#include <common/mutators/mutator/buffs/_mod.qh>
#include <common/mutators/mutator/instagib/sv_instagib.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/mutators/mutator/waypoints/waypointsprites.qh>
#include <common/notifications/all.qh>
#include <common/physics/movetypes/movetypes.qh>
#include <common/physics/player.qh>
#include <common/playerstats.qh>
#include <common/resources/sv_resources.qh>
#include <common/state.qh>
#include <common/teams.qh>
#include <common/util.qh>
#include <common/vehicles/all.qh>
#include <common/weapons/_all.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <lib/warpzone/common.qh>
#include <server/bot/api.qh>
#include <server/client.qh>
#include <server/gamelog.qh>
#include <server/hook.qh>
#include <server/items/items.qh>
#include <server/main.qh>
#include <server/mutators/_mod.qh>
#include <server/scores.qh>
#include <server/spawnpoints.qh>
#include <server/teamplay.qh>
#include <server/weapons/accuracy.qh>
#include <server/weapons/csqcprojectile.qh>
#include <server/weapons/selection.qh>
#include <server/weapons/weaponsystem.qh>
#include <server/world.qh>

void GiveFrags(entity attacker, entity targ, float f, int deathtype, .entity weaponentity)
{
	// TODO route through PlayerScores instead
	if(game_stopped) return;

	if(f < 0)
	{
		if(targ == attacker)
		{
			// suicide
			GameRules_scoring_add(attacker, SUICIDES, 1);
		}
		else
		{
			// teamkill
			GameRules_scoring_add(attacker, TEAMKILLS, 1);
		}
	}
	else
	{
		// regular frag
		GameRules_scoring_add(attacker, KILLS, 1);
		if(!warmup_stage && targ.playerid)
			PlayerStats_GameReport_Event_Player(attacker, sprintf("kills-%d", targ.playerid), 1);
	}

	GameRules_scoring_add(targ, DEATHS, 1);

	// FIXME fix the mess this is (we have REAL points now!)
	if(MUTATOR_CALLHOOK(GiveFragsForKill, attacker, targ, f, deathtype, attacker.(weaponentity)))
		f = M_ARGV(2, float);

	attacker.totalfrags += f;

	if(f)
		GameRules_scoring_add_team(attacker, SCORE, f);
}

string AppendItemcodes(string s, entity player)
{
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		int w = player.(weaponentity).m_weapon.m_id;
		if(w == 0)
			w = player.(weaponentity).cnt; // previous weapon
		if(w != 0 || slot == 0)
			s = strcat(s, ftos(w));
	}
	if(PHYS_INPUT_BUTTON_CHAT(player))
		s = strcat(s, "T");
	// TODO: include these codes as a flag on the item itself
	MUTATOR_CALLHOOK(LogDeath_AppendItemCodes, player, s);
	s = M_ARGV(1, string);
	return s;
}

void LogDeath(string mode, int deathtype, entity killer, entity killed)
{
	string s;
	if(!autocvar_sv_eventlog)
		return;
	s = strcat(":kill:", mode);
	s = strcat(s, ":", ftos(killer.playerid));
	s = strcat(s, ":", ftos(killed.playerid));
	s = strcat(s, ":type=", Deathtype_Name(deathtype));
	s = strcat(s, ":items=");
	s = AppendItemcodes(s, killer);
	if(killed != killer)
	{
		s = strcat(s, ":victimitems=");
		s = AppendItemcodes(s, killed);
	}
	GameLogEcho(s);
}

void Obituary_SpecialDeath(
	entity notif_target,
	float murder,
	bool msg_from_ent,
	int deathtype,
	string s1, string s2, string s3, string s4,
	float f1, float f2, float f3)
{
	if(!DEATH_ISSPECIAL(deathtype))
	{
		backtrace("Obituary_SpecialDeath called without a special deathtype?\n");
		return;
	}

	entity deathent = REGISTRY_GET(Deathtypes, deathtype - DT_FIRST);
	if (!deathent)
	{
		backtrace("Obituary_SpecialDeath: Could not find deathtype entity!\n");
		return;
	}

	if(g_cts && deathtype == DEATH_KILL.m_id)
		return; // TODO: somehow put this in CTS gametype file!

	Notification death_message = (murder) ? deathent.death_msgmurder : deathent.death_msgself;
	if (msg_from_ent)
		death_message = (murder) ? deathent.death_msg_ent_murder : deathent.death_msg_ent_self;
	if(death_message)
	{
		Send_Notification_WOCOVA(
			NOTIF_ONE,
			notif_target,
			MSG_MULTI,
			death_message,
			s1, s2, s3, s4,
			f1, f2, f3, 0
		);
		Send_Notification_WOCOVA(
			NOTIF_ALL_EXCEPT,
			notif_target,
			MSG_INFO,
			death_message.nent_msginfo,
			s1, s2, s3, s4,
			f1, f2, f3, 0
		);
	}
}

float Obituary_WeaponDeath(
	entity notif_target,
	float murder,
	int deathtype,
	string s1, string s2, string s3,
	float f1, float f2)
{
	Weapon death_weapon = DEATH_WEAPONOF(deathtype);
	if (death_weapon == WEP_Null)
		return false;

	w_deathtype = deathtype;
	Notification death_message = ((murder) ? death_weapon.wr_killmessage(death_weapon) : death_weapon.wr_suicidemessage(death_weapon));
	w_deathtype = false;

	if (death_message)
	{
		Send_Notification_WOCOVA(
			NOTIF_ONE,
			notif_target,
			MSG_MULTI,
			death_message,
			s1, s2, s3, "",
			f1, f2, 0, 0
		);
		// send the info part to everyone
		Send_Notification_WOCOVA(
			NOTIF_ALL_EXCEPT,
			notif_target,
			MSG_INFO,
			death_message.nent_msginfo,
			s1, s2, s3, "",
			f1, f2, 0, 0
		);
	}
	else
	{
		LOG_TRACEF(
			"Obituary_WeaponDeath(): ^1Deathtype ^7(%d)^1 has no notification for weapon %s!\n",
			deathtype,
			death_weapon.netname
		);
	}

	return true;
}

bool frag_centermessage_override(entity attacker, entity targ, int deathtype, int kill_count_to_attacker, int kill_count_to_target, string attacker_name)
{
	if(deathtype == DEATH_FIRE.m_id)
	{
		Send_Notification(NOTIF_ONE, attacker, MSG_CHOICE, CHOICE_FRAG_FIRE, targ.netname, kill_count_to_attacker, (IS_BOT_CLIENT(targ) ? -1 : CS(targ).ping));
		Send_Notification(NOTIF_ONE, targ, MSG_CHOICE, CHOICE_FRAGGED_FIRE, attacker_name, kill_count_to_target, GetResource(attacker, RES_HEALTH), GetResource(attacker, RES_ARMOR), (IS_BOT_CLIENT(attacker) ? -1 : CS(attacker).ping));
		return true;
	}

	return MUTATOR_CALLHOOK(FragCenterMessage, attacker, targ, deathtype, kill_count_to_attacker, kill_count_to_target);
}

void Obituary(entity attacker, entity inflictor, entity targ, int deathtype, .entity weaponentity)
{
	// Sanity check
	if (!IS_PLAYER(targ)) { backtrace("Obituary called on non-player?!\n"); return; }

	// Declarations
	float notif_firstblood = false;
	float kill_count_to_attacker, kill_count_to_target;
	bool notif_anonymous = false;
	string attacker_name = attacker.netname;

	// Set final information for the death
	targ.death_origin = targ.origin;
	string deathlocation = (autocvar_notification_server_allows_location ? NearestLocation(targ.death_origin) : "");

	// Abort now if a mutator requests it
	if (MUTATOR_CALLHOOK(ClientObituary, inflictor, attacker, targ, deathtype, attacker.(weaponentity))) { CS(targ).killcount = 0; return; }
	notif_anonymous = M_ARGV(5, bool);

	// TODO: Replace "???" with a translatable "Anonymous player" string
	// https://gitlab.com/xonotic/xonotic-data.pk3dir/-/issues/2839
	if(notif_anonymous)
		attacker_name = "???";

	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(
		sprintf(
			"Obituary(%s, %s, %s, %s = %d);\n",
			attacker_name,
			inflictor.netname,
			targ.netname,
			Deathtype_Name(deathtype),
			deathtype
		)
	);
	#endif

	// =======
	// SUICIDE
	// =======
	if(targ == attacker)
	{
		if(DEATH_ISSPECIAL(deathtype))
		{
			if(deathtype == DEATH_TEAMCHANGE.m_id || deathtype == DEATH_AUTOTEAMCHANGE.m_id)
			{
				Obituary_SpecialDeath(targ, false, 0, deathtype, targ.netname, deathlocation, "", "", targ.team, 0, 0);
			}
			else
			{
				switch(DEATH_ENT(deathtype))
				{
					case DEATH_MIRRORDAMAGE:
					{
						Obituary_SpecialDeath(targ, false, 0, deathtype, targ.netname, deathlocation, "", "", CS(targ).killcount, 0, 0);
						break;
					}
					case DEATH_HURTTRIGGER:
						bool msg_from_ent = (inflictor && inflictor.message != "");
						Obituary_SpecialDeath(targ, false, msg_from_ent, deathtype,
							targ.netname,
							(msg_from_ent ? inflictor.message : deathlocation),
							(msg_from_ent ? deathlocation : ""),
							"", CS(targ).killcount, 0, 0);
						break;
					default:
					{
						Obituary_SpecialDeath(targ, false, 0, deathtype, targ.netname, deathlocation, "", "", CS(targ).killcount, 0, 0);
						break;
					}
				}
			}
		}
		else if (!Obituary_WeaponDeath(targ, false, deathtype, targ.netname, deathlocation, "", CS(targ).killcount, 0))
		{
			backtrace("SUICIDE: what the hell happened here?\n");
			return;
		}
		LogDeath("suicide", deathtype, targ, targ);
		if(deathtype != DEATH_AUTOTEAMCHANGE.m_id) // special case: don't negate frags if auto switched
			GiveFrags(attacker, targ, -1, deathtype, weaponentity);
	}

	// ======
	// MURDER
	// ======
	else if(IS_PLAYER(attacker))
	{
		if(SAME_TEAM(attacker, targ))
		{
			LogDeath("tk", deathtype, attacker, targ);
			GiveFrags(attacker, targ, -1, deathtype, weaponentity);

			CS(attacker).killcount = 0;

			Send_Notification(NOTIF_ONE, attacker, MSG_CENTER, CENTER_DEATH_TEAMKILL_FRAG, targ.netname);
			Send_Notification(NOTIF_ONE, targ, MSG_CENTER, CENTER_DEATH_TEAMKILL_FRAGGED, attacker_name);
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(targ.team, INFO_DEATH_TEAMKILL), targ.netname, attacker_name, deathlocation, CS(targ).killcount);

			// In this case, the death message will ALWAYS be "foo was betrayed by bar"
			// No need for specific death/weapon messages...
		}
		else
		{
			LogDeath("frag", deathtype, attacker, targ);
			GiveFrags(attacker, targ, 1, deathtype, weaponentity);

			CS(attacker).taunt_soundtime = time + 1;
			CS(attacker).killcount = CS(attacker).killcount + 1;

			attacker.killsound += 1;

			// TODO: improve SPREE_ITEM and KILL_SPREE_LIST
			// these 2 macros are spread over multiple files
			#define SPREE_ITEM(counta,countb,center,normal,gentle) \
				case counta: \
					Send_Notification(NOTIF_ONE, attacker, MSG_ANNCE, ANNCE_KILLSTREAK_##countb); \
					if (!warmup_stage) \
						PlayerStats_GameReport_Event_Player(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_##counta, 1); \
					break;

			switch(CS(attacker).killcount)
			{
				KILL_SPREE_LIST
				default: break;
			}
			#undef SPREE_ITEM

			if(!warmup_stage && !checkrules_firstblood)
			{
				checkrules_firstblood = true;
				notif_firstblood = true; // modify the current messages so that they too show firstblood information
				PlayerStats_GameReport_Event_Player(attacker, PLAYERSTATS_ACHIEVEMENT_FIRSTBLOOD, 1);
				PlayerStats_GameReport_Event_Player(targ, PLAYERSTATS_ACHIEVEMENT_FIRSTVICTIM, 1);

				// tell spree_inf and spree_cen that this is a first-blood and first-victim event
				kill_count_to_attacker = -1;
				kill_count_to_target = -2;
			}
			else
			{
				kill_count_to_attacker = CS(attacker).killcount;
				kill_count_to_target = 0;
			}

			if(targ.istypefrag)
			{
				Send_Notification(
					NOTIF_ONE,
					attacker,
					MSG_CHOICE,
					CHOICE_TYPEFRAG,
					targ.netname,
					kill_count_to_attacker,
					(IS_BOT_CLIENT(targ) ? -1 : CS(targ).ping)
				);
				Send_Notification(
					NOTIF_ONE,
					targ,
					MSG_CHOICE,
					CHOICE_TYPEFRAGGED,
					attacker_name,
					kill_count_to_target,
					GetResource(attacker, RES_HEALTH),
					GetResource(attacker, RES_ARMOR),
					(IS_BOT_CLIENT(attacker) ? -1 : CS(attacker).ping)
				);
			}
			else if(!frag_centermessage_override(attacker, targ, deathtype, kill_count_to_attacker, kill_count_to_target, attacker_name))
			{
				Send_Notification(
					NOTIF_ONE,
					attacker,
					MSG_CHOICE,
					CHOICE_FRAG,
					targ.netname,
					kill_count_to_attacker,
					(IS_BOT_CLIENT(targ) ? -1 : CS(targ).ping)
				);
				Send_Notification(
					NOTIF_ONE,
					targ,
					MSG_CHOICE,
					CHOICE_FRAGGED,
					attacker_name,
					kill_count_to_target,
					GetResource(attacker, RES_HEALTH),
					GetResource(attacker, RES_ARMOR),
					(IS_BOT_CLIENT(attacker) ? -1 : CS(attacker).ping)
				);
			}

			int f3 = 0;
			if(deathtype == DEATH_BUFF.m_id)
				f3 = buff_FirstFromFlags(attacker).m_id;

			if (!Obituary_WeaponDeath(targ, true, deathtype, targ.netname, attacker_name, deathlocation, CS(targ).killcount, kill_count_to_attacker))
			{
				if (DEATH_ENT(deathtype) == DEATH_HURTTRIGGER)
				{
					bool msg_from_ent = (inflictor && inflictor.message2 != "");
					Obituary_SpecialDeath(targ, true, msg_from_ent, deathtype,
						targ.netname,
						attacker_name,
						(msg_from_ent ? inflictor.message2 : deathlocation),
						(msg_from_ent ? deathlocation : ""),
						CS(targ).killcount, kill_count_to_attacker, f3);
				}
				else
					Obituary_SpecialDeath(targ, true, 0, deathtype, targ.netname, attacker_name, deathlocation, "", CS(targ).killcount, kill_count_to_attacker, f3);
			}
		}
	}

	// =============
	// ACCIDENT/TRAP
	// =============
	else
	{
		switch(DEATH_ENT(deathtype))
		{
			// For now, we're just forcing HURTTRIGGER to behave as "DEATH_VOID" and giving it no special options...
			// Later on you will only be able to make custom messages using DEATH_CUSTOM,
			// and there will be a REAL DEATH_VOID implementation which mappers will use.
			case DEATH_HURTTRIGGER:
			{
				bool msg_from_ent = (inflictor && inflictor.message != "");
				Obituary_SpecialDeath(targ, false, msg_from_ent, deathtype,
					targ.netname,
					(msg_from_ent ? inflictor.message : deathlocation),
					(msg_from_ent ? deathlocation : ""),
					"",
					CS(targ).killcount,
					0,
					0);
				break;
			}

			case DEATH_CUSTOM:
			{
				Obituary_SpecialDeath(targ, false, 0, deathtype,
					targ.netname,
					((strstrofs(deathmessage, "%", 0) < 0) ? strcat("%s ", deathmessage) : deathmessage),
					deathlocation,
					"",
					CS(targ).killcount,
					0,
					0);
				break;
			}

			default:
			{
				Obituary_SpecialDeath(targ, false, 0, deathtype, targ.netname, deathlocation, "", "", CS(targ).killcount, 0, 0);
				break;
			}
		}

		LogDeath("accident", deathtype, targ, targ);
		GiveFrags(targ, targ, -1, deathtype, weaponentity);

		if(GameRules_scoring_add(targ, SCORE, 0) == -5)
		{
			Send_Notification(NOTIF_ONE, targ, MSG_ANNCE, ANNCE_ACHIEVEMENT_BOTLIKE);
			if (!warmup_stage)
			{
				PlayerStats_GameReport_Event_Player(attacker, PLAYERSTATS_ACHIEVEMENT_BOTLIKE, 1);
			}
		}
	}

	// reset target kill count
	CS(targ).killcount = 0;
}

void Damage(entity targ, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	float complainteamdamage = 0;
	float mirrordamage = 0;
	float mirrorforce = 0;

	if (game_stopped || (IS_CLIENT(targ) && CS(targ).killcount == FRAGS_SPECTATOR))
		return;

	entity attacker_save = attacker;

	// special rule: gravity bombs and sound-based attacks do not affect teammates (other than for disconnecting the hook)
	if(DEATH_ISWEAPON(deathtype, WEP_HOOK) || (deathtype & HITTYPE_SOUND))
	{
		if(IS_PLAYER(targ) && SAME_TEAM(targ, attacker))
		{
			return;
		}
	}

	if(deathtype == DEATH_KILL.m_id || deathtype == DEATH_TEAMCHANGE.m_id || deathtype == DEATH_AUTOTEAMCHANGE.m_id)
	{
		// exit the vehicle before killing (fixes a crash)
		if(IS_PLAYER(targ) && targ.vehicle)
			vehicles_exit(targ.vehicle, VHEF_RELEASE);

		// These are ALWAYS lethal
		// No damage modification here
		// Instead, prepare the victim for their death...
		if(deathtype == DEATH_TEAMCHANGE.m_id || deathtype == DEATH_AUTOTEAMCHANGE.m_id)
		{
			SetResourceExplicit(targ, RES_ARMOR, 0);
			SetResourceExplicit(targ, RES_HEALTH, 0.9); // this is < 1
		}
		StatusEffects_remove(STATUSEFFECT_SpawnShield, targ, STATUSEFFECT_REMOVE_CLEAR);
		targ.flags -= targ.flags & FL_GODMODE;
		damage = 100000;
	}
	else if(deathtype == DEATH_MIRRORDAMAGE.m_id || deathtype == DEATH_NOAMMO.m_id)
	{
		// no processing
	}
	else
	{
		// nullify damage if teamplay is on
		if(deathtype != DEATH_TELEFRAG.m_id)
		if(IS_PLAYER(attacker))
		{
			// avoid dealing damage or force to other independent players
			// and avoid dealing damage or force to things owned by other independent players
			if((IS_PLAYER(targ) && targ != attacker && (IS_INDEPENDENT_PLAYER(attacker) || IS_INDEPENDENT_PLAYER(targ))) ||
				(targ.realowner && IS_INDEPENDENT_PLAYER(targ.realowner) && attacker != targ.realowner))
			{
				damage = 0;
				force = '0 0 0';
			}
			else if(!STAT(FROZEN, targ) && SAME_TEAM(attacker, targ))
			{
				if(autocvar_teamplay_mode == 1)
					damage = 0;
				else if(attacker != targ)
				{
					if(autocvar_teamplay_mode == 2)
					{
						if(IS_PLAYER(targ) && !IS_DEAD(targ))
						{
							attacker.dmg_team = attacker.dmg_team + damage;
							complainteamdamage = attacker.dmg_team - autocvar_g_teamdamage_threshold;
						}
					}
					else if(autocvar_teamplay_mode == 3)
						damage = 0;
					else if(autocvar_teamplay_mode == 4)
					{
						if(IS_PLAYER(targ) && !IS_DEAD(targ))
						{
							attacker.dmg_team = attacker.dmg_team + damage;
							complainteamdamage = attacker.dmg_team - autocvar_g_teamdamage_threshold;
							if(complainteamdamage > 0)
								mirrordamage = autocvar_g_mirrordamage * complainteamdamage;
							mirrorforce = autocvar_g_mirrordamage * vlen(force);
							damage = autocvar_g_friendlyfire * damage;
							// mirrordamage will be used LATER

							if(autocvar_g_mirrordamage_virtual)
							{
								vector v  = healtharmor_applydamage(GetResource(attacker, RES_ARMOR), autocvar_g_balance_armor_blockpercent, deathtype, mirrordamage);
								attacker.dmg_take += v.x;
								attacker.dmg_save += v.y;
								attacker.dmg_inflictor = inflictor;
								mirrordamage = v.z;
								mirrorforce = 0;
							}

							if(autocvar_g_friendlyfire_virtual)
							{
								vector v = healtharmor_applydamage(GetResource(targ, RES_ARMOR), autocvar_g_balance_armor_blockpercent, deathtype, damage);
								targ.dmg_take += v.x;
								targ.dmg_save += v.y;
								targ.dmg_inflictor = inflictor;
								damage = 0;
								if(!autocvar_g_friendlyfire_virtual_force)
									force = '0 0 0';
							}
						}
						else if(!targ.canteamdamage)
							damage = 0;
					}
				}
			}
		}

		if (!DEATH_ISSPECIAL(deathtype))
		{
			damage *= autocvar_g_weapondamagefactor;
			mirrordamage *= autocvar_g_weapondamagefactor;
			complainteamdamage *= autocvar_g_weapondamagefactor;
			force = force * autocvar_g_weaponforcefactor;
			mirrorforce *= autocvar_g_weaponforcefactor;
		}

		// should this be changed at all? If so, in what way?
		MUTATOR_CALLHOOK(Damage_Calculate, inflictor, attacker, targ, deathtype, damage, mirrordamage, force, attacker.(weaponentity));
		damage = M_ARGV(4, float);
		mirrordamage = M_ARGV(5, float);
		force = M_ARGV(6, vector);

		if(IS_PLAYER(targ) && damage > 0 && attacker)
		{
			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity went = weaponentities[slot];
				if(targ.(went).hook && targ.(went).hook.aiment == attacker)
					RemoveHook(targ.(went).hook);
			}
		}

		if (targ == attacker)
			damage = damage * autocvar_g_balance_selfdamagepercent;	// Partial damage if the attacker hits himself

		// count the damage
		if(attacker)
		if(!IS_DEAD(targ))
		if(deathtype != DEATH_BUFF.m_id)
		if(targ.takedamage == DAMAGE_AIM)
		if(targ != attacker)
		{
			entity victim;
			if(IS_VEHICLE(targ) && targ.owner)
				victim = targ.owner;
			else
				victim = targ;

			// TODO: allow the mutator hook to tell if the hit sound should be team or not
			if(IS_PLAYER(victim) || (IS_TURRET(victim) && victim.active == ACTIVE_ACTIVE) || IS_MONSTER(victim) || MUTATOR_CALLHOOK(PlayHitsound, victim, attacker))
			{
				if (DIFF_TEAM(victim, attacker))
				{
					if(damage > 0)
					{
						if(deathtype != DEATH_FIRE.m_id)
						{
							if(PHYS_INPUT_BUTTON_CHAT(victim))
								attacker.typehitsound += 1;
							else
								attacker.hitsound_damage_dealt += damage;
						}

						impressive_hits += 1;

						if (!DEATH_ISSPECIAL(deathtype))
						{
							if(IS_PLAYER(targ)) // don't do this for vehicles
							if(IsFlying(victim))
								yoda = 1;
						}
					}
				}
				else if (IS_PLAYER(attacker) && !STAT(FROZEN, victim) && !(deathtype & HITTYPE_SPAM)) // same team
				{
					if (deathtype != DEATH_FIRE.m_id)
					{
						attacker.typehitsound += 1;
					}
					if(complainteamdamage > 0)
						if(time > CS(attacker).teamkill_complain)
						{
							CS(attacker).teamkill_complain = time + 5;
							CS(attacker).teamkill_soundtime = time + 0.4;
							CS(attacker).teamkill_soundsource = targ;
						}
				}
			}
		}
	}

	// apply push
	if (targ.damageforcescale)
	if (force)
	if (!IS_PLAYER(targ) || !StatusEffects_active(STATUSEFFECT_SpawnShield, targ) || targ == attacker)
	{
		vector farce = damage_explosion_calcpush(targ.damageforcescale * force, targ.velocity, autocvar_g_balance_damagepush_speedfactor);
		if(targ.move_movetype == MOVETYPE_PHYSICS)
		{
			entity farcent = new(farce);
			farcent.enemy = targ;
			farcent.movedir = farce * 10;
			if(targ.mass)
				farcent.movedir = farcent.movedir * targ.mass;
			farcent.origin = hitloc;
			farcent.forcetype = FORCETYPE_FORCEATPOS;
			farcent.nextthink = time + 0.1;
			setthink(farcent, SUB_Remove);
		}
		else if(targ.move_movetype != MOVETYPE_NOCLIP)
		{
			targ.velocity = targ.velocity + farce;
		}
		UNSET_ONGROUND(targ);
		UpdateCSQCProjectile(targ);
	}
	// apply damage
	if (damage != 0 || (targ.damageforcescale && force))
	if (targ.event_damage)
		targ.event_damage (targ, inflictor, attacker, damage, deathtype, weaponentity, hitloc, force);

	// apply mirror damage if any
	if(!autocvar_g_mirrordamage_onlyweapons || DEATH_WEAPONOF(deathtype) != WEP_Null)
	if(mirrordamage > 0 || mirrorforce > 0)
	{
		attacker = attacker_save;

		force = normalize(attacker.origin + attacker.view_ofs - hitloc) * mirrorforce;
		Damage(attacker, inflictor, attacker, mirrordamage, DEATH_MIRRORDAMAGE.m_id, weaponentity, attacker.origin, force);
	}
}

// Returns total damage applies to creatures
float RadiusDamageForSource (entity inflictor, vector inflictororigin, vector inflictorvelocity, entity attacker, float coredamage, float edgedamage, float rad, entity cantbe, entity mustbe,
								float inflictorselfdamage, float forceintensity, vector forcexyzscale, int deathtype, .entity weaponentity, entity directhitentity)
{
	entity	targ;
	vector	force;
	float   total_damage_to_creatures;
	entity  next;
	float   tfloordmg;
	float   tfloorforce;

	float stat_damagedone;

	if(RadiusDamage_running)
	{
		backtrace("RadiusDamage called recursively! Expect stuff to go HORRIBLY wrong.");
		return 0;
	}

	if (rad < 0) rad = 0;

	RadiusDamage_running = 1;

	tfloordmg = autocvar_g_throughfloor_damage;
	tfloorforce = autocvar_g_throughfloor_force;

	total_damage_to_creatures = 0;

	if(!(deathtype & (HITTYPE_SOUND | HITTYPE_SPAM))) // do not send bandwidth-hogging radial spam attacks
	{
		force = inflictorvelocity;
		if(force == '0 0 0')
			force = '0 0 -1';
		else
			force = normalize(force);
		if(forceintensity >= 0)
			Damage_DamageInfo(inflictororigin, coredamage, edgedamage, rad, forceintensity * force, deathtype, 0, attacker);
		else
			Damage_DamageInfo(inflictororigin, coredamage, edgedamage, -rad, (-forceintensity) * force, deathtype, 0, attacker);
	}

	stat_damagedone = 0;

	targ = WarpZone_FindRadius (inflictororigin, rad + MAX_DAMAGEEXTRARADIUS, false);
	while (targ)
	{
		next = targ.chain;
		if ((targ != inflictor) || inflictorselfdamage)
		if (((cantbe != targ) && !mustbe) || (mustbe == targ))
		if (targ.takedamage)
		{
			// calculate distance from nearest point on target to nearest point on inflictor
			// instead of origin to ensure full damage on impacts

			vector nearest = targ.WarpZone_findradius_nearest;

			// optimize code by getting inflictororigin_wz from WarpZone_FindRadius calculations instead of
			//vector inflictororigin_wz = WarpZone_TransformOrigin(targ, inflictororigin);

			vector inflictororigin_wz = targ.WarpZone_findradius_nearest + targ.WarpZone_findradius_dist;
			vector inflictornearest = NearestPointOnBoundingBox(
				inflictororigin_wz + inflictor.mins, inflictororigin_wz + inflictor.maxs, nearest);
			vector diff = inflictornearest - nearest;

			// round up a little on the damage to ensure full damage on impacts
			// and turn the distance into a fraction of the radius
			float dist = max(0, vlen(diff) - bound(MIN_DAMAGEEXTRARADIUS, targ.damageextraradius, MAX_DAMAGEEXTRARADIUS));
			if (dist <= rad)
			{
				float f = (rad > 0) ? 1 - (dist / rad) : 1;
				// at this point f can't be < 0 or > 1
				float finaldmg = coredamage * f + edgedamage * (1 - f);
				if (finaldmg > 0)
				{
					float a;
					float c;
					vector hitloc;

					// if it's a player, use the view origin as reference
					vector center = CENTER_OR_VIEWOFS(targ);

					if (autocvar_g_player_damageplayercenter)
					{
						if (targ != attacker)
						{
							// always use target's bbox centerpoint
							center = targ.origin + ((targ.mins + targ.maxs) * 0.5);
						}
						else // targ == attacker
						{
						#if 0
							// code stolen from W_SetupShot_Dir_ProjectileSize_Range()
							vector md = targ.(weaponentity).movedir;
							vector dv = v_right * -md.y + v_up * md.z;
							vector mi = '0 0 0', ma = '0 0 0';

							if(IS_CLIENT(targ)) // no antilag for non-clients!
							{
								if(CS(targ).antilag_debug)
									tracebox_antilag(targ, center, mi, ma, center + dv, MOVE_NORMAL, targ, CS(targ).antilag_debug);
								else
									tracebox_antilag(targ, center, mi, ma, center + dv, MOVE_NORMAL, targ, ANTILAG_LATENCY(targ));
							}
							else
								tracebox(center, mi, ma, center + dv, MOVE_NORMAL, targ);

							center.z = trace_endpos.z;
						#else
							// very cheap way but it skips move into solid checks which is fine most of the time for now AFAIK
							// this should only really be an issue with some rare edge cases where
							// shot origin was prevented from going into a ceiling but it still explodes at the ceiling
							// shot origin wasn't raised as high as possible and the shooter gets upwards knockback
							// TL;DR: no bugs if vertical shot origin is always within player bbox
							center.z = center.z + targ.(weaponentity).movedir.z;
						#endif
						}
					}

					/* debug prints
					print(sprintf("origin  vec %v\n", targ.origin));
					print(sprintf("movedir vec %v\n", targ.(weaponentity).movedir));
					print(sprintf("old def vec %v\n", CENTER_OR_VIEWOFS(targ)));
					print(sprintf("origin+vofs %v\n", targ.origin + targ.view_ofs));
					print(sprintf("bbox center %v\n", (targ.origin + ((targ.mins + targ.maxs) * 0.5))));
					print(sprintf("center  vec %v\n", center));
					print(sprintf("shotorg vec %v\n", w_shotorg));
					print("\n");
					*/

					force = normalize(center - inflictororigin_wz);
					force = force * (finaldmg / max(coredamage, edgedamage)) * forceintensity;
					hitloc = nearest;

					// apply special force scalings
					if(forcexyzscale.x)
						force.x *= forcexyzscale.x;
					if(forcexyzscale.y)
						force.y *= forcexyzscale.y;
					if(forcexyzscale.z)
						force.z *= forcexyzscale.z;

					if(targ != directhitentity)
					{
						float hits;
						float total;
						float hitratio;
						float mininv_f, mininv_d;

						// test line of sight to multiple positions on box,
						// and do damage if any of them hit
						hits = 0;

						// we know: max stddev of hitratio = 1 / (2 * sqrt(n))
						// so for a given max stddev:
						// n = (1 / (2 * max stddev of hitratio))^2

						mininv_d = (finaldmg * (1-tfloordmg)) / autocvar_g_throughfloor_damage_max_stddev;
						mininv_f = (vlen(force) * (1-tfloorforce)) / autocvar_g_throughfloor_force_max_stddev;

						if(autocvar_g_throughfloor_debug)
							LOG_INFOF("THROUGHFLOOR: D=%f F=%f max(dD)=1/%f max(dF)=1/%f", finaldmg, vlen(force), mininv_d, mininv_f);


						total = 0.25 * (max(mininv_f, mininv_d) ** 2);

						if(autocvar_g_throughfloor_debug)
							LOG_INFOF(" steps=%f", total);


						if (IS_PLAYER(targ))
							total = ceil(bound(autocvar_g_throughfloor_min_steps_player, total, autocvar_g_throughfloor_max_steps_player));
						else
							total = ceil(bound(autocvar_g_throughfloor_min_steps_other, total, autocvar_g_throughfloor_max_steps_other));

						if(autocvar_g_throughfloor_debug)
							LOG_INFOF(" steps=%f dD=%f dF=%f", total, finaldmg * (1-tfloordmg) / (2 * sqrt(total)), vlen(force) * (1-tfloorforce) / (2 * sqrt(total)));

						for(c = 0; c < total; ++c)
						{
							//traceline(targ.WarpZone_findradius_findorigin, nearest, MOVE_NOMONSTERS, inflictor);
							WarpZone_TraceLine(inflictororigin, WarpZone_UnTransformOrigin(targ, nearest), MOVE_NOMONSTERS, inflictor);
							if (trace_fraction == 1 || trace_ent == targ)
							{
								++hits;
								if (hits > 1)
									hitloc = hitloc + nearest;
								else
									hitloc = nearest;
							}
							nearest.x = targ.origin.x + targ.mins.x + random() * targ.size.x;
							nearest.y = targ.origin.y + targ.mins.y + random() * targ.size.y;
							nearest.z = targ.origin.z + targ.mins.z + random() * targ.size.z;
						}

						nearest = hitloc * (1 / max(1, hits));
						hitratio = (hits / total);
						a = bound(0, tfloordmg + (1-tfloordmg) * hitratio, 1);
						finaldmg = finaldmg * a;
						a = bound(0, tfloorforce + (1-tfloorforce) * hitratio, 1);
						force = force * a;

						if(autocvar_g_throughfloor_debug)
							LOG_INFOF(" D=%f F=%f", finaldmg, vlen(force));

						/*if (targ == attacker)
						{
							print("hits ", ftos(hits), " / ", ftos(total));
							print(" finaldmg ", ftos(finaldmg), " force ", ftos(vlen(force)));
							print(" (", vtos(force), ") (", ftos(a), ")\n");
						}*/
					}

					if(finaldmg || force)
					{
						if(targ.iscreature)
						{
							total_damage_to_creatures += finaldmg;

							if(accuracy_isgooddamage(attacker, targ))
								stat_damagedone += finaldmg;
						}

						if(targ == directhitentity || DEATH_ISSPECIAL(deathtype))
							Damage(targ, inflictor, attacker, finaldmg, deathtype, weaponentity, nearest, force);
						else
							Damage(targ, inflictor, attacker, finaldmg, deathtype | HITTYPE_SPLASH, weaponentity, nearest, force);
					}
				}
			}
		}
		targ = next;
	}

	RadiusDamage_running = 0;

	if(!DEATH_ISSPECIAL(deathtype))
		accuracy_add(attacker, DEATH_WEAPONOF(deathtype), 0, min(max(coredamage, edgedamage), stat_damagedone), 0); // add to hit

	return total_damage_to_creatures;
}

float RadiusDamage(entity inflictor, entity attacker, float coredamage, float edgedamage, float rad, entity cantbe, entity mustbe, float forceintensity, int deathtype, .entity weaponentity, entity directhitentity)
{
	return RadiusDamageForSource(inflictor, (inflictor.origin + (inflictor.mins + inflictor.maxs) * 0.5), inflictor.velocity, attacker, coredamage, edgedamage, rad,
									cantbe, mustbe, false, forceintensity, '1 1 1', deathtype, weaponentity, directhitentity);
}

bool Heal(entity targ, entity inflictor, float amount, float limit)
{
	// TODO: mutator hook to control healing
	if(game_stopped || (IS_CLIENT(targ) && CS(targ).killcount == FRAGS_SPECTATOR) || STAT(FROZEN, targ) || IS_DEAD(targ))
		return false;

	bool healed = false;
	if(targ.event_heal)
		healed = targ.event_heal(targ, inflictor, amount, limit);
	// TODO: additional handling? what if the healing kills them? should this abort if healing would do so etc
	// TODO: healing fx!
	// TODO: armor healing?
	return healed;
}

float Fire_AddDamage(entity e, entity o, float d, float t, float dt)
{
	float maxtime, mintime, maxdamage, mindamage, maxdps, mindps, totaldamage, totaltime;

	if (d <= 0)
		return -1;

	if(IS_PLAYER(e))
	{
		if(IS_DEAD(e))
			return -1;
	}

	t = max(t, 0.1);
	float dps = d / t;
	if(StatusEffects_active(STATUSEFFECT_Burning, e))
	{
		float fireendtime = StatusEffects_gettime(STATUSEFFECT_Burning, e);

		mintime = fireendtime - time;
		maxtime = max(mintime, t);

		mindps = e.fire_damagepersec;
		maxdps = max(mindps, dps);

		if(maxtime > mintime || maxdps > mindps)
		{
			// Constraints:

			// damage we have right now
			mindamage = mindps * mintime;

			// damage we want to get
			maxdamage = mindamage + d;

			// but we can't exceed maxtime * maxdps!
			totaldamage = min(maxdamage, maxtime * maxdps);

			// LEMMA:
			// Look at:
			// totaldamage = min(mindamage + d, maxtime * maxdps)
			// We see:
			// totaldamage <= maxtime * maxdps
			// ==> totaldamage / maxdps <= maxtime.
			// We also see:
			// totaldamage / mindps = min(mindamage / mindps + d, maxtime * maxdps / mindps)
			//                     >= min(mintime, maxtime)
			// ==> totaldamage / maxdps >= mintime.

			/*
			// how long do we damage then?
			// at least as long as before
			// but, never exceed maxdps
			totaltime = max(mintime, totaldamage / maxdps); // always <= maxtime due to lemma
			*/

			// alternate:
			// at most as long as maximum allowed
			// but, never below mindps
			totaltime = min(maxtime, totaldamage / mindps); // always >= mintime due to lemma

			// assuming t > mintime, dps > mindps:
			// we get d = t * dps = maxtime * maxdps
			// totaldamage = min(maxdamage, maxtime * maxdps) = min(... + d, maxtime * maxdps) = maxtime * maxdps
			// totaldamage / maxdps = maxtime
			// totaldamage / mindps > totaldamage / maxdps = maxtime
			// FROM THIS:
			// a) totaltime = max(mintime, maxtime) = maxtime
			// b) totaltime = min(maxtime, totaldamage / maxdps) = maxtime

			// assuming t <= mintime:
			// we get maxtime = mintime
			// a) totaltime = max(mintime, ...) >= mintime, also totaltime <= maxtime by the lemma, therefore totaltime = mintime = maxtime
			// b) totaltime = min(maxtime, ...) <= maxtime, also totaltime >= mintime by the lemma, therefore totaltime = mintime = maxtime

			// assuming dps <= mindps:
			// we get mindps = maxdps.
			// With this, the lemma says that mintime <= totaldamage / mindps = totaldamage / maxdps <= maxtime.
			// a) totaltime = max(mintime, totaldamage / maxdps) = totaldamage / maxdps
			// b) totaltime = min(maxtime, totaldamage / mindps) = totaldamage / maxdps

			e.fire_damagepersec = totaldamage / totaltime;
			StatusEffects_apply(STATUSEFFECT_Burning, e, time + totaltime, 0);
			if(totaldamage > 1.2 * mindamage)
			{
				e.fire_deathtype = dt;
				if(e.fire_owner != o)
				{
					e.fire_owner = o;
					e.fire_hitsound = false;
				}
			}
			if(accuracy_isgooddamage(o, e))
				accuracy_add(o, DEATH_WEAPONOF(dt), 0, max(0, totaldamage - mindamage), 0); // add to hit
			return max(0, totaldamage - mindamage); // can never be negative, but to make sure
		}
		else
			return 0;
	}
	else
	{
		e.fire_damagepersec = dps;
		StatusEffects_apply(STATUSEFFECT_Burning, e, time + t, 0);
		e.fire_deathtype = dt;
		e.fire_owner = o;
		e.fire_hitsound = false;
		if(accuracy_isgooddamage(o, e))
			accuracy_add(o, DEATH_WEAPONOF(dt), 0, d, 0); // add to hit
		return d;
	}
}

void Fire_ApplyDamage(entity e)
{
	float t, d, hi, ty;
	entity o;

	for(t = 0, o = e.owner; o.owner && t < 16; o = o.owner, ++t);
	if(IS_NOT_A_CLIENT(o))
		o = e.fire_owner;

	float fireendtime = StatusEffects_gettime(STATUSEFFECT_Burning, e);
	t = min(frametime, fireendtime - time);
	d = e.fire_damagepersec * t;

	hi = e.fire_owner.hitsound_damage_dealt;
	ty = e.fire_owner.typehitsound;
	Damage(e, e, e.fire_owner, d, e.fire_deathtype, DMG_NOWEP, e.origin, '0 0 0');
	if(e.fire_hitsound && e.fire_owner)
	{
		e.fire_owner.hitsound_damage_dealt = hi;
		e.fire_owner.typehitsound = ty;
	}
	e.fire_hitsound = true;

	if(!IS_INDEPENDENT_PLAYER(e) && !STAT(FROZEN, e) && !StatusEffects_active(STATUSEFFECT_Frozen, e))
	{
		IL_EACH(g_damagedbycontents, it.damagedbycontents && it != e,
		{
			if(!IS_DEAD(it) && it.takedamage && !IS_INDEPENDENT_PLAYER(it))
			if(boxesoverlap(e.absmin, e.absmax, it.absmin, it.absmax))
			{
				t = autocvar_g_balance_firetransfer_time * (fireendtime - time);
				d = autocvar_g_balance_firetransfer_damage * e.fire_damagepersec * t;
				Fire_AddDamage(it, o, d, t, DEATH_FIRE.m_id);
			}
		});
	}
}
