#ifndef DIALOG_SETTINGS_GAME_H
#define DIALOG_SETTINGS_GAME_H
#include "tab.qc"
CLASS(XonoticGameSettingsTab, XonoticTab)
	METHOD(XonoticGameSettingsTab, fill, void(entity));
	ATTRIB(XonoticGameSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticGameSettingsTab, rows, float, 15.5)
	ATTRIB(XonoticGameSettingsTab, columns, float, 6.5)
ENDCLASS(XonoticGameSettingsTab)
entity makeXonoticGameSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticGameSettingsTab()
{
	entity me;
	me = NEW(XonoticGameSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameSettingsTab_fill(entity me)
{
	entity mc;
	mc = makeXonoticTabController(me.rows - 2.5);

	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("View"),           makeXonoticGameViewSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Crosshair"),      makeXonoticGameCrosshairSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("HUD"),            makeXonoticGameHUDSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Messages"),       makeXonoticGameMessageSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Weapons"),        makeXonoticGameWeaponsSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, _("Models"),         makeXonoticGameModelSettingsTab()));

	me.gotoRC(me, 1.5, 0);
		me.TD(me, me.rows - 1.5, me.columns, mc);

	/*

	  makeXonoticGameViewSettingsTab()));
	  makeXonoticGameGeneralSettingsTab()));
	makeXonoticGameCrosshairSettingsTab()));

	       makeXonoticGameWeaponSettingsTab()));
	l"),   makeXonoticGamePlayermodelSettingsTab()));
	       makeXonoticGameHUDSettingsTab()));
	on"),  makeXonoticGameNotificationSettingsTab()));


	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_gentle", _("Disable gore effects and harsh language"))); // also set sv_gentle
	*/
}
#endif
