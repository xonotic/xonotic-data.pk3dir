#include "gamemode_singleplayer.qh"
#include "../../bot/default/bot.qh"

const int SP_TEAM_PLAYER = NUM_TEAM_1;
const int SP_TEAM_ENEMY = NUM_TEAM_2;

.bool can_drop_weapon;
.string weapon_name;
.int sp_spawn_team;
.entity sp_spawn_spot;
.bool can_respawn;

bool autocvar_g_sp_allow_bot_pickup;

int sp_bot_number;

// Team entity for single player mode
spawnfunc(sp_team)
{
    if(!g_singleplayer || !this.cnt) { delete(this); return; }

    this.classname = "sp_team";
    this.team = this.cnt + 1;
}

// Spawns the given team
void sp_spawn_team_entity(string teamname, int teamcolor)
{
    entity this = new_pure(sp_team);
    this.netname = teamname;
    this.cnt = teamcolor - 1;
    this.team = teamcolor;
    this.spawnfunc_checked = true;
}

// Spawn point for the player
spawnfunc(info_player_singleplayer)
{
    if (!g_singleplayer) { delete(this); return; }

    this.team = SP_TEAM_PLAYER;
    this.sp_spawn_team = SP_TEAM_PLAYER;
    spawnfunc_info_player_deathmatch(this);
}

.bool sp_hack;
/*
 * Creates a new bot and assigns it to the given spawn point
 */
void sp_spawn_bot(entity spawn_point)
{
    sp_bot_number++;
    entity bot = spawn();
    if (bot)
    {
        bot.sp_spawn_spot = spawn_point;
//         bot.flags |= FL_CLIENT;
        bot_spawn_setup(bot);
        //bot.origin = spawn_point.origin;
        bot.team = SP_TEAM_ENEMY;
        bot.sp_hack = true;
    }
    else
    {
        LOG_WARN("Could not spawn bot");
    }
}

/*
 * Think function for enemy spawn points,
 * creates a bot and stops all processing
 */
void sp_enemy_spawn_think(entity this)
{
    sp_spawn_bot(this);
    setthink(this, func_null);
}

/*
 * Use function for enemy spawn points,
 * creates bot
 */
void sp_enemy_spawn_use(entity this, entity actor, entity trigger)
{
    sp_spawn_bot(this);
}

// Enemy spawn point entity
spawnfunc(info_player_singleplayer_enemy)
{
	if (!g_singleplayer) { delete(this); return; }

	this.team = SP_TEAM_ENEMY;
    this.sp_spawn_team = SP_TEAM_ENEMY;
	spawnfunc_info_player_deathmatch(this);
    this.use = sp_enemy_spawn_use;
    if ( this.targetname == "" )
        setthink(this, sp_enemy_spawn_think);
}

// Game mode initialization function
void sp_delayed_init(entity this)
{
    // if no teams are found, spawn defaults
    if(find(NULL, classname, "sp_team") == NULL)
    {
        sp_spawn_team_entity("Player", SP_TEAM_PLAYER);
        sp_spawn_team_entity("Enemy", SP_TEAM_ENEMY);
    }

    sp_bot_number = 0;
}

// Ensures the given bot will be removed
void sp_remove_bot(entity bot)
{
    bot.netname = "killed";
    sp_bot_number--;
    bot.sp_spawn_spot = NULL;
    bot_clear(bot);
}

/*
 * Force teams:
 * bots are team 2,
 * players (including observers) are in team 1
 */
MUTATOR_HOOKFUNCTION(sp, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "sp_team";
    entity ent = M_ARGV(2, entity);
    if ( !IS_REAL_CLIENT(ent) )
    {
        ent.team_forced = NUM_TEAM_2;
    }
    else
    {
        ent.team_forced = NUM_TEAM_1;
        c1 = 1;
        c2 = 0;
        c3 = 0;
        c4 = 0;
    }
    return true;
}

// Avoid the frags left messages
MUTATOR_HOOKFUNCTION(sp, Scores_CountFragsRemaining)
{
    return false;
}

/*
 * Sets up players, more specifically assigns items, health and name to bots
 * based on their spawn point
 */
MUTATOR_HOOKFUNCTION(sp, PlayerSpawn)
{
    entity player = M_ARGV(0, entity);
    entity spawn_spot = M_ARGV(1, entity);
    if ( !IS_REAL_CLIENT(player) )
    {
        if ( player.sp_spawn_spot != spawn_spot )
        {
            player.netname = "derp";
            return;
        }

        player.can_drop_weapon = spawn_spot.can_drop_weapon;
        player.items |= IT_UNLIMITED_WEAPON_AMMO;
        if ( spawn_spot.health )
            player.health = spawn_spot.health;
        else
            player.health = 100;
        player.armorvalue = spawn_spot.armorvalue;
        player.weapons = WepSet_FromWeapon(Weapons_fromstr(spawn_spot.weapon_name));
        if ( spawn_spot.netname )
            player.netname = spawn_spot.netname;
    }
    else
    {
        player.can_drop_weapon = true;
    }
}

// Prevent bots from dropping weapons by default
MUTATOR_HOOKFUNCTION(sp, ForbidDropCurrentWeapon)
{
    entity player = M_ARGV(0, entity);
    return !player.can_drop_weapon;
}

// Winning rules (TODO)
MUTATOR_HOOKFUNCTION(sp, CheckRules_World)
{
    M_ARGV(0, float) = WINNING_NO;
    // TODO: conditions for WINNING_YES
    return true;
}

/*
 * Only allow players to spawn from specific points
 * For real clients forces the team spawn points even for observers
 * For bots that need to be spawned, forces them to spawn from their specifi point
 * for bots that need to be removes, allows all team spawn points to avoid crashes
 */
MUTATOR_HOOKFUNCTION(sp, Spawn_Score)
{
    entity player = M_ARGV(0, entity);
    entity spawn_spot = M_ARGV(1, entity);
    vector spawn_score = M_ARGV(2, vector);
    if ( !IS_REAL_CLIENT(player) )
    {
        if ( spawn_spot.sp_spawn_team != SP_TEAM_ENEMY ||
            (player.sp_spawn_spot && player.sp_spawn_spot != spawn_spot) )
            spawn_score.x = -1;
    }
    else if ( spawn_spot.sp_spawn_team != SP_TEAM_PLAYER )
    {
        spawn_score.x = -1;
    }

    M_ARGV(2, vector) = spawn_score;
}

// Avoid unbalanced teams notice as there will be far more enemies than players
MUTATOR_HOOKFUNCTION(sp, HideTeamNagger)
{
    return true;
}

/*
 * Forces the bot count to be determined based on the spawn points,
 * regardless of any other setting
 */
MUTATOR_HOOKFUNCTION(sp, Bot_FixCount)
{
    M_ARGV(2, int) = 0;
    return true;
}

// Remove bots that cannot respawn when they die
MUTATOR_HOOKFUNCTION(sp, PlayerDies)
{
    entity target = M_ARGV(2, entity);
    if ( !IS_REAL_CLIENT(target) )
    {
        if ( target.sp_spawn_spot && !target.sp_spawn_spot.can_respawn )
        {
            sp_remove_bot(target);
        }
    }
}

// Ensures the bots that get removed are the ones that cannot respawn
MUTATOR_HOOKFUNCTION(sp, Bot_SelectRemove)
{
    FOREACH_CLIENT(it.isbot,
    {
        if ( !it.sp_spawn_spot )
        {
            M_ARGV(0, entity) = it;
            return;
        }
    });
}

// Actually removes the bot entity when needed
MUTATOR_HOOKFUNCTION(sp, PlayerPreThink)
{
    entity player = M_ARGV(0, entity);
    if ( !IS_REAL_CLIENT(player) && !player.sp_spawn_spot )
    {
        bot_remove(player);
    }
}

// Prevents bots from being able to pick up items
MUTATOR_HOOKFUNCTION(sp, ItemTouch)
{
    entity toucher = M_ARGV(1, entity);
    if ( !IS_REAL_CLIENT(toucher) && !autocvar_g_sp_allow_bot_pickup )
        return MUT_ITEMTOUCH_RETURN;
    return MUT_ITEMTOUCH_CONTINUE;
}

// Prevents bots from being willing to pick up items
MUTATOR_HOOKFUNCTION(sp, Item_Spawn)
{
    entity item = M_ARGV(0, entity);
    if ( !autocvar_g_sp_allow_bot_pickup )
    {
        item.bot_pickup = false;
    }
    return false;
}

void PlayerPreThinkHack (entity this)
{
	WarpZone_PlayerPhysics_FixVAngle(this);

    STAT(GAMESTARTTIME, this) = game_starttime;
	STAT(ROUNDSTARTTIME, this) = round_starttime;
	STAT(ALLOW_OLDVORTEXBEAM, this) = autocvar_g_allow_oldvortexbeam;
	STAT(LEADLIMIT, this) = autocvar_leadlimit;

	STAT(WEAPONSINMAP, this) = weaponsInMap;

	if (frametime) {
		// physics frames: update anticheat stuff
		anticheat_prethink(this);
	}

	if (blockSpectators && frametime) {
		// WORKAROUND: only use dropclient in server frames (frametime set).
		// Never use it in cl_movement frames (frametime zero).
		checkSpectatorBlock(this);
    }

	zoomstate_set = false;

	// Check for nameless players
	/*if (isInvisibleString(this.netname)) {
		this.netname = strzone(sprintf("Player#%d", this.playerid));
		// stuffcmd(this, strcat("name ", this.netname, "\n")); // maybe?
	}
	if (this.netname != this.netname_previous) {
		if (autocvar_sv_eventlog) {
			GameLogEcho(strcat(":name:", ftos(this.playerid), ":", playername(this, false)));
        }
		if (this.netname_previous) strunzone(this.netname_previous);
		this.netname_previous = strzone(this.netname);
	}*/

	// version nagging
	/*if (this.version_nagtime && this.cvar_g_xonoticversion && time > this.version_nagtime) {
        this.version_nagtime = 0;
        if (strstrofs(this.cvar_g_xonoticversion, "git", 0) >= 0 || strstrofs(this.cvar_g_xonoticversion, "autobuild", 0) >= 0) {
            // git client
        } else if (strstrofs(autocvar_g_xonoticversion, "git", 0) >= 0 || strstrofs(autocvar_g_xonoticversion, "autobuild", 0) >= 0) {
            // git server
            Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_BETA, autocvar_g_xonoticversion, this.cvar_g_xonoticversion);
        } else {
            int r = vercmp(this.cvar_g_xonoticversion, autocvar_g_xonoticversion);
            if (r < 0) { // old client
                Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_OUTDATED, autocvar_g_xonoticversion, this.cvar_g_xonoticversion);
            } else if (r > 0) { // old server
                Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_VERSION_OLD, autocvar_g_xonoticversion, this.cvar_g_xonoticversion);
            }
        }
    }*/

	// GOD MODE info
	if (!(this.flags & FL_GODMODE) && this.max_armorvalue)
	{
		Send_Notification(NOTIF_ONE_ONLY, this, MSG_INFO, INFO_GODMODE_OFF, this.max_armorvalue);
		this.max_armorvalue = 0;
	}

	if (STAT(FROZEN, this) == 2)
	{
		this.revive_progress = bound(0, this.revive_progress + frametime * this.revive_speed, 1);
		this.health = max(1, this.revive_progress * start_health);
		this.iceblock.alpha = bound(0.2, 1 - this.revive_progress, 1);

		if (this.revive_progress >= 1)
			Unfreeze(this);
	}
	else if (STAT(FROZEN, this) == 3)
	{
		this.revive_progress = bound(0, this.revive_progress - frametime * this.revive_speed, 1);
		this.health = max(0, autocvar_g_nades_ice_health + (start_health-autocvar_g_nades_ice_health) * this.revive_progress );

		if (this.health < 1)
		{
			if (this.vehicle)
				vehicles_exit(this.vehicle, VHEF_RELEASE);
			if(this.event_damage)
				this.event_damage(this, this, this.frozen_by, 1, DEATH_NADE_ICE_FREEZE.m_id, this.origin, '0 0 0');
		}
		else if (this.revive_progress <= 0)
			Unfreeze(this);
	}

	MUTATOR_CALLHOOK(PlayerPreThink, this);

	/*if(autocvar_g_vehicles_enter && (time > this.last_vehiclecheck) && !game_stopped && !this.vehicle)
	if(IS_PLAYER(this) && !STAT(FROZEN, this) && !IS_DEAD(this))
	{
		FOREACH_ENTITY_RADIUS(this.origin, autocvar_g_vehicles_enter_radius, IS_VEHICLE(it),
		{
			if(!IS_DEAD(it) && it.takedamage != DAMAGE_NO)
			if((it.vehicle_flags & VHF_MULTISLOT) && SAME_TEAM(it.owner, this))
			{
				Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER_GUNNER);
			}
			else if(!it.owner)
			{
				if(!it.team || SAME_TEAM(this, it))
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER);
				else if(autocvar_g_vehicles_steal)
					Send_Notification(NOTIF_ONE, this, MSG_CENTER, CENTER_VEHICLE_ENTER_STEAL);
			}
		});

		this.last_vehiclecheck = time + 1;
	}*/

	if(!this.cvar_cl_newusekeysupported) // FIXME remove this - it was a stupid idea to begin with, we can JUST use the button
	{
		if(PHYS_INPUT_BUTTON_USE(this) && !this.usekeypressed)
			PlayerUseKey(this);
		this.usekeypressed = PHYS_INPUT_BUTTON_USE(this);
	}

	/*if (IS_REAL_CLIENT(this))
		PrintWelcomeMessage(this);*/

	if (IS_PLAYER(this)) {
		CheckRules_Player(this);

		if (game_stopped || intermission_running) {
			this.modelflags &= ~MF_ROCKET;
			if(intermission_running)
				IntermissionThink(this);
			return;
		}

		if (timeout_status == TIMEOUT_ACTIVE) {
            // don't allow the player to turn around while game is paused
			// FIXME turn this into CSQC stuff
			this.v_angle = this.lastV_angle;
			this.angles = this.lastV_angle;
			this.fixangle = true;
		}

		if (frametime) player_powerups(this);

		if (IS_DEAD(this)) {
			if (this.personal && g_race_qualifying) {
				if (time > this.respawn_time) {
					STAT(RESPAWN_TIME, this) = this.respawn_time = time + 1; // only retry once a second
					respawn(this);
					this.impulse = CHIMPULSE_SPEEDRUN.impulse;
				}
			} else {
				if (frametime) player_anim(this);
				bool button_pressed = (PHYS_INPUT_BUTTON_ATCK(this) || PHYS_INPUT_BUTTON_JUMP(this) || PHYS_INPUT_BUTTON_ATCK2(this) || PHYS_INPUT_BUTTON_HOOK(this) || PHYS_INPUT_BUTTON_USE(this));

				switch(this.deadflag)
				{
					case DEAD_DYING:
					{
						if ((this.respawn_flags & RESPAWN_FORCE) && !(this.respawn_time < this.respawn_time_max))
							this.deadflag = DEAD_RESPAWNING;
						else if (!button_pressed || (time >= this.respawn_time_max && (this.respawn_flags & RESPAWN_FORCE)))
							this.deadflag = DEAD_DEAD;
						break;
					}
					case DEAD_DEAD:
					{
						if (button_pressed)
							this.deadflag = DEAD_RESPAWNABLE;
						else if (time >= this.respawn_time_max && (this.respawn_flags & RESPAWN_FORCE))
							this.deadflag = DEAD_RESPAWNING;
						break;
					}
					case DEAD_RESPAWNABLE:
					{
						if (!button_pressed || (this.respawn_flags & RESPAWN_FORCE))
							this.deadflag = DEAD_RESPAWNING;
						break;
					}
					case DEAD_RESPAWNING:
					{
						if (time > this.respawn_time)
						{
							this.respawn_time = time + 1; // only retry once a second
							this.respawn_time_max = this.respawn_time;
							respawn(this);
						}
						break;
					}
				}

				ShowRespawnCountdown(this);

				if (this.respawn_flags & RESPAWN_SILENT)
					STAT(RESPAWN_TIME, this) = 0;
				else if ((this.respawn_flags & RESPAWN_FORCE) && this.respawn_time < this.respawn_time_max)
				{
					if (time < this.respawn_time)
						STAT(RESPAWN_TIME, this) = this.respawn_time;
					else if (this.deadflag != DEAD_RESPAWNING)
						STAT(RESPAWN_TIME, this) = -this.respawn_time_max;
				}
				else
					STAT(RESPAWN_TIME, this) = this.respawn_time;
			}

			// if respawning, invert stat_respawn_time to indicate this, the client translates it
			if (this.deadflag == DEAD_RESPAWNING && STAT(RESPAWN_TIME, this) > 0)
				STAT(RESPAWN_TIME, this) *= -1;

			return;
		}

		this.prevorigin = this.origin;

		bool have_hook = false;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if(this.(weaponentity).hook.state)
			{
				have_hook = true;
				break;
			}
		}
		bool do_crouch = PHYS_INPUT_BUTTON_CROUCH(this);
		if (have_hook) {
			do_crouch = false;
		} else if (this.waterlevel >= WATERLEVEL_SWIMMING) {
			do_crouch = false;
		} else if (this.vehicle) {
			do_crouch = false;
		} else if (STAT(FROZEN, this)) {
			do_crouch = false;
        }

		if (do_crouch) {
			if (!this.crouch) {
				this.crouch = true;
				this.view_ofs = STAT(PL_CROUCH_VIEW_OFS, this);
				setsize(this, STAT(PL_CROUCH_MIN, this), STAT(PL_CROUCH_MAX, this));
				// setanim(this, this.anim_duck, false, true, true); // this anim is BROKEN anyway
			}
		} else if (this.crouch) {
            tracebox(this.origin, STAT(PL_MIN, this), STAT(PL_MAX, this), this.origin, false, this);
            if (!trace_startsolid) {
                this.crouch = false;
                this.view_ofs = STAT(PL_VIEW_OFS, this);
                setsize(this, STAT(PL_MIN, this), STAT(PL_MAX, this));
            }
		}

		FixPlayermodel(this);

		// LordHavoc: allow firing on move frames (sub-ticrate), this gives better timing on slow servers
		//if(frametime)
		{
			this.items &= ~this.items_added;

			for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
			{
				.entity weaponentity = weaponentities[slot];
				W_WeaponFrame(this, weaponentity);

				if(slot == 0)
				{
					this.clip_load = this.(weaponentity).clip_load;
					this.clip_size = this.(weaponentity).clip_size;
				}
			}

			this.items_added = 0;
			if (this.items & ITEM_Jetpack.m_itemid && (this.items & ITEM_JetpackRegen.m_itemid || this.ammo_fuel >= 0.01))
                this.items_added |= IT_FUEL;

			this.items |= this.items_added;
		}

		player_regen(this);

		// WEAPONTODO: Add a weapon request for this
		// rot vortex charge to the charge limit
		/*for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			if (WEP_CVAR(vortex, charge_rot_rate) && this.(weaponentity).vortex_charge > WEP_CVAR(vortex, charge_limit) && this.(weaponentity).vortex_charge_rottime < time)
				this.(weaponentity).vortex_charge = bound(WEP_CVAR(vortex, charge_limit), this.(weaponentity).vortex_charge - WEP_CVAR(vortex, charge_rot_rate) * frametime / W_TICSPERFRAME, 1);
		}*/

		if (frametime) player_anim(this);

		// secret status
		//secrets_setstatus(this);

		// monsters status
		//monsters_setstatus(this);

		this.dmg_team = max(0, this.dmg_team - autocvar_g_teamdamage_resetspeed * frametime);
	}
	else if (game_stopped || intermission_running) {
		if(intermission_running)
			IntermissionThink(this);
		return;
	}
	/*else if (IS_OBSERVER(this)) {
		ObserverThink(this);
	}
	else if (IS_SPEC(this)) {
		SpectatorThink(this);
	}*/

	// WEAPONTODO: Add weapon request for this
	/*if (!zoomstate_set) {
		bool wep_zoomed = false;
		for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
		{
			.entity weaponentity = weaponentities[slot];
			Weapon thiswep = this.(weaponentity).m_weapon;
			if(thiswep != WEP_Null && thiswep.wr_zoom)
				wep_zoomed += thiswep.wr_zoom(thiswep, this);
		}
		SetZoomState(this, PHYS_INPUT_BUTTON_ZOOM(this) || PHYS_INPUT_BUTTON_ZOOMSCRIPT(this) || wep_zoomed);
    }*/

	/*if (this.teamkill_soundtime && time > this.teamkill_soundtime)
	{
		this.teamkill_soundtime = 0;

		entity e = this.teamkill_soundsource;
		entity oldpusher = e.pusher;
		e.pusher = this;
		PlayerSound(e, playersound_teamshoot, CH_VOICE, VOL_BASEVOICE, VOICETYPE_LASTATTACKER_ONLY);
		e.pusher = oldpusher;
	}

	if (this.taunt_soundtime && time > this.taunt_soundtime) {
		this.taunt_soundtime = 0;
		PlayerSound(this, playersound_taunt, CH_VOICE, VOL_BASEVOICE, VOICETYPE_AUTOTAUNT);
	}

	target_voicescript_next(this);

	// WEAPONTODO: Move into weaponsystem somehow
	// if a player goes unarmed after holding a loaded weapon, empty his clip size and remove the crosshair ammo ring
	for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
	{
		.entity weaponentity = weaponentities[slot];
		if(this.(weaponentity).m_weapon == WEP_Null)
			this.(weaponentity).clip_load = this.(weaponentity).clip_size = 0;
	}*/
}


MUTATOR_HOOKFUNCTION(sp, SV_StartFrame)
{
    entity e = NULL;
    while( (e = findfloat(e, sp_hack, true)) )
    {
//         PlayerPreThink(e);
		PlayerPreThinkHack(e);

    }
}
