#include "survival.qh"

#ifdef MENUQC
METHOD(Survival, describe, string(Survival this))
{
	TC(Survival, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a hunter-survivor gametype involving two teams where the goal of the hunters is to frag all survivors, and the goal of the survivors is to frag all hunters or survive until time runs out. "
	      "The trick lies in the fact that survivors don't know who else is a survivor."), COLORED_NAME(this));
	PAR(_("Since the goal of both teams is essentially to eliminate all members of the opposite team, it can be tricky for survivors to figure out their fellow teammates."));
	PAR(_("If there's enough players available, there may also detectives on the survivors' team, who can shoot corpses to find out their identity and sometimes who eliminated them. "
	      "Detectives are known to everyone, even the hunters, so may be targeted!"));
	PAR(_("Teams are randomly selected as the round begins, with the hunter team being a bit smaller, "
	      "and then the round starts with a brief warmup grace period in which items can be collected but weapons can't be fired."));
	PAR(_("Players are rewarded with a point for each member of the opposing team they frag, and an additional point if they're alive at the end of the round."));
	return PAGE_TEXT;
}
#endif
