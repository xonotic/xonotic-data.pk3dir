#ifdef INTERFACE
CLASS(XonoticGameMessageSettingsTab) EXTENDS(XonoticTab)
	//METHOD(XonoticGameWeaponsSettingsTab, toString, string(entity))
	METHOD(XonoticGameMessageSettingsTab, fill, void(entity))
	METHOD(XonoticGameMessageSettingsTab, showNotify, void(entity))
	ATTRIB(XonoticGameMessageSettingsTab, title, string, _("Messages"))
	ATTRIB(XonoticGameMessageSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticGameMessageSettingsTab, rows, float, 13)
	ATTRIB(XonoticGameMessageSettingsTab, columns, float, 6)
	ATTRIB(XonoticGameMessageSettingsTab, weaponsList, entity, NULL)
ENDCLASS(XonoticGameMessageSettingsTab)
entity makeXonoticGameMessageSettingsTab();
#endif

#ifdef IMPLEMENTATION
void XonoticGameMessageSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameMessageSettingsTab()
{
	entity me;
	me = spawnXonoticGameMessageSettingsTab();
	me.configureDialog(me);
	return me;
}

void XonoticGameMessageSettingsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Frag Information")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_show_sprees", _("Display information about killing sprees")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "notification_show_sprees_info_specialonly", _("Only display sprees if they are achievements")));
			makeMulti(e, "notification_show_sprees_center_specialonly");
			setDependent(e, "notification_show_sprees", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "notification_show_sprees_center", _("Show spree information in centerprints")));
			setDependent(e, "notification_show_sprees", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(3, 0, "notification_show_sprees_info", _("Show spree information in death messages")));
			setDependent(e, "notification_show_sprees", 1, 1);
	#if 0
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Sprees in info messages:")));
			setDependent(e, "notification_show_sprees", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("notification_show_sprees_info"));
			e.addValue(e, ZCTX(_("Disabled")), "0");
			e.addValue(e, ZCTX(_("Target")), "1");
			e.addValue(e, ZCTX(_("Attacker")), "2");
			e.addValue(e, ZCTX(_("Both")), "3");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "notification_show_sprees", 1, 1);
	#endif
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 2.6, e = makeXonoticCheckBox(0, "notification_show_sprees_info_newline", _("Print on a seperate line")));
			setDependent(e, "notification_show_sprees", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 1, "notification_CHOICE_FRAG", _("Add extra frag information to centerprint when available")));
			makeMulti(e, "notification_CHOICE_FRAGGED notification_CHOICE_TYPEFRAG notification_CHOICE_TYPEFRAGGED");
			e.sendCvars = TRUE;
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_show_location", _("Add frag location to death messages when available")));

	me.gotoRC(me, 9, 0); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Gamemode Settings")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 1, "notification_CHOICE_CTF_CAPTURE_TIME_RED", _("Display capture times in Capture The Flag")));
			makeMulti(e, "notification_CHOICE_CTF_CAPTURE_TIME_BLUE notification_CHOICE_CTF_CAPTURE_BROKEN_RED notification_CHOICE_CTF_CAPTURE_BROKEN_BLUE notification_CHOICE_CTF_CAPTURE_UNBROKEN_RED notification_CHOICE_CTF_CAPTURE_UNBROKEN_BLUE ");
			e.sendCvars = TRUE;
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 1, "notification_CHOICE_CTF_PICKUP_ENEMY", _("Display name of flag stealer in Capture The Flag")));
			makeMulti(e, "notification_CHOICE_CTF_PICKUP_TEAM");
			e.sendCvars = TRUE;

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Other")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(4, 1, "con_notify", _("Display console messages in the top left corner")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 1, "notification_allow_chatboxprint", _("Display all info messages in the chatbox")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 1, "notification_INFO_QUIT_DISCONNECT", _("Display player statuses in the chatbox")));
			makeMulti(e, "notification_INFO_QUIT_KICK_IDLING notification_INFO_JOIN_CONNECT_TEAM_BLUE notification_INFO_JOIN_CONNECT_TEAM_PINK notification_INFO_JOIN_CONNECT_TEAM_RED notification_INFO_JOIN_CONNECT_TEAM_YELLOW");
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_CENTER_POWERUP_INVISIBILITY", _("Powerup notifications")));
			makeMulti(e, "notification_CENTER_POWERUP_SHIELD notification_CENTER_POWERUP_SPEED notification_CENTER_POWERUP_STRENGTH notification_CENTER_POWERDOWN_INVISIBILITY notification_CENTER_POWERDOWN_SHIELD notification_CENTER_POWERDOWN_SPEED notification_CENTER_POWERDOWN_STRENGTH notification_CENTER_SUPERWEAPON_BROKEN notification_CENTER_SUPERWEAPON_LOST notification_CENTER_SUPERWEAPON_PICKUP notification_INFO_POWERUP_INVISIBILITY notification_INFO_POWERUP_SHIELD notification_INFO_POWERUP_SPEED notification_INFO_POWERUP_STRENGTH");
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_CENTER_ITEM_WEAPON_DONTHAVE", _("Weapon centerprint notifications")));
			makeMulti(e, "notification_CENTER_ITEM_WEAPON_DROP notification_CENTER_ITEM_WEAPON_GOT notification_CENTER_ITEM_WEAPON_NOAMMO notification_CENTER_ITEM_WEAPON_PRIMORSEC notification_CENTER_ITEM_WEAPON_UNAVAILABLE"); 
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "notification_INFO_ITEM_WEAPON_DONTHAVE", _("Weapon info message notifications")));
			makeMulti(e, "notification_INFO_ITEM_WEAPON_DROP notification_INFO_ITEM_WEAPON_GOT notification_INFO_ITEM_WEAPON_NOAMMO notification_INFO_ITEM_WEAPON_PRIMORSEC notification_INFO_ITEM_WEAPON_UNAVAILABLE"); 

	me.gotoRC(me, 9, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Announcers")));
	#if 0
	// there's just not enough room for this, and it's not important enough to justify...
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 0, "notification_ANNCE_NUM_RESPAWN_1", _("Respawn countdown sounds")));
			makeMulti(e, "notification_ANNCE_NUM_RESPAWN_2 notification_ANNCE_NUM_RESPAWN_3 notification_ANNCE_NUM_RESPAWN_4 notification_ANNCE_NUM_RESPAWN_5 notification_ANNCE_NUM_RESPAWN_6 notification_ANNCE_NUM_RESPAWN_7 notification_ANNCE_NUM_RESPAWN_8 notification_ANNCE_NUM_RESPAWN_9 notification_ANNCE_NUM_RESPAWN_10");
	#endif
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(1, 0, "notification_ANNCE_KILLSTREAK_03", _("Killstreak sounds")));
			makeMulti(e, "notification_ANNCE_KILLSTREAK_05 notification_ANNCE_KILLSTREAK_10 notification_ANNCE_KILLSTREAK_15 notification_ANNCE_KILLSTREAK_20 notification_ANNCE_KILLSTREAK_25 notification_ANNCE_KILLSTREAK_30");
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(1, 0, "notification_ANNCE_ACHIEVEMENT_AIRSHOT", _("Achievement sounds")));
			makeMulti(e, "notification_ANNCE_ACHIEVEMENT_AMAZING notification_ANNCE_ACHIEVEMENT_AWESOME notification_ANNCE_ACHIEVEMENT_BOTLIKE notification_ANNCE_ACHIEVEMENT_ELECTROBITCH notification_ANNCE_ACHIEVEMENT_IMPRESSIVE notification_ANNCE_ACHIEVEMENT_YODA");
}
#endif
