#include "dialog_settings_game_hudconfirm.qh"

#include "textlabel.qh"
#include "button.qh"

void HUDSetup_Start(entity me, entity btn)
{
	if (!(gamestatus & (GAME_CONNECTED | GAME_ISSERVER)))
		localcmd("map _hudsetup\n");
	else
		localcmd("togglemenu 0\n");

	localcmd("_hud_configure 1\n");
}

void XonoticHUDConfirmDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("In order for the HUD editor to show, you must first be in game.")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Do you wish to start a local game to set up the HUD?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton(_("Yes"), '1 0 0'));
			e.onClick = HUDSetup_Start;
			e.onClickEntity = me;
		me.TD(me, 1, 1, e = makeXonoticButton(_("No"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
