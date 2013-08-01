#ifdef INTERFACE
CLASS(XonoticNotificationDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticNotificationDialog, toString, string(entity))
	METHOD(XonoticNotificationDialog, fill, void(entity))
	METHOD(XonoticNotificationDialog, showNotify, void(entity))
	ATTRIB(XonoticNotificationDialog, title, string, _("Notification settings"))
	ATTRIB(XonoticNotificationDialog, color, vector, SKINCOLOR_DIALOG_MODEL)
	ATTRIB(XonoticNotificationDialog, intendedWidth, float, 0.8)
	ATTRIB(XonoticNotificationDialog, rows, float, 15)
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
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 2, 1, "notification_INFO_JOIN_CONNECT"));

	// Item notifications
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Item Notifications:")));
		
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Print weapon notifications:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 3, 1, "notification_INFO_ITEM_WEAPON_DONTHAVE"));
		
	// Gamemode dependent notifications
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gamemode Notifications:")));
		
	// Information on killingsprees
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Information on killingsprees:")));
		
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_show_sprees", _("Print information on sprees")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Show spree information:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 3, 1, "notification_show_sprees_info"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_show_sprees_info_newline", _("Show spree information in a seperate line")));
		
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif