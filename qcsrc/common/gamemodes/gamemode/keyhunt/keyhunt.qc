#include "keyhunt.qh"

#ifdef MENUQC
#include <common/gamemodes/gamemode/ctf/ctf.qh>

METHOD(KeyHunt, describe, string(KeyHunt this))
{
    TC(KeyHunt, this);
    return sprintf(_("%s is a round-based gamemode played with a few teams, where each team starts with 1 key and all keys must be collected to win the round. "
        "The team member who is given the key at the start of the round is randomly selected after a ten second period, and the location of all keys will be visible in the radar after a few seconds\n\n"
        "Scoring in %s is quite complicated, involving a mix of gathering all keys, points for collecting a key, killing an enemy key carrier, and killing other enemies. "
        "If a key is destroyed by being dropped into the void or a death trap, points are allocated accordingly\n\n"
        "Like in %s the key can be dropped, so you can pass it to your teammates if you're running low on health"),
    COLORED_NAME(this), COLORED_NAME(this), COLORED_NAME(MAPINFO_TYPE_CTF));
}
#endif
