#ifndef DIALOG_SETTINGS_H
#define DIALOG_SETTINGS_H
#include "dialog.qc"
CLASS(XonoticSettingsDialog, XonoticDialog)
	METHOD(XonoticSettingsDialog, fill, void(entity));
	ATTRIB(XonoticSettingsDialog, title, string, _("Settings"))
	ATTRIB(XonoticSettingsDialog, tooltip, string, _("Change the game settings"))
	ATTRIB(XonoticSettingsDialog, color, vector, SKINCOLOR_DIALOG_SETTINGS)
	ATTRIB(XonoticSettingsDialog, intendedWidth, float, 0.96)
	ATTRIB(XonoticSettingsDialog, rows, float, 18)
	ATTRIB(XonoticSettingsDialog, columns, float, 6)
ENDCLASS(XonoticSettingsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticSettingsDialog_fill(entity me)
{
	entity mc;
	mc = makeXonoticTabController(me.rows - 2.5);
	me.TR(me);
		me.TD(me, 1, 2, mc.makeTabButton_T(mc, _("Video"),   makeXonoticVideoSettingsTab(), _("Video settings")));
		me.TD(me, 1, 2, mc.makeTabButton_T(mc, _("Effects"), makeXonoticEffectsSettingsTab(), _("Effects settings")));
		me.TD(me, 1, 2, mc.makeTabButton_T(mc, _("Audio"),   makeXonoticAudioSettingsTab(), _("Audio settings")));
	me.TR(me);
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("Game"),    NEW(XonoticGameSettingsTab)));
		me.TD(me, 1, 1.5, mc.makeTabButton_T(mc, _("Input"),   makeXonoticInputSettingsTab(), _("Input settings")));
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("User"),    makeXonoticUserSettingsTab()));
		me.TD(me, 1, 1.5, mc.makeTabButton_T(mc, _("Misc"),    makeXonoticMiscSettingsTab(), _("Misc settings")));
	me.gotoRC(me, 2.5, 0);
		me.TD(me, me.rows - 2.5, me.columns, mc);
}
#endif
