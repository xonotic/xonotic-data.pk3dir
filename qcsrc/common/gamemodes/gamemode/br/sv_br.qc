// battle royale
// author: Juhu

#include "sv_br.qh"
#include <server/elimination.qh>
#include <server/resources.qh>
#include <common/mutators/base.qh>

#define BR_KILLS_INSTANTLY(pl, dt) (!IN_SQUAD((pl)) || (br_SquadFindLastAlive((pl).br_squad, true) == (pl)) || ((dt) == DEATH_HURTTRIGGER.m_id) || ((dt) == DEATH_KILL.m_id) || ((dt) == DEATH_TEAMCHANGE.m_id) || ((dt) == DEATH_AUTOTEAMCHANGE.m_id))

float br_CalculatePlayerDropAngle(entity this);
void br_LastPlayerForSquad_Notify(entity squad);
void br_RemovePlayer(entity player);
void br_Revive(entity player);
int br_WinningCondition();

entity ring;
entity dropship;

bool squads_colored = false;

.bool br_ring_warned;
.float br_force_drop_distance;

.entity br_bleeding_inflictor;
.entity br_bleeding_attacker;
.int br_bleeding_deathtype;
..entity br_bleeding_weaponentity;

// weapon set restoring for revive/drop
.WepSet br_wepset_old;
.Weapon br_weapon_prev[MAX_WEAPONSLOTS];
.float br_lastweapon_prev[MAX_WEAPONSLOTS];

float autocvar_g_br_revive_health = 0.25;
float autocvar_g_br_bleeding_health = 0.5;
float autocvar_g_br_drop_damage = 0.5;
float autocvar_g_br_drop_speed_max = 2;
float autocvar_g_br_drop_speed_vertical_min = 0.1;
bool autocvar_g_br_squad_colors = true;
float autocvar_g_br_drop_accel_dive = 600;
float autocvar_g_br_drop_accel_turn = 1500;
bool autocvar_g_br_startweapons = false;
bool autocvar_g_br_ring_exitvehicle = false;

.vector br_drop_velocity;
.vector br_drop_angles;

MUTATOR_HOOKFUNCTION(br, reset_map_global)
{
    dropship_path_length = 0; // this should kill the dropship
    dropship_path_direction = '0 0 0';

    delete(ring);
    ring = dropship = NULL;
}

MUTATOR_HOOKFUNCTION(br, reset_map_players)
{
    FOREACH_CLIENT(true, {
        GameRules_scoring_add(it, BR_RANK, -GameRules_scoring_add(it, BR_RANK, 0));
        GameRules_scoring_add(it, BR_SQUAD, -GameRules_scoring_add(it, BR_SQUAD, 0));
        GameRules_scoring_add(it, BR_REVIVALS, -GameRules_scoring_add(it, BR_REVIVALS, 0));

        br_RemovePlayer(it);

        it.br_wepset_old = '0 0 0';
        for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
        {
            it.br_weapon_prev[slot] = WEP_Null;
            it.br_lastweapon_prev[slot] = 0;
        }
    });

    br_SquadUpdateInfo();
}

MUTATOR_HOOKFUNCTION(br, CheckRules_World)
{
    M_ARGV(0, float) = br_WinningCondition();
    return true;
}

MUTATOR_HOOKFUNCTION(br, ForbidPlayerScore_Clear)
{
    // don't clear player score
    return true;
}

MUTATOR_HOOKFUNCTION(br, GetPlayerStatus)
{
    entity player = M_ARGV(0, entity);
    return IN_SQUAD(player);
}

MUTATOR_HOOKFUNCTION(br, ClientConnect)
{
    entity player = M_ARGV(0, entity);

    STAT(SQUADCOLORS, player) = squads_colored;

    if(ring)
        ring_timelimit(ring);

    br_SquadUpdateInfo();
}

MUTATOR_HOOKFUNCTION(br, ClientDisconnect)
{
    entity player = M_ARGV(0, entity);

    br_RemovePlayer(player);
    br_SquadUpdateInfo();
}

MUTATOR_HOOKFUNCTION(br, PutClientInServer)
{
    entity player = M_ARGV(0, entity);

    if (!(round_handler_IsActive() && round_handler_IsRoundStarted()))
        return false;

    if (IN_SQUAD(player))
        Send_Notification(NOTIF_ONE_ONLY, player, MSG_CENTER, CENTER_BR_JOIN_DEAD);
    else
        Send_Notification(NOTIF_ONE_ONLY, player, MSG_CENTER, CENTER_BR_JOIN_LATE);

    TRANSMUTE(Observer, player);
}

MUTATOR_HOOKFUNCTION(br, MakePlayerObserver)
{
    entity player = M_ARGV(0, entity);

    if(IN_SQUAD(player))
    {
        player.frags = FRAGS_PLAYER_OUT_OF_GAME;
        return true;
    }

    return false;
}

MUTATOR_HOOKFUNCTION(br, SpectateSet)
{
    entity client = M_ARGV(0, entity);
    entity target = M_ARGV(1, entity);

    return (IN_SQUAD(client) && !client.br_squad.br_squad_dead && DIFF_SQUAD(client, target));
}

MUTATOR_HOOKFUNCTION(br, SpectateNext)
{
    entity client = M_ARGV(0, entity);

    if(!IS_REAL_CLIENT(client) || !IN_SQUAD(client) || client.br_squad.br_squad_dead)
        return false;

    entity new_target;

    if(client.enemy && client.enemy.br_squad_next)
        new_target = client.enemy.br_squad_next;
    else
        new_target = client.br_squad.br_squad_first;

    while((new_target == client) || IS_DEAD(new_target) || IS_SPEC(new_target) || IS_OBSERVER(new_target))
    {
        new_target = new_target.br_squad_next;
        if(!new_target)
            new_target = client.br_squad.br_squad_first;
    }
    M_ARGV(1, entity) = new_target;

    return true;
}

MUTATOR_HOOKFUNCTION(br, SpectatePrev)
{
    entity client = M_ARGV(0, entity);

    if(!IS_REAL_CLIENT(client) || !IN_SQUAD(client) || client.br_squad.br_squad_dead)
        return MUT_SPECPREV_CONTINUE;

    entity new_target;

    if(client.enemy && client.enemy.br_squad_prev)
        new_target = client.enemy.br_squad_prev;
    else
        new_target = client.br_squad.br_squad_last;

    while((new_target == client) || IS_DEAD(new_target) || IS_SPEC(new_target) || IS_OBSERVER(new_target))
    {
        new_target = new_target.br_squad_prev;
        if(!new_target)
            new_target = client.br_squad.br_squad_last;
    }
    M_ARGV(1, entity) = new_target;

    return MUT_SPECPREV_FOUND;
}

MUTATOR_HOOKFUNCTION(br, ForbidSpawn)
{
    return (round_handler_IsActive() && round_handler_IsRoundStarted());
}

MUTATOR_HOOKFUNCTION(br, SetStartItems)
{
    start_items &= ~(IT_UNLIMITED_AMMO | IT_UNLIMITED_SUPERWEAPONS);

    start_health       = warmup_start_health       = cvar("g_br_start_health");
    start_armorvalue   = warmup_start_armorvalue   = cvar("g_br_start_armor");
    start_ammo_shells  = warmup_start_ammo_shells  = cvar("g_br_start_ammo_shells");
    start_ammo_nails   = warmup_start_ammo_nails   = cvar("g_br_start_ammo_nails");
    start_ammo_rockets = warmup_start_ammo_rockets = cvar("g_br_start_ammo_rockets");
    start_ammo_cells   = warmup_start_ammo_cells   = cvar("g_br_start_ammo_cells");
    start_ammo_plasma  = warmup_start_ammo_plasma  = cvar("g_br_start_ammo_plasma");
    start_ammo_fuel    = warmup_start_ammo_fuel    = cvar("g_br_start_ammo_fuel");
}

// adjusted freezetag reviving code
#ifdef IN_REVIVING_RANGE
    #undef IN_REVIVING_RANGE
#endif

#define IN_REVIVING_RANGE(player, it, revive_extra_size) \
    (it != player && !IS_DEAD(it) && !IS_SPEC(it) && !IS_OBSERVER(it) && SAME_SQUAD(it, player) \
    && boxesoverlap(player.absmin - revive_extra_size, player.absmax + revive_extra_size, it.absmin, it.absmax))

MUTATOR_HOOKFUNCTION(br, PlayerPreThink, CBC_ORDER_FIRST)
{
    entity player = M_ARGV(0, entity);

    if (game_stopped || !frametime || !IS_PLAYER(player))
        return true;

    if(ring)
    {
        if(vlen((player.origin + player.view_ofs) - ring.origin) > ring_calculate_current_radius(ring))
        {
            if(!player.br_ring_warned)
            {
                player.br_ring_warned = true;
                Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_BR_RING_WARN);
            }

            if(player.vehicle && autocvar_g_br_ring_exitvehicle) // if the player is controlling a vehicle
                vehicles_exit(player.vehicle, VHEF_RELEASE); // begone!

            Damage(player, ring, ring, ring.strength * frametime, DEATH_RING.m_id, DMG_NOWEP, player.origin, '0 0 0'); // ring damage
        }
        else
        {
            player.br_ring_warned = false;
        }
    }

    if(STAT(DROP, player) == DROP_TRANSPORT){
        if(!(STAT(PRESSED_KEYS, player) & KEY_JUMP) && (dropship_path_length > player.br_squad.br_force_drop_distance)){
            player.velocity = dropship_path_direction * max(autocvar_g_br_dropship_speed, 0);
        }
        else{
            if(!(IN_SQUAD(player) && player.br_squad.br_squad_drop_leader))
            {
                const float inital_dropangle = 60; // 0 = straight down
                player.effects &= ~EF_NODRAW;
                set_movetype(player, MOVETYPE_WALK);
                Kill_Notification(NOTIF_ONE_ONLY, player, MSG_CENTER, CPID_BR_DROPSHIP);
                STAT(DROP, player) = DROP_FALLING;
                float maxdropspeed = PHYS_MAXAIRSPEED(player) * max(autocvar_g_br_drop_speed_max, 0); // no maxspeed_mod available here
                player.br_drop_velocity.x = cos(player.angles.y * DEG2RAD);
                player.br_drop_velocity.y = sin(player.angles.y * DEG2RAD);
                player.br_drop_velocity.z = tan((inital_dropangle - 90) * DEG2RAD);

                player.br_drop_velocity = normalize(player.br_drop_velocity) * maxdropspeed;

                player.br_drop_angles.x = br_CalculatePlayerDropAngle(player) - 90;
                player.br_drop_angles.y = vectoangles(vec2(player.br_drop_velocity)).y + 180;
                player.br_drop_angles.z = 180;

                // the .br_drop values aren't modified by physics and will be used by other squad members
                player.velocity = player.br_drop_velocity;
                player.angles = player.br_drop_angles;

                if(IN_SQUAD(player))
                {
                    player.br_squad.br_squad_drop_leader = player;

                    vector drop_offset;
                    drop_offset.x = cos((player.angles.y + 90) * DEG2RAD);
                    drop_offset.y = sin((player.angles.y + 90) * DEG2RAD);
                    drop_offset.z = 0;
                    drop_offset = drop_offset * vlen(vec2(player.maxs - player.mins)) + drop_offset * 32; // I hope individual players never get different mins/maxs

                    FOREACH_CLIENT(IS_PLAYER(it) && (it != player) && SAME_SQUAD(it, player) && (STAT(DROP, it) == DROP_TRANSPORT), {
                        it.effects &= ~EF_NODRAW;
                        set_movetype(it, MOVETYPE_WALK);
                        Kill_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, CPID_BR_DROPSHIP);
                        STAT(DROP, it) = DROP_FALLING;

                        setorigin(it, player.origin + drop_offset); // FIXME: this can teleport players into brushes/void
                        drop_offset *= 2;

                        it.velocity = it.br_drop_velocity = player.velocity;
                        it.angles = it.br_drop_angles = player.angles;
                    });
                }
            }
        }
    }

    // adjusted freezetag reviving code
    entity revivers_last = NULL;
    entity revivers_first = NULL;

    bool player_is_reviving = false;
    bool player_is_being_revived = false;
    vector revive_extra_size = '1 1 1' * max(autocvar_g_br_revive_extra_size, 0);
    FOREACH_CLIENT(IS_PLAYER(it), {
        // check if player is reviving anyone
        if (STAT(BLEEDING, it))
        {
            if (STAT(BLEEDING, player))
                continue;
            if (!IN_REVIVING_RANGE(player, it, revive_extra_size))
                continue;
            player_is_reviving = true;
            break;
        }

        if (!STAT(BLEEDING, player))
            continue; // both player and it are NOT bleeding
        if (!IN_REVIVING_RANGE(player, it, revive_extra_size))
            continue;

        // found a squadmate that is reviving player
        if (revivers_last)
            revivers_last.chain = it;
        revivers_last = it;
        if (!revivers_first)
            revivers_first = it;
        player_is_being_revived = true;
    });
    if (revivers_last)
        revivers_last.chain = NULL;

    if (!player_is_being_revived) // no squadmate nearby
    {
        float clearspeed = max(autocvar_g_br_revive_clearspeed, 0);
        if (STAT(BLEEDING, player))
            STAT(REVIVE_PROGRESS, player) = bound(0, STAT(REVIVE_PROGRESS, player) - frametime * clearspeed, 1);
        else if (!player_is_reviving)
            STAT(REVIVE_PROGRESS, player) = 0; // reviving nobody
    }
    else // OK, there is at least one squadmate reviving us
    {
        float spd = max(autocvar_g_br_revive_speed, 0);
        STAT(REVIVE_PROGRESS, player) = bound(0, STAT(REVIVE_PROGRESS, player) + frametime * spd, 1);

        if(STAT(REVIVE_PROGRESS, player) >= 1)
        {
            br_Revive(player);

            // EVERY squad mate nearby gets a point (even if multiple!)
            for(entity it = revivers_first; it; it = it.chain)
            {
                GameRules_scoring_add(it, BR_REVIVALS, +1);
            }

            Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_BR_REVIVED, revivers_first.netname);
            Send_Notification(NOTIF_ONE, revivers_first, MSG_CENTER, CENTER_BR_REVIVE, player.netname);
            Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_BR_REVIVED, player.netname, revivers_first.netname);
            if(autocvar_sv_eventlog)
            {
                string revivers = "";
                for(entity it = revivers_first; it; it = it.chain)
                    revivers = strcat(revivers, ftos(it.playerid), ",");
                revivers = substring(revivers, 0, strlen(revivers) - 1);
                GameLogEcho(strcat(":br:revival:", ftos(player.playerid), ":", revivers));
            }
        }

        for(entity it = revivers_first; it; it = it.chain)
            STAT(REVIVE_PROGRESS, it) = STAT(REVIVE_PROGRESS, player);
    }

    if (STAT(BLEEDING, player))
    {
        entity player_wp = player.waypointsprite_attached;
        if (player_is_being_revived)
        {
            WaypointSprite_UpdateSprites(player_wp, WP_BRReviving, WP_Null, WP_Null);
            WaypointSprite_UpdateTeamRadar(player_wp, RADARICON_WAYPOINT, WP_BR_REVIVING_COLOR);
        }
        else
        {
            WaypointSprite_UpdateSprites(player_wp, WP_BRBleeding, WP_Null, WP_Null);
            WaypointSprite_UpdateTeamRadar(player_wp, RADARICON_WAYPOINT, WP_BR_BLEEDING_COLOR);
        }

        WaypointSprite_UpdateMaxHealth(player_wp, 1);
        WaypointSprite_UpdateHealth(player_wp, STAT(REVIVE_PROGRESS, player));
    }

    return true;
}

#undef IN_REVIVING_RANGE

MUTATOR_HOOKFUNCTION(br, PM_Physics)
{
    entity player = M_ARGV(0, entity);
    float maxspeed_mod = M_ARGV(1, float);
    float dt = M_ARGV(2, float); // tick rate

    if(STAT(DROP, player) == DROP_TRANSPORT)
        return true;

    // set the drop stat to landed on the next frame if it was set on landing
    if(STAT(DROP, player) == DROP_LANDING)
        STAT(DROP, player) = DROP_LANDED;

    // TODO: improve dropping physics
    if(STAT(DROP, player) == DROP_FALLING){
        if(!IS_ONGROUND(player) && ((tracebox(player.origin, player.mins, player.maxs, player.origin - '0 0 1', MOVE_NOMONSTERS, player), trace_fraction) >= 1)) // IS_ONGROUND doesn't work if jump is held (jump is theoretically blocked until landed)
        {
            ITEMS_STAT(player) |= IT_USING_JETPACK;
            bool has_drop_leader = IN_SQUAD(player) && (player.br_squad.br_squad_drop_leader && (STAT(DROP, player.br_squad.br_squad_drop_leader) == DROP_FALLING));
            bool player_is_drop_leader = has_drop_leader && (player == player.br_squad.br_squad_drop_leader);
            if(player_is_drop_leader || !has_drop_leader)
            {
                float maxairspeed = PHYS_MAXAIRSPEED(player) * max(maxspeed_mod, 1);
                float maxdropspeed = maxairspeed * max(autocvar_g_br_drop_speed_max, 0);
                float mindropspeed_z = maxdropspeed * bound(0, autocvar_g_br_drop_speed_vertical_min, 1);
                float maxdropspeed_z = maxdropspeed * 0.9; // moving straight down is glitchy
                float pitch_current = br_CalculatePlayerDropAngle(player);
                float pitch_view = player.v_angle.x;

                // pitch_view angle needs to be between -90 and 90 degrees
                if(pitch_view > 90)
                    pitch_view = 180 - pitch_view;
                if(pitch_view < -90)
                    pitch_view = -180 - pitch_view;

                float pitch_diff = pitch_current - pitch_view;
                float pitch_ratio = 0;

                // calculate how much the player wants to change pitch (ratio is at least 0.1)
                // ratio is between -1 (looking straight down) and +1 (looking straight ahead or up)
                if((pitch_diff < 0) && (pitch_current < 90))
                {
                    float pitch_diff_max = 90 - pitch_current;
                    pitch_ratio = bound(-1, sin(max(pitch_diff, -pitch_diff_max) * 90 / pitch_diff_max * DEG2RAD), -0.1);
                }
                else if((pitch_diff > 0) && (pitch_current > 0))
                {
                    float pitch_diff_max = pitch_current;
                    pitch_ratio = bound(0.1, sin(min(pitch_diff, pitch_diff_max) * 90 / pitch_diff_max * DEG2RAD), 1);
                }

                makevectors(player.v_angle);
                // horizontal wishvel as usual
                vector wishvel = v_forward * CS(player).movement.x + v_right * CS(player).movement.y;
                wishvel = normalize(wishvel) * min(1, vlen(wishvel) / maxairspeed);
                // vertical wishvel using forward movement and the previously calculated ratio
                wishvel.z = pitch_ratio * bound(0, CS(player).movement.x / maxairspeed, 1);
                // apply turn acceleration to the horizontal portion of the wishvel
                wishvel.x *= max(autocvar_g_br_drop_accel_turn, 0);
                wishvel.y *= max(autocvar_g_br_drop_accel_turn, 0);
                // apply dive acceleration to the vertical portion of the wishvel
                wishvel.z *= max(autocvar_g_br_drop_accel_dive, 0);
                player.br_drop_velocity += wishvel * dt;

                // modify mindropspeed_z and maxdropspeed_z so that the player does not rotate beyond the view angle
                float vpitch_ratio = sin(pitch_view * DEG2RAD);
                if(pitch_ratio > 0)
                    mindropspeed_z = bound(mindropspeed_z, vpitch_ratio * maxdropspeed, maxdropspeed_z);
                else if(pitch_ratio < 0)
                    maxdropspeed_z = bound(mindropspeed_z, vpitch_ratio * maxdropspeed, maxdropspeed_z);

                // constrain to vertical min/maxdropspeed
                if(player.br_drop_velocity.z > -mindropspeed_z)
                    player.br_drop_velocity.z = -mindropspeed_z;
                if(player.br_drop_velocity.z < -maxdropspeed_z)
                    player.br_drop_velocity.z = -maxdropspeed_z;

                // if there is no horizontal movement point the horizontal vector towards the view direction
                if(vlen(vec2(player.br_drop_velocity)) == 0)
                    player.br_drop_velocity += eX * cos(player.angles.y * DEG2RAD) + eY * sin(player.angles.y * DEG2RAD);

                // adjust horizontal speed so that vertical speed + horizontal speed = maxdropspeed
                player.br_drop_velocity = eZ * player.br_drop_velocity.z + normalize(vec2(player.br_drop_velocity)) * sqrt(pow(maxdropspeed, 2) - pow(player.br_drop_velocity.z, 2));

                player.br_drop_angles.x = br_CalculatePlayerDropAngle(player) - 90;
                player.br_drop_angles.y = vectoangles(vec2(player.br_drop_velocity)).y + 180;
                player.br_drop_angles.z = 180;

                // the .br_drop values aren't modified by physics and will be used by other squad members
                player.velocity = player.br_drop_velocity;
                player.angles = player.br_drop_angles;

                if(player_is_drop_leader)
                {
                    FOREACH_CLIENT(IS_PLAYER(it) && (it != player) && SAME_SQUAD(it, player) && (STAT(DROP, it) == DROP_FALLING), {
                        it.velocity = it.br_drop_velocity = player.br_drop_velocity;
                        it.angles = it.br_drop_angles = player.br_drop_angles;
                    });
                }
            }
            else
            {
                player.velocity = player.br_drop_velocity;
                player.angles = player.br_drop_angles; // no fixangles, only moves the player model not the player view
            }

            return true;
        }
        else
        {
            STAT(DROP, player) = DROP_LANDING;
            ITEMS_STAT(player) &= ~IT_USING_JETPACK;
            player.flags |= FL_PICKUPITEMS;
            player.dphitcontentsmask |= DPCONTENTS_BODY;

            SetResource(player, RES_SHELLS, start_ammo_shells);
            SetResource(player, RES_BULLETS, start_ammo_nails);
            SetResource(player, RES_ROCKETS, start_ammo_rockets);
            SetResource(player, RES_CELLS, start_ammo_cells);
            SetResource(player, RES_PLASMA, start_ammo_plasma);
            SetResource(player, RES_FUEL, start_ammo_fuel);
            STAT(WEAPONS, player) = player.br_wepset_old;

            .entity weaponentity = weaponentities[0];
            W_SwitchWeapon_Force(player, w_getbestweapon(player, weaponentity), weaponentity);
        }
    }
}

MUTATOR_HOOKFUNCTION(br, Damage_Calculate)
{
    entity target = M_ARGV(2, entity);
    float deathtype = M_ARGV(3, float);

    if(STAT(DROP, target) != DROP_LANDED)
    {
        // weapon impact has no push force while dropping
        M_ARGV(6, vector) = '0 0 0';

        if(STAT(DROP, target) == DROP_TRANSPORT)
            M_ARGV(4, float) = M_ARGV(5, float) = 0; // can't take damage while on the dropship
        else
        {
            switch(deathtype)
            {
                case DEATH_FALL.m_id:
                case DEATH_SHOOTING_STAR.m_id:
                    // do not take fall damage when landing from dropship
                    M_ARGV(4, float) = M_ARGV(5, float) = 0;
                    break;
                default:
                    // only take half of the usual damage
                    M_ARGV(4, float) *= max(autocvar_g_br_drop_damage, 0);
                    M_ARGV(5, float) *= max(autocvar_g_br_drop_damage, 0);
            }
        }
    }
}

MUTATOR_HOOKFUNCTION(br, PlayerDies)
{
    entity frag_attacker = M_ARGV(1, entity);
    entity frag_target = M_ARGV(2, entity);
    float frag_deathtype = M_ARGV(3, float); // float for some reason, breaks if changed to int

    if(!IS_PLAYER(frag_target))
        return false;

    if(STAT(DROP, frag_target) == DROP_TRANSPORT)
    {
        frag_target.effects &= ~EF_NODRAW;
        set_movetype(frag_target, MOVETYPE_WALK);
        Kill_Notification(NOTIF_ONE_ONLY, frag_target, MSG_CENTER, CPID_BR_DROPSHIP);
    }

    if(STAT(DROP, frag_target) != DROP_LANDED)
    {
        frag_target.dphitcontentsmask |= DPCONTENTS_BODY;
        STAT(DROP, frag_target) = DROP_LANDED;
    }

    if(STAT(BLEEDING, frag_target) || BR_KILLS_INSTANTLY(frag_target, frag_deathtype))
    {
        if(STAT(BLEEDING, frag_target))
        {
            Kill_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CPID_BR_DOWN);
            STAT(BLEEDING, frag_target) = false;
        }
        frag_target.respawn_flags = RESPAWN_SILENT | RESPAWN_FORCE;
        frag_target.respawn_time = time + 2;
        return true;
    }

    frag_target.flags &= ~FL_PICKUPITEMS;
    RemoveGrapplingHooks(frag_target);
    StatusEffects_removeall(frag_target, STATUSEFFECT_REMOVE_NORMAL);

    SetResource(frag_target, RES_HEALTH, start_health * max(autocvar_g_br_bleeding_health, 0));
    SetResource(frag_target, RES_ARMOR, 0);
    Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_BR_DOWN_WAIT);
    STAT(BLEEDING, frag_target) = true;

    FOREACH_CLIENT(IS_PLAYER(it),
    {
        for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
        {
            .entity weaponentity = weaponentities[slot];
            if(it.(weaponentity).hook.aiment == frag_target)
                RemoveHook(it.(weaponentity).hook);
        }
    });

    frag_target.br_wepset_old = STAT(WEAPONS, frag_target);
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    {
        .entity weaponentity = weaponentities[slot];
        frag_target.br_weapon_prev[slot] = frag_target.(weaponentity).m_switchweapon;
        frag_target.br_lastweapon_prev[slot] = frag_target.(weaponentity).cnt;
    }
    STAT(WEAPONS, frag_target) = '0 0 0';

    WaypointSprite_Spawn(WP_BRBleeding, 0, 0, frag_target, '0 0 64', NULL, 0, frag_target, waypointsprite_attached, true, RADARICON_WAYPOINT).br_squad = frag_target.br_squad;

    if(frag_attacker == frag_target || !frag_attacker || ITEM_DAMAGE_NEEDKILL(frag_deathtype))
    {
        if(IS_PLAYER(frag_target))
            Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_BR_DOWN_SELF);
        Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_BR_DOWN_SELF, frag_target.netname);
    }
    else
    {
        if(IS_PLAYER(frag_target))
            Send_Notification(NOTIF_ONE, frag_target, MSG_CENTER, CENTER_BR_DOWN, frag_attacker.netname);
        Send_Notification(NOTIF_ALL, NULL, MSG_INFO, INFO_BR_DOWN, frag_target.netname, frag_attacker.netname);
    }

    br_SquadUpdateInfo();

    return true;
}

MUTATOR_HOOKFUNCTION(br, PlayerDied)
{
    entity player = M_ARGV(0, entity);
    if(round_handler_IsActive() && round_handler_IsRoundStarted())
        br_LastPlayerForSquad_Notify(player.br_squad);
    br_SquadUpdateInfo();
}

MUTATOR_HOOKFUNCTION(br, ClientObituary)
{
    entity frag_inflictor = M_ARGV(0, entity);
    entity frag_attacker = M_ARGV(1, entity);
    entity frag_target = M_ARGV(2, entity);
    float frag_deathtype = M_ARGV(3, float); // float for some reason, breaks if changed to int
    //entity frag_weaponentity = M_ARGV(4, entity);

    if(!STAT(BLEEDING, frag_target) && !BR_KILLS_INSTANTLY(frag_target, frag_deathtype))
    {
        frag_target.br_bleeding_inflictor = frag_inflictor;
        frag_target.br_bleeding_attacker = frag_attacker;
        frag_target.br_bleeding_deathtype = frag_deathtype;
        //frag_target.br_bleeding_weaponentity = frag_weaponentity; // TODO: get entity field
        return true;
    }

    if(STAT(BLEEDING, frag_target) && frag_target.br_bleeding_attacker)
    {
        entity new_inflictor = frag_target.br_bleeding_inflictor;
        entity new_attacker = frag_target.br_bleeding_attacker;
        int new_deathtype = frag_target.br_bleeding_deathtype;
        .entity new_weaponentity = frag_target.br_bleeding_weaponentity;
        frag_target.br_bleeding_attacker = frag_target.br_bleeding_inflictor = NULL;

        Obituary(new_attacker, new_inflictor, frag_target, new_deathtype, new_weaponentity);
        return true;
    }

    return false;
}

MUTATOR_HOOKFUNCTION(br, SetResource)
{
    entity player = M_ARGV(0, entity);
    if(!IS_PLAYER(player))
        return false;

    int res_type = M_ARGV(1, int);
    float amount = M_ARGV(2, float);

    if(STAT(BLEEDING, player) && (res_type == RES_HEALTH || res_type == RES_ARMOR))
    {
        if(amount > GetResource(player, res_type)) // prevent the player from getting health or armor in any way
            return true;
    }
}

MUTATOR_HOOKFUNCTION(br, GetResourceLimit)
{
    entity player = M_ARGV(0, entity);

    if(!IS_PLAYER(player) || !STAT(BLEEDING, player))
        return false;

    int res_type = M_ARGV(1, int);

    switch(res_type)
    {
        case RES_HEALTH:
            M_ARGV(2, float) *= max(autocvar_g_br_bleeding_health, 0);
            break;
        case RES_ARMOR:
            M_ARGV(2, float) = 0;
    }
}

MUTATOR_HOOKFUNCTION(br, PlayerRegen)
{
    entity player = M_ARGV(0, entity);

    if(STAT(BLEEDING, player)){
        M_ARGV(7, float) = max(autocvar_g_br_bleed, 0);
        M_ARGV(8, float) = max(autocvar_g_br_bleedlinear, 0);
        M_ARGV(2, float) = M_ARGV(10, float) = 0;
        return false;
    }
    return true;
}

MUTATOR_HOOKFUNCTION(br, PlayerCanCrouch)
{
    entity player = M_ARGV(0, entity);
    if(STAT(BLEEDING, player))
        M_ARGV(1, bool) = true;
    else if(STAT(DROP, player) != DROP_LANDED)
        M_ARGV(1, bool) = false;
}

MUTATOR_HOOKFUNCTION(br, PlayerJump)
{
    entity player = M_ARGV(0, entity);
    return STAT(BLEEDING, player) || (STAT(DROP, player) != DROP_LANDED);
}

MUTATOR_HOOKFUNCTION(br, BotShouldAttack)
{
    entity bot = M_ARGV(0, entity);
    entity target = M_ARGV(1, entity);

    return SAME_SQUAD(bot, target) || (STAT(DROP, target) == DROP_TRANSPORT);
}

MUTATOR_HOOKFUNCTION(br, AccuracyTargetValid)
{
    entity attacker = M_ARGV(0, entity);
    entity target = M_ARGV(1, entity);

    if(SAME_SQUAD(attacker, target) || (STAT(DROP, target) == DROP_TRANSPORT))
        return MUT_ACCADD_INDIFFERENT;
    return MUT_ACCADD_VALID;
}

MUTATOR_HOOKFUNCTION(br, CustomizeWaypoint)
{
    entity wp = M_ARGV(0, entity);
    entity player = M_ARGV(1, entity);

    if(!IS_PLAYER(player) || DIFF_SQUAD(wp, player))
        return true;
}

MUTATOR_HOOKFUNCTION(br, ClientKill)
{
    entity player = M_ARGV(0, entity);

    if(round_handler_IsActive() && round_handler_IsRoundStarted())
    {
        // no forfeiting once the game started
        Send_Notification(NOTIF_ONE_ONLY, player, MSG_CENTER, CENTER_BR_FORFEIT);
        return true;
    }

    return false;
}

MUTATOR_HOOKFUNCTION(br, ClientCommand_Spectate)
{
    entity player = M_ARGV(0, entity);

    if(round_handler_IsActive() && round_handler_IsRoundStarted())
    {
        // no forfeiting once the game started
        Send_Notification(NOTIF_ONE_ONLY, player, MSG_CENTER, CENTER_BR_FORFEIT);
        return MUT_SPECCMD_RETURN;
    }
    return MUT_SPECCMD_CONTINUE;
}

float br_CalculatePlayerDropAngle(entity this)
{
    if(this.br_drop_velocity.z < 0)
    {
        float dropspeed_xy = vlen(vec2(this.br_drop_velocity));
        float dropspeed_z = fabs(this.br_drop_velocity.z);
        return 90 - atan(dropspeed_xy / dropspeed_z) * RAD2DEG;
    }

    return 0;
}

void br_LastPlayerForSquad_Notify(entity squad)
{
    entity player = br_SquadFindLastAlive(squad, false);
    if(player)
        Send_Notification(NOTIF_ONE, player, MSG_CENTER, CENTER_ALONE);
}

void br_RemovePlayer(entity player)
{
    br_SquadMember_Remove(player);

    FOREACH_CLIENT((it.br_bleeding_attacker == player) || (it.br_bleeding_inflictor == player), {
        it.br_bleeding_attacker = it.br_bleeding_inflictor = NULL;
    });
}

void br_Revive(entity player)
{
    if(STAT(BLEEDING, player))
    {
        Kill_Notification(NOTIF_ONE, player, MSG_CENTER, CPID_BR_DOWN);
        STAT(BLEEDING, player) = false;
    }
    player.flags |= FL_PICKUPITEMS;
    SetResource(player, RES_HEALTH, start_health * max(autocvar_g_br_revive_health, 0));

    STAT(WEAPONS, player) = player.br_wepset_old;
    for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
    {
        .entity weaponentity = weaponentities[slot];
        W_SwitchWeapon_Force(player, player.br_weapon_prev[slot], weaponentity);
        player.(weaponentity).cnt = player.br_lastweapon_prev[slot];
    }

    player.pauseregen_finished = time + autocvar_g_balance_pause_health_regen;

    STAT(REVIVE_PROGRESS, player) = 0;
    player.revival_time = time;

    WaypointSprite_Kill(player.waypointsprite_attached);

    br_SquadUpdateInfo();
}

int br_WinningCondition()
{
    int total_squads = br_SquadUpdateInfo();

    if ((total_squads > 1) || !(round_handler_IsActive() && round_handler_IsRoundStarted()))
        return WINNING_NEVER;

    entity winner_squad = NULL;
    IL_EACH(squads, !it.br_squad_dead, winner_squad = it);

    for(entity member = winner_squad.br_squad_first; member; member = member.br_squad_next)
    {
        GameRules_scoring_add(member, BR_RANK, 1);
    }

    return WINNING_YES;
}

bool br_isEliminated(entity e)
{
    return (IN_SQUAD(e) && (IS_DEAD(e) || IS_SPEC(e) || IS_OBSERVER(e)));
}

bool br_CheckWinner()
{
    return false;
}

bool br_CheckPlayers()
{
    total_players = 0;
    FOREACH_CLIENT(IS_PLAYER(it), ++total_players);

    static int prev_players = 0;
    if (total_players >= autocvar_g_br_minplayers || total_players == 0)
    {
        if(prev_players > 0)
            Kill_Notification(NOTIF_ALL, NULL, MSG_CENTER, CPID_MISSING_PLAYERS);
        prev_players = 0;
        return (total_players >= autocvar_g_br_minplayers);
    }

    if(prev_players != total_players)
    {
        Send_Notification(NOTIF_ALL, NULL, MSG_CENTER, CENTER_MISSING_PLAYERS, autocvar_g_br_minplayers - total_players);
        prev_players = total_players;
    }

    return false;
}

void br_RoundStart(){
    ring = ring_initialize();

    dropship = dropship_initialize();

    if(!dropship)
    {
        delete(ring);
        ring = NULL;

        FOREACH_CLIENT(IS_PLAYER(it), {
            TRANSMUTE(Observer, it);
            PutClientInServer(it);
        });
        LOG_SEVERE("Failed to determine dropship route, aborting...");
    }

    int num_players = 0;

    FOREACH_CLIENT(IS_PLAYER(it), {
        GameRules_scoring_add(it, BR_RANK, -GameRules_scoring_add(it, BR_RANK, 0));
        GameRules_scoring_add(it, BR_SQUAD, -GameRules_scoring_add(it, BR_SQUAD, 0));
        GameRules_scoring_add(it, BR_REVIVALS, -GameRules_scoring_add(it, BR_REVIVALS, 0));

        RemoveGrapplingHooks(it);
        StatusEffects_removeall(it, STATUSEFFECT_REMOVE_CLEAR);

        // isn't there another way to initialize these?
        SetResource(it, RES_HEALTH, start_health);
        SetResource(it, RES_ARMOR, start_armorvalue);
        SetResource(it, RES_SHELLS, 0);
        SetResource(it, RES_BULLETS, 0);
        SetResource(it, RES_ROCKETS, 0);
        SetResource(it, RES_CELLS, 0);
        SetResource(it, RES_PLASMA, 0);
        SetResource(it, RES_FUEL, 0);
        STAT(WEAPONS, it) = '0 0 0';
        it.br_wepset_old = autocvar_g_br_startweapons ? start_weapons : '0 0 0';
        for(int slot = 0; slot < MAX_WEAPONSLOTS; ++slot)
        {
            it.br_weapon_prev[slot] = WEP_Null;
            it.br_lastweapon_prev[slot] = 0;
        }

        ++num_players;
    });

    max_squad_size = max(autocvar_g_br_squad_size, 1);
    if(num_players <= max_squad_size)
        max_squad_size = ceil(num_players / 2);

    for(int num_squads = 0; (num_squads * max_squad_size) < num_players; ++num_squads)
    {
        entity new_squad = spawn();
        new_squad.br_squad_drop_leader = NULL;
        new_squad.br_squad_id = num_squads + 1;

        IL_PUSH(squads, new_squad);
    }

    FOREACH_CLIENT(IS_PLAYER(it), {
        entity current_squad = br_SquadGetRandomAvail();
        br_SquadMember_Add(current_squad, it);
        GameRules_scoring_add(it, BR_SQUAD, current_squad.br_squad_id);

        setorigin(it, dropship.origin + eZ * (dropship.mins.z - it.maxs.z - 64)); // FIXME: this can teleport players into brushes/void
        it.angles = vectoangles(dropship_path_direction) + '45 0 0';
        it.fixangle = true;
        it.velocity = '0 0 0';
        set_movetype(it, MOVETYPE_FLY_WORLDONLY);
        it.flags &= ~FL_PICKUPITEMS;
        it.dphitcontentsmask &= ~DPCONTENTS_BODY;
        it.effects |= EF_NODRAW;
        Send_Notification(NOTIF_ONE_ONLY, it, MSG_CENTER, CENTER_BR_DROPSHIP);
        STAT(DROP, it) = DROP_TRANSPORT;
        UNSET_ONGROUND(it); // otherwise this isn't unset if the player drops in the same frame
    });

    squads_colored = autocvar_g_br_squad_colors;

    FOREACH_CLIENT(IS_REAL_CLIENT(it),
    {
        STAT(SQUADCOLORS, it) = squads_colored;
    });

    IL_EACH(squads, true,
    {
        if(squads_colored)
        {
            float squad_color;
            squad_color = 16 * floor(random() * 15) + floor(random() * 15); // color 15 is special, don't select it as a squad color

            for(entity member = it.br_squad_first; member; member = member.br_squad_next)
            {
                member.colormap = 1024 + squad_color;
            }
        }

        float min_distance = max(autocvar_g_br_drop_distance_force, 0);
        if(!br_SquadIsBotsOnly(it))
            it.br_force_drop_distance = min_distance;
        else
            it.br_force_drop_distance = min_distance + random() * max(dropship_path_length - min_distance, 0);
    });
}

void br_Initialize()
{
    squads_colored = autocvar_g_br_squad_colors;

    // TODO: remove round handler
    round_handler_Spawn(br_CheckPlayers, br_CheckWinner, br_RoundStart);
    round_handler_Init(5, 0, 0); // no warmup or timelimit in battle royale

    EliminatedPlayers_Init(br_isEliminated);
}
