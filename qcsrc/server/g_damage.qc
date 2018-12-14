#include "g_damage.qh"

#include <common/effects/all.qh>
#include "bot/api.qh"
#include "g_hook.qh"
#include <server/mutators/_mod.qh>
#include "teamplay.qh"
#include "scores.qh"
#include "spawnpoints.qh"
#include "../common/state.qh"
#include "../common/physics/player.qh"
#include "../common/t_items.qh"
#include "resources.qh"
#include "../common/vehicles/all.qh"
#include "../common/items/_mod.qh"
#include "../common/mutators/mutator/waypoints/waypointsprites.qh"
#include "../common/mutators/mutator/instagib/sv_instagib.qh"
#include "../common/mutators/mutator/buffs/buffs.qh"
#include "weapons/accuracy.qh"
#include "weapons/csqcprojectile.qh"
#include "weapons/selection.qh"
#include "../common/constants.qh"
#include "../common/deathtypes/all.qh"
#include "../common/notifications/all.qh"
#include "../common/physics/movetypes/movetypes.qh"
#include "../common/playerstats.qh"
#include "../common/teams.qh"
#include "../common/util.qh"
#include <common/gamemodes/rules.qh>
#include <common/weapons/_all.qh>
#include "../lib/csqcmodel/sv_model.qh"
#include "../lib/warpzone/common.qh"

void UpdateFrags(entity player, int f)
{
	GameRules_scoring_add_team(player, SCORE, f);
}

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
		UpdateFrags(attacker, f);
}

.entity kh_next;

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
	if(time < player.strength_finished)
		s = strcat(s, "S");
	if(time < player.invincible_finished)
		s = strcat(s, "I");
	if(player.flagcarried != NULL)
		s = strcat(s, "F");
	if(PHYS_INPUT_BUTTON_CHAT(player))
		s = strcat(s, "T");
	if(player.kh_next)
		s = strcat(s, "K");
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
	int deathtype,
	string s1, string s2, string s3,
	float f1, float f2, float f3)
{
	if(!DEATH_ISSPECIAL(deathtype))
	{
		backtrace("Obituary_SpecialDeath called without a special deathtype?\n");
		return;
	}

	entity deathent = Deathtypes_from(deathtype - DT_FIRST);
	if (!deathent)
	{
		backtrace("Obituary_SpecialDeath: Could not find deathtype entity!\n");
		return;
	}

	if(g_cts && deathtype == DEATH_KILL.m_id)
		return; // TODO: somehow put this in CTS gamemode file!

	Notification death_message = (murder) ? deathent.death_msgmurder : deathent.death_msgself;
	if(death_message)
	{
		Send_Notification_WOCOVA(
			NOTIF_ONE,
			notif_target,
			MSG_MULTI,
			death_message,
			s1, s2, s3, "",
			f1, f2, f3, 0
		);
		Send_Notification_WOCOVA(
			NOTIF_ALL_EXCEPT,
			notif_target,
			MSG_INFO,
			death_message.nent_msginfo,
			s1, s2, s3, "",
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
			"Obituary_WeaponDeath(): ^1Deathtype ^7(%d)^1 has no notification for weapon %d!\n",
			deathtype,
			death_weapon
		);
	}

	return true;
}

bool frag_centermessage_override(entity attacker, entity targ, int deathtype, int kill_count_to_attacker, int kill_count_to_target)
{
	if(deathtype == DEATH_FIRE.m_id)
	{
		Send_Notification(NOTIF_ONE, attacker, MSG_CHOICE, CHOICE_FRAG_FIRE, targ.netname, kill_count_to_attacker, (IS_BOT_CLIENT(targ) ? -1 : CS(targ).ping));
		Send_Notification(NOTIF_ONE, targ, MSG_CHOICE, CHOICE_FRAGGED_FIRE, attacker.netname, kill_count_to_target, GetResourceAmount(attacker, RESOURCE_HEALTH), GetResourceAmount(attacker, RESOURCE_ARMOR), (IS_BOT_CLIENT(attacker) ? -1 : CS(attacker).ping));
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

	// Set final information for the death
	targ.death_origin = targ.origin;
	string deathlocation = (autocvar_notification_server_allows_location ? NearestLocation(targ.death_origin) : "");

	#ifdef NOTIFICATIONS_DEBUG
	Debug_Notification(
		sprintf(
			"Obituary(%s, %s, %s, %s = %d);\n",
			attacker.netname,
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
				Obituary_SpecialDeath(targ, false, deathtype, targ.netname, deathlocation, "", targ.team, 0, 0);
			}
			else
			{
				switch(DEATH_ENT(deathtype))
				{
					case DEATH_MIRRORDAMAGE:
					{
						Obituary_SpecialDeath(targ, false, deathtype, targ.netname, deathlocation, "", CS(targ).killcount, 0, 0);
						break;
					}

					default:
					{
						Obituary_SpecialDeath(targ, false, deathtype, targ.netname, deathlocation, "", CS(targ).killcount, 0, 0);
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
			Send_Notification(NOTIF_ONE, targ, MSG_CENTER, CENTER_DEATH_TEAMKILL_FRAGGED, attacker.netname);
			Send_Notification(NOTIF_ALL, NULL, MSG_INFO, APP_TEAM_NUM(targ.team, INFO_DEATH_TEAMKILL), targ.netname, attacker.netname, deathlocation, CS(targ).killcount);

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
				{ \
					Send_Notification(NOTIF_ONE, attacker, MSG_ANNCE, ANNCE_KILLSTREAK_##countb); \
					if (!warmup_stage)\
					{\
						PlayerStats_GameReport_Event_Player(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_##counta, 1); \
					}\
					break; \
				}
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
					attacker.netname,
					kill_count_to_target,
					GetResourceAmount(attacker, RESOURCE_HEALTH),
					GetResourceAmount(attacker, RESOURCE_ARMOR),
					(IS_BOT_CLIENT(attacker) ? -1 : CS(attacker).ping)
				);
			}
			else if(!frag_centermessage_override(attacker, targ, deathtype, kill_count_to_attacker, kill_count_to_target))
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
					attacker.netname,
					kill_count_to_target,
					GetResourceAmount(attacker, RESOURCE_HEALTH),
					GetResourceAmount(attacker, RESOURCE_ARMOR),
					(IS_BOT_CLIENT(attacker) ? -1 : CS(attacker).ping)
				);
			}

			int f3 = 0;
			if(deathtype == DEATH_BUFF.m_id)
				f3 = buff_FirstFromFlags(STAT(BUFFS, attacker)).m_id;

			if (!Obituary_WeaponDeath(targ, true, deathtype, targ.netname, attacker.netname, deathlocation, CS(targ).killcount, kill_count_to_attacker))
				Obituary_SpecialDeath(targ, true, deathtype, targ.netname, attacker.netname, deathlocation, CS(targ).killcount, kill_count_to_attacker, f3);
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
				Obituary_SpecialDeath(targ, false, deathtype,
					targ.netname,
					inflictor.message,
					deathlocation,
					CS(targ).killcount,
					0,
					0);
				break;
			}

			case DEATH_CUSTOM:
			{
				Obituary_SpecialDeath(targ, false, deathtype,
					targ.netname,
					((strstrofs(deathmessage, "%", 0) < 0) ? strcat("%s ", deathmessage) : deathmessage),
					deathlocation,
					CS(targ).killcount,
					0,
					0);
				break;
			}

			default:
			{
				Obituary_SpecialDeath(targ, false, deathtype, targ.netname, deathlocation, "", CS(targ).killcount, 0, 0);
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

void Ice_Think(entity this)
{
	if(!STAT(FROZEN, this.owner) || this.owner.iceblock != this)
	{
		delete(this);
		return;
	}
	setorigin(this, this.owner.origin - '0 0 16');
	this.nextthink = time;
}

void Freeze(entity targ, float revivespeed, int frozen_type, bool show_waypoint)
{
	if(!IS_PLAYER(targ) && !IS_MONSTER(targ)) // TODO: only specified entities can be freezed
		return;

	if(STAT(FROZEN, targ))
		return;

	float targ_maxhealth = ((IS_MONSTER(targ)) ? targ.max_health : start_health);

	STAT(FROZEN, targ) = frozen_type;
	STAT(REVIVE_PROGRESS, targ) = ((frozen_type == FROZEN_TEMP_DYING) ? 1 : 0);
	SetResourceAmount(targ, RESOURCE_HEALTH, ((frozen_type == FROZEN_TEMP_DYING) ? targ_maxhealth : 1));
	targ.revive_speed = revivespeed;
	if(targ.bot_attack)
		IL_REMOVE(g_bot_targets, targ);
	targ.bot_attack = false;
	targ.freeze_time = time;

	entity ice = new(ice);
	ice.owner = targ;
	ice.scale = targ.scale;
	setthink(ice, Ice_Think);
	ice.nextthink = time;
	ice.frame = floor(random() * 21); // ice model has 20 different looking frames
	setmodel(ice, MDL_ICE);
	ice.alpha = 1;
	ice.colormod = Team_ColorRGB(targ.team);
	ice.glowmod = ice.colormod;
	targ.iceblock = ice;
	targ.revival_time = 0;

	Ice_Think(ice);

	RemoveGrapplingHooks(targ);

	FOREACH_CLIENT(IS_PLAYER(it),
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	    {
	    	.entity weaponentity = weaponentities[slot];
	    	if(it.(weaponentity).hook.aiment == targ)
	    		RemoveHook(it.(weaponentity).hook);
	    }
	});

	// add waypoint
	if(MUTATOR_CALLHOOK(Freeze, targ, revivespeed, frozen_type) || show_waypoint)
		WaypointSprite_Spawn(WP_Frozen, 0, 0, targ, '0 0 64', NULL, targ.team, targ, waypointsprite_attached, true, RADARICON_WAYPOINT);
}

void Unfreeze(entity targ, bool reset_health)
{
	if(!STAT(FROZEN, targ))
		return;

	if (reset_health && STAT(FROZEN, targ) != FROZEN_TEMP_DYING)
		SetResourceAmount(targ, RESOURCE_HEALTH, ((IS_PLAYER(targ)) ? start_health : targ.max_health));

	targ.pauseregen_finished = time + autocvar_g_balance_pause_health_regen;

	STAT(FROZEN, targ) = 0;
	STAT(REVIVE_PROGRESS, targ) = 0;
	targ.revival_time = time;
	if(!targ.bot_attack)
		IL_PUSH(g_bot_targets, targ);
	targ.bot_attack = true;

	WaypointSprite_Kill(targ.waypointsprite_attached);

	FOREACH_CLIENT(IS_PLAYER(it),
	{
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	    {
	    	.entity weaponentity = weaponentities[slot];
	    	if(it.(weaponentity).hook.aiment == targ)
	    		RemoveHook(it.(weaponentity).hook);
	    }
	});

	// remove the ice block
	if(targ.iceblock)
		delete(targ.iceblock);
	targ.iceblock = NULL;

	MUTATOR_CALLHOOK(Unfreeze, targ);
}

void Damage(entity targ, entity inflictor, entity attacker, float damage, int deathtype, .entity weaponentity, vector hitloc, vector force)
{
	float complainteamdamage = 0;
	float mirrordamage = 0;
	float mirrorforce = 0;

	if (game_stopped || (IS_CLIENT(targ) && CS(targ).killcount == FRAGS_SPECTATOR))
		return;

	entity attacker_save = attacker;

	// special rule: gravity bomb does not hit team mates (other than for disconnecting the hook)
	if(DEATH_ISWEAPON(deathtype, WEP_HOOK) || DEATH_ISWEAPON(deathtype, WEP_TUBA))
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
		// Instead, prepare the victim for his death...
		SetResourceAmountExplicit(targ, RESOURCE_ARMOR, 0);
		targ.spawnshieldtime = 0;
		SetResourceAmountExplicit(targ, RESOURCE_HEALTH, 0.9); // this is < 1
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
			if(IS_PLAYER(targ) && targ != attacker && (IS_INDEPENDENT_PLAYER(attacker) || IS_INDEPENDENT_PLAYER(targ)))
			{
				damage = 0;
				force = '0 0 0';
			}
			else if(SAME_TEAM(attacker, targ))
			{
				if(autocvar_teamplay_mode == 1)
					damage = 0;
				else if(attacker != targ)
				{
					if(autocvar_teamplay_mode == 3)
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
								vector v  = healtharmor_applydamage(GetResourceAmount(attacker, RESOURCE_ARMOR), autocvar_g_balance_armor_blockpercent, deathtype, mirrordamage);
								attacker.dmg_take += v.x;
								attacker.dmg_save += v.y;
								attacker.dmg_inflictor = inflictor;
								mirrordamage = v.z;
								mirrorforce = 0;
							}

							if(autocvar_g_friendlyfire_virtual)
							{
								vector v = healtharmor_applydamage(GetResourceAmount(targ, RESOURCE_ARMOR), autocvar_g_balance_armor_blockpercent, deathtype, damage);
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
			damage *= g_weapondamagefactor;
			mirrordamage *= g_weapondamagefactor;
			complainteamdamage *= g_weapondamagefactor;
			force = force * g_weaponforcefactor;
			mirrorforce *= g_weaponforcefactor;
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

		if(deathtype != DEATH_HURTTRIGGER.m_id && deathtype != DEATH_TEAMCHANGE.m_id && deathtype != DEATH_AUTOTEAMCHANGE.m_id && STAT(FROZEN, targ))
		{
			if(autocvar_g_frozen_revive_falldamage > 0 && deathtype == DEATH_FALL.m_id && damage >= autocvar_g_frozen_revive_falldamage)
			{
				Unfreeze(targ, false);
				SetResourceAmount(targ, RESOURCE_HEALTH, autocvar_g_frozen_revive_falldamage_health);
				Send_Effect(EFFECT_ICEORGLASS, targ.origin, '0 0 0', 3);
				Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_FREEZETAG_REVIVED_FALL, targ.netname);
				Send_Notification(NOTIF_ONE, targ, MSG_CENTER, CENTER_FREEZETAG_REVIVE_SELF);
			}

			damage = 0;
			force *= autocvar_g_frozen_force;
		}

		if(IS_PLAYER(targ) && STAT(FROZEN, targ) && deathtype == DEATH_HURTTRIGGER.m_id && !autocvar_g_frozen_damage_trigger)
		{
			Send_Effect(EFFECT_TELEPORT, targ.origin, '0 0 0', 1);

			entity spot = SelectSpawnPoint (targ, false);

			if(spot)
			{
				damage = 0;
				targ.deadflag = DEAD_NO;

				targ.angles = spot.angles;

				targ.effects = 0;
				targ.effects |= EF_TELEPORT_BIT;

				targ.angles_z = 0; // never spawn tilted even if the spot says to
				targ.fixangle = true; // turn this way immediately
				targ.velocity = '0 0 0';
				targ.avelocity = '0 0 0';
				targ.punchangle = '0 0 0';
				targ.punchvector = '0 0 0';
				targ.oldvelocity = targ.velocity;

				targ.spawnorigin = spot.origin;
				setorigin(targ, spot.origin + '0 0 1' * (1 - targ.mins.z - 24));
				// don't reset back to last position, even if new position is stuck in solid
				targ.oldorigin = targ.origin;

				Send_Effect(EFFECT_TELEPORT, targ.origin, '0 0 0', 1);
			}
		}

		if(!MUTATOR_IS_ENABLED(mutator_instagib))
		{
			// apply strength multiplier
			if (attacker.items & ITEM_Strength.m_itemid)
			{
				if(targ == attacker)
				{
					damage = damage * autocvar_g_balance_powerup_strength_selfdamage;
					force = force * autocvar_g_balance_powerup_strength_selfforce;
				}
				else
				{
					damage = damage * autocvar_g_balance_powerup_strength_damage;
					force = force * autocvar_g_balance_powerup_strength_force;
				}
			}

			// apply invincibility multiplier
			if (targ.items & ITEM_Shield.m_itemid)
			{
				damage = damage * autocvar_g_balance_powerup_invincible_takedamage;
				if (targ != attacker)
				{
					force = force * autocvar_g_balance_powerup_invincible_takeforce;
				}
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

			if(IS_PLAYER(victim) || (IS_TURRET(victim) && victim.active == ACTIVE_ACTIVE) || IS_MONSTER(victim) || MUTATOR_CALLHOOK(PlayHitsound, victim, attacker))
			{
				if(DIFF_TEAM(victim, attacker) && !STAT(FROZEN, victim))
				{
					if(damage > 0)
					{
						if(deathtype != DEATH_FIRE.m_id)
						{
							if(PHYS_INPUT_BUTTON_CHAT(victim))
								attacker.typehitsound += 1;
							else
								attacker.damage_dealt += damage;
						}

						damage_goodhits += 1;
						damage_gooddamage += damage;

						if (!DEATH_ISSPECIAL(deathtype))
						{
							if(IS_PLAYER(targ)) // don't do this for vehicles
							if(IsFlying(victim))
								yoda = 1;
						}
					}
				}
				else if(IS_PLAYER(attacker))
				{
					// if enemy gets frozen in this frame and receives other damage don't
					// play the typehitsound e.g. when hit by multiple bullets of the shotgun
					if (deathtype != DEATH_FIRE.m_id && (!STAT(FROZEN, victim) || time > victim.freeze_time))
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
	if (!IS_PLAYER(targ) || time >= targ.spawnshieldtime || targ == attacker)
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
		else
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

float RadiusDamageForSource (entity inflictor, vector inflictororigin, vector inflictorvelocity, entity attacker, float coredamage, float edgedamage, float rad, entity cantbe, entity mustbe,
								float inflictorselfdamage, float forceintensity, int deathtype, .entity weaponentity, entity directhitentity)
	// Returns total damage applies to creatures
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

	RadiusDamage_running = 1;

	tfloordmg = autocvar_g_throughfloor_damage;
	tfloorforce = autocvar_g_throughfloor_force;

	total_damage_to_creatures = 0;

	if(deathtype != (WEP_HOOK.m_id | HITTYPE_SECONDARY | HITTYPE_BOUNCE)) // only send gravity bomb damage once
		if(DEATH_WEAPONOF(deathtype) != WEP_TUBA) // do not send tuba damage (bandwidth hog)
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
			vector nearest;
			vector diff;
			float power;

			// LordHavoc: measure distance to nearest point on target (not origin)
			// (this guarentees 100% damage on a touch impact)
			nearest = targ.WarpZone_findradius_nearest;
			diff = targ.WarpZone_findradius_dist;
			// round up a little on the damage to ensure full damage on impacts
			// and turn the distance into a fraction of the radius
			power = 1 - ((vlen (diff) - bound(MIN_DAMAGEEXTRARADIUS, targ.damageextraradius, MAX_DAMAGEEXTRARADIUS)) / rad);
			//bprint(" ");
			//bprint(ftos(power));
			//if (targ == attacker)
			//	print(ftos(power), "\n");
			if (power > 0)
			{
				float finaldmg;
				if (power > 1)
					power = 1;
				finaldmg = coredamage * power + edgedamage * (1 - power);
				if (finaldmg > 0)
				{
					float a;
					float c;
					vector hitloc;
					vector myblastorigin;
					vector center;

					myblastorigin = WarpZone_TransformOrigin(targ, inflictororigin);

					// if it's a player, use the view origin as reference
					center = CENTER_OR_VIEWOFS(targ);

					force = normalize(center - myblastorigin);
					force = force * (finaldmg / coredamage) * forceintensity;
					hitloc = nearest;

					if(deathtype & WEP_BLASTER.m_id)
						force *= WEP_CVAR_BOTH(blaster, !(deathtype & HITTYPE_SECONDARY), force_zscale);

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
					}

					//if (targ == attacker)
					//{
					//	print("hits ", ftos(hits), " / ", ftos(total));
					//	print(" finaldmg ", ftos(finaldmg), " force ", vtos(force));
					//	print(" (", ftos(a), ")\n");
					//}
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
		accuracy_add(attacker, DEATH_WEAPONOF(deathtype), 0, min(coredamage, stat_damagedone));

	return total_damage_to_creatures;
}

float RadiusDamage(entity inflictor, entity attacker, float coredamage, float edgedamage, float rad, entity cantbe, entity mustbe, float forceintensity, int deathtype, .entity weaponentity, entity directhitentity)
{
	return RadiusDamageForSource(inflictor, (inflictor.origin + (inflictor.mins + inflictor.maxs) * 0.5), inflictor.velocity, attacker, coredamage, edgedamage, rad, cantbe, mustbe, false, forceintensity, deathtype, weaponentity, directhitentity);
}

bool Heal(entity targ, entity inflictor, float amount, float limit)
{
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

float Fire_IsBurning(entity e)
{
	return (time < e.fire_endtime);
}

float Fire_AddDamage(entity e, entity o, float d, float t, float dt)
{
	float dps;
	float maxtime, mintime, maxdamage, mindamage, maxdps, mindps, totaldamage, totaltime;

	if(IS_PLAYER(e))
	{
		if(IS_DEAD(e))
			return -1;
	}
	else
	{
		if(!e.fire_burner)
		{
			// print("adding a fire burner to ", e.classname, "\n");
			e.fire_burner = new(fireburner);
			setthink(e.fire_burner, fireburner_think);
			e.fire_burner.nextthink = time;
			e.fire_burner.owner = e;
		}
	}

	t = max(t, 0.1);
	dps = d / t;
	if(Fire_IsBurning(e))
	{
		mintime = e.fire_endtime - time;
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
			e.fire_endtime = time + totaltime;
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
				accuracy_add(o, DEATH_WEAPONOF(dt), 0, max(0, totaldamage - mindamage));
			return max(0, totaldamage - mindamage); // can never be negative, but to make sure
		}
		else
			return 0;
	}
	else
	{
		e.fire_damagepersec = dps;
		e.fire_endtime = time + t;
		e.fire_deathtype = dt;
		e.fire_owner = o;
		e.fire_hitsound = false;
		if(accuracy_isgooddamage(o, e))
			accuracy_add(o, DEATH_WEAPONOF(dt), 0, d);
		return d;
	}
}

void Fire_ApplyDamage(entity e)
{
	float t, d, hi, ty;
	entity o;

	if (!Fire_IsBurning(e))
		return;

	for(t = 0, o = e.owner; o.owner && t < 16; o = o.owner, ++t);
	if(IS_NOT_A_CLIENT(o))
		o = e.fire_owner;

	// water and slime stop fire
	if(e.waterlevel)
	if(e.watertype != CONTENT_LAVA)
		e.fire_endtime = 0;

	// ice stops fire
	if(STAT(FROZEN, e))
		e.fire_endtime = 0;

	t = min(frametime, e.fire_endtime - time);
	d = e.fire_damagepersec * t;

	hi = e.fire_owner.damage_dealt;
	ty = e.fire_owner.typehitsound;
	Damage(e, e, e.fire_owner, d, e.fire_deathtype, DMG_NOWEP, e.origin, '0 0 0');
	if(e.fire_hitsound && e.fire_owner)
	{
		e.fire_owner.damage_dealt = hi;
		e.fire_owner.typehitsound = ty;
	}
	e.fire_hitsound = true;

	if(!IS_INDEPENDENT_PLAYER(e) && !STAT(FROZEN, e))
	{
		IL_EACH(g_damagedbycontents, it.damagedbycontents && it != e,
		{
			if(!IS_DEAD(it) && it.takedamage && !IS_INDEPENDENT_PLAYER(it))
			if(boxesoverlap(e.absmin, e.absmax, it.absmin, it.absmax))
			{
				t = autocvar_g_balance_firetransfer_time * (e.fire_endtime - time);
				d = autocvar_g_balance_firetransfer_damage * e.fire_damagepersec * t;
				Fire_AddDamage(it, o, d, t, DEATH_FIRE.m_id);
			}
		});
	}
}

void Fire_ApplyEffect(entity e)
{
	if(Fire_IsBurning(e))
		e.effects |= EF_FLAME;
	else
		e.effects &= ~EF_FLAME;
}

void fireburner_think(entity this)
{
	// for players, this is done in the regular loop
	if(wasfreed(this.owner))
	{
		delete(this);
		return;
	}
	Fire_ApplyEffect(this.owner);
	if(!Fire_IsBurning(this.owner))
	{
		this.owner.fire_burner = NULL;
		delete(this);
		return;
	}
	Fire_ApplyDamage(this.owner);
	this.nextthink = time;
}
