#ifdef INTERFACE
CLASS(XonoticHUDExitDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDExitDialog, fill, void(entity))
	ATTRIB(XonoticHUDExitDialog, title, string, "HUD Setup")
	ATTRIB(XonoticHUDExitDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDExitDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDExitDialog, rows, float, 15)
	ATTRIB(XonoticHUDExitDialog, columns, float, 4)
	ATTRIB(XonoticHUDExitDialog, name, string, "HUDExit")
ENDCLASS(XonoticHUDExitDialog)

#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDExitDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, "Panel Defaults:"));
			me.TR(me);
				me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_bg", "Panel Background"));
			me.TR(me);
				me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
					me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_bg_color_team"));
			me.TR(me);
				me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
					me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_bg_alpha"));
			me.TR(me);
				me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Foreground Alpha:"));
					me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_fg_alpha"));
			me.TR(me);
				me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Progress Bar Alpha:"));
					me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_progressbar_alpha"));
			me.TR(me);
				me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_configure_checkcollisions", "Collision Check"));
	me.TR(me);
	
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, "Dock Settings:"));

			me.TR(me);
				me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
					me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_dock_color_team"));
			me.TR(me);	
				me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Dock Alpha:"));
					me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_dock_alpha"));
	me.TR(me);
	
	me.TR(me);
		me.TD(me, 1, 4, makeXonoticTextLabel(0, "Grid Settings:"));

			me.TR(me);
				me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "hud_configure_grid", "Snap Panel to Grid"));
			me.gotoRC(me, me.rows - 1, 0);
				me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
