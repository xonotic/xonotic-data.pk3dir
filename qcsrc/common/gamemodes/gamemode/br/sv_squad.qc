#include "sv_squad.qh"

.int br_squad_members;
.int br_squad_members_alive;

int br_SquadUpdateInfo()
{
    int alive_players = 0;
    int alive_squads = 0;

    IL_EACH(squads, !it.br_squad_dead,
    {
        it.br_squad_members_alive = 0;

        for(entity member = it.br_squad_first; member; member = member.br_squad_next)
        {
            if (IS_DEAD(member) || !IS_PLAYER(member))
                continue;
            ++alive_players;

            if (STAT(BLEEDING, member))
                continue;
            ++it.br_squad_members_alive;
        }

        if(it.br_squad_members_alive > 0)
            ++alive_squads;
    });

    // all members are either dead or bleeding, kill the squad
    IL_EACH(squads, !it.br_squad_dead && (it.br_squad_members_alive == 0),
    {
        it.br_squad_dead = true;

        for(entity member = it.br_squad_first; member; member = member.br_squad_next)
        {
            Send_Notification(NOTIF_ONE, member, MSG_CENTER, CENTER_BR_DEAD_SQUAD);
            GameRules_scoring_add(member, BR_RANK, alive_squads + 1);

            if (IS_DEAD(member) || !IS_PLAYER(member))
                continue;

            // kill player
            SetResourceExplicit(member, RES_HEALTH, 0);
            if(member.event_damage)
                member.event_damage(member, member, member, 1, DEATH_ROT.m_id, DMG_NOWEP, member.origin, '0 0 0');
        }
    });

    FOREACH_CLIENT(IS_REAL_CLIENT(it),
    {
        if(IN_SQUAD(it))
            br_SendSquad(it);

        STAT(SQUADSALIVE, it) = alive_squads;
        STAT(PLAYERSALIVE, it) = alive_players;
    });

    eliminatedPlayers.SendFlags |= 1;

    return alive_squads;
}

void br_SquadMember_Add(entity squad, entity player)
{
    player.br_squad = squad;
    ++squad.br_squad_members;

    entity member_prev = squad.br_squad_last;
    squad.br_squad_last = player;
    player.br_squad_next = NULL;
    player.br_squad_prev = member_prev;
    if(member_prev)
        member_prev.br_squad_next = player;

    if(squad.br_squad_first == NULL)
        squad.br_squad_first = player;
}

void br_SquadMember_Remove(entity player)
{
    entity squad = player.br_squad;

    if(!squad)
        return;

    WaypointSprite_Kill(player.br_allywaypoint);
    --squad.br_squad_members;

    entity member_next = player.br_squad_next;
    entity member_prev = player.br_squad_prev;
    if(member_next)
        member_next.br_squad_prev = member_prev;
    if(member_prev)
        member_prev.br_squad_next = member_next;

    if(squad.br_squad_first == player)
        squad.br_squad_first = member_next;
    if(squad.br_squad_last == player)
        squad.br_squad_last = member_prev;

    if(squad.br_squad_drop_leader == player)
        squad.br_squad_drop_leader = NULL; // TODO: delegate another drop leader

    if(!squad.br_squad_first) // empty squad
        delete(squad);

    player.br_squad = NULL;
    player.br_squad_next = NULL;
    player.br_squad_prev = NULL;
}

bool br_SquadIsBotsOnly(entity squad)
{
    for(entity member = squad.br_squad_first; member; member = member.br_squad_next)
    {
        if(IS_REAL_CLIENT(member))
            return false;
    }

    return true;
}

entity br_SquadGetRandomAvail()
{
    int min_members = max_squad_size;
    IL_EACH(squads, it.br_squad_members < min_members, min_members = it.br_squad_members);

    int num_avail = 0;
    IL_EACH(squads, it.br_squad_members == min_members, ++num_avail);

    if(num_avail == 0)
        return NULL;

    int target_id = floor(random() * num_avail);

    int current_id = 0;
    IL_EACH(squads, it.br_squad_members == min_members,
    {
        if(current_id == target_id)
            return it;

        ++current_id;
    });

    return NULL;
}

entity br_SquadFindLastAlive(entity squad, bool healthy_only)
{
    if(!squad)
        return NULL;

    entity last_alive = NULL;
    for(entity member = squad.br_squad_first; member; member = member.br_squad_next)
    {
        if (IS_PLAYER(member) && !IS_DEAD(member) && (!STAT(BLEEDING, member) || !healthy_only))
        {
            if(last_alive)
                return NULL; // more than one squad member is alive

            last_alive = member;
        }
    }

    return last_alive;
}

void br_SendSquad(entity to)
{
    msg_entity = to;
    entity squad = to.br_squad;

    if(!squad)
        return;

    WriteHeader(MSG_ONE, TE_CSQC_BR_SQUAD);
    WriteByte(MSG_ONE, squad.br_squad_members);

    for(entity member = squad.br_squad_first; member; member = member.br_squad_next)
    {
        WriteByte(MSG_ONE, etof(member));
    }
}
