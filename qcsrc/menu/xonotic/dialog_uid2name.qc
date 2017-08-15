#include "dialog_uid2name.qh"

#include "textlabel.qh"
#include "commandbutton.qh"

void XonoticUid2NameDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Allow player statistics to use your nickname?")));
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Answering \"No\" you will appear as \"Anonymous player\"")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Yes"), '0 0 0', "vyes; setreport cl_allow_uid2name 1", COMMANDBUTTON_CLOSE));
			e.preferredFocusPriority = 1;
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("No"), '0 0 0', "vno; setreport cl_allow_uid2name 0", COMMANDBUTTON_CLOSE));
}
