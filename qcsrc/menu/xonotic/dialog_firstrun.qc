#include "dialog_firstrun.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "languagelist.qh"
#include "radiobutton.qh"
#include "colorpicker.qh"
#include "charmap.qh"
#include "commandbutton.qh"

bool XonoticFirstRunDialog_shouldShow()
{
    return cvar_string("_cl_name") == cvar_defstring("_cl_name");
}

float CheckFirstRunButton(entity me)
{
	if(cvar_string("_cl_name") != cvar_defstring("_cl_name"))
		return 1;

	if(cvar_string("_menu_prvm_language") != prvm_language)
		return 1; // OK will then reopen the dialog in another language

	if(cvar_string("cl_allow_uid2name") != "-1")
		return 1;

	return 0;
}

void firstRun_setLanguage(entity me)
{
	if(prvm_language != cvar_string("_menu_prvm_language"))
		localcmd("\nprvm_language \"$_menu_prvm_language\"; saveconfig; menu_restart\n");
}

void XonoticFirstRunDialog_fill(entity me)
{
	entity e;
	entity label, box;

	me.TR(me);
	me.TR(me);
		me.TDempty(me, 1);
		me.TD(me, 2, 4, e = makeXonoticTextLabel(0, _("Welcome to Xonotic, please select your language preference and enter your player name to get started.  You can change these options later through the menu system.")));
		e.allowWrap = 1;
		e.allowWrap_spacing = 0.5;
	me.TR(me);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.5, me.playerNameLabel = makeXonoticTextLabel(0, _("Name:")));
			me.playerNameLabelAlpha = me.playerNameLabel.alpha;
		me.TD(me, 1, 3.25, label = makeXonoticTextLabel(0, string_null));
			label.allowCut = 1;
			label.allowColors = 1;
			label.alpha = 1;
	me.TR(me);
		me.TD(me, 1, 3.75, box = makeXonoticInputBox_T(1, "_cl_name",
			_("Name under which you will appear in the game")));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 0;  // Sorry, can't do this, it spams "name" commands.
			box.enableClearButton = 0;
			label.textEntity = box;
	me.TR(me);
		me.TD(me, 5, 1.25, e = makeXonoticColorpicker(box));
		me.TD(me, 5, 2.5, e = makeXonoticCharmap(box));
	me.TR(me);
	me.TR(me);
	me.TR(me);
	me.TR(me);

	me.gotoRC(me, 3, 4); me.setFirstColumn(me, me.currentColumn);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Text language:")));
	me.TR(me);
		me.TD(me, 6, 2, e = makeXonoticLanguageList());
			e.name = "languageselector_firstrun";
			e.setLanguage = firstRun_setLanguage;
	me.TR(me);
	me.TR(me);

	me.gotoRC(me, me.rows - 4, 0); me.setFirstColumn(me, me.currentColumn);
	me.TD(me, 1, me.columns, e = makeXonoticTextLabel(0.5, _("Allow player statistics to use your nickname at stats.xonotic.org?")));

	me.gotoRC(me, me.rows - 3, 0);
	me.TDempty(me, 1.5);
	me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "cl_allow_uid2name", "1", _("Yes")));
	me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "cl_allow_uid2name", "0", _("No")));
	me.TD(me, 1, 1, e = makeXonoticRadioButton(1, "cl_allow_uid2name", "-1", _("Undecided")));
	me.TR(me);
	me.TD(me, 1, me.columns, e = makeXonoticTextLabel(0.5, _("Player statistics are enabled by default, you can change this in the Profile menu")));

	// because of the language selector, this is a menu_restart!
	me.gotoRC(me, me.rows - 1, 0);
	me.TD(me, 1, me.columns, e = makeXonoticCommandButton(_("Save settings"), '0 0 0', "prvm_language \"$_menu_prvm_language\"; saveconfig; menu_restart", COMMANDBUTTON_APPLY));
		setDependentWeird(e, CheckFirstRunButton);
}
