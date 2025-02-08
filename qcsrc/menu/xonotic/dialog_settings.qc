#include "dialog_settings.qh"

#include "dialog_settings_video.qh"
#include "dialog_settings_effects.qh"
#include "dialog_settings_audio.qh"
#include "dialog_settings_game.qh"
#include "dialog_settings_input.qh"
#include "dialog_settings_user.qh"
#include "dialog_settings_misc.qh"

#include "tabcontroller.qh"

void XonoticSettingsDialog_fill(entity me)
{
	entity mc;
	mc = makeXonoticTabController(me.rows - 2.5);
	me.TR(me);
		me.TD(me, 1, 2, mc.makeTabButton(mc, _("Video"),    makeXonoticVideoSettingsTab()));
		me.TD(me, 1, 2, mc.makeTabButton(mc, _("Effects"),  makeXonoticEffectsSettingsTab()));
		me.TD(me, 1, 2, mc.makeTabButton(mc, _("Audio"),    makeXonoticAudioSettingsTab()));
	me.TR(me);
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("Game"),   makeXonoticGameSettingsTab()));
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("Input"),  makeXonoticInputSettingsTab()));
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("User"),   makeXonoticUserSettingsTab()));
		me.TD(me, 1, 1.5, mc.makeTabButton(mc, _("Misc"),   makeXonoticMiscSettingsTab()));
	me.gotoRC(me, 2.5, 0);
		me.TD(me, me.rows - 2.5, me.columns, mc);
}
