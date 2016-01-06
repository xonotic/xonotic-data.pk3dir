#ifndef DIALOG_SETTINGS_USER_H
#define DIALOG_SETTINGS_USER_H
#include "tab.qc"
CLASS(XonoticUserSettingsTab, XonoticTab)
	METHOD(XonoticUserSettingsTab, fill, void(entity));
	ATTRIB(XonoticUserSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticUserSettingsTab, rows, float, 15.5)
	ATTRIB(XonoticUserSettingsTab, columns, float, 6)
ENDCLASS(XonoticUserSettingsTab)
entity makeXonoticUserSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticUserSettingsTab()
{
	entity me;
	me = NEW(XonoticUserSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticUserSettingsTab_fill(entity me)
{
	entity e;
	entity sk;

	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticHeaderLabel(_("Menu Skins")));
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

	me.gotoRC(me, 0, 3.75); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.5, e = makeXonoticHeaderLabel(_("Text Language")));
	me.TR(me);
		me.TD(me, 8, 1.5, sk = makeXonoticLanguageList());

	me.gotoRC(me, 9, 3.75); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.5, e = makeXonoticButton(_("Set language"), '0 0 0'));
			e.onClick = SetLanguage_Click;
			e.onClickEntity = sk;

	me.gotoRC(me, 11.5, 3.25); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox_T(0, "cl_gentle", _("Disable gore effects and harsh language"),
			_("Replace blood and gibs with content that does not have any gore effects (default: disabled)")));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, 6, makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "sendcvar cl_gentle;", COMMANDBUTTON_APPLY));

}
#endif
