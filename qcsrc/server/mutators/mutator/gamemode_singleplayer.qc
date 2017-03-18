#include "gamemode_singleplayer.qh"

/*QUAKED spawnfunc_tdm_team (0 .5 .8) (-16 -16 -24) (16 16 32)
Team declaration for TDM gameplay, this allows you to decide what team names and control point models are used in your map.
Note: If you use spawnfunc_tdm_team entities you must define at least 2!  However, unlike domination, you don't need to make a blank one too.
Keys:
"netname" Name of the team (for example Red, Blue, Green, Yellow, Life, Death, Offense, Defense, etc)...
"cnt" Scoreboard color of the team (for example 4 is red and 13 is blue)... */
spawnfunc(sp_team)
{
    if(!g_singleplayer || !this.cnt) { delete(this); return; }

    this.classname = "sp_team";
    this.team = this.cnt + 1;
}

// code from here on is just to support maps that don't have team entities
void sp_SpawnTeam (string teamname, int teamcolor)
{
    entity this = new_pure(sp_team);
    this.netname = teamname;
    this.cnt = teamcolor - 1;
    this.team = teamcolor;
    this.spawnfunc_checked = true;
    //spawnfunc_sp_team(this);
}


// spawnfuncs
spawnfunc(info_player_singleplayer)
{
    if (!g_singleplayer) { delete(this); return; }

    this.team = NUM_TEAM_1;
    spawnfunc_info_player_deathmatch(this);
}

spawnfunc(info_player_singleplayer_enemy)
{
	if (!g_singleplayer) { delete(this); return; }

	this.team = NUM_TEAM_2;
	spawnfunc_info_player_deathmatch(this);
}

void sp_DelayedInit(entity this)
{
    // if no teams are found, spawn defaults
    if(find(NULL, classname, "sp_team") == NULL)
    {
        LOG_TRACE("No \"sp_team\" entities found on this map, creating them anyway.");

        sp_SpawnTeam("Player", NUM_TEAM_1);
        sp_SpawnTeam("Enemy", NUM_TEAM_2);
    }
}

MUTATOR_HOOKFUNCTION(sp, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
    LOG_TRACEF("\n==== here ====\n");
	M_ARGV(1, string) = "sp_team";
    entity ent = M_ARGV(2, entity);
    if ( IS_BOT_CLIENT(ent) )
    {
        ent.team_forced = NUM_TEAM_2;
    }
    else if( IS_PLAYER(ent) )
    {
        ent.team_forced = NUM_TEAM_1;
    }
    LOG_TRACEF("\n==== After processing ====\nent: %s\nteam: %d\n\n",
               etos(ent), ent.team_forced);
    return true;
}

MUTATOR_HOOKFUNCTION(sp, Scores_CountFragsRemaining)
{
    return false;
}


.bool can_drop_weapon;
.string weapon_name;

MUTATOR_HOOKFUNCTION(sp, PlayerSpawn)
{
	entity player = M_ARGV(0, entity);
	entity spawn_spot = M_ARGV(1, entity);
    if ( IS_BOT_CLIENT(player) )
    {
        player.can_drop_weapon = spawn_spot.can_drop_weapon;
        player.items |= IT_UNLIMITED_WEAPON_AMMO;
        if ( spawn_spot.health )
            player.health = spawn_spot.health;
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

MUTATOR_HOOKFUNCTION(sp, ForbidDropCurrentWeapon)
{
    entity player = M_ARGV(0, entity);
    return !player.can_drop_weapon;
}
