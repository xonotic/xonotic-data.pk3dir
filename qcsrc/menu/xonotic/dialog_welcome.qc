#include "dialog_welcome.qh"

#include "image.qh"
#include "textlabel.qh"
#include "textbox.qh"
#include "radiobutton.qh"
#include "commandbutton.qh"
#include "slider.qh"

void welcomeDialog_resetStrings(entity me)
{
	if(me.serverinfo_name)
		strunzone(me.serverinfo_name);
	me.serverinfo_name = strzone(_("<NO NAME>"));

	if(me.serverinfo_MOTD)
		strunzone(me.serverinfo_MOTD);
	me.serverinfo_MOTD = strzone(_("<NO MOTD>"));
}

float XonoticWelcomeDialog_keyDown(entity me, float key, float ascii, float shift)
{
	switch(key)
	{
		case K_KP_ENTER:
		case K_ENTER:
		case K_SPACE:
			me.close(me);
			return true;
		default:
			return SUPER(XonoticWelcomeDialog).keyDown(me, key, ascii, shift);
	}
}

void XonoticWelcomeDialog_configureDialog(entity me)
{
	welcomeDialog_resetStrings(me);
	SUPER(XonoticWelcomeDialog).configureDialog(me);
	registercvar("_menu_welcome_dialog_available", "0", 0);
	cvar_set("_menu_welcome_dialog_available", "1");
}

void XonoticWelcomeDialog_destroy(entity me)
{
	cvar_set("_menu_welcome_dialog_available", "0");
}

void XonoticWelcomeDialog_readInputArgs(entity me, float argsbuf)
{
	int i = 0;
	string s;
	welcomeDialog_resetStrings(me);
	if(argsbuf >= 0)
	while((s = bufstr_get(argsbuf, i)) != "")
	{
		if(s == "name")
		{
			if(me.serverinfo_name)
				strunzone(me.serverinfo_name);
			me.serverinfo_name = strzone(bufstr_get(argsbuf, i + 1));
			++i;
		}
		else if(s == "motd")
		{
			if(me.serverinfo_MOTD)
				strunzone(me.serverinfo_MOTD);
			me.serverinfo_MOTD = strzone(bufstr_get(argsbuf, i + 1));
			++i;
		}
		++i;
	}
	//me.serverinfo_name_ent.setText(me.serverinfo_name_ent, me.serverinfo_name);
	me.serverinfo_MOTD_ent.setText(me.serverinfo_MOTD_ent, me.serverinfo_MOTD);
	me.frame.setText(me.frame, me.serverinfo_name);
}

void XonoticWelcomeDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, me.serverinfo_MOTD_ent = makeXonoticTextBox());
			me.serverinfo_MOTD_ent.align = 0.5;
			me.serverinfo_MOTD_ent.allowColors = true;
			me.serverinfo_MOTD_ent.escapedNewLines = true;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
			e.preferredFocusPriority = 1;
}
