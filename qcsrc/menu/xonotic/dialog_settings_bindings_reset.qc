#include "dialog_settings_bindings_reset.qh"

#include "textlabel.qh"
#include "button.qh"
#include "keybinder.qh"

void XonoticBindingsResetDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Are you sure you want to reset all key bindings?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton(_("Yes"), '1 0 0'));
			e.onClick = KeyBinder_Bind_Reset_All;
			e.onClickEntity = me;
		me.TD(me, 1, 1, e = makeXonoticButton(_("No"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
