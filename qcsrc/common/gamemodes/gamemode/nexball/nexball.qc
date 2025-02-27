#include "nexball.qh"

#ifdef MENUQC
#include "weapon.qh"

METHOD(NexBall, describe, string(NexBall this))
{
    TC(NexBall, this);
    return sprintf(_("%s is a fun ball sport game where 2 teams compete to score the most goals.\n\n"
        "%s is usually played as either soccer where players walk into the ball to kick it around, or basketball where players have a %s so can pass the ball and intercept passes.\n\n"
        "Keep in mind players can score own goals, so don't embarrass yourself in front of your team!"),
    COLORED_NAME(this), COLORED_NAME(this), COLORED_NAME(WEP_NEXBALL));
}
#endif
