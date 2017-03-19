#include "gamemode_singleplayer.qh"

const int SP_TEAM_PLAYER = NUM_TEAM_1;
const int SP_TEAM_ENEMY = NUM_TEAM_2;

.bool can_drop_weapon;
.string weapon_name;
.int sp_spawn_team;
.entity sp_spawn_spot;
.bool can_respawn;

int sp_bot_number;

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
void sp_spawn_team_entity(string teamname, int teamcolor)
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

    this.team = SP_TEAM_PLAYER;
    this.sp_spawn_team = SP_TEAM_PLAYER;
    spawnfunc_info_player_deathmatch(this);
}

void sp_spawn_bot(entity spawn_point)
{
    sp_bot_number++;
    entity bot = spawnclient();
    if (bot)
    {
        bot.sp_spawn_spot = spawn_point;
        bot_spawn_setup(bot);
    }
    else
    {
        LOG_WARN("Could not spawn bot");
    }
}

void sp_enemy_spawn_think(entity this)
{
    sp_spawn_bot(this);
    setthink(this, func_null);
}


void sp_enemy_spawn_use(entity this, entity actor, entity trigger)
{
    sp_spawn_bot(this);
}

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

void sp_remove_bot(entity bot)
{
    sp_bot_number--;
    bot.sp_spawn_spot = NULL;
    bot_clear(bot);
}

MUTATOR_HOOKFUNCTION(sp, CheckAllowedTeams, CBC_ORDER_EXCLUSIVE)
{
	M_ARGV(1, string) = "sp_team";
    entity ent = M_ARGV(2, entity);
    if ( IS_BOT_CLIENT(ent) )
    {
        ent.team_forced = NUM_TEAM_2;
    }
    else if( IS_REAL_CLIENT(ent) )
    {
        ent.team_forced = NUM_TEAM_1;
        c1 = 1;
        c2 = 0;
        c3 = 0;
        c4 = 0;
    }
    return true;
}

MUTATOR_HOOKFUNCTION(sp, Scores_CountFragsRemaining)
{
    return false;
}

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

MUTATOR_HOOKFUNCTION(sp, CheckRules_World)
{
    M_ARGV(0, float) = WINNING_NO;
    // TODO: conditions for WINNING_YES
    return true;
}

MUTATOR_HOOKFUNCTION(sp, Spawn_Score)
{
    entity player = M_ARGV(0, entity);
    entity spawn_spot = M_ARGV(1, entity);
    vector spawn_score = M_ARGV(2, vector);
    if ( IS_BOT_CLIENT(player) )
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

MUTATOR_HOOKFUNCTION(sp, HideTeamNagger)
{
    return true;
}

MUTATOR_HOOKFUNCTION(sp, Bot_FixCount)
{
    M_ARGV(2, int) = sp_bot_number;
    return true;
}

MUTATOR_HOOKFUNCTION(sp, PlayerDies)
{
    entity target = M_ARGV(2, entity);
    if ( IS_BOT_CLIENT(target) )
    {
        if ( target.sp_spawn_spot && !target.sp_spawn_spot.can_respawn )
        {
            sp_remove_bot(target);
        }
    }
}

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

MUTATOR_HOOKFUNCTION(sp, PlayerPreThink)
{
    entity player = M_ARGV(0, entity);
    if ( IS_BOT_CLIENT(player) && !player.sp_spawn_spot )
        bot_remove(player);
}
