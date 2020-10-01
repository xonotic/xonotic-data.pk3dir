#include "dialog_settings_misc.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "textslider.qh"
#include "slider.qh"
#include "checkbox.qh"
#include "button.qh"
#include "mainwindow.qh"

#define ADDVALUE_FPS(i) e.addValue(e, strzone(sprintf(_("%d fps"), i)), #i)
#define ADDVALUE_SPEED_KB(i) e.addValue(e, strzone(sprintf(_("%d KB/s"), i)), #i)
#define ADDVALUE_SPEED_MB(i, j) e.addValue(e, strzone(sprintf(_("%d MB/s"), i)), #j)
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

	entity miscApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"menu_restart;"
		, COMMANDBUTTON_APPLY);
	miscApplyButton.disableOnClick = true;

	me.TR(me);
		me.TD(me, 1, 3.25, e = makeXonoticHeaderLabel(_("Network")));
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeXonoticTextLabel(0, _("UDP bandwidth:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("_cl_rate",
			_("Speed limit for the game protocol")));
			e.addValue(e, _("56k"), "4000");
			e.addValue(e, _("ISDN"), "7000");
			e.addValue(e, _("Slow ADSL"), "20000");
			e.addValue(e, _("Fast ADSL"), "40000");
			e.addValue(e, _("Broadband"), "66666");
			e.configureXonoticTextSliderValues(e);
	if(cvar_type("crypto_aeslevel") & CVAR_TYPEFLAG_ENGINE)
	{
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeXonoticTextLabel(0, _("UDP encryption:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("crypto_aeslevel",
			_("AES encryption of the game protocol")));
			e.addValue(e, _("Disabled"), "0");
			e.addValue(e, _("Supported"), "1");
			e.addValue(e, _("Requested"), "2");
			e.addValue(e, _("Required"), "3");
			e.configureXonoticTextSliderValues(e);
	}
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "cl_netrepeatinput", _("Packet loss compensation"),
			_("Smooths movement during packet loss, but doubles the amount of data sent")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_movement_errorcompensation", _("Movement error compensation")));
		setDependent(e, "cl_movement", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "shownetgraph", _("Show net graph"),
			_("Show graph of UDP packets, may reduce FPS")));
	if(cvar("developer") > 0)
	{
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeXonoticTextLabel(0, _("Local latency:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1000, 25, "cl_netlocalping"));
	}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeXonoticTextLabel(0, _("HTTP Download speed:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("cl_curl_maxspeed",
			_("Speed limit of HTTP file downloads")));
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
	me.TR(me);
		me.TD(me, 1, 1.25, e = makeXonoticTextLabel(0, _("Simultaneous downloads:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 5, 1, "cl_curl_maxdownloads"));
	me.TR(me);


	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2.5, e = makeXonoticHeaderLabel(_("Framerate")));
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticTextLabel(0, _("Maximum:")));
		me.TD(me, 1, 1.75, e = makeXonoticTextSlider("cl_maxfps"));
			ADDVALUE_FPS(62.5);
			ADDVALUE_FPS(100);
			ADDVALUE_FPS(125);
			ADDVALUE_FPS(150);
			ADDVALUE_FPS(200);
			ADDVALUE_FPS(250);
			ADDVALUE_FPS(500);
			e.addValue(e, ZCTX(_("MAXFPS^Unlimited")), "0");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticTextLabel(0, _("Target:")));
		me.TD(me, 1, 1.75, e = makeXonoticTextSlider("cl_minfps"));
			e.addValue(e, ZCTX(_("TRGT^Disabled")), "0");
			ADDVALUE_FPS(30);
			ADDVALUE_FPS(60);
			ADDVALUE_FPS(100);
			ADDVALUE_FPS(125);
			ADDVALUE_FPS(150);
			ADDVALUE_FPS(200);
			ADDVALUE_FPS(250);
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticTextLabel(0, _("Idle limit:")));
		me.TD(me, 1, 1.75, e = makeXonoticTextSlider("cl_maxidlefps"));
			ADDVALUE_FPS(10);
			ADDVALUE_FPS(20);
			ADDVALUE_FPS(30);
			ADDVALUE_FPS(60);
			e.addValue(e, ZCTX(_("IDLFPS^Unlimited")), "0");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox_T(0, "showfps", _("Show frames per second"),
			_("Show your rendered frames per second")));


	me.gotoRC(me, 8, 3.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2.5, e = makeXonoticHeaderLabel(_("Other")));
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2, e = makeXonoticButton_T(_("Advanced settings..."), '0 0 0',
			_("Advanced settings where you can tweak every single variable of the game")));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.cvarsDialog;
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Factory reset"), '0 0 0'));
			e.onClick = DialogOpenButton_Click;
			e.onClickEntity = main.resetDialog;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "developer", _("Enable developer mode")));
			e.applyButton = miscApplyButton;

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, miscApplyButton);
}
#undef ADDVALUE_FPS
