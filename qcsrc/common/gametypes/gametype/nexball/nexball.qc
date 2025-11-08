#include "nexball.qh"

#ifdef MENUQC
#include "weapon.qh"

METHOD(NexBall, describe, string(NexBall this))
{
	TC(NexBall, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a fun ball sport game where 2 teams compete to score the most goals."), COLORED_NAME(this));
	PAR(_("%s is usually played as either soccer where players walk into the ball to kick it around, or basketball where players have a %s so they can pass the ball and intercept passes."), COLORED_NAME(this), COLORED_NAME(WEP_NEXBALL));
	PAR(_("Keep in mind players can score own goals, so don't embarrass yourself in front of your team!"));
	return PAGE_TEXT;
}
#endif
