#include "assault.qh"

#ifdef MENUQC
METHOD(Assault, describe, string(Assault this))
{
    TC(Assault, this);
    return sprintf(_("%s is a team-based gamemode involving an attacking and a defending team\n\n"
        "The attacking team destroys objects placed on the map, which opens up new doors or pathways to more objects, until a main object (the enemy power core) is reached. "
        "The attacking team wins the round if they manage to destroy the power core before time runs out, and then teams switch roles in the next round\n\n"
        "The defending team has to defend the objects, winning the round if they successfully prevent the attacking team from destroying the power core\n\n"
        "A team will win the match overall once they win at least one round where they attacked and one round where they defended, meaning there can be ties\n\n"
        "Objects have waypoints which show their health and position, and they're destroyed by shooting them with any weapon"),
    COLORED_NAME(this));
}
#endif
