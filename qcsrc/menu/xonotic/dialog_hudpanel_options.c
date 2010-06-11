#ifdef INTERFACE
CLASS(XonoticHUDOptionsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDOptionsDialog, fill, void(entity))
	ATTRIB(XonoticHUDOptionsDialog, title, string, "Panel Options")
	ATTRIB(XonoticHUDOptionsDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDOptionsDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDOptionsDialog, rows, float, 15)
	ATTRIB(XonoticHUDOptionsDialog, columns, float, 4)
	ATTRIB(XonoticHUDOptionsDialog, name, string, "HUDOptions")
ENDCLASS(XonoticHUDOptionsDialog)

#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDOptionsDialog(entity me)
{
	entity e;
	float panelID;
	me.TR(me);
	
	panelID = cvar("_hud_panel_id");
	if(panelID >= 0) 
	{
		me.TR(me);
			me.TDempty(me, 0.2);
			me.TD(me, 1, 1.2, e = makeNexuizTextLabel(0, "Alpha:"));
			me.TD(me, 1, 2.6, e = makeNexuizSlider(0, 1, 0.01, "hud_", HUD_Panel_GetName(panelID), "_bg_alpha"));
	}
	
}
#endif
