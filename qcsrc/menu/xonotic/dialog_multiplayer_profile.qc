#include "dialog_multiplayer_profile.qh"

#include "playermodel.qh"
#include "statslist.qh"
#include "languagelist.qh"
#include "textlabel.qh"
#include "commandbutton.qh"
#include "inputbox.qh"
#include "colorpicker.qh"
#include "charmap.qh"
#include "colorbutton.qh"
#include "checkbox.qh"
#include "radiobutton.qh"

entity makeXonoticProfileTab()
{
	entity me;
	me = NEW(XonoticProfileTab);
	me.configureDialog(me);
	return me;
}
void XonoticProfileTab_draw(entity me)
{
	if(cvar_string("_cl_name") == "Player")
		me.playerNameLabel.alpha = ((mod(time * 2, 2) < 1) ? 1 : 0);
	else
		me.playerNameLabel.alpha = me.playerNameLabelAlpha;
	SUPER(XonoticProfileTab).draw(me);
}
void language_selector_click(entity me, entity btn)
{
	localcmd("\nmenu_cmd languageselect\n");
}
void XonoticProfileTab_fill(entity me)
{
	entity e, pms, label, box;
	float i;
	entity profileApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"color -1 -1; " // apply colors contained in _cl_color
		"name \"$_cl_name\"; "
		"playermodel $_cl_playermodel; "
		"playerskin $_cl_playerskin"
		, COMMANDBUTTON_APPLY);
	profileApplyButton.disableOnClick = true;

	// ==============
	//  NAME SECTION
	// ==============
	me.gotoRC(me, 0.5, 0);
		me.TD(me, 1, 3, me.playerNameLabel = makeXonoticHeaderLabel(_("Name")));

	me.gotoRC(me, 1.5, 0);
		me.TD(me, 1, 3, label = makeXonoticTextLabel(0.5, string_null));
			label.allowCut = true;
			label.allowColors = true;
			label.alpha = 1;
			label.isBold = true;
			label.fontSize = SKINFONTSIZE_TITLE;

	me.gotoRC(me, 2.5, 0);
		me.TD(me, 1, 3.0, box = makeXonoticInputBox_T(1, "_cl_name",
			_("Name under which you will appear in the game")));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = false;  // Sorry, can't do this, it spams "name" commands.
			box.enableClearButton = false;
			box.applyButton = profileApplyButton;
			label.textEntity = box;
	me.TR(me);
		me.TD(me, 5, 1, e = makeXonoticColorpicker(box));
		me.TD(me, 5, 2, e = makeXonoticCharmap(box));

	// ===============
	//  MODEL SECTION
	// ===============
	//me.gotoRC(me, 0.5, 3.1); me.setFirstColumn(me, me.currentColumn); // TOP RIGHT
	//me.gotoRC(me, 9, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM RIGHT
	me.gotoRC(me, 9, 0); me.setFirstColumn(me, me.currentColumn); // BOTTOM LEFT
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Model")));

	me.TR(me);
		//me.TDempty(me, 0); // MODEL LEFT, COLOR RIGHT
		me.TDempty(me, 1); // MODEL RIGHT, COLOR LEFT
		pms = makeXonoticPlayerModelSelector();
		me.TD(me, 1, 0.3, e = makeXonoticButton("<<", '0 0 0'));
			e.onClick = PlayerModelSelector_Prev_Click;
			e.onClickEntity = pms;
			e.applyButton = profileApplyButton;
		me.TD(me, 11.5, 1.4, pms);
		me.TD(me, 1, 0.3, e = makeXonoticButton(">>", '0 0 0'));
			e.onClick = PlayerModelSelector_Next_Click;
			e.onClickEntity = pms;
			e.applyButton = profileApplyButton;

	//me.setFirstColumn(me, me.currentColumn + 2); // MODEL LEFT, COLOR RIGHT
	me.gotoRC(me, me.currentRow, 0); me.setFirstColumn(me, me.currentColumn); // MODEL RIGHT, COLOR LEFT
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticHeaderLabel(_("Glowing color")));
		for(i = 0; i < 15; ++i)
		{
			if(mod(i, 5) == 0)
				me.TR(me);
			me.TDNoMargin(me, 1, 0.2, e = makeXonoticColorButton(1, 0, i), '0 1 0');
				e.applyButton = profileApplyButton;
		}
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticHeaderLabel(_("Detail color")));
		for(i = 0; i < 15; ++i)
		{
			if(mod(i, 5) == 0)
				me.TR(me);
			me.TDNoMargin(me, 1, 0.2, e = makeXonoticColorButton(2, 1, i), '0 1 0');
				e.applyButton = profileApplyButton;
		}

	// ====================
	//  STATISTICS SECTION
	// ====================
	me.gotoRC(me, 0.5, 3.1); me.setFirstColumn(me, me.currentColumn); // TOP RIGHT
	//me.gotoRC(me, 9, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM RIGHT
	//me.gotoRC(me, 9, 0); me.setFirstColumn(me, me.currentColumn); // BOTTOM LEFT
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Statistics")));

	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "cl_allow_uidtracking", _("Allow player statistics to track your client")));
			e.sendCvars = true;
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "cl_allow_uid2name", _("Allow player statistics to use your nickname")));
			e.sendCvars = true;
			setDependent(e, "cl_allow_uidtracking", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.25);
		me.TD(me, 1, 2.5, e = makeXonoticCheckBox(0, "cl_allow_uidranking", _("Allow player statistics to rank you in leaderboards")));
			e.sendCvars = true;
			setDependent(e, "cl_allow_uidtracking", 1, 1);
	me.gotoRC(me, 4.5, 3.1); // TOP RIGHT
	//me.gotoRC(me, 12.5, 3.1); // BOTTOM RIGHT
	//me.gotoRC(me, 12.5, 0); // BOTTOM LEFT
		me.TDempty(me, 0.25);
		me.TD(me, 9, 2.5, statslist = makeXonoticStatsList());
		//setDependent(statslist, "cl_allow_uidtracking", 1, 1);

	// =================
	//  COUNTRY SECTION
	// =================
	me.gotoRC(me, 16, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM SECTION, TOP POS
	//me.gotoRC(me, 13.5, 3.1); me.setFirstColumn(me, me.currentColumn); // BOTTOM SECTION, TOP POS
	//me.gotoRC(me, 0.5, 3.1); me.setFirstColumn(me, me.currentColumn); // TOP SECTION, TOP POS
		//me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Country")));

	me.TR(me);
		me.TDempty(me, 0.75);
		me.TD(me, 1, 1.5, e = makeXonoticButton(_("Select language..."), '0 0 0'));
			e.onClick = language_selector_click;
			e.onClickEntity = me;
		/*
		me.TDempty(me, 0.5);
		me.TD(me, 4.5, 2, e = makeXonoticLanguageList()); // todo: cl_country: create proper country list
		*/

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, profileApplyButton);
}
