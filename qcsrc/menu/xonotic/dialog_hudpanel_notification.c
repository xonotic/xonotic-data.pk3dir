#ifdef INTERFACE
CLASS(XonoticHUDNotificationDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDNotificationDialog, fill, void(entity))
	ATTRIB(XonoticHUDNotificationDialog, title, string, "Notification Panel Setup")
	ATTRIB(XonoticHUDNotificationDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDNotificationDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDNotificationDialog, rows, float, 15)
	ATTRIB(XonoticHUDNotificationDialog, columns, float, 4)
	ATTRIB(XonoticHUDNotificationDialog, name, string, "HUDnotify")
ENDCLASS(XonoticHUDNotificationDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDNotificationDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_notify", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_notify_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_notify_bg_alpha"));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_notify_flip", "Flip"));
	me.TR(me);
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
