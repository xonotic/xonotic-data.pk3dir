#include "dialog_settings_game_messages.qh"

#include "textlabel.qh"
#include "checkbox.qh"
#include "mixedslider.qh"
#include <common/mapinfo.qh>
#include <common/gametypes/gametype/ctf/ctf.qh>

void XonoticGameMessageSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGameMessageSettingsTab()
{
	entity me;
	me = NEW(XonoticGameMessageSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGameMessageSettingsTab_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 3.1, e = makeXonoticHeaderLabel(_("Frag Information")));
	me.TR(me);
		me.TD(me, 1, 3.1, e = makeXonoticCheckBox_T(0, "notification_show_sprees", _("Display information about killing sprees"), "-"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBox_T(0, "notification_show_sprees_info_specialonly", _("Only display sprees if they are achievements"), "-"));
			makeMulti(e, "notification_show_sprees_center_specialonly");
			setDependent(e, "notification_show_sprees", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBox_T(0, "notification_show_sprees_center", _("Show spree information in centerprints"), "-"));
			setDependent(e, "notification_show_sprees", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBoxEx_T(3, 0, "notification_show_sprees_info", _("Show spree information in death messages"), "-"));
			setDependent(e, "notification_show_sprees", 1, 1);
	#if 0
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Sprees in info messages:")));
			setDependent(e, "notification_show_sprees", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("notification_show_sprees_info", "-"));
			e.addText(e, ZCTX(_("SPREES^Disabled")), 0);
			e.addText(e, _("Target"), 1);
			e.addText(e, _("Attacker"), 2);
			e.addText(e, ZCTX(_("SPREES^Both")), 3);
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "notification_show_sprees", 1, 1);
	#endif
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 2.7, e = makeXonoticCheckBox_T(0, "notification_show_sprees_info_newline", _("Print on a separate line"), "-"));
			setDependent(e, "notification_show_sprees", 1, 1);
			setDependentAND(e, "notification_show_sprees_info", 1, 3);
	me.TR(me);
		me.TD(me, 1, 3.1, e = makeXonoticCheckBoxEx_T(2, 1, "notification_CHOICE_FRAG", _("Add extra frag information to centerprint when available"), "-"));
			makeMulti(e, "notification_CHOICE_FRAGGED notification_CHOICE_TYPEFRAG notification_CHOICE_TYPEFRAGGED notification_CHOICE_FRAG_FIRE notification_CHOICE_FRAGGED_FIRE notification_CHOICE_FRAG_FREEZE notification_CHOICE_FRAGGED_FREEZE");
			e.sendCvars = true;
	me.TR(me);
		me.TD(me, 1, 3.1, e = makeXonoticCheckBox_T(0, "notification_show_location", _("Add frag location to death messages when available"), "-"));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3.1, e = makeXonoticHeaderLabel(_("Gametype Settings")));
	me.TR(me);
		me.TD(me, 1, 3.1, e = makeXonoticCheckBoxEx_T(2, 1, "notification_CHOICE_CTF_CAPTURE_TIME", strzone(sprintf(_("Display capture times in %s"), MapInfo_Type_ToText(MAPINFO_TYPE_CTF))), "-"));
			makeMulti(e, "notification_CHOICE_CTF_CAPTURE_BROKEN notification_CHOICE_CTF_CAPTURE_UNBROKEN");
			e.sendCvars = true;
	me.TR(me);
		me.TD(me, 1, 3.1, e = makeXonoticCheckBoxEx_T(2, 1, "notification_CHOICE_CTF_PICKUP_ENEMY", strzone(sprintf(_("Display name of flag stealer in %s"), MapInfo_Type_ToText(MAPINFO_TYPE_CTF))), "-"));
			makeMulti(e, "notification_CHOICE_CTF_PICKUP_ENEMY_TEAM notification_CHOICE_CTF_PICKUP_ENEMY_NEUTRAL");
			e.sendCvars = true;

	me.gotoRC(me, 0, 3.1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 2.9, e = makeXonoticHeaderLabel(_("Other")));
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBoxEx_T(4, 0, "con_notify", _("Display console messages in the top left corner"), "-"));
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBoxEx_T(2, 1, "notification_allow_chatboxprint", _("Display all info messages in the chatbox"), "-"));
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBoxEx_T(2, 1, "notification_INFO_QUIT_DISCONNECT", _("Display player statuses in the chatbox"), "-"));
			makeMulti(e, "notification_INFO_QUIT_KICK_IDLING notification_INFO_JOIN_CONNECT");
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBox_T(0, "notification_CENTER_POWERUP_INVISIBILITY", _("Powerup notifications"), "-"));
			makeMulti(e, "notification_CENTER_POWERUP_SHIELD notification_CENTER_POWERUP_SPEED notification_CENTER_POWERUP_STRENGTH notification_CENTER_POWERDOWN_INVISIBILITY notification_CENTER_POWERDOWN_SHIELD notification_CENTER_POWERDOWN_SPEED notification_CENTER_POWERDOWN_STRENGTH notification_CENTER_SUPERWEAPON_BROKEN notification_CENTER_SUPERWEAPON_LOST notification_CENTER_SUPERWEAPON_PICKUP notification_INFO_POWERUP_INVISIBILITY notification_INFO_POWERUP_SHIELD notification_INFO_POWERUP_SPEED notification_INFO_POWERUP_STRENGTH");
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBox_T(0, "notification_CENTER_ITEM_WEAPON_DONTHAVE", _("Weapon centerprint notifications"), "-"));
			makeMulti(e, "notification_CENTER_ITEM_WEAPON_DROP notification_CENTER_ITEM_WEAPON_GOT notification_CENTER_ITEM_WEAPON_NOAMMO notification_CENTER_ITEM_WEAPON_PRIMORSEC notification_CENTER_ITEM_WEAPON_UNAVAILABLE");
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBox_T(0, "notification_INFO_ITEM_WEAPON_DONTHAVE", _("Weapon info message notifications"), "-"));
			makeMulti(e, "notification_INFO_ITEM_WEAPON_DROP notification_INFO_ITEM_WEAPON_GOT notification_INFO_ITEM_WEAPON_NOAMMO notification_INFO_ITEM_WEAPON_PRIMORSEC notification_INFO_ITEM_WEAPON_UNAVAILABLE");

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticHeaderLabel(_("Announcers")));
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBoxEx_T(2, 0, "notification_ANNCE_NUM_RESPAWN_1", _("Respawn countdown sounds"), "-"));
			makeMulti(e, "notification_ANNCE_NUM_RESPAWN_2 notification_ANNCE_NUM_RESPAWN_3 notification_ANNCE_NUM_RESPAWN_4 notification_ANNCE_NUM_RESPAWN_5 notification_ANNCE_NUM_RESPAWN_6 notification_ANNCE_NUM_RESPAWN_7 notification_ANNCE_NUM_RESPAWN_8 notification_ANNCE_NUM_RESPAWN_9 notification_ANNCE_NUM_RESPAWN_10");
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBoxEx_T(1, 0, "notification_ANNCE_KILLSTREAK_03", _("Killstreak sounds"), "-"));
			makeMulti(e, "notification_ANNCE_KILLSTREAK_05 notification_ANNCE_KILLSTREAK_10 notification_ANNCE_KILLSTREAK_15 notification_ANNCE_KILLSTREAK_20 notification_ANNCE_KILLSTREAK_25 notification_ANNCE_KILLSTREAK_30");
	me.TR(me);
		me.TD(me, 1, 2.9, e = makeXonoticCheckBoxEx_T(1, 0, "notification_ANNCE_ACHIEVEMENT_AIRSHOT", _("Achievement sounds"), "-"));
			makeMulti(e, "notification_ANNCE_ACHIEVEMENT_AMAZING notification_ANNCE_ACHIEVEMENT_AWESOME notification_ANNCE_ACHIEVEMENT_BOTLIKE notification_ANNCE_ACHIEVEMENT_ELECTROBITCH notification_ANNCE_ACHIEVEMENT_IMPRESSIVE notification_ANNCE_ACHIEVEMENT_YODA");
}
