#include "tdm.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/deathmatch/deathmatch.qh>

METHOD(TeamDeathmatch, describe, string(TeamDeathmatch this))
{
    TC(TeamDeathmatch, this);
    return sprintf(_("%s is the team version of %s, played with 2 teams.\n\n"
        "Scoring is quite simple, adding a point for every frag, and subtracting a point for fragging yourself or a teammate.\n\n"
        "Careful team coordination and map control is often a key to winning a match, and sometimes players will share weapons with their teammates."),
    COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_DEATHMATCH));
}
#endif
