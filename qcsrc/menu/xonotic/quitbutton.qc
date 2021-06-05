#include "quitbutton.qh"

// resets g_campaign and updates menu items to reflect cvar values that may have been restored after leaving the campaign
// the delay is for allowing listening to the button sound (if enabled), since the disconnect command stops all sounds
// menu_sync is also useful when quitting Instant Action mode
// see also m_draw
const string QUITGAME_CMD = "defer 0.4 disconnect; defer 0.4 wait; defer 0.4 \"g_campaign 0\"; defer 0.4 menu_sync\n";

string quitGameButton_getText(entity me)
{
	if (me.disabled)
		return _("Quit current game");
	else if(cvar("g_campaign"))
		return _("Quit campaign");
	else if (cvar_string("net_address") == "127.0.0.1" && cvar_string("net_address_ipv6") == "::1")
		return _("Quit singleplayer");
	else
		return _("Quit multiplayer");
}

string quitGameButton_getTooltip(entity me)
{
	if (me.disabled)
		return "-";
	else if(cvar("g_campaign"))
		return _("Quit current campaign level");
	else if (cvar_string("net_address") == "127.0.0.1" && cvar_string("net_address_ipv6") == "::1")
		return _("Quit current singleplayer match");
	else
		return _("Quit current multiplayer match / Disconnect from the server");
}

entity makeXonoticQuitButton(vector theColor, int theFlags)
{
	entity me;
	me = NEW(XonoticQuitButton);
	me.configureXonoticQuitButton(me, theColor, theFlags);
	return me;
}

void XonoticQuitButton_draw(entity me)
{
	SUPER(XonoticCommandButton).draw(me);
	me.disabled = !(gamestatus & (GAME_ISSERVER | GAME_CONNECTED));
	me.setText(me, quitGameButton_getText(me));
	setZonedTooltip(me, quitGameButton_getTooltip(me), string_null);
}

void XonoticQuitButton_configureXonoticQuitButton(entity me, vector theColor, int theFlags)
{
	me.configureXonoticCommandButton(me, string_null, theColor, QUITGAME_CMD, theFlags, string_null);
	me.draw = XonoticQuitButton_draw;
}
