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
		me.TD(me, me.rows - 2.5, 2.5, sk = makeXonoticSkinList());
	me.gotoRC(me, me.rows - 1.5, 0.25);
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
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "cl_gentle", _("Disable gore effects and harsh language")));

	//me.TR(me);
	//	me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Menu tooltips:")));
	//	me.TD(me, 1, 2, e = makeXonoticTextSlider("menu_tooltips"));
	//		e.addValue(e, ZCTX(_("TLTIP^Disabled")), "0");
	//		e.addValue(e, ZCTX(_("TLTIP^Standard")), "1");
	//		e.addValue(e, ZCTX(_("TLTIP^Advanced")), "2");
	//		e.configureXonoticTextSliderValues(e);
	//me.TR(me);
	//	me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_allow_uidtracking", _("Allow player statistics to track your client"))); // TODO: move to profile tab
	//me.TR(me);
	//	me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "cl_allow_uid2name", _("Allow player statistics to use your nickname")));
	//	setDependent(e, "cl_allow_uidtracking", 1, 1);

	//me.gotoRC(me, me.rows - 1, 2.6);
	//	me.TD(me, 1, 2, makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "sendcvar cl_gentle; sendcvar cl_allow_uidtracking; sendcvar cl_allow_uid2name;", COMMANDBUTTON_APPLY));

}
#endif
