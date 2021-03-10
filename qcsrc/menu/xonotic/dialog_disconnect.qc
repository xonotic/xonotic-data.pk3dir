#include "dialog_disconnect.qh"

#include "textlabel.qh"
#include "button.qh"

void Disconnect_Click(entity btn, entity me)
{
	localcmd("disconnect\n");
	Dialog_Close(btn, me);
}

void XonoticDisconnectDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Are you sure to disconnect from server?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton_T(_("Yes"), '1 0 0', _("I would disconnect from server...")));
			e.onClick = Disconnect_Click;
			e.onClickEntity = me;
		me.TD(me, 1, 1, e = makeXonoticButton_T(_("No"), '0 1 0', _("I would play more!")));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
