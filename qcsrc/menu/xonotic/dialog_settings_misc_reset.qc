#include "dialog_settings_misc_reset.qh"

#include "textlabel.qh"
#include "commandbutton.qh"
#include "button.qh"

void XonoticResetDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Are you sure you want to reset all settings?")));
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("This will create a backup config in your data directory")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCommandButton(_("Yes"), '1 0 0', "saveconfig backup.cfg; exec default.cfg", 0));
		me.TD(me, 1, 1, e = makeXonoticButton(_("No"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
