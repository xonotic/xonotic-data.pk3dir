#ifndef COMMANDBUTTON_CLOSE
# define COMMANDBUTTON_CLOSE 1
# define COMMANDBUTTON_APPLY 2
//# define COMMANDBUTTON_REVERT 4
#endif

#ifndef COMMANDBUTTON_H
#define COMMANDBUTTON_H
#include "button.qc"
CLASS(XonoticCommandButton, XonoticButton)
	METHOD(XonoticCommandButton, configureXonoticCommandButton, void(entity, string, vector, string, float, string));
	ATTRIB(XonoticCommandButton, onClickCommand, string, string_null)
	ATTRIB(XonoticCommandButton, flags, float, 0)
ENDCLASS(XonoticCommandButton)
entity makeXonoticCommandButton_T(string theText, vector theColor, string theCommand, float closesMenu, string theTooltip);
entity makeXonoticCommandButton(string theText, vector theColor, string theCommand, float closesMenu);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticCommandButton_T(string theText, vector theColor, string theCommand, float theFlags, string theTooltip)
{
	entity me;
	me = NEW(XonoticCommandButton);
	me.configureXonoticCommandButton(me, theText, theColor, theCommand, theFlags, theTooltip);
	return me;
}
entity makeXonoticCommandButton(string theText, vector theColor, string theCommand, float theFlags)
{
	return makeXonoticCommandButton_T(theText, theColor, theCommand, theFlags, string_null);
}

void XonoticCommandButton_Click(entity me, entity other)
{
	//if(me.flags & COMMANDBUTTON_APPLY)
	//	saveAllCvars(me.parent);
	cmd("\n", me.onClickCommand, "\n");
	//if(me.flags & COMMANDBUTTON_REVERT)
	//	loadAllCvars(me.parent);
	if(me.flags & COMMANDBUTTON_CLOSE)
		m_goto(string_null);
}

void XonoticCommandButton_configureXonoticCommandButton(entity me, string theText, vector theColor, string theCommand, float theFlags, string theTooltip)
{
	me.configureXonoticButton(me, theText, theColor, theTooltip);
	me.onClickCommand = theCommand;
	me.flags = theFlags;
	me.onClick = XonoticCommandButton_Click;
	me.onClickEntity = me;
}
#endif
