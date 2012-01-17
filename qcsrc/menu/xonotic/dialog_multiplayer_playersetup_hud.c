#ifdef INTERFACE
CLASS(XonoticHUDDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticHUDDialog, toString, string(entity))
	METHOD(XonoticHUDDialog, fill, void(entity))
	METHOD(XonoticHUDDialog, showNotify, void(entity))
	ATTRIB(XonoticHUDDialog, title, string, _("HUD settings"))
	ATTRIB(XonoticHUDDialog, color, vector, SKINCOLOR_DIALOG_HUD)
	ATTRIB(XonoticHUDDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticHUDDialog, rows, float, 12)
	ATTRIB(XonoticHUDDialog, columns, float, 3)
ENDCLASS(XonoticHUDDialog)
void HUDSetup_Start(entity me, entity btn);
#endif

#ifdef IMPLEMENTATION
void HUDSetup_Check_Gamestatus(entity me, entity btn)
{
	if not(gamestatus & (GAME_CONNECTED | GAME_ISSERVER)) // we're not in a match, ask the player if they want to start one anyway
	{
		DialogOpenButton_Click(me, main.hudconfirmDialog);
	}
	else // already in a match, lets just cut to the point and open up the hud editor directly
	{
		HUDSetup_Start(me, btn);
	}
}
void XonoticHUDDialog_showNotify(entity me)
{
	loadAllCvars(me);
}
string XonoticHUDDialog_toString(entity me)
{
	return "hi"; // TODO: show hud config name with text here 
}
void XonoticHUDDialog_fill(entity me)
{
	entity e;
	
	me.TR(me);
		me.TDempty(me, 0.5);
		me.TD(me, 1, 2, e = makeXonoticButton(_("Enter HUD editor"), '0 0 0'));
			e.onClick = HUDSetup_Check_Gamestatus;
			e.onClickEntity = me;
		// TODO: show hud config name with text here 
		
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif