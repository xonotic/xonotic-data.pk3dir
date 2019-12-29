#include "dialog_multiplayer_join_ToS.qh"

#include "textlabel.qh"
#include <lib/urllib.qh>


entity makeXonoticServerToSTab()
{
	entity me;
	me = NEW(XonoticServerToSTab);
	me.configureDialog(me);
	return me;
}

void XonoticServerToSTab_loadToS(entity me, float i)
{
    //TODO: download ToS from server
    localcmd("echo test1");
}

void XonoticServerToSTab_fill(entity me)
{
	entity e;
    me.TR(me);
        me.TD(me, 1, 6.2, e = makeXonoticTextLabel(0, _("ToS")));
        me.nameLabel = e;
}

void AdditionalServerInfo_OnGet(entity fh, entity pass, int status)
{
    localcmd("echo test2");
}
