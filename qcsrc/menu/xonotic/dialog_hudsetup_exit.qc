#include "dialog_hudsetup_exit.qh"

#include "textlabel.qh"
#include "button.qh"
#include "slider.qh"
#include "textslider.qh"
#include "mixedslider.qh"
#include "inputbox.qh"
#include "hudskinlist.qh"
#include "colorpicker_string.qh"
#include "checkbox.qh"
#include "mainwindow.qh"
#include "commandbutton.qh"

void HUDSkinList_Reset_Click(entity me, entity btn)
{
	DialogOpenButton_Click(me, main.skinResetDialog);
}

void XonoticSkinResetDialog_fill(entity me)
{
	entity e;
	if (!hudskinlist)
		hudskinlist = makeXonoticHUDSkinList();

	me.TR(me);
		me.TD(me, 1, 2, makeXonoticTextLabel(0.5, _("Are you sure you want to reset your HUD to this skin?")));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticButton(_("Yes"), '1 0 0'));
			e.onClick = SetHUDSkin_Click;
			e.onClickEntity = hudskinlist;
		me.TD(me, 1, 1, e = makeXonoticButton(_("No"), '0 1 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

void XonoticHUDExitDialog_fill(entity me)
{
	entity e;
	int i;
	if (!hudskinlist)
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
			e.onClick = HUDSkinList_Reset_Click;
			e.onClickEntity = me;
	me.gotoRC(me, me.rows - 2.5, 0);
		me.TD(me, 1, 2, e = makeXonoticButton_T(_("Save current skin"), '0 0 0',
			_("Note: HUD skins are saved in data/data/ directory and can be manually renamed/deleted from there")));
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
				e.setValueSpace(e, e.valueSpace * 1.25);
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
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_bg_border"));
				e.addText(e, _("Disable"), 0);
				e.addRange(e, 2, 20, 2);
				e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Opacity:")));
			me.TD(me, 1, 2.6, e = makeXonoticSlider(0.05, 1, 0.05, "hud_panel_bg_alpha"));
				e.formatString = "%";
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Team color:")));
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_panel_bg_color_team"));
				e.formatString = "%";
				e.addText(e, _("Disable"), 0);
				e.addRange(e, 0.1, 1, 0.1);
				e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3.6, e = makeXonoticCheckBox(0, "hud_configure_teamcolorforced", _("Test team color in configure mode")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Padding:")));
			me.TD(me, 1, 2.6, e = makeXonoticSlider(-5, 5, 1, "hud_panel_bg_padding"));

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
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Opacity:")));
			me.TD(me, 1, 2.6, e = makeXonoticSlider(0.05, 1, 0.05, "hud_dock_alpha"));
				e.formatString = "%";
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Team color:")));
			me.TD(me, 1, 2.6, e = makeXonoticMixedSlider("hud_dock_color_team"));
				e.formatString = "%";
				e.addText(e, _("Disable"), 0);
				e.addRange(e, 0.1, 1, 0.1);
				e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.4, makeXonoticTextLabel(0, _("Grid settings:")));
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "hud_configure_grid", _("Snap panels to grid")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Grid size:")));
			setDependent(e, "hud_configure_grid", 1, 1);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, _("X:")));
			setDependent(e, "hud_configure_grid", 1, 1);
			me.TD(me, 1, 1.1, e = makeXonoticSlider(0.005, 0.07, 0.005, "hud_configure_grid_xsize"));
				e.formatString = "%";
				e.valueDigits = 3;
				setDependent(e, "hud_configure_grid", 1, 1);
		me.TD(me, 1, 0.2, e = makeXonoticTextLabel(0, _("Y:")));
			setDependent(e, "hud_configure_grid", 1, 1);
			me.TD(me, 1, 1.1, e = makeXonoticSlider(0.005, 0.07, 0.005, "hud_configure_grid_ysize"));
				e.formatString = "%";
				e.valueDigits = 3;
				setDependent(e, "hud_configure_grid", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		string vertical_lines_cvarname = "hud_configure_vertical_lines";
		me.TD(me, 1, 3.6, e = makeXonoticCheckBoxEx_T(0.5, 0, vertical_lines_cvarname, _("Center line"),
			sprintf(_("Show a vertical centerline to help align panels. It's possible to show more vertical lines by editing %s in the console"), vertical_lines_cvarname)));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticCommandButton(_("Exit setup"), '0 0 0', "_hud_configure 0", COMMANDBUTTON_CLOSE));
}
