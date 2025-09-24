#include "ctf.qh"

#ifdef MENUQC
METHOD(CaptureTheFlag, describe, string(CaptureTheFlag this))
{
	TC(CaptureTheFlag, this);
	PAGE_TEXT_INIT();
	PAR(_("%s is a common team-based gametype where the objective is to steal an enemy team's flag and bring it to your own to capture it. "
	      "A flag can only be captured if your own flag is also home in its base, so it's important to collect your flag after it's dropped."), COLORED_NAME(this));
	PAR(_("The game is won once a team reaches a certain number of \"caps\" (captures), or has a considerable lead over the other team."));
	PAR(_("If a flag is dropped into the void or a death trap it will be immediately returned to its base, or otherwise sit idle for a while before automatically returning itself. "
	      "If all flags are held, after some time period a \"stalemate\" will initiate and all flag carriers (\"fc\"s) will be exposed on the radar and with waypoints."));
	PAR(_("%s rewards crafty movement, since the more difficult it is for enemies to attack you the more likely you are to escape from their base with their flag. "
	      "Importantly, it also rewards base defense since if your enemies can't take your flag, they can never capture. "
	      "Lastly, good team communication is important, especially to let teammates know if you see the enemy flag carrier."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif
