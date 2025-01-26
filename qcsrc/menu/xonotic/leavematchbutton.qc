#include "leavematchbutton.qh"

// resets g_campaign and updates menu items to reflect cvar values that may have been restored after leaving the campaign
// the delay is for allowing listening to the button sound (if enabled), since the disconnect command stops all sounds
// menu_sync is also useful when leaving Instant Action mode
// see also m_draw
const string LEAVEMATCH_CMD = "defer 0.4 disconnect; defer 0.4 wait; defer 0.4 \"g_campaign 0\"; defer 0.4 menu_sync";

string leaveMatchButton_getText(entity me)
{
	if (me.disabled)
		return _("Leave current match");
	else if(isdemo())
		return _("Stop demo");
	else if(cvar("g_campaign"))
		return _("Leave campaign");
	else if (isServerSingleplayer())
		return _("Leave singleplayer");
	else
		return _("Leave multiplayer");
}

string leaveMatchButton_getTooltip(entity me)
{
	if (me.disabled || isdemo())
		return "-";
	else if(cvar("g_campaign"))
		return _("Leave current campaign level");
	else if (isServerSingleplayer())
		return _("Leave current singleplayer match");
	else
		return _("Leave current multiplayer match / Disconnect from the server");
}

entity makeXonoticLeaveMatchButton(vector theColor, int theFlags)
{
	entity me;
	me = NEW(XonoticLeaveMatchButton);
	me.configureXonoticLeaveMatchButton(me, theColor, theFlags);
	return me;
}

void XonoticLeaveMatchButton_draw(entity me)
{
	SUPER(XonoticCommandButton).draw(me);
	me.disabled = !(gamestatus & (GAME_ISSERVER | GAME_CONNECTED));
	me.setText(me, leaveMatchButton_getText(me));
	setZonedTooltip(me, leaveMatchButton_getTooltip(me), string_null);
}

void XonoticLeaveMatchButton_configureXonoticLeaveMatchButton(entity me, vector theColor, int theFlags)
{
	me.configureXonoticCommandButton(me, string_null, theColor, LEAVEMATCH_CMD, theFlags, string_null);
	me.draw = XonoticLeaveMatchButton_draw;
}
