#include "dialog_settings_game_hud.qh"

#include "../item/modalcontroller.qh"
#include "button.qh"
#include "checkbox.qh"
#include "mainwindow.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "slider_sbfadetime.qh"
#include "textlabel.qh"

void HUDSetup_Check_Gamestatus(entity me, entity btn)
{
	if (!(gamestatus & (GAME_CONNECTED | GAME_ISSERVER))) // we're not in a match, ask the player if they want to start one anyway
		DialogOpenButton_Click(me, main.hudconfirmDialog);
	else // already in a match, lets just cut to the point and open up the hud editor directly
		HUDSetup_Start(me, btn);
}
void XonoticGameHUDSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameHUDSettingsTab()
{
	entity me = NEW(XonoticGameHUDSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameHUDSettingsTab_fill(entity me)
{
	entity e;

	// TODO:
	// threshold: hud_damage_pain_threshold_lower_health
	// scoreboard_alpha*

	me.gotoRC(me, 0, (me.columns - 3) * 0.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Scoreboard")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Opacity:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0.1, 1, 0.1, "hud_panel_scoreboard_bg_alpha"));
			e.formatString = "%";
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Fading speed:")));
		me.TD(me, 1, 2, e = makeXonoticScoreboardFadeTimeSlider());
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_panel_scoreboard_table_highlight", _("Enable rows / columns highlighting")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_panel_scoreboard_accuracy", _("Show accuracy underneath scoreboard")));
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Show team sizes:")));
		me.TD(me, 1, 1.8, e = makeXonoticMixedSlider_T("hud_panel_scoreboard_team_size_position", _("Team size position: Off=do not show; Left=on the left side of the scoreboard and move team scores to the right; Right=on the right of the scoreboard")));
			e.setValueSpace(e, e.valueSpace * (10/9));
			e.addText(e, _("Left"),  1);
			e.addText(e, _("Off"),   0);
			e.addText(e, _("Right"), 2);
			e.configureXonoticMixedSliderValues(e);

#if 0
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Damage")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Overlay:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.05, "hud_damage"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Factor:")));
			setDependentNOT(e, "hud_damage", 0);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.025, 0.1, 0.025, "hud_damage_factor"));
			setDependentNOT(e, "hud_damage", 0);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Fade rate:")));
			setDependentNOT(e, "hud_damage", 0);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.25, 1, 0.05, "hud_damage_fade_rate"));
			setDependentNOT(e, "hud_damage", 0);
	me.TR(me);
#endif

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Other")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Speed unit:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("hud_speed_unit"));
			e.addText(e, _("qu/s"),  1);
			e.addText(e, _("m/s"),   2);
			e.addText(e, _("km/h"),  3);
			e.addText(e, _("mph"),   4);
			e.addText(e, _("knots"), 5);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Damage overlay:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("hud_damage"));
			e.formatString = "%";
			e.addText(e, _("Disable"), 0);
			e.addRange(e, 0.05, 1, 0.05);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticCheckBox_T(0, "hud_dynamic_follow", _("Dynamic HUD"),
			_("HUD moves around following player's movement")));
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox(0, "hud_dynamic_shake", _("Shake the HUD when hurt")));

	me.gotoRC(me, me.rows - 2.5, 0.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 2, me.columns - 0.5 * 2, e = makeXonoticButton(_("Enter HUD editor"), '0 0 0'));
			e.onClick = HUDSetup_Check_Gamestatus;
			e.onClickEntity = me;
		// TODO: show hud config name with text here
}
