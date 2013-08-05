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
	
	// General settings for the player
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("General Settings:")));
		
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Centerprint time:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 3, 0.1, "notification_item_centerprinttime"));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_allow_chatboxprint", _("Print all notifications into the chatbox")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_MOTD", _("Centerprint the MOTD")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Notice joining/quiting players:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("notification_INFO_QUIT_DISCONNECT"));
			//makeMulti(me, "notification_INFO_QUIT_KICK_IDLING notification_INFO_QUIT_KICK_SPECTATING notification_INFO_JOIN_PLAY notification_INFO_JOIN_CONNECT_TEAM_BLUE notification_INFO_JOIN_CONNECT_TEAM_PINK notification_INFO_JOIN_CONNECT_TEAM_RED notification_INFO_JOIN_CONNECT_TEAM_YELLOW");
			e.addValue(e, ZCTX(_("off")), "0");
			e.addValue(e, ZCTX(_("only console")), "1");
			e.addValue(e, ZCTX(_("console & chat")), "2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_TEAMCHANGE_AUTO", _("Centerprint teamchanges")));
			//makeMulti(e, "notification_CENTER_TEAMCHANGE_BLUE notification_CENTER_TEAMCHANGE_PINK notification_CENTER_TEAMCHANGE_RED notification_CENTER_TEAMCHANGE_SPECTATE notification_CENTER_TEAMCHANGE_SUICIDE notification_CENTER_TEAMCHANGE_YELLOW");
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_ITEM_WEAPON_DONTHAVE", _("Item notifications")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_POWERUP_INVISIBILITY", _("Powerup notifications")));
			//makeMulti(e, "notification_CENTER_POWERUP_SHIELD notification_CENTER_POWERUP_SPEED notification_CENTER_POWERUP_STRENGTH notification_CENTER_POWERDOWN_INVISIBILITY notification_CENTER_POWERDOWN_SHIELD notification_CENTER_POWERDOWN_SPEED notification_CENTER_POWERDOWN_STRENGTH notification_CENTER_SUPERWEAPON_BROKEN notification_CENTER_SUPERWEAPON_LOST notification_CENTER_SUPERWEAPON_PICKUP");
			
	me.TR(me);
		
	// Gamemode dependent notifications
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Gamemode specific Notifications:")));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Arena notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_ARENA_BEGIN", _("Centerprint information for arena")));
			//makeMulti(me, "notification_CENTER_ARENA_NEEDPLAYER notification_CENTER_ARENA_ROUNDSTART");
		
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Assault notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_ASSAULT_ATTACKING", _("Centerprint information for assault")));
			//makeMulti(me, "notification_CENTER_ASSAULT_DEFENDING");
		
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("CTF notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_CTF_PICKUP_BLUE", _("Centerprint information for ctf")));
			//makeMulti(me, "notification_CENTER_CTF_PICKUP_ENEMY notification_CENTER_CTF_PICKUP_RED notification_CENTER_CTF_PICKUP_TEAM");
		
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Freezetag notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_FREEZETAG_FREEZE", _("Centerprint information for freezetag")));
			//makeMulti(me, "notification_CENTER_FREEZETAG_FROZEN notification_CENTER_FREEZETAG_REVIVE notification_CENTER_FREEZETAG_REVIVED notification_CENTER_FREEZETAG_ROUND_WIN_BLUE notification_CENTER_FREEZETAG_ROUND_WIN_PINK notification_CENTER_FREEZETAG_ROUND_WIN_RED notification_CENTER_FREEZETAG_ROUND_WIN_YELLOW notification_CENTER_FREEZETAG_SELF notification_CENTER_FREEZETAG_SPAWN_LATE");
		
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Keepaway notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_KEEPAWAY_DROPPED", _("Centerprint information for keepaway")));
			//makeMulti(me, "notification_CENTER_KEEPAWAY_PICKUP notification_CENTER_KEEPAWAY_WARN");
			
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Keyhunt notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_KEYHUNT_HELP", _("Centerprint information for keyhunt")));
			//makeMulti(me, "notification_CENTER_KEYHUNT_INTERFERE_BLUE notification_CENTER_KEYHUNT_INTERFERE_PINK notification_CENTER_KEYHUNT_INTERFERE_RED notification_CENTER_KEYHUNT_INTERFERE_YELLOW notification_CENTER_KEYHUNT_MEET notification_CENTER_KEYHUNT_SCAN notification_CENTER_KEYHUNT_START_BLUE notification_CENTER_KEYHUNT_START_PINK notification_CENTER_KEYHUNT_START_RED notification_CENTER_KEYHUNT_START_YELLOW notification_CENTER_KEYHUNT_WAIT");
			
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("LMS notifications:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "notification_CENTER_LMS_CAMPCHECK", _("Centerprint information for LMS")));
	
	me.TR(me);
	
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