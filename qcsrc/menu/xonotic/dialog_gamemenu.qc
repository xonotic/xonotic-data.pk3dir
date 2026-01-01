#include "dialog_gamemenu.qh"

#include "textlabel.qh"
#include "commandbutton.qh"
#include "leavematchbutton.qh"
#include "button.qh"

void XonoticGameMenuDialog_destroy(entity me)
{
	cvar_set("_menu_gamemenu_dialog_available", "0");
}

void XonoticGameMenuDialog_draw(entity me)
{
	entity btn = me.joinButton;
	if(cvar("g_campaign"))
	{
		if (btn.toString(btn) == _("Join!"))
		{
			btn.setText(btn, _("Restart level"));
			btn.onClickCommand = "resetmatch";
		}
	}
	else
	{
		if (btn.toString(btn) == _("Restart level"))
		{
			btn.setText(btn, _("Join!"));
			btn.onClickCommand = "join";
		}
	}
	SUPER(XonoticGameMenuDialog).draw(me);
}

void XonoticGameMenuDialog_fill(entity me)
{
	registercvar("_menu_gamemenu_dialog_available", "0", 0);
	cvar_set("_menu_gamemenu_dialog_available", "1");

	entity e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Main menu"), '0 0 0', "menu_cmd nexposee", 0));
		// NOTE these buttons use directmenu so that the menu will be hidden when these dialogs are closed
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.8, e = makeXonoticCommandButton(_("Servers"), '0 0 0', "menu_cmd directmenu servers", 0));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.8, e = makeXonoticCommandButton(_("Profile"), '0 0 0', "menu_cmd directmenu profile", 0));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.8, e = makeXonoticCommandButton(_("Settings"), '0 0 0', "menu_cmd directmenu settings", 0));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.8, e = makeXonoticCommandButton(_("Input"), '0 0 0', "menu_cmd directmenu inputsettings", 0));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.8, e = makeXonoticCommandButton(_("Guide"), '0 0 0', "menu_cmd directmenu guide", 0));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Quick menu"), '0 0 0', "quickmenu", COMMANDBUTTON_CLOSE));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = me.joinButton = makeXonoticCommandButton(_("Join!"), '0 0 0', "join", COMMANDBUTTON_CLOSE));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Spectate"), '0 0 0', "spec", COMMANDBUTTON_CLOSE));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticLeaveMatchButton('0 0 0', COMMANDBUTTON_CLOSE));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Quit"), '1 0 0', "menu_showquitdialog", 0));
}
