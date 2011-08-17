.float dmg;
.float dmg_edge;
.float dmg_force;
.float dmg_radius;

float Damage_DamageInfo_SendEntity(entity to, float sf)
{
	WriteByte(MSG_ENTITY, ENT_CLIENT_DAMAGEINFO);
	WriteShort(MSG_ENTITY, self.projectiledeathtype);
	WriteCoord(MSG_ENTITY, floor(self.origin_x));
	WriteCoord(MSG_ENTITY, floor(self.origin_y));
	WriteCoord(MSG_ENTITY, floor(self.origin_z));
	WriteByte(MSG_ENTITY, bound(1, self.dmg, 255));
	WriteByte(MSG_ENTITY, bound(0, self.dmg_radius, 255));
	WriteByte(MSG_ENTITY, bound(1, self.dmg_edge, 255));
	WriteShort(MSG_ENTITY, self.oldorigin_x);
	return TRUE;
}

void Damage_DamageInfo(vector org, float coredamage, float edgedamage, float rad, vector force, float deathtype, entity dmgowner)
{
	// TODO maybe call this from non-edgedamage too?
	// TODO maybe make the client do the particle effects for the weapons and the impact sounds using this info?

	entity e;

	if(!sound_allowed(MSG_BROADCAST, dmgowner))
		deathtype |= 0x8000;

	e = spawn();
	setorigin(e, org);
	e.projectiledeathtype = deathtype;
	e.dmg = coredamage;
	e.dmg_edge = edgedamage;
	e.dmg_radius = rad;
	e.dmg_force = vlen(force);
	e.velocity = force;

	e.oldorigin_x = compressShortVector(e.velocity);

	Net_LinkEntity(e, FALSE, 0.2, Damage_DamageInfo_SendEntity);
}

float checkrules_firstblood;

float yoda;
float damage_goodhits;
float damage_gooddamage;
float headshot;
float damage_headshotbonus; // bonus multiplier for head shots, set to 0 after use

.float dmg_team;
.float teamkill_complain;
.float teamkill_soundtime;
.entity teamkill_soundsource;
.entity pusher;
.float taunt_soundtime;


float IsDifferentTeam(entity a, entity b)
{
	if(teamplay)
	{
		if(a.team == b.team)
			return 0;
	}
	else
	{
		if(a == b)
			return 0;
	}
	return 1;
}

float IsFlying(entity a)
{
	if(a.flags & FL_ONGROUND)
		return 0;
	if(a.waterlevel >= WATERLEVEL_SWIMMING)
		return 0;
	traceline(a.origin, a.origin - '0 0 48', MOVE_NORMAL, a);
	if(trace_fraction < 1)
		return 0;
	return 1;
}

vector GetHeadshotMins(entity targ)
{
	return '-0.5 0 0' * PL_HEAD_x + '0 -0.5 0' * PL_HEAD_y + '0 0 1' * (targ.maxs_z - PL_HEAD_z);
}
vector GetHeadshotMaxs(entity targ)
{
	return '0.5 0 0' * PL_HEAD_x + '0 0.5 0' * PL_HEAD_y + '0 0 1' * targ.maxs_z;
}

void UpdateFrags(entity player, float f)
{
	PlayerTeamScore_AddScore(player, f);
}

// NOTE: f=0 means still count as a (positive) kill, but count no frags for it
void W_SwitchWeapon_Force(entity e, float w);
void GiveFrags (entity attacker, entity targ, float f, float deathtype)
{
	float w;

	// TODO route through PlayerScores instead
	if(gameover) return;

	if(f < 0)
	{
		if(targ == attacker)
		{
			// suicide
			PlayerScore_Add(attacker, SP_SUICIDES, 1);
		}
		else
		{
			// teamkill
			PlayerScore_Add(attacker, SP_KILLS, -1); // or maybe add a teamkills field?
		}
	}
	else
	{
		// regular frag
		PlayerScore_Add(attacker, SP_KILLS, 1);
		if(targ.playerid)
			PlayerStats_Event(attacker, sprintf("kills-%d", targ.playerid), 1);
	}

	PlayerScore_Add(targ, SP_DEATHS, 1);

	if(g_arena || g_ca)
		if(autocvar_g_arena_roundbased)
			return;

	if(targ != attacker) // not for suicides
	if(g_weaponarena_random)
	{
		// after a frag, exchange the current weapon (or the culprit, if detectable) by a new random weapon
		float culprit;
		culprit = DEATH_WEAPONOF(deathtype);
		if(!culprit || !(attacker.weapons & W_WeaponBit(culprit)))
			culprit = attacker.weapon;

		if(g_weaponarena_random_with_laser && culprit == WEPBIT_LASER)
		{
			// no exchange
		}
		else
		{
			if(inWarmupStage)
				w = warmup_start_weapons;
			else
				w = start_weapons;

			// all others (including the culprit): remove
			w &~= attacker.weapons;

			// among the remaining ones, choose one by random
			w = randombits(w, 1, FALSE);
			if(w)
			{
				attacker.weapons |= w;
				attacker.weapons &~= W_WeaponBit(culprit);
			}
		}

		// after a frag, choose another random weapon set
		if not(attacker.weapons & W_WeaponBit(attacker.weapon))
			W_SwitchWeapon_Force(attacker, w_getbestweapon(attacker));
	}

	// FIXME fix the mess this is (we have REAL points now!)
	entity oldself;
	oldself = self;
	self = attacker;
	frag_attacker = attacker;
	frag_target = targ;
	frag_score = f;
	if(MUTATOR_CALLHOOK(GiveFragsForKill))
	{
		f = frag_score;
		self = oldself;
	}
	else
	{
		self = oldself;
		if(g_runematch)
		{
			f = RunematchHandleFrags(attacker, targ, f);
		}
		else if(g_lms)
		{
			// remove a life
			float tl;
			tl = PlayerScore_Add(targ, SP_LMS_LIVES, -1);
			if(tl < lms_lowest_lives)
				lms_lowest_lives = tl;
			if(tl <= 0)
			{
				if(!lms_next_place)
					lms_next_place = player_count;
				else
					lms_next_place = min(lms_next_place, player_count);
				PlayerScore_Add(targ, SP_LMS_RANK, lms_next_place); // won't ever spawn again
				--lms_next_place;
			}
			f = 0;
		}
		else if(g_ctf)
		{
			if(g_ctf_ignore_frags)
				f = 0;
		}
	}

	attacker.totalfrags += f;

	if(f)
		UpdateFrags(attacker, f);
}

string AppendItemcodes(string s, entity player)
{
	float w;
	w = player.weapon;
	//if(w == 0)
	//	w = player.switchweapon;
	if(w == 0)
		w = player.cnt; // previous weapon!
	s = strcat(s, ftos(w));
	if(time < player.strength_finished)
		s = strcat(s, "S");
	if(time < player.invincible_finished)
		s = strcat(s, "I");
	if(player.flagcarried != world)
		s = strcat(s, "F");
	if(player.BUTTON_CHAT)
		s = strcat(s, "T");
	if(player.kh_next)
		s = strcat(s, "K");
	if(player.runes)
		s = strcat(s, "|", ftos(player.runes));
	return s;
}

void LogDeath(string mode, float deathtype, entity killer, entity killed)
{
	string s;
	if(!autocvar_sv_eventlog)
		return;
	s = strcat(":kill:", mode);
	s = strcat(s, ":", ftos(killer.playerid));
	s = strcat(s, ":", ftos(killed.playerid));
	s = strcat(s, ":type=", ftos(deathtype));
	s = strcat(s, ":items=");
	s = AppendItemcodes(s, killer);
	if(killed != killer)
	{
		s = strcat(s, ":victimitems=");
		s = AppendItemcodes(s, killed);
	}
	GameLogEcho(s);
}

void Send_KillNotification (string s1, string s2, string s3, float msg, float type)
{
	WriteByte(MSG_ALL, SVC_TEMPENTITY);
	WriteByte(MSG_ALL, TE_CSQC_NOTIFY);
	WriteByte(MSG_ALL, CSQC_KILLNOTIFY);
	WriteString(MSG_ALL, s1);
	WriteString(MSG_ALL, s2);
	WriteString(MSG_ALL, s3);
	WriteShort(MSG_ALL, msg);
	WriteByte(MSG_ALL, type);
}

// Function is used to send a generic centerprint whose content CSQC gets to decide (gentle version or not in the below cases)
void Send_CSQC_Centerprint(entity e, string s1, string s2, float msg, float type)
{
	if (clienttype(e) == CLIENTTYPE_REAL)
	{
		msg_entity = e;
		WRITESPECTATABLE_MSG_ONE({
			WriteByte(MSG_ONE, SVC_TEMPENTITY);
			WriteByte(MSG_ONE, TE_CSQC_NOTIFY);
			WriteByte(MSG_ONE, CSQC_CENTERPRINT);
			WriteString(MSG_ONE, s1);
			WriteString(MSG_ONE, s2);
			WriteShort(MSG_ONE, msg);
			WriteByte(MSG_ONE, type);
		});
	}
}

void Obituary (entity attacker, entity inflictor, entity targ, float deathtype)
{
	string	s, a, msg;
	float w, type;

	if (targ.classname == "player")
	{
		s = targ.netname;
		a = attacker.netname;

		if (targ == attacker) // suicides
		{
			if (deathtype == DEATH_TEAMCHANGE || deathtype == DEATH_AUTOTEAMCHANGE)
				msg = ColoredTeamName(targ.team); // TODO: check if needed?
            if(!g_cts) // no "killed your own dumb self" message in CTS
                Send_CSQC_Centerprint(targ, msg, "", deathtype, MSG_SUICIDE);

			if(deathtype != DEATH_TEAMCHANGE && deathtype != DEATH_QUIET)
			{
				LogDeath("suicide", deathtype, targ, targ);
				GiveFrags(attacker, targ, -1, deathtype);
			}

			if (targ.killcount > 2)
				msg = ftos(targ.killcount);
			if(teamplay && deathtype == DEATH_MIRRORDAMAGE)
			{
				if(attacker.team == COLOR_TEAM1)
					deathtype = KILL_TEAM_RED;
				else
					deathtype = KILL_TEAM_BLUE;
			}

			Send_KillNotification(s, msg, ftos(w), deathtype, MSG_SUICIDE);
		}
		else if (attacker.classname == "player")
		{
			if(teamplay && attacker.team == targ.team)
			{
				if(attacker.team == COLOR_TEAM1)
					type = KILL_TEAM_RED;
				else
					type = KILL_TEAM_BLUE;

				GiveFrags(attacker, targ, -1, deathtype);

				Send_CSQC_Centerprint(attacker, s, "", type, MSG_KILL);

				if (targ.killcount > 2) {
					msg = ftos(targ.killcount);
				}

				if (attacker.killcount > 2) {
					msg = ftos(attacker.killcount);
					type = KILL_TEAM_SPREE;
				}
				Send_KillNotification(a, s, msg, type, MSG_KILL);

				attacker.killcount = 0;

				LogDeath("tk", deathtype, attacker, targ);
			}
			else
			{
				if (!checkrules_firstblood)
				{
					checkrules_firstblood = TRUE;
					Send_KillNotification(a, "", "", KILL_FIRST_BLOOD, MSG_KILL);
					// TODO: make these print a newline if they dont
					Send_CSQC_Centerprint(attacker, "", "", KILL_FIRST_BLOOD, MSG_KILL);
					Send_CSQC_Centerprint(targ, "", "", KILL_FIRST_VICTIM, MSG_KILL);
					PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_FIRSTBLOOD, 1);
					PlayerStats_Event(targ, PLAYERSTATS_ACHIEVEMENT_FIRSTVICTIM, 1);
				}

				if((autocvar_sv_fragmessage_information_typefrag) && (targ.BUTTON_CHAT)) {
					Send_CSQC_Centerprint(attacker, s, GetAdvancedDeathReports(targ), KILL_TYPEFRAG, MSG_KILL);
					Send_CSQC_Centerprint(targ, a, GetAdvancedDeathReports(attacker), KILL_TYPEFRAGGED, MSG_KILL);
				} else {
					Send_CSQC_Centerprint(attacker, s, GetAdvancedDeathReports(targ), KILL_FRAG, MSG_KILL);
					Send_CSQC_Centerprint(targ, a, GetAdvancedDeathReports(attacker), KILL_FRAGGED, MSG_KILL);
				}

				attacker.taunt_soundtime = time + 1;

				// TODO: fix this?
				if (deathtype == DEATH_CUSTOM)
					msg = deathmessage;
				else
					msg = inflictor.message2;

				if(strstrofs(msg, "%", 0) < 0)
					msg = strcat("%s ", msg, " by %s");

				Send_KillNotification(a, s, msg, deathtype, MSG_KILL);

				if(g_ctf && targ.flagcarried)
				{
					UpdateFrags(attacker, ctf_score_value("score_kill"));
					PlayerScore_Add(attacker, SP_CTF_FCKILLS, 1);
					GiveFrags(attacker, targ, 0, deathtype); // for logging
				}
				else
					GiveFrags(attacker, targ, 1, deathtype);

				if (targ.killcount > 2) {
					Send_KillNotification(s, ftos(targ.killcount), a, KILL_END_SPREE, MSG_SPREE);
				}

				attacker.killcount = attacker.killcount + 1;

				if (attacker.killcount > 2) {
					Send_KillNotification(a, ftos(attacker.killcount), "", KILL_SPREE, MSG_SPREE);
				}
				else if (attacker.killcount == 3)
				{
					Send_KillNotification(a, "", "", KILL_SPREE_3, MSG_SPREE);
					AnnounceTo(attacker, "03kills");
					PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_3, 1);
				}
				else if (attacker.killcount == 5)
				{
					Send_KillNotification(a, "", "", KILL_SPREE_5, MSG_SPREE);
					AnnounceTo(attacker, "05kills");
					PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_5, 1);
				}
				else if (attacker.killcount == 10)
				{
					Send_KillNotification(a, "", "", KILL_SPREE_10, MSG_SPREE);
					AnnounceTo(attacker, "10kills");
					PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_10, 1);
				}
				else if (attacker.killcount == 15)
				{
					Send_KillNotification(a, "", "", KILL_SPREE_15, MSG_SPREE);
					AnnounceTo(attacker, "15kills");
					PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_15, 1);
				}
				else if (attacker.killcount == 20)
				{
					Send_KillNotification(a, "", "", KILL_SPREE_20, MSG_SPREE);
					AnnounceTo(attacker, "20kills");
					PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_20, 1);
				}
				else if (attacker.killcount == 25)
				{
					Send_KillNotification(a, "", "", KILL_SPREE_25, MSG_SPREE);
					AnnounceTo(attacker, "25kills");
					PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_25, 1);
				}
				else if (attacker.killcount == 30)
				{
					Send_KillNotification(a, "", "", KILL_SPREE_30, MSG_SPREE);
					AnnounceTo(attacker, "30kills");
					PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_KILL_SPREE_30, 1);
				}
				LogDeath("frag", deathtype, attacker, targ);
			}
		}
		else
		{
			Send_CSQC_Centerprint(targ, "", "", deathtype, MSG_KILL_ACTION);
			if (deathtype == DEATH_HURTTRIGGER && inflictor.message != "")
				msg = inflictor.message;
			else if (deathtype == DEATH_CUSTOM)
				msg = deathmessage;
			if(strstrofs(msg, "%", 0) < 0)
				msg = strcat("%s ", msg);

			GiveFrags(targ, targ, -1, deathtype);
			if(PlayerScore_Add(targ, SP_SCORE, 0) == -5) {
				AnnounceTo(targ, "botlike");
				PlayerStats_Event(attacker, PLAYERSTATS_ACHIEVEMENT_BOTLIKE, 1);
			}
			Send_KillNotification(s, msg, "", deathtype, MSG_KILL_ACTION);

			if (targ.killcount > 2)
				Send_KillNotification(s, ftos(targ.killcount), "", 0, MSG_KILL_ACTION_SPREE);

			LogDeath("accident", deathtype, targ, targ);
		}

		targ.death_origin = targ.origin;
		if(targ != attacker)
			targ.killer_origin = attacker.origin;

		// FIXME: this should go in PutClientInServer
		if (targ.killcount)
			targ.killcount = 0;
	}
}

// these are updated by each Damage call for use in button triggering and such
entity damage_targ;
entity damage_inflictor;
entity damage_attacker;

void Damage (entity targ, entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
	float mirrordamage;
	float mirrorforce;
	float teamdamage0;
	entity attacker_save;
	mirrordamage = 0;
	mirrorforce = 0;

	if (gameover || targ.killcount == -666)
		return;

	local entity oldself;
	oldself = self;
	self = targ;
        damage_targ = targ;
        damage_inflictor = inflictor;
        damage_attacker = attacker;
		attacker_save = attacker;

	if(targ.classname == "player")
		if(targ.hook)
			if(targ.hook.aiment)
				if(targ.hook.aiment == attacker)
					RemoveGrapplingHook(targ); // STOP THAT, you parasite!

	// special rule: gravity bomb does not hit team mates (other than for disconnecting the hook)
	if(DEATH_ISWEAPON(deathtype, WEP_HOOK) || DEATH_ISWEAPON(deathtype, WEP_TUBA))
	{
		if(targ.classname == "player")
			if not(IsDifferentTeam(targ, attacker))
			{
				self = oldself;
				return;
			}
	}

	if(deathtype == DEATH_KILL || deathtype == DEATH_TEAMCHANGE || deathtype == DEATH_AUTOTEAMCHANGE || deathtype == DEATH_QUIET)
	{
		// These are ALWAYS lethal
		// No damage modification here
		// Instead, prepare the victim for his death...
		targ.armorvalue = 0;
		targ.spawnshieldtime = 0;
		targ.health = 0.9; // this is < 1
		targ.flags -= targ.flags & FL_GODMODE;
		damage = 100000;
	}
	else if(deathtype == DEATH_MIRRORDAMAGE || deathtype == DEATH_NOAMMO)
	{
		// no processing
	}
	else
	{
		if (targ.classname == "player")
		if (attacker.classname == "player")
		if (!targ.isbot)
		if (attacker.isbot)
			damage = damage * bound(0.1, (skill + 5) * 0.1, 1);

		// nullify damage if teamplay is on
		if(deathtype != DEATH_TELEFRAG)
		if(attacker.classname == "player")
		{
			if(targ.classname == "player" && targ != attacker && (IS_INDEPENDENT_PLAYER(attacker) || IS_INDEPENDENT_PLAYER(targ)))
			{
				damage = 0;
				force = '0 0 0';
			}
			else if(teamplay && attacker.team == targ.team)
			{
				if(autocvar_teamplay_mode == 1)
					damage = 0;
				else if(attacker != targ)
				{
					if(autocvar_teamplay_mode == 3)
						damage = 0;
					else if(autocvar_teamplay_mode == 4)
					{
						if(targ.classname == "player" && targ.deadflag == DEAD_NO)
						{
							teamdamage0 = max(attacker.dmg_team, autocvar_g_teamdamage_threshold);
							attacker.dmg_team = attacker.dmg_team + damage;
							if(attacker.dmg_team > teamdamage0 && !g_ca)
								mirrordamage = autocvar_g_mirrordamage * (attacker.dmg_team - teamdamage0);
							mirrorforce = autocvar_g_mirrordamage * vlen(force);
							if(g_minstagib)
							{
								if(autocvar_g_friendlyfire == 0)
									damage = 0;
							}
							else if(g_ca)
								damage = 0;
							else
								damage = autocvar_g_friendlyfire * damage;
							// mirrordamage will be used LATER

							if(autocvar_g_mirrordamage_virtual)
							{
								vector v;
								v = healtharmor_applydamage(attacker.armorvalue, autocvar_g_balance_armor_blockpercent, mirrordamage);
								attacker.dmg_take += v_x;
								attacker.dmg_save += v_y;
								attacker.dmg_inflictor = inflictor;
								mirrordamage = 0;
								mirrorforce = 0;
							}

							if(autocvar_g_friendlyfire_virtual)
							{
								vector v;
								v = healtharmor_applydamage(targ.armorvalue, autocvar_g_balance_armor_blockpercent, damage);
								targ.dmg_take += v_x;
								targ.dmg_save += v_y;
								targ.dmg_inflictor = inflictor;
								damage = 0;
                                if(!autocvar_g_friendlyfire_virtual_force)
                                    force = '0 0 0';
							}
						}
						else
							damage = 0;
					}
				}
			}
		}

		if(targ.classname == "player")
		if(attacker.classname == "player")
		if(attacker != targ)
		{
			targ.lms_traveled_distance = autocvar_g_lms_campcheck_distance;
			attacker.lms_traveled_distance = autocvar_g_lms_campcheck_distance;
		}

		if(targ.classname == "player")
		if (g_minstagib)
		{
			if ((deathtype == DEATH_FALL)  ||
				(deathtype == DEATH_DROWN) ||
				(deathtype == DEATH_SLIME) ||
				(deathtype == DEATH_LAVA)  ||
				(!DEATH_ISWEAPON(deathtype, WEP_LASER) && damage > 0 && damage < 100))
			{
				self = oldself;
				return;
			}
			if(damage > 0)
			    damage = 10000;
			if (targ.armorvalue && (deathtype == WEP_MINSTANEX) && damage)
			{
				targ.armorvalue -= 1;
				centerprint(targ, strcat("^3Remaining extra lives: ",ftos(targ.armorvalue)));
				damage = 0;
				targ.hitsound += 1;
				attacker.hitsound += 1; // TODO change this to a future specific hitsound for armor hit
			}
			if (DEATH_ISWEAPON(deathtype, WEP_LASER))
			{
				damage = 0;
				mirrordamage = 0;
				if (targ != attacker)
				{
					if ((targ.health >= 1) && (targ.classname == "player"))
						centerprint(attacker, "Secondary fire inflicts no damage!");
					force = '0 0 0';
					// keep mirrorforce
					attacker = targ;
				}
			}
		}

		if not(DEATH_ISSPECIAL(deathtype))
		{
			damage *= g_weapondamagefactor;
			mirrordamage *= g_weapondamagefactor;
			force = force * g_weaponforcefactor;
			mirrorforce *= g_weaponforcefactor;
		}
		
		// should this be changed at all? If so, in what way?
		frag_attacker = attacker;
		frag_target = targ;
		frag_damage = damage;
		frag_force = force;
        frag_deathtype = deathtype;
		MUTATOR_CALLHOOK(PlayerDamage_Calculate);
		damage = frag_damage;
		force = frag_force;
		
		// apply strength multiplier
		if ((attacker.items & IT_STRENGTH) && !g_minstagib)
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
		if (targ.items & IT_INVINCIBLE && !g_minstagib)
			damage = damage * autocvar_g_balance_powerup_invincible_takedamage;

		if (targ == attacker)
		{
			if(g_ca || (g_cts && !autocvar_g_cts_selfdamage))
				damage = 0;
			else
				damage = damage * autocvar_g_balance_selfdamagepercent;	// Partial damage if the attacker hits himself
		}

		// CTF: reduce damage/force
		if(g_ctf)
		if(targ == attacker)
		if(targ.flagcarried)
		{
			damage = damage * autocvar_g_ctf_flagcarrier_selfdamage;
			force = force * autocvar_g_ctf_flagcarrier_selfforce;
		}

		if(g_runematch)
		{
			// apply strength rune
			if (attacker.runes & RUNE_STRENGTH)
			{
				if(attacker.runes & CURSE_WEAK) // have both curse & rune
				{
					damage = damage * autocvar_g_balance_rune_strength_combo_damage;
					force = force * autocvar_g_balance_rune_strength_combo_force;
				}
				else
				{
					damage = damage * autocvar_g_balance_rune_strength_damage;
					force = force * autocvar_g_balance_rune_strength_force;
				}
			}
			else if (attacker.runes & CURSE_WEAK)
			{
				damage = damage * autocvar_g_balance_curse_weak_damage;
				force = force * autocvar_g_balance_curse_weak_force;
			}

			// apply defense rune
			if (targ.runes & RUNE_DEFENSE)
			{
				if (targ.runes & CURSE_VULNER) // have both curse & rune
					damage = damage * autocvar_g_balance_rune_defense_combo_takedamage;
				else
					damage = damage * autocvar_g_balance_rune_defense_takedamage;
			}
			else if (targ.runes & CURSE_VULNER)
				damage = damage * autocvar_g_balance_curse_vulner_takedamage;
		}

		// count the damage
		if(attacker)
		if(!targ.deadflag)
		if(targ.takedamage == DAMAGE_AIM)
		if(targ != attacker)
		{
			if(targ.classname == "player")
			{
				// HEAD SHOT:
				// find height of hit on player axis
				// if above view_ofs and below maxs, and also in the middle half of the bbox, it is head shot
				vector headmins, headmaxs, org;
				org = antilag_takebackorigin(targ, time - ANTILAG_LATENCY(attacker));
				headmins = org + GetHeadshotMins(targ);
				headmaxs = org + GetHeadshotMaxs(targ);
				if(trace_hits_box(railgun_start, railgun_end, headmins, headmaxs))
				{
					deathtype |= HITTYPE_HEADSHOT;
				}
			}
			else if(targ.classname == "turret_head")
			{
				deathtype |= HITTYPE_HEADSHOT;
			}
			if(deathtype & HITTYPE_HEADSHOT)
				damage *= 1 + damage_headshotbonus;

			entity victim;
			if((targ.vehicle_flags & VHF_ISVEHICLE) && targ.owner)
				victim = targ.owner;
			else
				victim = targ;

			if(victim.classname == "player" || victim.turrcaps_flags & TFL_TURRCAPS_ISTURRET)
			{
				if(IsDifferentTeam(victim, attacker))
				{
					if(damage > 0)
					{
						if(deathtype != DEATH_FIRE)
						{
							if(victim.BUTTON_CHAT)
								attacker.typehitsound += 1;
							else
								attacker.hitsound += 1;
						}

						damage_goodhits += 1;
						damage_gooddamage += damage;

						if not(DEATH_ISSPECIAL(deathtype))
						{
							if(targ.classname == "player") // don't do this for vehicles
							if(!g_minstagib)
							if(IsFlying(victim))
								yoda = 1;

							if(g_minstagib)
							if(victim.items & IT_STRENGTH)
								yoda = 1;

							if(deathtype & HITTYPE_HEADSHOT)
								headshot = 1;
						}
						if(g_ca)
							PlayerScore_Add(attacker, SP_SCORE, damage * autocvar_g_ca_damage2score_multiplier);
					}
				}
				else
				{
					if(deathtype != DEATH_FIRE)
					{
						attacker.typehitsound += 1;
					}
					if(mirrordamage > 0)
						if(time > attacker.teamkill_complain)
						{
							attacker.teamkill_complain = time + 5;
							attacker.teamkill_soundtime = time + 0.4;
							attacker.teamkill_soundsource = targ;
						}
				}
			}
		}
	}

	// apply push
	if (self.damageforcescale)
	if (vlen(force))
	if (self.classname != "player" || time >= self.spawnshieldtime || g_midair)
	{
		self.velocity = self.velocity + damage_explosion_calcpush(self.damageforcescale * force, self.velocity, autocvar_g_balance_damagepush_speedfactor);
		self.flags &~= FL_ONGROUND;
		UpdateCSQCProjectile(self);
	}
	// apply damage
	if (damage != 0 || (self.damageforcescale && vlen(force)))
	if (self.event_damage)
		self.event_damage (inflictor, attacker, damage, deathtype, hitloc, force);
	self = oldself;

	if(targ.classname == "player" && attacker.classname == "player" && attacker != targ && attacker.health > 2)
	{
		if(g_runematch)
		{
			if (attacker.runes & RUNE_VAMPIRE)
			{
			// apply vampire rune
				if (attacker.runes & CURSE_EMPATHY) // have the curse too
				{
					//attacker.health = attacker.health + damage * autocvar_g_balance_rune_vampire_combo_absorb;
					attacker.health = bound(
						autocvar_g_balance_curse_empathy_minhealth, // LA: was 3, now 40
						attacker.health + damage * autocvar_g_balance_rune_vampire_combo_absorb,
						autocvar_g_balance_rune_vampire_maxhealth);	// LA: was 1000, now 500
				}
				else
				{
					//attacker.health = attacker.health + damage * autocvar_g_balance_rune_vampire_absorb;
					attacker.health = bound(
						attacker.health,	// LA: was 3, but changed so that you can't lose health
											// empathy won't let you gain health in the same way...
						attacker.health + damage * autocvar_g_balance_rune_vampire_absorb,
						autocvar_g_balance_rune_vampire_maxhealth);	// LA: was 1000, now 500
					}
			}
			// apply empathy curse
			else if (attacker.runes & CURSE_EMPATHY)
			{
				attacker.health = bound(
					autocvar_g_balance_curse_empathy_minhealth, // LA: was 3, now 20
					attacker.health + damage * autocvar_g_balance_curse_empathy_takedamage,
					attacker.health);
			}
		}
	}

	// apply mirror damage if any
	if(mirrordamage > 0 || mirrorforce > 0)
	{
		attacker = attacker_save;
		if(g_minstagib)
		if(mirrordamage > 0)
		{
			// just lose extra LIVES, don't kill the player for mirror damage
			if(attacker.armorvalue > 0)
			{
				attacker.armorvalue = attacker.armorvalue - 1;
				centerprint(attacker, strcat("^3Remaining extra lives: ",ftos(attacker.armorvalue)));
				attacker.hitsound += 1;
			}
			mirrordamage = 0;
		}

		force = normalize(attacker.origin + attacker.view_ofs - hitloc) * mirrorforce;
		Damage(attacker, inflictor, attacker, mirrordamage, DEATH_MIRRORDAMAGE, attacker.origin, force);
	}
}

float RadiusDamage_running;
float RadiusDamage (entity inflictor, entity attacker, float coredamage, float edgedamage, float rad, entity ignore, float forceintensity, float deathtype, entity directhitentity)
// Returns total damage applies to creatures
{
	entity	targ;
	float	finaldmg;
	float	power;
	vector	blastorigin;
	vector	force;
	vector  diff;
	vector  center;
	vector  nearest;
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

	blastorigin = (inflictor.origin + (inflictor.mins + inflictor.maxs) * 0.5);
	total_damage_to_creatures = 0;

	if(deathtype != (WEP_HOOK | HITTYPE_SECONDARY | HITTYPE_BOUNCE)) // only send gravity bomb damage once
	if(DEATH_WEAPONOF(deathtype) != WEP_TUBA) // do not send tuba damage (bandwidth hog)
	{
		force = inflictor.velocity;
		if(vlen(force) == 0)
			force = '0 0 -1';
		else
			force = normalize(force);
		if(forceintensity >= 0)
			Damage_DamageInfo(blastorigin, coredamage, edgedamage, rad, forceintensity * force, deathtype, attacker);
		else
			Damage_DamageInfo(blastorigin, coredamage, edgedamage, -rad, (-forceintensity) * force, deathtype, attacker);
	}

	stat_damagedone = 0;

	targ = WarpZone_FindRadius (blastorigin, rad, FALSE);
	while (targ)
	{
		next = targ.chain;
		if (targ != inflictor)
			if (ignore != targ) if(targ.takedamage)
			{
				// LordHavoc: measure distance to nearest point on target (not origin)
				// (this guarentees 100% damage on a touch impact)
				nearest = targ.WarpZone_findradius_nearest;
				diff = targ.WarpZone_findradius_dist;
				// round up a little on the damage to ensure full damage on impacts
				// and turn the distance into a fraction of the radius
				power = 1 - ((vlen (diff) - 2) / rad);
				//bprint(" ");
				//bprint(ftos(power));
				//if (targ == attacker)
				//	print(ftos(power), "\n");
				if (power > 0)
				{
					if (power > 1)
						power = 1;
					finaldmg = coredamage * power + edgedamage * (1 - power);
					if (finaldmg > 0)
					{
						local float a;
						local float c;
						local float hits;
						local float total;
						local float hitratio;
						local vector hitloc;
						local vector myblastorigin;
						myblastorigin = WarpZone_TransformOrigin(targ, blastorigin);
						center = targ.origin + (targ.mins + targ.maxs) * 0.5;
						// if it's a player, use the view origin as reference
						if (targ.classname == "player")
							center = targ.origin + targ.view_ofs;
						force = normalize(center - myblastorigin);
						force = force * (finaldmg / coredamage) * forceintensity;
						// test line of sight to multiple positions on box,
						// and do damage if any of them hit
						hits = 0;
						if (targ.classname == "player")
							total = ceil(bound(1, finaldmg, 50));
						else
							total = ceil(bound(1, finaldmg/10, 5));
						hitloc = nearest;
						c = 0;
						while (c < total)
						{
							//traceline(targ.WarpZone_findradius_findorigin, nearest, MOVE_NOMONSTERS, inflictor);
							WarpZone_TraceLine(blastorigin, WarpZone_UnTransformOrigin(targ, nearest), MOVE_NOMONSTERS, inflictor);
							if (trace_fraction == 1 || trace_ent == targ)
							{
								hits = hits + 1;
								if (hits > 1)
									hitloc = hitloc + nearest;
								else
									hitloc = nearest;
							}
							nearest_x = targ.origin_x + targ.mins_x + random() * targ.size_x;
							nearest_y = targ.origin_y + targ.mins_y + random() * targ.size_y;
							nearest_z = targ.origin_z + targ.mins_z + random() * targ.size_z;
							c = c + 1;
						}
						nearest = hitloc * (1 / max(1, hits));
						hitratio = (hits / total);
						a = bound(0, tfloordmg + (1-tfloordmg) * hitratio, 1);
						finaldmg = finaldmg * a;
						a = bound(0, tfloorforce + (1-tfloorforce) * hitratio, 1);
						force = force * a;

						// laser force adjustments :P
						if(DEATH_WEAPONOF(deathtype) == WEP_LASER)
						{
                            if (targ == attacker)
                            {
                                vector vel;

                                float force_zscale;
                                float force_velocitybiasramp;
                                float force_velocitybias;

                                force_velocitybiasramp = autocvar_sv_maxspeed;
                                if(deathtype & HITTYPE_SECONDARY)
                                {
                                    force_zscale = autocvar_g_balance_laser_secondary_force_zscale;
                                    force_velocitybias = autocvar_g_balance_laser_secondary_force_velocitybias;
                                }
                                else
                                {
                                    force_zscale = autocvar_g_balance_laser_primary_force_zscale;
                                    force_velocitybias = autocvar_g_balance_laser_primary_force_velocitybias;
                                }

                                vel = targ.velocity;
                                vel_z = 0;
                                vel = normalize(vel) * bound(0, vlen(vel) / force_velocitybiasramp, 1) * force_velocitybias;
                                force =
                                    vlen(force)
                                    *
                                    normalize(normalize(force) + vel);

                                force_z *= force_zscale;
                            }
                            else
                            {
                                if(deathtype & HITTYPE_SECONDARY)
                                {
                                    force *= autocvar_g_balance_laser_secondary_force_other_scale;
                                }
                                else
                                {
                                    force *= autocvar_g_balance_laser_primary_force_other_scale;
                                }
                            }
						}

						//if (targ == attacker)
						//{
						//	print("hits ", ftos(hits), " / ", ftos(total));
						//	print(" finaldmg ", ftos(finaldmg), " force ", vtos(force));
						//	print(" (", ftos(a), ")\n");
						//}
						if(hits || tfloordmg || tfloorforce)
						{
							if(targ.iscreature)
							{
								total_damage_to_creatures += finaldmg;

								if(accuracy_isgooddamage(attacker, targ))
									stat_damagedone += finaldmg;
							}

							if(targ == directhitentity || DEATH_ISSPECIAL(deathtype))
								Damage (targ, inflictor, attacker, finaldmg, deathtype, nearest, force);
							else
								Damage (targ, inflictor, attacker, finaldmg, deathtype | HITTYPE_SPLASH, nearest, force);
						}
					}
				}
			}
		targ = next;
	}

	RadiusDamage_running = 0;

	if(!DEATH_ISSPECIAL(deathtype))
		accuracy_add(attacker, DEATH_WEAPONOFWEAPONDEATH(deathtype), 0, min(coredamage, stat_damagedone));

	return total_damage_to_creatures;
}

.float fire_damagepersec;
.float fire_endtime;
.float fire_deathtype;
.entity fire_owner;
.float fire_hitsound;
.entity fire_burner;

void fireburner_think();

float Fire_IsBurning(entity e)
{
	return (time < e.fire_endtime);
}

float Fire_AddDamage(entity e, entity o, float d, float t, float dt)
{
	float dps;
	float maxtime, mintime, maxdamage, mindamage, maxdps, mindps, totaldamage, totaltime;

	if(e.classname == "player")
	{
		if(e.deadflag)
			return -1;
	}
	else
	{
		if(!e.fire_burner)
		{
			// print("adding a fire burner to ", e.classname, "\n");
			e.fire_burner = spawn();
			e.fire_burner.classname = "fireburner";
			e.fire_burner.think = fireburner_think;
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
			mindamage = mindps * mintime;
			maxdamage = mindamage + d;

			// interval [mintime, maxtime] * [mindps, maxdps]
			// intersected with
			// [mindamage, maxdamage]
			// maximum of this!

			if(maxdamage >= maxtime * maxdps)
			{
				totaltime = maxtime;
				totaldamage = maxtime * maxdps;

				// this branch increases totaldamage if either t > mintime, or dps > mindps
			}
			else
			{
				// maxdamage is inside the interval!
				// first, try to use mindps; only if this fails, increase dps as needed
				totaltime = min(maxdamage / mindps, maxtime); // maxdamage / mindps >= mindamage / mindps = mintime
				totaldamage = maxdamage;
				// can totaldamage / totaltime be >= maxdps?
				// max(mindps, maxdamage / maxtime) >= maxdps?
				// we know maxdamage < maxtime * maxdps
				// so it cannot be

				// this branch ALWAYS increases totaldamage, but requires maxdamage < maxtime * maxdps
			}

			// total conditions for increasing:
			//     maxtime > mintime OR maxdps > mindps OR maxtime * maxdps > maxdamage
			// however:
			//     if maxtime = mintime, maxdps = mindps
			// then:
			//     maxdamage = mindamage + d
			//     mindamage = mindps * mintime = maxdps * maxtime < maxdamage!
			// so the last condition is not needed

			e.fire_damagepersec = totaldamage / totaltime;
			e.fire_endtime = time + totaltime;
			if(totaldamage > 1.2 * mindamage)
			{
				e.fire_deathtype = dt;
				if(e.fire_owner != o)
				{
					e.fire_owner = o;
					e.fire_hitsound = FALSE;
				}
			}
			if(accuracy_isgooddamage(o, e))
				accuracy_add(o, DEATH_WEAPONOFWEAPONDEATH(dt), 0, max(0, totaldamage - mindamage));
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
		e.fire_hitsound = FALSE;
		if(accuracy_isgooddamage(o, e))
			accuracy_add(o, DEATH_WEAPONOFWEAPONDEATH(dt), 0, d);
		return d;
	}
}

void Fire_ApplyDamage(entity e)
{
	float t, d, hi, ty;
	entity o;

	if not(Fire_IsBurning(e))
		return;

	for(t = 0, o = e.owner; o.owner && t < 16; o = o.owner, ++t);
	if(clienttype(o) == CLIENTTYPE_NOTACLIENT)
		o = e.fire_owner;

	// water and slime stop fire
	if(e.waterlevel)
	if(e.watertype != CONTENT_LAVA)
		e.fire_endtime = 0;

	// ice stops fire
	if(e.freezetag_frozen)
		e.fire_endtime = 0;

	t = min(frametime, e.fire_endtime - time);
	d = e.fire_damagepersec * t;

	hi = e.fire_owner.hitsound;
	ty = e.fire_owner.typehitsound;
	Damage(e, e, e.fire_owner, d, e.fire_deathtype, e.origin, '0 0 0');
	if(e.fire_hitsound && e.fire_owner)
	{
		e.fire_owner.hitsound = hi;
		e.fire_owner.typehitsound = ty;
	}
	e.fire_hitsound = TRUE;

	if not(IS_INDEPENDENT_PLAYER(e))
	FOR_EACH_PLAYER(other) if(e != other)
	{
		if(other.classname == "player")
		if(other.deadflag == DEAD_NO)
		if not(IS_INDEPENDENT_PLAYER(other))
		if(boxesoverlap(e.absmin, e.absmax, other.absmin, other.absmax))
		{
			t = autocvar_g_balance_firetransfer_time * (e.fire_endtime - time);
			d = autocvar_g_balance_firetransfer_damage * e.fire_damagepersec * t;
			Fire_AddDamage(other, o, d, t, DEATH_FIRE);
		}
	}
}

void Fire_ApplyEffect(entity e)
{
	if(Fire_IsBurning(e))
		e.effects |= EF_FLAME;
	else
		e.effects &~= EF_FLAME;
}

void fireburner_think()
{
	// for players, this is done in the regular loop
	if(wasfreed(self.owner))
	{
		remove(self);
		return;
	}
	Fire_ApplyEffect(self.owner);
	if(!Fire_IsBurning(self.owner))
	{
		self.owner.fire_burner = world;
		remove(self);
		return;
	}
	Fire_ApplyDamage(self.owner);
	self.nextthink = time;
}
