#include "dialog_credits.qh"

#include "credits.qh"
#include "button.qh"
#include "../item/dialog.qh"

void XonoticCreditsDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, me.rows - 1, me.columns, me.creditsList = makeXonoticCreditsList());
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
void XonoticCreditsDialog_focusEnter(entity me)
{
	me.creditsList.scrolling = time + 1;
}
