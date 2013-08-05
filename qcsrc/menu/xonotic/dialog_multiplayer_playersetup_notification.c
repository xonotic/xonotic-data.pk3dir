#ifdef INTERFACE
CLASS(XonoticNotificationDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticNotificationDialog, toString, string(entity))
	METHOD(XonoticNotificationDialog, fill, void(entity))
	METHOD(XonoticNotificationDialog, showNotify, void(entity))
	ATTRIB(XonoticNotificationDialog, title, string, _("Notification settings"))
	ATTRIB(XonoticNotificationDialog, color, vector, SKINCOLOR_DIALOG_MODEL)
	ATTRIB(XonoticNotificationDialog, intendedWidth, float, 0.8)
	ATTRIB(XonoticNotificationDialog, rows, float, 20)
	ATTRIB(XonoticNotificationDialog, columns, float, 3)
ENDCLASS(XonoticNotificationDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticNotificationDialog_showNotify(entity me)
{
	loadAllCvars(me);
}
string XonoticNotificationDialog_toString(entity me)
{
	return "hi"; // TODO: show csqc model settings like forcemyplayer and deglowing/ghosting bodies with text here
}
void XonoticNotificationDialog_fill(entity me)
{
	entity e;
	
	// Make a proper structure of this... 
	// Like, go through all notifications and strip out useless ones, then write down the plan and group things properly
	
	// General settings for the player
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("General Settings:")));
		
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Centerprint time:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 3, 0.1, "notification_item_centerprinttime"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_allow_chatboxprint", _("Print all notifications into the chatbox")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Notice joining players:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 2, 1, "notifications_INFO_JOIN_CONNECT"));
			makeMulti(me, "notifications_INFO_JOIN_CONNECT notifications_INFO_JOIN_CONNECT_TEAM_BLUE notifications_INFO_JOIN_CONNECt_TEAM_RED notifications_INFO_JOIN_CONNECT_TEAM_YELLOW notifications_INFO_JOIN_CONNECT_TEAM_PINK");
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_CENTER_TEAMCHANGE_AUTO", _("Print teamchanges")));
			makeMulti(e, "notification_CENTER_TEAMCHANGE_AUTO notification_CENTER_TEAMCHANGE_SUICIDE notification_CENTER_TEAMCHANGE_SPECTATE notification_CENTER_TEAMCHANGE_BLUE notification_CENTER_TEAMCHANGE_RED notification_CENTER_TEAMCHANGE_YELLOW notification_CENTER_TEAMCHANGE_PINK");
		
	// Gamemode dependent notifications
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Gamemode specific Notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Keyhunt notifications:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 3, 1, "Keyhunt notifications in the infopanel"));
			makeMulti(e, "notification_INFO_KEYHUNT_CAPTURE_BLUE notification_INFO_KEYHUNT_DROP_BLUE notification_INFO_KEYHUNT_LOST_BLUE notification_INFO_KEYHUNT_PICKUP_BLUE notification_INFO_KEYHUNT_CAPTURE_RED notification_INFO_KEYHUNT_DROP_RED notification_INFO_KEYHUNT_LOST_RED notification_INFO_KEYHUNT_PICKUP_RED notification_INFO_KEYHUNT_CAPTURE_PINK notification_INFO_KEYHUNT_DROP_PINK notification_INFO_KEYHUNT_LOST_PINK notification_INFO_KEYHUNT_PICKUP_PINK notification_INFO_KEYHUNT_CAPTURE_YELLOW notification_INFO_KEYHUNT_DROP_YELLOW notification_INFO_KEYHUNT_LOST_YELLOW notification_INFO_KEYHUNT_PICKUP_YELLOW");
	
	// Information on killingsprees
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Information on killingsprees:")));
	me.TR(me);
		//me.TDempty(me, 0.1);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "notification_show_sprees", _("Print information on sprees")));
	me.TR(me);
		//me.TDempty(me, 0.1);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Show spree information:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("notification_show_sprees_info"));
			e.addValue(e, ZCTX(_("off")), "0");
			e.addValue(e, ZCTX(_("target")), "1");
			e.addValue(e, ZCTX(_("attacker")), "2");
			e.addValue(e, ZCTX(_("target and attacker")), "3");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		//me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_show_sprees_info_newline", _("Print spree information in a new line")));
		
	// Close this dialog
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif