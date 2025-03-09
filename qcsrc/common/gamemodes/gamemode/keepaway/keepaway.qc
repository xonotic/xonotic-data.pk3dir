#include "keepaway.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/ctf/ctf.qh>

METHOD(Keepaway, describe, string(Keepaway this))
{
    TC(Keepaway, this);
    return sprintf(_("%s is a free-for-all match where a ball spawns randomly on the map and the goal is to hold the ball for as long as possible.\n\n"
        "Your score increases when you frag someone while you're holding a ball and when you frag the ball carrier. "
        "The first player to reach the score limit will win the match.\n\n"
        "When the ball carrier is fragged, the ball will drop to the ground and anyone is able to pick it up. "
        "If nobody picks it up after some time it will get bored and teleport itself elsewhere. "
        "Like the flag in %s, the ball in %s can also be thrown, but it's not a great idea since you have no teammates!\n\n"
        "%s rewards good fragging but also good movement, since the better you can evade attacks, the longer you can keep the ball."),
    COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_CTF), COLORED_NAME(this), COLORED_NAME(this));
}
#endif
