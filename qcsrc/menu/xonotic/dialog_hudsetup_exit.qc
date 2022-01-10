#include "dialog_hudsetup_exit.qh"

#include "textlabel.qh"
#include "button.qh"
#include "textslider.qh"
#include "inputbox.qh"
#include "hudskinlist.qh"
#include "colorpicker_string.qh"
#include "checkbox.qh"
#include "commandbutton.qh"

void XonoticHUDExitDialog_fill(entity me)
{
	entity e;
	int i;
	hudskinlist = makeXonoticHUDSkinList();

	me.TR(me);
		me.TD(me, 1, 4, makeXonoticHeaderLabel(_("HUD skins")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.7, e = makeXonoticTextLabel(0.5, _("Filter:")));
		me.TD(me, 1, 2.9, e = makeXonoticInputBox(0, string_null));
			e.onChange = HUDSkinList_Filter_Change;
			e.onChangeEntity = hudskinlist;
	me.TR(me);
		me.TD(me, 12, 4, hudskinlist);
	me.gotoRC(me, me.rows - 4, 0);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.4, e = makeXonoticButton(_("Refresh"), '0 0 0'));
			e.onClick = HUDSkinList_Refresh_Click;
			e.onClickEntity = hudskinlist;
		me.TD(me, 1, 2.2, e = makeXonoticButton(_("Set skin"), '0 0 0'));
			e.onClick = SetHUDSkin_Click;
			e.onClickEntity = hudskinlist;
	me.gotoRC(me, me.rows - 2.5, 0);
		me.TD(me, 1, 2, e = makeXonoticButton_T(_("Save current skin"), '0 0 0',
			"Note: HUD skins are saved in data/data/ directory and can be manually renamed/deleted from there"));
			e.onClick = SaveHUDSkin_Click;
			e.onClickEntity = hudskinlist;
		me.TD(me, 1, 2, e = makeXonoticInputBox(0, string_null));
			e.onChange = HUDSkinList_SavedName_Change;
			e.onChangeEntity = hudskinlist;

	me.gotoRC(me, 0, 4.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, _("Panel background defaults:")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Background:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_bg"));
				e.addValue(e, _("Disable"), "0");
				e.addValue(e, "border_default", "border_default"); // this is a file name!
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Color:")));
		me.TD(me, 2, 2.6, e = makeXonoticColorpickerString("hud_panel_bg_color", "hud_panel_bg_color"));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Border size:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_bg_border"));
				e.addValue(e, _("Disable"), "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i * 2, 0)), strzone(ftos(i * 2)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Alpha:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_bg_alpha"));
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Team color:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_bg_color_team"));
				e.addValue(e, _("Disable"), "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3.6, e = makeXonoticCheckBox(0, "hud_configure_teamcolorforced", _("Test team color in configure mode")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Padding:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_panel_bg_padding"));
				for(i = 0; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i - 5, 0)), strzone(ftos(i - 5)));
				e.configureXonoticTextSliderValues(e);

	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("HUD Dock:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_dock"));
				e.addValue(e, ZCTX(_("DOCK^Disabled")), "0");
				e.addValue(e, ZCTX(_("DOCK^Small")), "dock_small");
				e.addValue(e, ZCTX(_("DOCK^Medium")), "dock_medium");
				e.addValue(e, ZCTX(_("DOCK^Large")), "dock_large");
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Color:")));
		me.TD(me, 2, 2.6, e = makeXonoticColorpickerString("hud_dock_color", "hud_dock_color"));
	me.TR(me);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Alpha:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_dock_alpha"));
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Team color:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider("hud_dock_color_team"));
				e.addValue(e, _("Disable"), "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, _("Grid settings:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3.8, e = makeXonoticCheckBox(0, "hud_configure_grid", _("Snap panels to grid")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Grid size:")));
			setDependent(e, "hud_configure_grid", 1, 1);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, _("X:")));
			setDependent(e, "hud_configure_grid", 1, 1);
			me.TD(me, 1, 1.1, e = makeXonoticTextSlider("hud_configure_grid_xsize"));
				for(i = 1; i <= 14; ++i)
					e.addValue(e, strzone(sprintf("%.1f%%", i/2)), strzone(ftos(i/200)));
				e.configureXonoticTextSliderValues(e);
				setDependent(e, "hud_configure_grid", 1, 1);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, _("Y:")));
			setDependent(e, "hud_configure_grid", 1, 1);
			me.TD(me, 1, 1.1, e = makeXonoticTextSlider("hud_configure_grid_ysize"));
				for(i = 1; i <= 14; ++i)
					e.addValue(e, strzone(sprintf("%.1f%%", i/2)), strzone(ftos(i/200)));
				e.configureXonoticTextSliderValues(e);
				setDependent(e, "hud_configure_grid", 1, 1);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticCommandButton(_("Exit setup"), '0 0 0', "_hud_configure 0", COMMANDBUTTON_CLOSE));
}
