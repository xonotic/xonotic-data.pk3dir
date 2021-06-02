#include "dialog_quit.qh"

#include "textlabel.qh"
#include "commandbutton.qh"
#include "quitbutton.qh"
#include "button.qh"

void XonoticQuitDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 1, me.disconnectButton = makeXonoticQuitButton('0 0 0', COMMANDBUTTON_CLOSE));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Quit Xonotic"), '1 0 0', "echo ]quit; quit", 0));
		me.TD(me, 1, 1, e = makeXonoticButton(_("Cancel"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
