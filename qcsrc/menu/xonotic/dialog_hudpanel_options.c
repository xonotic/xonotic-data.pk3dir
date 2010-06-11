#ifdef INTERFACE
CLASS(XonoticHUDOptionsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDOptionsDialog, fill, void(entity))
	METHOD(XonoticHUDOptionsDialog, change, void(entity, float))
	ATTRIB(XonoticHUDOptionsDialog, title, string, "HUD Setup")
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
	me.TR(me);
}

/* nvm these, i guess they wont be used
void saveCvarsXonoticHUDOptionsDialog(entity me)
{
	cvar_set(strcat("hud_", HUD_Panel_GetName(me.currentPanel)), ftos(me.currentEnabled));
	if(me.currentPanel == HUD_PANEL_WEAPONICONS)
		cvar_set(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_number"), ftos(me.currentNumber));

	cvar_set(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg"), ftos(me.currentBg));
	cvar_set(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_color"), me.currentBgColor);
	cvar_set(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_color_team"), ftos(me.currentBgColorTeam));
	cvar_set(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_alpha"), ftos(me.currentBgAlpha));
	cvar_set(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_border"), ftos(me.currentBgBorder));
	cvar_set(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_padding"), ftos(me.currentBgPadding));
}

void loadCvarsXonoticHUDOptionsDialog(entity me)
{
	me.currentEnabled = cvar(strcat("hud_", HUD_Panel_GetName(me.currentPanel)));
	if(me.currentPanel == HUD_PANEL_WEAPONICONS)
		me.currentNumber = cvar(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_number")); // only weaponicons panel

	me.currentBg = cvar(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg"));
	me.currentBgColor = cvar_string(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_color"));
	me.currentBgColorTeam = cvar(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_color_team"));
	me.currentBgAlpha = cvar(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_alpha"));
	me.currentBgBorder = cvar(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_border"));
	me.currentBgPadding = cvar(strcat("hud_", HUD_Panel_GetName(me.currentPanel), "_bg_padding"));

	// wtf?
	me.go(me, 0); // this will set the other vars for currentSkin and currentModel
}
*/

void changeXonoticHUDOptionsDialog(entity me, float id)
{
	loadAllCvars(me);
	highlightedPanel = id;
	print("Yay!", ftos(id), "\n");

}

#endif
