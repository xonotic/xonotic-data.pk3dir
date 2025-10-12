#include "dialog_media_demo_timeconfirm.qh"

#include "demolist.qh"
#include "textlabel.qh"
#include "button.qh"

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
