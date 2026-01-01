#include "cheats.qh"

#include "weapons/tracing.qh"
#include <common/constants.qh>
#include <common/deathtypes/all.qh>
#include <common/effects/all.qh>
#include <common/items/_mod.qh>
#include <common/mapobjects/func/breakable.qh>
#include <common/mapobjects/subs.qh>
#include <common/mapobjects/teleporters.qh>
#include <common/mapobjects/triggers.qh>
#include <common/monsters/_mod.qh>
#include <common/mutators/mutator/status_effects/_mod.qh>
#include <common/physics/player.qh>
#include <common/resources/sv_resources.qh>
#include <common/stats.qh>
#include <common/util.qh>
#include <common/weapons/_all.qh>
#include <common/weapons/_all.qh>
#include <lib/csqcmodel/sv_model.qh>
#include <lib/warpzone/anglestransform.qh>
#include <lib/warpzone/common.qh>
#include <lib/warpzone/util_server.qh>
#include <server/client.qh>
#include <server/clientkill.qh>
#include <server/damage.qh>
#include <server/main.qh>
#include <server/mutators/_mod.qh>
#include <server/player.qh>
#include <server/race.qh>
#include <server/world.qh>

#ifdef NOCHEATS

float CheatImpulse(entity this, int imp) { return 0; }
float CheatCommand(entity this, int argc) { return 0; }
float CheatFrame(entity this) { return 0; }
void CheatInit() { cheatcount_total = world.cheatcount; }
void CheatShutdown() { }
void Drag_MoveDrag(entity from, entity to) { }

#else

.bool maycheat;
float gamestart_sv_cheats;



void CheatInit()
{
	gamestart_sv_cheats = autocvar_sv_cheats;
}

void CheatShutdown()
{
}

// the cheat gets passed as argument for possible future ACL checking
float CheatsAllowed(entity this, float imp, int argc, float cheatframe, bool logattempt, bool ignoredead)
{
	if(!ignoredead && IS_DEAD(this))
		return 0;
	if(gamestart_sv_cheats < 2 && !IS_PLAYER(this))
		return 0;

	if(imp == CHIMPULSE_CLONE_MOVING.impulse || imp == CHIMPULSE_CLONE_STANDING.impulse)
		if(this.lip < autocvar_sv_clones)
			return 1;

	// haha
	if(this.maycheat)
		return 1;

	if(gamestart_sv_cheats && autocvar_sv_cheats)
		return 1;

	if (logattempt)
	{
		// if we get here, player is not allowed to cheat. Log it.
		if(imp)
			bprintf("Player %s^7 tried to use cheat 'impulse %d'\n", playername(this.netname, this.team, false), imp);
		else if(argc)
			bprintf("Player %s^7 tried to use cheat '%s'\n", playername(this.netname, this.team, false), argv(0));
		else if(cheatframe)
			bprintf("Player %s^7 tried to use cheat frame %d\n", playername(this.netname, this.team, false), cheatframe);
		else
			bprintf("Player %s^7 tried to use an unknown cheat\n", playername(this.netname, this.team, false));
	}
	return 0;
}

#define BEGIN_CHEAT_FUNCTION() \
	float cheating = 0, attempting = 0
#define DID_CHEAT() \
	++cheating
#define ADD_CHEATS(e,n) \
	cheatcount_total += n; \
	e.cheatcount += n
#define END_CHEAT_FUNCTION() \
	ADD_CHEATS(this, cheating); \
	return attempting
#define IS_CHEAT(ent,i,argc,fr) \
	if((++attempting, !CheatsAllowed(ent,i,argc,fr,true,false))) \
		break

float num_autoscreenshot;
void info_autoscreenshot_findtarget(entity this)
{
	entity e;
	e = find(NULL, targetname, this.target);
	if(!e)
	{
		objerror(this, "Missing target. FAIL!");
		return;
	}
	vector a = vectoangles(e.origin - this.origin);
	a.x = -a.x; // don't ask
	this.angles_x = a.x;
	this.angles_y = a.y;
	// we leave Rick Roll alone
}
spawnfunc(info_autoscreenshot)
{
	// this one just has to exist
	if(++num_autoscreenshot > autocvar_g_max_info_autoscreenshot)
	{
		objerror(this, "Too many info_autoscreenshot entitites. FAIL!");
		return;
	}
	if(this.target != "")
		InitializeEntity(this, info_autoscreenshot_findtarget, INITPRIO_FINDTARGET);

	tracebox(this.origin, PL_CROUCH_MIN_CONST, PL_CROUCH_MAX_CONST, this.origin, MOVE_WORLDONLY, this);
	if(!trace_startsolid)
		IL_PUSH(g_observepoints, this);
}

float CheatImpulse(entity this, int imp)
{
	BEGIN_CHEAT_FUNCTION();
	switch(imp)
	{
		entity e, e2;

		case CHIMPULSE_SPEEDRUN_INIT.impulse: // deploy personal waypoint
			// shared with regular waypoint init, so this is not a cheat by itself
			if(!this.personal)
			{
				this.personal = new(personal_wp);
			}
			this.personal.origin = this.origin;
			this.personal.v_angle = this.v_angle;
			this.personal.velocity = this.velocity;
			SetResource(this.personal, RES_ROCKETS, GetResource(this, RES_ROCKETS));
			SetResource(this.personal, RES_BULLETS, GetResource(this, RES_BULLETS));
			SetResource(this.personal, RES_CELLS, GetResource(this, RES_CELLS));
			SetResource(this.personal, RES_SHELLS, GetResource(this, RES_SHELLS));
			SetResource(this.personal, RES_FUEL, GetResource(this, RES_FUEL));
			SetResource(this.personal, RES_HEALTH, max(1, GetResource(this, RES_HEALTH)));
			SetResource(this.personal, RES_ARMOR, GetResource(this, RES_ARMOR));
			STAT(WEAPONS, this.personal) = STAT(WEAPONS, this);
			StatusEffects_copy(this.statuseffects, this.personal, 0);
			this.personal.items = this.items;
			this.personal.pauserotarmor_finished = this.pauserotarmor_finished;
			this.personal.pauserothealth_finished = this.pauserothealth_finished;
			this.personal.pauserotfuel_finished = this.pauserotfuel_finished;
			this.personal.pauseregen_finished = this.pauseregen_finished;
			this.personal.teleport_time = time;
			break; // this part itself doesn't cheat, so let's not count this
		case CHIMPULSE_CLONE_MOVING.impulse:
			IS_CHEAT(this, imp, 0, 0);
			makevectors (this.v_angle);
			this.velocity = this.velocity + v_forward * 300;
			CopyBody(this, 1);
			this.lip += 1;
			this.velocity = this.velocity - v_forward * 300;
			DID_CHEAT();
			break;
		case CHIMPULSE_CLONE_STANDING.impulse:
			IS_CHEAT(this, imp, 0, 0);
			CopyBody(this, 0);
			this.lip += 1;
			DID_CHEAT();
			break;
		case CHIMPULSE_GIVE_ALL.impulse:
			IS_CHEAT(this, imp, 0, 0);
			CheatCommand(this, tokenize_console("give all"));
			break; // already counted as cheat
		case CHIMPULSE_SPEEDRUN.impulse:
			if(!autocvar_g_allow_checkpoints)
				IS_CHEAT(this, imp, 0, 0);
			if(this.personal)
			{
				this.speedrunning = true;
				tracebox(this.personal.origin, this.mins, this.maxs, this.personal.origin, MOVE_WORLDONLY, this);
				if(trace_startsolid)
				{
					sprint(this, "Cannot move there, cheater - only waypoints set using g_waypointsprite_personal work\n");
				}
				else
				{
					// Abort speedrun, teleport back
					setorigin(this, this.personal.origin);
					this.oldvelocity = this.velocity = this.personal.velocity;
					this.angles = this.personal.v_angle;
					this.fixangle = true;

					MUTATOR_CALLHOOK(AbortSpeedrun, this);
				}

				SetResource(this, RES_ROCKETS, GetResource(this.personal, RES_ROCKETS));
				SetResource(this, RES_BULLETS, GetResource(this.personal, RES_BULLETS));
				SetResource(this, RES_CELLS, GetResource(this.personal, RES_CELLS));
				SetResource(this, RES_SHELLS, GetResource(this.personal, RES_SHELLS));
				SetResource(this, RES_FUEL, GetResource(this.personal, RES_FUEL));
				SetResource(this, RES_HEALTH, GetResource(this.personal, RES_HEALTH));
				SetResource(this, RES_ARMOR, GetResource(this.personal, RES_ARMOR));
				STAT(WEAPONS, this) = STAT(WEAPONS, this.personal);
				this.items = this.personal.items;
				this.pauserotarmor_finished = time + this.personal.pauserotarmor_finished - this.personal.teleport_time;
				this.pauserothealth_finished = time + this.personal.pauserothealth_finished - this.personal.teleport_time;
				this.pauserotfuel_finished = time + this.personal.pauserotfuel_finished - this.personal.teleport_time;
				this.pauseregen_finished = time + this.personal.pauseregen_finished - this.personal.teleport_time;
				StatusEffects_copy(this.personal, this.statuseffects, this.personal.teleport_time);
				StatusEffects_update(this);

				if(!autocvar_g_allow_checkpoints)
					DID_CHEAT();
				break;
			}
			if(IS_DEAD(this))
				sprint(this, "UR DEAD AHAHAH))\n");
			else
				sprint(this, "No waypoint set, cheater (use g_waypointsprite_personal to set one)\n");
			break;
		case CHIMPULSE_TELEPORT.impulse:
			IS_CHEAT(this, imp, 0, 0);
			if(this.move_movetype == MOVETYPE_NOCLIP)
			{
				e = find(NULL, classname, "info_autoscreenshot");
				if(e)
				{
					sprint(this, "Emergency teleport used info_autoscreenshot location\n");
					setorigin(this, e.origin);
					this.angles = e.angles;
					delete(e);
					// should we? this.angles_x = -this.angles_x;
					this.fixangle = true;
					this.velocity = '0 0 0';
					DID_CHEAT();
					break;
				}
			}
			if(MoveToRandomMapLocation(this, DPCONTENTS_SOLID | DPCONTENTS_CORPSE | DPCONTENTS_PLAYERCLIP, DPCONTENTS_SLIME | DPCONTENTS_LAVA | DPCONTENTS_SKY | DPCONTENTS_BODY | DPCONTENTS_DONOTENTER, Q3SURFACEFLAG_SKY, ((gamestart_sv_cheats < 2) ? 100 : 100000), 384, 384))
			{
				sprint(this, "Emergency teleport used random location\n");
				this.angles_x = -this.angles.x;
				this.fixangle = true;
				this.velocity = '0 0 0';
				DID_CHEAT();
				break;
			}
			sprint(this, "Emergency teleport could not find a good location, forget it!\n");
			break;
		case CHIMPULSE_R00T.impulse:
			IS_CHEAT(this, imp, 0, 0);
			RandomSelection_Init();
			FOREACH_CLIENT(IS_PLAYER(it) && !IS_DEAD(it) && DIFF_TEAM(it, this), { RandomSelection_AddEnt(it, 1, 1); });
			if(RandomSelection_chosen_ent)
				e = RandomSelection_chosen_ent;
			else
				e = this;

			Send_Effect(EFFECT_ROCKET_EXPLODE, e.origin, '0 0 0', 1);
			sound(e, CH_SHOTS, SND_ROCKET_IMPACT, VOL_BASE, ATTEN_NORM);

			e2 = spawn();
			setorigin(e2, e.origin);
			RadiusDamage(e2, this, 1000, 0, 128, NULL, NULL, 500, DEATH_CHEAT.m_id, DMG_NOWEP, e);
			delete(e2);

			LOG_INFO("404 Sportsmanship not found.");
			DID_CHEAT();
			break;
	}

	END_CHEAT_FUNCTION();
}

float drag_lastcnt;
float CheatCommand(entity this, int argc)
{
	BEGIN_CHEAT_FUNCTION();
	string cmd;
	cmd = argv(0);
	switch(cmd)
	{
		float effectnum, f;
		vector start, end;

		case "pointparticles":
			IS_CHEAT(this, 0, argc, 0);
			if(argc == 5)
			{
				f = stof(argv(2));
				crosshair_trace(this);
				start = (1-f) * this.origin + f * trace_endpos;
				end = stov(argv(3));
				f = stof(argv(4));
				Send_Effect_(argv(1), start, end, f);
				DID_CHEAT();
				break;
			}
			sprint(this, "Usage:^3 sv_cheats 1; restart; cmd pointparticles <effectname> <position> <velocity> <countmultiplier>\n");
			sprint(this, "  Where <position> is a number from 0 to 1 representing distance on the crosshair line,\n");
			sprint(this, "  and <velocity> is a vector \"x y z\"\n");
			break;
		case "trailparticles":
			IS_CHEAT(this, 0, argc, 0);
			if(argc == 2)
			{
				// arguments:
				//   effectname
				effectnum = _particleeffectnum(argv(1));
				W_SetupShot(this, weaponentities[0], false, false, SND_Null, CH_WEAPON_A, 0, 0);
				traceline(w_shotorg, w_shotorg + w_shotdir * max_shot_distance, MOVE_NORMAL, this);
				__trailparticles(this, effectnum, w_shotorg, trace_endpos);
				DID_CHEAT();
				break;
			}
			sprint(this, "Usage: sv_cheats 1; restart; cmd trailparticles <effectname>\n");
			break;
		case "make":
			IS_CHEAT(this, 0, argc, 0);
			if(argc == 3)
			{
				f = stof(argv(2));
				W_SetupShot(this, weaponentities[0], false, false, SND_Null, CH_WEAPON_A, 0, 0);
				traceline(w_shotorg, w_shotorg + w_shotdir * 2048, MOVE_NORMAL, this);
				if((trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT) || trace_fraction == 1)
				{
					sprint(this, "cannot make stuff there (bad surface)\n");
				}
				else
				{
					entity e = new(func_breakable);
					e.model = strzone(argv(1));
					e.mdl = "rocket_explode";
					SetResourceExplicit(e, RES_HEALTH, 1000);
					setorigin(e, trace_endpos);
					e.effects = EF_NOMODELFLAGS;
					if(f == 1)
					{
						e.angles = fixedvectoangles2(trace_plane_normal, v_forward);
						e.angles = AnglesTransform_ApplyToAngles(e.angles, '-90 0 0'); // so unrotated models work
					}
					func_breakable_setup(e);
					// now, is it valid?
					if(f == 0)
					{
						tracebox(e.origin, e.mins, e.maxs, e.origin, MOVE_NORMAL, e);
						if(trace_startsolid)
						{
							delete(e);
							sprint(this, "cannot make stuff there (no space)\n");
						}
						else
							DID_CHEAT();
					}
					else
						DID_CHEAT();
				}
			}
			else
			{
				sprint(this, "Usage:^3 sv_cheats 1; restart; cmd make <modelname> <mode>\n");
				sprint(this, "  where <mode> can be 0, 1 or 2\n");
			}
			break;
		case "penalty":
			IS_CHEAT(this, 0, argc, 0);
			if(argc == 3)
			{
				race_ImposePenaltyTime(this, stof(argv(1)), argv(2));
				DID_CHEAT();
				break;
			}
			sprint(this, "Usage:^3 sv_cheats 1; restart; cmd penalty <duration> <reason>))\n");
			break;
		case "dragbox_spawn": {
			IS_CHEAT(this, 0, argc, 0);
			entity e = new(dragbox_box);
			setthink(e, DragBox_Think);
			e.nextthink = time;
			e.solid = -1; // black
			setmodel(e, MDL_Null); // network it
			if(argc == 4)
				e.cnt = stof(argv(1));
			else
				e.cnt = max(0, drag_lastcnt);

			e.aiment = new(dragbox_corner_1);
			e.aiment.owner = e;
			setmodel(e.aiment, MDL_MARKER);
			e.aiment.skin = 0;
			setsize(e.aiment, '0 0 0', '0 0 0');
			if(argc == 4)
				setorigin(e.aiment, stov(argv(2)));
			else
			{
				crosshair_trace(this);
				setorigin(e.aiment, trace_endpos);
			}

			e.enemy = new(dragbox_corner_2);
			e.enemy.owner = e;
			setmodel(e.enemy, MDL_MARKER);
			e.enemy.skin = 1;
			setsize(e.enemy, '0 0 0', '0 0 0');
			end = normalize(this.origin + this.view_ofs - e.aiment.origin);
			end.x = (end.x > 0) * 2 - 1;
			end.y = (end.y > 0) * 2 - 1;
			end.z = (end.z > 0) * 2 - 1;
			if(argc == 4)
				setorigin(e.enemy, stov(argv(3)));
			else
				setorigin(e.enemy, e.aiment.origin + 32 * end);

			e.killindicator = new(drag_digit);
			e.killindicator.owner = e;
			setattachment(e.killindicator, e, "");
			setorigin(e.killindicator, '0 0 -8');
			e.killindicator.killindicator = new(drag_digit);
			e.killindicator.killindicator.owner = e;
			setattachment(e.killindicator.killindicator, e, "");
			setorigin(e.killindicator.killindicator, '0 0 8');
			DID_CHEAT();
			break;
		}
		case "dragpoint_spawn": {
			IS_CHEAT(this, 0, argc, 0);
			entity e = new(dragpoint);
			setthink(e, DragBox_Think);
			e.nextthink = time;
			e.solid = 0; // nothing special
			setmodel(e, MDL_MARKER);
			setsize(e, STAT(PL_MIN, this), STAT(PL_MAX, this));
			e.skin = 2;
			if(argc == 3)
				e.cnt = stof(argv(1));
			else
				e.cnt = drag_lastcnt;
			if(argc == 3)
				setorigin(e, stov(argv(2)));
			else
			{
				crosshair_trace(this);
				setorigin(e, trace_endpos + normalize(this.origin + this.view_ofs - trace_endpos));
				move_out_of_solid(e);
			}

			e.killindicator = new(drag_digit);
			e.killindicator.owner = e;
			setattachment(e.killindicator, e, "");
			setorigin(e.killindicator, '0 0 40');
			e.killindicator.killindicator = new(drag_digit);
			e.killindicator.killindicator.owner = e;
			setattachment(e.killindicator.killindicator, e, "");
			setorigin(e.killindicator.killindicator, '0 0 56');
			DID_CHEAT();
			break;
		}
		case "drag_remove":
			IS_CHEAT(this, 0, argc, 0);
			RandomSelection_Init();
			crosshair_trace(this);
			for(entity e = NULL; (e = find(e, classname, "dragbox_box")); )
				RandomSelection_AddEnt(e, 1, 1 / vlen(e.origin + (e.mins + e.maxs) * 0.5 - trace_endpos));
			for(entity e = NULL; (e = find(e, classname, "dragpoint")); )
				RandomSelection_AddEnt(e, 1, 1 / vlen(e.origin + (e.mins + e.maxs) * 0.5 - trace_endpos));
			if(RandomSelection_chosen_ent)
			{
				delete(RandomSelection_chosen_ent.killindicator.killindicator);
				delete(RandomSelection_chosen_ent.killindicator);
				if(RandomSelection_chosen_ent.aiment)
					delete(RandomSelection_chosen_ent.aiment);
				if(RandomSelection_chosen_ent.enemy)
					delete(RandomSelection_chosen_ent.enemy);
				delete(RandomSelection_chosen_ent);
			}
			DID_CHEAT();
			break;
		case "drag_setcnt":
			IS_CHEAT(this, 0, argc, 0);
			if(argc == 2)
			{
				RandomSelection_Init();
				crosshair_trace(this);
				for(entity e = NULL; (e = find(e, classname, "dragbox_box")); )
					RandomSelection_AddEnt(e, 1, 1 / vlen(e.origin + (e.mins + e.maxs) * 0.5 - trace_endpos));
				for(entity e = NULL; (e = find(e, classname, "dragpoint")); )
					RandomSelection_AddEnt(e, 1, 1 / vlen(e.origin + (e.mins + e.maxs) * 0.5 - trace_endpos));
				if(RandomSelection_chosen_ent)
				{
					if(substring(argv(1), 0, 1) == "*")
						RandomSelection_chosen_ent.cnt = drag_lastcnt = RandomSelection_chosen_ent.cnt + stof(substring(argv(1), 1, -1));
					else
						RandomSelection_chosen_ent.cnt = drag_lastcnt = stof(argv(1));
				}
				DID_CHEAT();
				break;
			}
			sprint(this, "Usage:^3 sv_cheats 1; restart; cmd dragbox_setcnt <cnt>\n");
			break;
		case "drag_save":
			IS_CHEAT(this, 0, argc, 0);
			if(argc == 2)
			{
				f = fopen(argv(1), FILE_WRITE);
				fputs(f, "cmd drag_clear\n");
				for(entity e = NULL; (e = find(e, classname, "dragbox_box")); )
				{
					fputs(f, strcat("cmd dragbox_spawn ", ftos(e.cnt), " \"", vtos(e.aiment.origin), "\" \"", vtos(e.enemy.origin), "\"\n"));
				}
				for(entity e = NULL; (e = find(e, classname, "dragpoint")); )
				{
					fputs(f, strcat("cmd dragpoint_spawn ", ftos(e.cnt), " \"", vtos(e.origin), "\"\n"));
				}
				fclose(f);
				DID_CHEAT();
				break;
			}
			sprint(this, "Usage:^3 sv_cheats 1; restart; cmd dragbox_save <filename>\n");
			break;
		case "drag_saveraceent":
			IS_CHEAT(this, 0, argc, 0);
			if(argc == 2)
			{
				f = fopen(argv(1), FILE_WRITE);
				for(entity e = NULL; (e = find(e, classname, "dragbox_box")); )
				{
					fputs(f, "{\n");
					fputs(f, "\"classname\" \"trigger_race_checkpoint\"\n");
					fputs(f, strcat("\"origin\" \"", ftos(e.absmin.x), " ", ftos(e.absmin.y), " ", ftos(e.absmin.z), "\"\n"));
					fputs(f, strcat("\"maxs\" \"", ftos(e.absmax.x - e.absmin.x), " ", ftos(e.absmax.y - e.absmin.y), " ", ftos(e.absmax.z - e.absmin.z), "\"\n"));
					fputs(f, strcat("\"cnt\" \"", ftos(e.cnt), "\"\n"));
					fputs(f, strcat("\"targetname\" \"checkpoint", ftos(e.cnt), "\"\n"));
					fputs(f, "}\n");
				}
				for(entity e = NULL; (e = find(e, classname, "dragpoint")); )
				{
					start = '0 0 0';
					effectnum = 0;
					for(entity ent = NULL; (ent = find(ent, classname, "dragbox_box")); )
					{
						if((e.cnt <= 0 && ent.cnt == 0) || e.cnt == ent.cnt)
						{
							start = start + ent.origin;
							++effectnum;
						}
					}
					start *= 1 / effectnum;
					fputs(f, "{\n");
					fputs(f, "\"classname\" \"info_player_race\"\n");
					fputs(f, strcat("\"angle\" \"", ftos(vectoyaw(start - e.origin)), "\"\n"));
					fputs(f, strcat("\"origin\" \"", ftos(e.origin.x), " ", ftos(e.origin.y), " ", ftos(e.origin.z), "\"\n"));
					if(e.cnt == -2)
					{
						fputs(f, "\"target\" \"checkpoint0\"\n");
						fputs(f, "\"race_place\" \"0\"\n");
					}
					else if(e.cnt == -1)
					{
						fputs(f, "\"target\" \"checkpoint0\"\n");
						fputs(f, "\"race_place\" \"-1\"\n");
					}
					else
					{
						fputs(f, strcat("\"target\" \"checkpoint", ftos(e.cnt), "\"\n"));
						if(e.cnt == 0)
						{
							// these need race_place
							// counting...
							effectnum = 1;
							for(entity ent = NULL; (ent = find(ent, classname, "dragpoint")); )
							if(ent.cnt == 0)
							{
								if(vlen2(ent.origin - start) < vlen2(e.origin - start))
									++effectnum;
								else if(vlen2(ent.origin - start) == vlen2(e.origin - start) && etof(ent) < etof(e))
									++effectnum;
							}
							fputs(f, strcat("\"race_place\" \"", ftos(effectnum), "\"\n"));
						}
					}
					fputs(f, "}\n");
				}
				fclose(f);
				DID_CHEAT();
				break;
			}
			sprint(this, "Usage:^3 sv_cheats 1; restart; cmd dragbox_save <filename>\n");
			break;
		case "drag_clear":
			IS_CHEAT(this, 0, argc, 0);
			for(entity e = NULL; (e = find(e, classname, "dragbox_box")); )
				delete(e);
			for(entity e = NULL; (e = find(e, classname, "dragbox_corner_1")); )
				delete(e);
			for(entity e = NULL; (e = find(e, classname, "dragbox_corner_2")); )
				delete(e);
			for(entity e = NULL; (e = find(e, classname, "dragpoint")); )
				delete(e);
			for(entity e = NULL; (e = find(e, classname, "drag_digit")); )
				delete(e);
			DID_CHEAT();
			break;
		case "god":
			IS_CHEAT(this, 0, argc, 0);
			BITXOR_ASSIGN(this.flags, FL_GODMODE);
			if(this.flags & FL_GODMODE)
			{
				sprint(this, "godmode ON\n");
				DID_CHEAT();
			}
			else
				sprint(this, "godmode OFF\n");
			break;
		case "notarget":
			IS_CHEAT(this, 0, argc, 0);
			BITXOR_ASSIGN(this.flags, FL_NOTARGET);
			if(this.flags & FL_NOTARGET)
			{
				sprint(this, "notarget ON\n");
				DID_CHEAT();
			}
			else
				sprint(this, "notarget OFF\n");
			break;
		case "noclip":
			IS_CHEAT(this, 0, argc, 0);
			if(this.move_movetype != MOVETYPE_NOCLIP)
			{
				set_movetype(this, MOVETYPE_NOCLIP);
				sprint(this, "noclip ON\n");
				DID_CHEAT();
			}
			else
			{
				set_movetype(this, MOVETYPE_WALK);
				sprint(this, "noclip OFF\n");
			}
			break;
		case "fly":
			IS_CHEAT(this, 0, argc, 0);
			if(this.move_movetype != MOVETYPE_FLY)
			{
				set_movetype(this, MOVETYPE_FLY);
				sprint(this, "flymode ON\n");
				DID_CHEAT();
			}
			else
			{
				set_movetype(this, MOVETYPE_WALK);
				sprint(this, "flymode OFF\n");
			}
			break;
		case "give":
			IS_CHEAT(this, 0, argc, 0);
			if(GiveItems(this, 1, argc))
				DID_CHEAT();
			break;
		case "usetarget":
			IS_CHEAT(this, 0, argc, 0);
			entity e = spawn();
			e.target = argv(1);
			SUB_UseTargets(e, this, NULL);
			delete(e);
			DID_CHEAT();
			break;
		case "killtarget":
			IS_CHEAT(this, 0, argc, 0);
			entity e2 = spawn();
			e2.killtarget = argv(1);
			SUB_UseTargets(e2, this, NULL);
			delete(e2);
			DID_CHEAT();
			break;
		case "teleporttotarget":
			IS_CHEAT(this, 0, argc, 0);
			entity ent = new(cheattriggerteleport);
			setorigin(ent, ent.origin);
			ent.target = argv(1);
			teleport_findtarget(ent);
			if(!wasfreed(ent))
			{
				Simple_TeleportPlayer(ent, this);
				delete(ent);
				DID_CHEAT();
			}
			break;
	}

	END_CHEAT_FUNCTION();
}

.entity dragentity;

float CheatFrame(entity this)
{
	BEGIN_CHEAT_FUNCTION();

	// Dragging can be used as either a cheat, or a function for some objects. If sv_cheats is active,
	// the cheat dragging is used (unlimited pickup range and any entity can be carried). If sv_cheats
	// is disabled, normal dragging is used (limited pickup range and only dragable objects can be carried),
	// grabbing itself no longer being accounted as cheating.

	switch(0)
	{
		default:
			if(this.maycheat || (gamestart_sv_cheats && autocvar_sv_cheats))
			{
				// use cheat dragging if cheats are enabled
				//if(Drag_IsDragging(this))
					//crosshair_trace_plusvisibletriggers(this);
				Drag(this, true, true);
			}
			else
			{
				Drag(this, false, false); // execute dragging
			}
			break;
	}

	END_CHEAT_FUNCTION();
}





// ENTITY DRAGGING

// on dragger:
.float draggravity;
.float dragspeed; // speed of mouse wheel action
.float dragdistance; // distance of dragentity's draglocalvector from view_ofs
.vector draglocalvector; // local attachment vector of the dragentity
.float draglocalangle;
// on draggee:
.entity draggedby;
.float dragmovetype;

float Drag(entity this, float force_allow_pick, float ischeat)
{
	BEGIN_CHEAT_FUNCTION();

	// returns true when an entity has been picked up
	// If pick is true, the object can also be picked up if it's not being held already
	// If pick is false, only keep dragging the object if it's already being held

	switch(0)
	{
		default:
			if(Drag_IsDragging(this))
			{
				if(PHYS_INPUT_BUTTON_DRAG(this))
				{
					if(CS(this).impulse == 10 || CS(this).impulse == 15 || CS(this).impulse == 18)
					{
						Drag_MoveForward(this);
						CS(this).impulse = 0;
					}
					else if(CS(this).impulse == 12 || CS(this).impulse == 16 || CS(this).impulse == 19)
					{
						Drag_MoveBackward(this);
						CS(this).impulse = 0;
					}
					else if(CS(this).impulse >= 1 && CS(this).impulse <= 9)
					{
						Drag_SetSpeed(this, CS(this).impulse - 1);
					}
					else if(CS(this).impulse == 14)
					{
						Drag_SetSpeed(this, 9);
					}

					if(frametime)
						Drag_Update(this);
				}
				else
				{
					Drag_Finish(this);
				}
			}
			else if(Drag_CanDrag(this) && PHYS_INPUT_BUTTON_DRAG(this))
			{
				crosshair_trace_plusvisibletriggers(this);
				entity e = trace_ent;
				float pick = force_allow_pick;
				if (e && !pick && vdist(this.origin - e.origin, <=, autocvar_g_grab_range))
				{
					// pick is true if the object can be picked up. While an object is being carried, the Drag() function
					// must execute for it either way, otherwise it would cause bugs if it went out of the player's trace.
					// This also makes sure that an object can only pe picked up if in range, but does not get dropped if
					// it goes out of range while slinging it around.

					switch(e.grab)
					{
						case 0: // can't grab
							break;
						case 1: // owner can grab
							if(e.owner == this || e.realowner == this)
								pick = true;
							break;
						case 2: // owner and teammates can grab
							if(SAME_TEAM(e.owner, this) || SAME_TEAM(e.realowner, this) || e.team == this.team)
								pick = true;
							break;
						case 3: // anyone can grab
							pick = true;
							break;
						default:
							break;
					}
				}
				// Find e and pick
				if(e && pick && Drag_IsDraggable(e, this))
				{
					if(ischeat)
						IS_CHEAT(this, 0, 0, CHRAME_DRAG);
					if(e.draggedby)
						Drag_Finish(e.draggedby);
					if(e.tag_entity)
						detach_sameorigin(e);
					Drag_Begin(this, e, trace_endpos);
					if(ischeat)
						DID_CHEAT();
					return true;
				}
			}
			break;
	}
	return false;
}

void Drag_Begin(entity dragger, entity draggee, vector touchpoint)
{
	float tagscale;

	draggee.dragmovetype = draggee.move_movetype;
	draggee.draggravity = draggee.gravity;
	set_movetype(draggee, MOVETYPE_WALK);
	draggee.gravity = 0.00001;
	UNSET_ONGROUND(draggee);
	draggee.draggedby = dragger;

	dragger.dragentity = draggee;

	dragger.dragdistance = vlen(touchpoint - dragger.origin - dragger.view_ofs);
	dragger.draglocalangle = draggee.angles.y - dragger.v_angle.y;
	touchpoint = touchpoint - gettaginfo(draggee, 0);
	tagscale = (vlen(v_forward) ** -2);
	dragger.draglocalvector_x = touchpoint * v_forward * tagscale;
	dragger.draglocalvector_y = touchpoint * v_right * tagscale;
	dragger.draglocalvector_z = touchpoint * v_up * tagscale;

	dragger.dragspeed = 64;
}

void Drag_Finish(entity dragger)
{
	entity draggee;
	draggee = dragger.dragentity;
	if(dragger)
		dragger.dragentity = NULL;
	draggee.draggedby = NULL;
	set_movetype(draggee, draggee.dragmovetype);
	draggee.gravity = draggee.draggravity;

	switch(draggee.move_movetype)
	{
		case MOVETYPE_TOSS:
		case MOVETYPE_WALK:
		case MOVETYPE_STEP:
		case MOVETYPE_FLYMISSILE:
		case MOVETYPE_BOUNCE:
		case MOVETYPE_BOUNCEMISSILE:
		case MOVETYPE_PHYSICS:
			break;
		default:
			draggee.velocity = '0 0 0';
			break;
	}

	if((draggee.flags & FL_ITEM) && (vdist(draggee.velocity, <, 32)))
	{
		draggee.velocity = '0 0 0';
		SET_ONGROUND(draggee); // floating items are FUN
	}
}

bool drag_undraggable(entity draggee, entity dragger)
{
	// stuff probably shouldn't need this, we should figure out why they do!
	// exceptions of course are observers and weapon entities, where things mess up
	return false;
}

float Drag_IsDraggable(entity draggee, entity dragger)
{
	// TODO add more checks for bad stuff here
	if(draggee == NULL)
		return false;
	if(draggee.classname == "door") // FIXME find out why these must be excluded, or work around the problem (trying to drag these causes like 4 fps)
		return false; // probably due to BSP collision
	//if(draggee.model == "")
	//	return false;

	return ((draggee.draggable) ? draggee.draggable(draggee, dragger) : true);
}

float Drag_MayChangeAngles(entity draggee)
{
	// TODO add more checks for bad stuff here
	if(substring(draggee.model, 0, 1) == "*")
		return false;
	return true;
}

void Drag_MoveForward(entity dragger)
{
	dragger.dragdistance += dragger.dragspeed;
}

void Drag_SetSpeed(entity dragger, float s)
{
	dragger.dragspeed = (2 ** s);
}

void Drag_MoveBackward(entity dragger)
{
	dragger.dragdistance = max(0, dragger.dragdistance - dragger.dragspeed);
}

void Drag_Update(entity dragger)
{
	vector curorigin, neworigin, goodvelocity;
	float f;
	entity draggee;

	draggee = dragger.dragentity;
	UNSET_ONGROUND(draggee);

	curorigin = gettaginfo(draggee, 0);
	curorigin = curorigin + v_forward * dragger.draglocalvector.x + v_right * dragger.draglocalvector.y + v_up * dragger.draglocalvector.z;
	makevectors(dragger.v_angle);
	neworigin = dragger.origin + dragger.view_ofs + v_forward * dragger.dragdistance;
	goodvelocity = (neworigin - curorigin) * (1 / frametime);

	while(draggee.angles.y - dragger.v_angle.y - dragger.draglocalangle > 180)
		dragger.draglocalangle += 360;
	while(draggee.angles.y - dragger.v_angle.y - dragger.draglocalangle <= -180)
		dragger.draglocalangle -= 360;

	f = min(frametime * 10, 1);
	draggee.velocity = draggee.velocity * (1 - f) + goodvelocity * f;

	if(Drag_MayChangeAngles(draggee))
		draggee.angles_y = draggee.angles.y * (1 - f) + (dragger.v_angle.y + dragger.draglocalangle) * f;

	draggee.ltime = max(servertime + serverframetime, draggee.ltime); // fixes func_train breakage

	vector vecs = '0 0 0';
	.entity weaponentity = weaponentities[0]; // TODO: unhardcode
	if(dragger.(weaponentity).movedir.x > 0)
		vecs = dragger.(weaponentity).movedir;

	vector dv = v_right * -vecs_y + v_up * vecs_z;

	te_lightning1(draggee, dragger.origin + dragger.view_ofs + dv, curorigin);
}

float Drag_CanDrag(entity dragger)
{
	return (!IS_DEAD(dragger)) || (IS_PLAYER(dragger));
}

float Drag_IsDragging(entity dragger)
{
	if(!dragger.dragentity)
		return false;
	if(wasfreed(dragger.dragentity) || dragger.dragentity.draggedby != dragger)
	{
		dragger.dragentity = NULL;
		return false;
	}
	if(!Drag_CanDrag(dragger) || !Drag_IsDraggable(dragger.dragentity, dragger))
	{
		Drag_Finish(dragger);
		return false;
	}
	return true;
}

void Drag_MoveDrag(entity from, entity to)
{
	if(from.draggedby)
	{
		to.draggedby = from.draggedby;
		to.draggedby.dragentity = to;
		from.draggedby = NULL;
	}
}

void DragBox_Think(entity this)
{
	if(this.aiment && this.enemy)
	{
		this.origin_x = (this.aiment.origin.x + this.enemy.origin.x) * 0.5;
		this.origin_y = (this.aiment.origin.y + this.enemy.origin.y) * 0.5;
		this.origin_z = (this.aiment.origin.z + this.enemy.origin.z) * 0.5;
		this.maxs_x = fabs(this.aiment.origin.x - this.enemy.origin.x) * 0.5;
		this.maxs_y = fabs(this.aiment.origin.y - this.enemy.origin.y) * 0.5;
		this.maxs_z = fabs(this.aiment.origin.z - this.enemy.origin.z) * 0.5;
		this.mins = -1 * this.maxs;
		setorigin(this, this.origin);
		setsize(this, this.mins, this.maxs); // link edict
	}

	if(this.cnt == -1) // actually race_place -1
	{
		// show "10 10" for qualifying spawns
		setmodel(this.killindicator, MDL_NUM(10));
		setmodel(this.killindicator.killindicator, MDL_NUM(10));
	}
	else if(this.cnt == -2) // actually race_place 0
	{
		// show "10 0" for loser spawns
		setmodel(this.killindicator, MDL_NUM(10));
		setmodel(this.killindicator.killindicator, MDL_NUM(0));
	}
	else
	{
		setmodel(this.killindicator, MDL_NUM(this.cnt % 10));
		setmodel(this.killindicator.killindicator, MDL_NUM(floor(this.cnt / 10)));
	}

	this.nextthink = time;
}

#endif
