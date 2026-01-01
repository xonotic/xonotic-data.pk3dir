#include "dialog_settings_misc.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "checkbox.qh"
#include "button.qh"
#include "mainwindow.qh"
#include "commandbutton.qh"

entity makeXonoticMiscSettingsTab()
{
	entity me;
	me = NEW(XonoticMiscSettingsTab);
	me.configureDialog(me);
	return me;
}
void XonoticMiscSettingsTab_fill(entity me)
{
	entity e;
	//entity sk;

	entity miscApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "menu_restart", COMMANDBUTTON_APPLY);
	miscApplyButton.disableOnClick = true;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Network")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "shownetgraph", _("Show netgraph"),
			_("Show a graph of packet sizes and other information")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "cl_netrepeatinput", _("Packet loss compensation"),
			_("Each packet includes a copy of the previous message")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_movement_errorcompensation", _("Movement prediction error compensation")));
			setDependent(e, "cl_movement", 1, 1);
	me.TR(me);
	if(cvar_type("crypto_aeslevel") & CVAR_TYPEFLAG_ENGINE)
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 1, "crypto_aeslevel", _("Use encryption (AES) when available")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("HTTP downloads")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Simultaneous:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 5, 1, "cl_curl_maxdownloads",
			_("Maximum number of concurrent HTTP downloads")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Bandwidth limit:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_curl_maxspeed"));
			#define ADDVALUE_SPEED_KB(i)    e.addText(e, strzone(sprintf(_("%d KiB/s"), i)), i)
			#define ADDVALUE_SPEED_MB(i, j) e.addText(e, strzone(sprintf(_("%d MiB/s"), i)), j)
			ADDVALUE_SPEED_KB(64);
			ADDVALUE_SPEED_KB(128);
			ADDVALUE_SPEED_KB(256);
			ADDVALUE_SPEED_KB(512);
			ADDVALUE_SPEED_MB(1, 1024);
			ADDVALUE_SPEED_MB(2, 2048);
			ADDVALUE_SPEED_MB(4, 4096);
			ADDVALUE_SPEED_MB(8, 8192);
			#undef ADDVALUE_SPEED_KB
			#undef ADDVALUE_SPEED_MB
		e.addText(e, strzone(_("Unlimited")), 0);
		e.configureXonoticMixedSliderValues(e);

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Other")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Menu tooltips:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("menu_tooltips",
			_("Menu tooltips: disabled, standard or advanced (also shows cvar or console command bound to the menu item)")));
			e.setValueSpace(e, e.valueSpace * 1.2);
			e.addText(e, ZCTX(_("TLTIP^Disabled")), 0);
			e.addText(e, ZCTX(_("TLTIP^Standard")), 1);
			e.addText(e, ZCTX(_("TLTIP^Advanced")), 2);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Menu animations:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("menu_animations",
			_("How fast animations in the menu occur")));
			e.formatString = "S";
			e.setValueSpace(e, e.valueSpace * 1.2);
			e.addText(e, ZCTX(_("Disabled")), 0);
			e.addRange(e, 0.05, 0.5, 0.05);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "r_textshadow", _("Text shadow"),
			_("Draw a shadow behind all text to improve readability")));
			e.applyButton = miscApplyButton;
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "showtime", _("Show current date and time"),
			_("Show current date and time of day, useful on screenshots")));
			makeMulti(e, "showdate");
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton_T(_("Advanced settings..."), '0 0 0',
			_("Advanced settings where you can tweak every single variable of the game")));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.cvarsDialog;
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Factory reset"), '1 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.resetDialog;

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, miscApplyButton);
}
