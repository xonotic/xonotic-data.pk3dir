#include "tka.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/keepaway/keepaway.qh>

METHOD(TeamKeepaway, describe, string(TeamKeepaway this))
{
    TC(TeamKeepaway, this);
    return sprintf(_("%s is the team version of %s, where teams compete to maintain superior control over the ball.\n\n"
        "Scoring is similar to in %s, except that points are awarded for frags for all members of the team of the player holding the ball."),
    COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_KEEPAWAY), COLORED_NAME(MAPINFO_TYPE_KEEPAWAY));
}
#endif
