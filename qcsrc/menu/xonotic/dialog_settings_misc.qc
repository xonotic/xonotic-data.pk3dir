#include "dialog_settings_misc.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "textslider.qh"
#include "slider.qh"
#include "checkbox.qh"
#include "button.qh"
#include "mainwindow.qh"
#include "commandbutton.qh"

#define ADDVALUE_FPS(i) e.addValue(e, strzone(sprintf(_("%d fps"), i)), #i)
#define ADDVALUE_SPEED_KB(i) e.addValue(e, strzone(sprintf(_("%d KiB/s"), i)), #i)
#define ADDVALUE_SPEED_MB(i, j) e.addValue(e, strzone(sprintf(_("%d MiB/s"), i)), #j)
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

	entity miscApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "menu_restart;", COMMANDBUTTON_APPLY);
	miscApplyButton.disableOnClick = true;

	me.TR(me);
		me.TD(me, 1, 3.25, e = makeXonoticHeaderLabel(_("Network")));
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
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Bandwidth limit:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("_cl_rate",
			_("Specify your network speed")));
			e.addValue(e, _("Slow ADSL"), "20000");
			e.addValue(e, _("Fast ADSL"), "40000");
			e.addValue(e, _("Broadband"), "66666");
			e.configureXonoticTextSliderValues(e);
	if(cvar("developer") > 0)
	{
		me.TR(me);
		me.TR(me);
			me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Local latency:")));
			me.TD(me, 1, 2, e = makeXonoticSlider(0, 1000, 25, "cl_netlocalping"));
	}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3.25, e = makeXonoticHeaderLabel(_("HTTP downloads")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Simultaneous:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 5, 1, "cl_curl_maxdownloads",
			_("Maximum number of concurrent HTTP downloads")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Bandwidth limit:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_curl_maxspeed"));
		ADDVALUE_SPEED_KB(64);
		ADDVALUE_SPEED_KB(128);
		ADDVALUE_SPEED_KB(256);
		ADDVALUE_SPEED_KB(512);
		ADDVALUE_SPEED_MB(1, 1024);
		ADDVALUE_SPEED_MB(2, 2048);
		ADDVALUE_SPEED_MB(4, 4096);
		ADDVALUE_SPEED_MB(8, 8192);
		e.addValue(e, strzone(_("Unlimited")), "0");
		e.configureXonoticTextSliderValues(e);

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Framerate")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "showfps", _("Show frames per second"),
			_("Show your rendered frames per second")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Maximum:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_maxfps"));
			ADDVALUE_FPS(60);
			ADDVALUE_FPS(100);
			ADDVALUE_FPS(125);
			ADDVALUE_FPS(150);
			ADDVALUE_FPS(200);
			ADDVALUE_FPS(250);
			ADDVALUE_FPS(400);
			e.addValue(e, ZCTX(_("MAXFPS^Unlimited")), "0");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Target:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_minfps"));
			e.addValue(e, ZCTX(_("TRGT^Disabled")), "0");
			ADDVALUE_FPS(40);
			ADDVALUE_FPS(60);
			ADDVALUE_FPS(100);
			ADDVALUE_FPS(125);
			ADDVALUE_FPS(150);
			ADDVALUE_FPS(200);
			ADDVALUE_FPS(250);
			ADDVALUE_FPS(400);
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Idle limit:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_maxidlefps"));
			ADDVALUE_FPS(10);
			ADDVALUE_FPS(20);
			ADDVALUE_FPS(30);
			ADDVALUE_FPS(60);
			e.addValue(e, ZCTX(_("IDLFPS^Unlimited")), "0");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Other")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Menu tooltips:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("menu_tooltips",
			_("Menu tooltips: disabled, standard or advanced (also shows cvar or console command bound to the menu item)")));
			e.addValue(e, ZCTX(_("TLTIP^Disabled")), "0");
			e.addValue(e, ZCTX(_("TLTIP^Standard")), "1");
			e.addValue(e, ZCTX(_("TLTIP^Advanced")), "2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "showtime", _("Show current date and time"),
			_("Show current date and time of day, useful on screenshots")));
			makeMulti(e, "showdate");
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "developer", _("Enable developer mode")));
			e.applyButton = miscApplyButton;

	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton_T(_("Advanced settings..."), '0 0 0',
			_("Advanced settings where you can tweak every single variable of the game")));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.cvarsDialog;
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Factory reset"), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.resetDialog;

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, miscApplyButton);
}
#undef ADDVALUE_FPS
