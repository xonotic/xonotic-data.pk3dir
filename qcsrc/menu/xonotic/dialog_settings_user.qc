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

	entity userApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"menu_cmd sync;"
		, COMMANDBUTTON_APPLY);
		userApplyButton.disableOnClick = true;
/*	FIXME: It would be nice to have this button apply the skin and language settings
 *	but there's only 1 onClickEntity */

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

	me.gotoRC(me, 11, 3.0625); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 0.75, e = makeXonoticTextLabel(0, _("Font/UI size:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("menu_vid_scale"));
			e.addValue(e, ZCTX(_("SZ^Unreadable")), "-1");
			e.addValue(e, ZCTX(_("SZ^Tiny")), "-0.75");
			e.addValue(e, ZCTX(_("SZ^Little")), "-0.5");
			e.addValue(e, ZCTX(_("SZ^Small")), "-0.25");
			e.addValue(e, ZCTX(_("SZ^Medium")), "0");
			e.addValue(e, ZCTX(_("SZ^Large")), "0.25");
			e.addValue(e, ZCTX(_("SZ^Huge")), "0.5");
			e.addValue(e, ZCTX(_("SZ^Gigantic")), "0.75");
			e.addValue(e, ZCTX(_("SZ^Colossal")), "1");
			e.configureXonoticTextSliderValues(e);
			e.applyButton = userApplyButton;
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticTextLabel(0, _("Menu tooltips:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("menu_tooltips",
			_("Menu tooltips: disabled, standard or advanced (also shows cvar or console command bound to the menu item)")));
			e.addValue(e, ZCTX(_("TLTIP^Disabled")), "0");
			e.addValue(e, ZCTX(_("TLTIP^Standard")), "1");
			e.addValue(e, ZCTX(_("TLTIP^Advanced")), "2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.5625);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "showdate", _("Show date")));
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "showtime", _("Show time")));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, userApplyButton);
}
