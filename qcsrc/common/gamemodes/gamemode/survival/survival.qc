#include "survival.qh"

#ifdef GAMEQC
REGISTER_NET_LINKED(ENT_CLIENT_SURVIVALSTATUSES)
#endif
#ifdef MENUQC
METHOD(Survival, describe, string(Survival this))
{
	TC(Survival, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a hunter-survivor gametype involving two teams where the goal of the hunters is to frag all survivors, and the goal of the survivors is to frag all hunters or survive until time runs out. "
	      "The trick lies in the fact that players only know which team they belong to, and not the team membership of any other players."), COLORED_NAME(this));
	PAR(_("Since the goal of both teams is essentially to eliminate all members of the opposite team, it can be tricky for survivors to figure out their fellow teammates."));
	PAR(_("Teams are randomly selected as the round begins, with the hunter team being a bit smaller, "
	      "and then the round starts with a brief warmup grace period in which items can be collected but weapons can't be fired."));
	PAR(_("Players are rewarded a point for each member of the opposing team they frag, only if they survive the round, and points are deducted for each teammate fragged. "
	      "Extra points are also given to survivors who survive until the round timer expires."));
	return PAGE_TEXT;
}
#endif
