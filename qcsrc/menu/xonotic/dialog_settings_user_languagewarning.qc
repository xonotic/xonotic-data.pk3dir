#include "dialog_settings_user_languagewarning.qh"

#include "textlabel.qh"
#include "commandbutton.qh"

void XonoticLanguageWarningDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 2, 4, e = makeXonoticTextLabel(0,
			_("While connected language changes will be applied only to the menu, full language changes will take effect starting from the next game")));
			e.allowWrap = true;
			e.allowWrap_spacing = 0.5;
	me.TR(me);
	me.TR(me);
	me.TR(me);
		// reconnect command doesn't work properly, otherwise it would replace disconnect
		me.TD(me, 1, 2, e = makeXonoticCommandButton(_("Disconnect now"), '0 0 0', "disconnect", 0));
		me.TD(me, 1, 2, e = makeXonoticCommandButton(_("Switch language"), '0 0 0', "prvm_language \"$_menu_prvm_language\"; menu_restart; menu_cmd languageselect", 0));
}
