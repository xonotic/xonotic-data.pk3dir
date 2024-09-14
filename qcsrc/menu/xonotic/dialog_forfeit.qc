#include "dialog_forfeit.qh"

#include "button.qh"
#include "commandbutton.qh"
#include "textlabel.qh"

void XonoticForfeitDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Are you sure you want to observe and quit current match?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Yes"), '1 0 0', "spec \"\" FORFEIT", COMMANDBUTTON_CLOSE));
		me.TD(me, 1, 1, e = makeXonoticButton(_("No"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
