#ifndef DIALOG_SETTINGS_H
#define DIALOG_SETTINGS_H
#include "dialog.qc"
CLASS(XonoticSettingsDialog, XonoticDialog)
	METHOD(XonoticSettingsDialog, fill, void(entity));
	ATTRIB(XonoticSettingsDialog, title, string, _("Settings"))
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
		me.TD(me, 1, 2, mc.makeTabButton(mc, _("Video"),   makeXonoticVideoSettingsTab()));
		me.TD(me, 1, 2, mc.makeTabButton(mc, _("Effects"), makeXonoticEffectsSettingsTab()));
		me.TD(me, 1, 2, mc.makeTabButton(mc, _("Audio"),   makeXonoticAudioSettingsTab()));
	me.TR(me);
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("Game"),   makeXonoticGameSettingsTab()));
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("Input"),   makeXonoticInputSettingsTab()));
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("User"),    makeXonoticUserSettingsTab()));
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("Misc"),    makeXonoticMiscSettingsTab()));
	me.gotoRC(me, 2.5, 0);
		me.TD(me, me.rows - 2.5, me.columns, mc);
}
#endif
