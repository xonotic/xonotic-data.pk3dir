#ifdef INTERFACE
CLASS(XonoticDemoConfirmDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticDemoConfirmDialog, fill, void(entity))
	ATTRIB(XonoticDemoConfirmDialog, title, string, _("Disconnect"))
	ATTRIB(XonoticDemoConfirmDialog, color, vector, SKINCOLOR_DIALOG_HUDCONFIRM)
	ATTRIB(XonoticDemoConfirmDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticDemoConfirmDialog, rows, float, 4)
	ATTRIB(XonoticDemoConfirmDialog, columns, float, 2)
ENDCLASS(XonoticDemoConfirmDialog)
#endif

#ifdef IMPLEMENTATION
void Demo_Confirm(entity me, entity btn)
{
	if not(gamestatus & (GAME_CONNECTED | GAME_ISSERVER))
		//me.onClick = TimeDemo_Click;
		me.onClick = StartDemo_Click;
	else
		localcmd("togglemenu 0\n");
}

void XonoticDemoConfirmDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Playing a demo will disconnect you from the current match.")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Do you really wish to disconnect now?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton(ZCTX(_("DMCNFRM^Yes")), '1 0 0'));
			e.onClick = Demo_Confirm;
			e.onClickEntity = me;
		me.TD(me, 1, 1, e = makeXonoticButton(ZCTX(_("DMCNFRM^No")), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
