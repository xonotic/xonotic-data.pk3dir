#include "commandbutton.qh"
#include "dialog.qh"

entity makeXonoticCommandButton_T(string theText, vector theColor, string theCommand, int theFlags, string theTooltip)
{
	entity me;
	me = NEW(XonoticCommandButton);
	me.configureXonoticCommandButton(me, theText, theColor, theCommand, theFlags, theTooltip);
	return me;
}
entity makeXonoticCommandButton(string theText, vector theColor, string theCommand, int theFlags)
{
	return makeXonoticCommandButton_T(theText, theColor, theCommand, theFlags, string_null);
}

void XonoticCommandButton_Click(entity me, entity other)
{
	//if(me.flags & COMMANDBUTTON_APPLY)
	//	saveAllCvars(me.parent);
	localcmd("\n", me.onClickCommand, "\n");
	//if(me.flags & COMMANDBUTTON_REVERT)
	//	loadAllCvars(me.parent);
	if(me.flags & COMMANDBUTTON_CLOSE)
		me.parent.close(me.parent);
}

void XonoticCommandButton_configureXonoticCommandButton(entity me, string theText, vector theColor, string theCommand, int theFlags, string theTooltip)
{
	me.configureXonoticButton(me, theText, theColor, theTooltip);
	me.onClickCommand = theCommand;
	me.flags = theFlags;
	me.onClick = XonoticCommandButton_Click;
	me.onClickEntity = me;
}
