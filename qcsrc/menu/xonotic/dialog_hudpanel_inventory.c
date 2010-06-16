#ifdef INTERFACE
CLASS(XonoticHUDInventoryDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDInventoryDialog, fill, void(entity))
	ATTRIB(XonoticHUDInventoryDialog, title, string, "Inventory Panel Setup")
	ATTRIB(XonoticHUDInventoryDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDInventoryDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDInventoryDialog, rows, float, 15)
	ATTRIB(XonoticHUDInventoryDialog, columns, float, 4)
	ATTRIB(XonoticHUDInventoryDialog, name, string, "HUDinventory")
ENDCLASS(XonoticHUDInventoryDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDInventoryDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(1, "hud_inventory", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_inventory_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_inventory_bg_alpha"));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_inventory_onlycurrent", "Show Current Ammo Only"));		
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
