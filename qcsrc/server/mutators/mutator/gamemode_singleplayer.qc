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

/*
 * Creates a new bot and assigns it to the given spawn point
 */
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
    M_ARGV(2, int) = sp_bot_number;
    return true;
}

// Remove bots that cannot respawn when they die
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
    if ( IS_BOT_CLIENT(player) && !player.sp_spawn_spot )
    {
        bot_remove(player);
    }
}

// Prevents bots from being able to pick up items
MUTATOR_HOOKFUNCTION(sp, ItemTouch)
{
    entity toucher = M_ARGV(1, entity);
    if ( IS_BOT_CLIENT(toucher) && !autocvar_g_sp_allow_bot_pickup )
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
