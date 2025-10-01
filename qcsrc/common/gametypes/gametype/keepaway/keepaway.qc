#include "keepaway.qh"

#ifdef MENUQC
#include <common/gametypes/gametype/ctf/ctf.qh>

METHOD(Keepaway, describe, string(Keepaway this))
{
	TC(Keepaway, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a free-for-all match where a ball spawns randomly on the map and the goal is to hold the ball for as long as possible."), COLORED_NAME(this));
	PAR(_("Your score increases when you frag someone while you're holding a ball and when you frag the ball carrier. "
	      "The first player to reach the score limit will win the match."));
	PAR(_("When the ball carrier is fragged, the ball will drop to the ground and anyone is able to pick it up. "
	      "If nobody picks it up after some time it will get bored and teleport itself elsewhere."));
	PAR(_("%s rewards good fragging but also good movement, since the better you can evade attacks, the longer you can keep the ball."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif
