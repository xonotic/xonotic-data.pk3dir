#include "dialog_settings_user.qh"

#include "commandbutton.qh"
#include "textlabel.qh"
#include "languagelist.qh"
#include "skinlist.qh"
#include "checkbox.qh"

entity makeXonoticUserSettingsTab()
{
	entity me;
	me = NEW(XonoticUserSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticUserSettingsTab_fill(entity me)
{
	entity e, sk;

	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticHeaderLabel(_("Menu Skin")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, me.rows - 3.5, 2.5, sk = makeXonoticSkinList());
	me.gotoRC(me, me.rows - 2.5, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticButton(_("Set skin"), '0 0 0'));
			e.onClick = SetSkin_Click;
			e.onClickEntity = sk;

	/* AFTER 0.6 RELEASE TODO: Add a listbox which has fonts too, this way user can select the font they want.
	me.gotoRC(me, 0, 2.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Text language:")));
	me.TR(me);
		me.TD(me, 6, 1, sk = makeXonoticLanguageList());
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton(_("Set language"), '0 0 0'));
			e.onClick = SetLanguage_Click;
			e.onClickEntity = sk;

	me.gotoRC(me, 0, 3.3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.5, e = makeXonoticTextLabel(0, _("Font:")));
	me.TR(me);
		me.TD(me, 2, 1.5, sk = makeXonoticLanguageList());
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticButton(_("Set font"), '0 0 0'));
			e.onClick = SetLanguage_Click;
			e.onClickEntity = sk;*/

	me.gotoRC(me, 0, 3.65); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.7, e = makeXonoticHeaderLabel(_("Text Language")));
	me.TR(me);
		me.TD(me, 8, 1.7, sk = makeXonoticLanguageList());

	me.gotoRC(me, 9, 3.65); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.7, e = makeXonoticButton(_("Set language"), '0 0 0'));
			e.onClick = SetLanguage_Click;
			e.onClickEntity = sk;

	me.gotoRC(me, 11, 3.25); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox_T(0, "cl_gentle", _("Disable gore effects and harsh language"),
			_("Replace blood and gibs with content that does not have any gore effects")));
			e.sendCvars = true;
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.3, e = makeXonoticCheckBox(0, "cl_gentle_gibs", _("Just the gore")));
			makeMulti(e, "cl_gentle_damage");
			setDependent(e, "cl_gentle", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.3, e = makeXonoticCheckBox(0, "cl_gentle_messages", _("Just the language")));
			setDependent(e, "cl_gentle", 0, 0);
}
