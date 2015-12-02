#ifndef DIALOG_MULTIPLAYER_MEDIA_DEMO_TIMECONFIRM_H
#define DIALOG_MULTIPLAYER_MEDIA_DEMO_TIMECONFIRM_H
#include "dialog.qc"
CLASS(XonoticDemoTimeConfirmDialog, XonoticDialog)
	METHOD(XonoticDemoTimeConfirmDialog, fill, void(entity));
	ATTRIB(XonoticDemoTimeConfirmDialog, title, string, _("Disconnect"))
	ATTRIB(XonoticDemoTimeConfirmDialog, color, vector, SKINCOLOR_DIALOG_HUDCONFIRM)
	ATTRIB(XonoticDemoTimeConfirmDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticDemoTimeConfirmDialog, rows, float, 4)
	ATTRIB(XonoticDemoTimeConfirmDialog, columns, float, 2)
ENDCLASS(XonoticDemoTimeConfirmDialog)
#endif

#ifdef IMPLEMENTATION
void Handle_TimeDemo_Click(entity unused, entity unused) { demolist.timeDemo(demolist); }
void XonoticDemoTimeConfirmDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Timing a demo will disconnect you from the current match.")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0.5, _("Do you really wish to disconnect now?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton(_("Yes"), '1 0 0'));
			e.onClick = Handle_TimeDemo_Click;
			e.onClickEntity = demolist;
		me.TD(me, 1, 1, e = makeXonoticButton(_("No"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
