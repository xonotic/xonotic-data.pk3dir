#ifndef DIALOG_SETTINGS_GAME_HUD_H
#define DIALOG_SETTINGS_GAME_HUD_H
#include "tab.qc"
CLASS(XonoticGameHUDSettingsTab, XonoticTab)
	METHOD(XonoticGameHUDSettingsTab, fill, void(entity));
	METHOD(XonoticGameHUDSettingsTab, showNotify, void(entity));
	ATTRIB(XonoticGameHUDSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticGameHUDSettingsTab, rows, float, 13)
	ATTRIB(XonoticGameHUDSettingsTab, columns, float, 6.2)
ENDCLASS(XonoticGameHUDSettingsTab)
entity makeXonoticGameHUDSettingsTab();
void HUDSetup_Start(entity me, entity btn);
#endif

#ifdef IMPLEMENTATION
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

	//me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Scoreboard")));
	//me.TR(me);
	//	me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Alpha:")));
	//	me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.05, "scoreboard_alpha_bg"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Fading speed:")));
		me.TD(me, 1, 2, e = makeXonoticScoreboardFadeTimeSlider());
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Side padding:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0.05, 0.3, 0.01, "scoreboard_offset_left"));
			makeMulti(e, "scoreboard_offset_right");

	me.TR(me);
	//me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "scoreboard_respawntime_decimals", _("Show decimals in respawn countdown")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "scoreboard_accuracy", _("Show accuracy underneath scoreboard")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Waypoints")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "cl_hidewaypoints", _("Display waypoint markers for objectives on the map")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Alpha:")));
			setDependent(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.1, 1, 0.05, "g_waypointsprite_alpha"));
			setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Fontsize:")));
			setDependent(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider(5, 16, 1, "g_waypointsprite_fontsize"));
			setDependent(e, "cl_hidewaypoints", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Edge offset:")));
			setDependent(e, "cl_hidewaypoints", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 0.3, 0.01, "g_waypointsprite_edgeoffset_bottom"));
			makeMulti(e, "g_waypointsprite_edgeoffset_top g_waypointsprite_edgeoffset_left g_waypointsprite_edgeoffset_right");
			setDependent(e, "cl_hidewaypoints", 0, 0);

	me.TR(me);
	//me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(0.25, 1, "g_waypointsprite_crosshairfadealpha", _("Fade when near the crosshair")));
			setDependent(e, "cl_hidewaypoints", 0, 0);

	#if 0
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Damage")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Overlay:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.05, "hud_damage"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Factor:")));
			setDependent(e, "hud_damage", 0.001, 100);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.025, 0.1, 0.025, "hud_damage_factor"));
			setDependent(e, "hud_damage", 0.001, 100);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Fade rate:")));
			setDependent(e, "hud_damage", 0.001, 100);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.25, 1, 0.05, "hud_damage_fade_rate"));
			setDependent(e, "hud_damage", 0.001, 100);
	me.TR(me);
	#endif

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Player Names")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_shownames", _("Show names above players")));

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Alpha:")));
			setDependent(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(0.1, 1, 0.05, "hud_shownames_alpha"));
			setDependent(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Fontsize:")));
			setDependent(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(5, 16, 1, "hud_shownames_fontsize"));
			setDependent(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Max distance:")));
			setDependent(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(2000, 10000, 500, "hud_shownames_maxdistance"));
			setDependent(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Decolorize:")));
			setDependent(e, "hud_shownames", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("hud_shownames_decolorize"));
			e.addValue(e, _("Never"), "0");
			e.addValue(e, _("Teamplay"), "1");
			e.addValue(e, _("Always"), "2");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "hud_shownames", 1, 1);

	me.TR(me);
	//me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(25, 0, "hud_shownames_crosshairdistance", _("Only when near crosshair")));
			setDependent(e, "hud_shownames", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "hud_shownames_status", _("Display health and armor")));
			setDependent(e, "hud_shownames", 1, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Damage overlay:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.05, "hud_damage"));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Enter HUD editor"), '0 0 0'));
			e.onClick = HUDSetup_Check_Gamestatus;
			e.onClickEntity = me;
		// TODO: show hud config name with text here
}
#endif
