#include "keyhunt.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/ctf/ctf.qh>

METHOD(KeyHunt, describe, string(KeyHunt this))
{
	TC(KeyHunt, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a round-based gametype played with a few teams, where each team starts with one key and all keys must be collected to win the round. "
	      "The team member who is given the key at the start of the round is randomly selected after a ten second period, and the location of all keys will be visible on the radar after a few seconds."), COLORED_NAME(this));
	PAR(_("Scoring in %s is quite complicated, involving a mix of gathering all keys, points for collecting a key, fragging an enemy key carrier, and fragging other enemies."), COLORED_NAME(this));
	PAR(_("Like in %s the key can be dropped, so you can pass it to your teammates if you're running low on health."), COLORED_NAME(MAPINFO_TYPE_CTF));
	return PAGE_TEXT;
}
#endif
