#ifdef INTERFACE
CLASS(XonoticDemoStartConfirmDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticDemoStartConfirmDialog, fill, void(entity))
	ATTRIB(XonoticDemoStartConfirmDialog, title, string, _("Disconnect"))
	ATTRIB(XonoticDemoStartConfirmDialog, color, vector, SKINCOLOR_DIALOG_HUDCONFIRM)
	ATTRIB(XonoticDemoStartConfirmDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticDemoStartConfirmDialog, rows, float, 4)
	ATTRIB(XonoticDemoStartConfirmDialog, columns, float, 2)
ENDCLASS(XonoticDemoStartConfirmDialog)
#endif

#ifdef IMPLEMENTATION
void Handle_StartDemo_Click(entity unused, entity me) { demolist.startDemo(demolist); }
void XonoticDemoStartConfirmDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Playing a demo will disconnect you from the current match.")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Do you really wish to disconnect now?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton(ZCTX(_("DMCNFRM^Yes")), '1 0 0'));
			e.onClick = Handle_StartDemo_Click;
			e.onClickEntity = demolist;
		me.TD(me, 1, 1, e = makeXonoticButton(ZCTX(_("DMCNFRM^No")), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
