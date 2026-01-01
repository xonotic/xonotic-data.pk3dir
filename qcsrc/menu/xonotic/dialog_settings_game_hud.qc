#include "dialog_settings_game_hud.qh"

#include "../item/modalcontroller.qh"
#include "mainwindow.qh"
#include "textlabel.qh"
#include "slider.qh"
#include "slider_sbfadetime.qh"
#include "mixedslider.qh"
#include "checkbox.qh"
#include "button.qh"

void HUDSetup_Check_Gamestatus(entity me, entity btn)
{
	if(!(gamestatus & (GAME_CONNECTED | GAME_ISSERVER))) // we're not in a match, ask the player if they want to start one anyway
	{
		DialogOpenButton_Click(me, main.hudconfirmDialog);
	}
	else // already in a match, lets just cut to the point and open up the hud editor directly
	{
		HUDSetup_Start(me, btn);
	}
}
void XonoticGameHUDSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameHUDSettingsTab()
{
	entity me;
	me = NEW(XonoticGameHUDSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameHUDSettingsTab_fill(entity me)
{
	entity e;

	// todo:
	// threshold: hud_damage_pain_threshold_lower_health
	// scoreboard_alpha*

	me.TR(me);
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
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Show team sizes:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("hud_panel_scoreboard_team_size_position", _("Team size position: Off=do not show; Left=on the left side of the scoreboard and move team scores to the right; Right=on the right of the scoreboard")));
			e.addText(e, _("Left"),  1);
			e.addText(e, _("Off"),   0);
			e.addText(e, _("Right"), 2);
			e.configureXonoticMixedSliderValues(e);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Waypoints")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(1, "cl_hidewaypoints", _("Display waypoint markers for objectives on the map"),
			_("Show various gametype specific waypoints")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Opacity:")));
			setDependent(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.1, 1, 0.1, "g_waypointsprite_alpha", "-"));
			e.formatString = "%";
			setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Font size:")));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider(5, 16, 1, "g_waypointsprite_fontsize"));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Edge offset:")));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 0.3, 0.01, "g_waypointsprite_edgeoffset_bottom", "-"));
			makeMulti(e, "g_waypointsprite_edgeoffset_top g_waypointsprite_edgeoffset_left g_waypointsprite_edgeoffset_right");
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.25, 1, "g_waypointsprite_crosshairfadealpha", _("Fade when near the crosshair")));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "g_waypointsprite_text", _("Display names instead of icons")));
			setDependentNOT(e, "g_waypointsprite_alpha", 0);
			setDependentAND(e, "cl_hidewaypoints", 0, 0);

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

	me.gotoRC(me, 0, 3); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Player Names")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_shownames", _("Show names above players")));

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Opacity:")));
			setDependent(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.1, 1, 0.1, "hud_shownames_alpha"));
			e.formatString = "%";
			setDependent(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Font size:")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(5, 16, 1, "hud_shownames_fontsize"));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Max distance:")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(2000, 10000, 500, "hud_shownames_maxdistance"));
			e.formatString = _("%s qu");
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Decolorize:")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("hud_shownames_decolorize"));
			e.addText(e, _("Never"),    0);
			e.addText(e, _("Teamplay"), 1);
			e.addText(e, _("Always"),   2);
			e.configureXonoticMixedSliderValues(e);
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);

	me.TR(me);
	//me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(25, 0, "hud_shownames_crosshairdistance", _("Only when near crosshair")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "hud_shownames_status", _("Display health and armor")));
			setDependentNOT(e, "hud_shownames_alpha", 0);
			setDependentAND(e, "hud_shownames", 1, 1);

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

	me.gotoRC(me, me.rows - 1, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("Enter HUD editor"), '0 0 0'));
			e.onClick = HUDSetup_Check_Gamestatus;
			e.onClickEntity = me;
		// TODO: show hud config name with text here
}
