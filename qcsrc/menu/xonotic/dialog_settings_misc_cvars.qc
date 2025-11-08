#include "dialog_settings_misc_cvars.qh"

#include "checkbox.qh"
#include "cvarlist.qh"
#include "textlabel.qh"
#include "inputbox.qh"
#include "button.qh"

void XonoticCvarsDialog_showNotify(entity me)
{
	SUPER(XonoticCvarsDialog).showNotify(me);
	loadAllCvars(me);
}
void XonoticCvarsDialog_fill(entity me) // in this dialog, use SKINCOLOR_CVARLIST_CONTROLS to color ALL controls
{

	entity e, cvarlist;

	cvarlist = makeXonoticCvarList();

	cvarlist.color =
		cvarlist.colorF =
		cvarlist.color2 =
		cvarlist.colorC =
		SKINCOLOR_CVARLIST_CONTROLS;

	// todo:
	// add button which does cvar_resettodefaults_saveonly

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Filter:")));
		me.TD(me, 1, 3, e = makeXonoticInputBox(0, string_null));
			e.color = e.colorF = SKINCOLOR_CVARLIST_CONTROLS;
			e.cb_color = e.cb_colorC = e.cb_colorF = SKINCOLOR_CVARLIST_CONTROLS;
			e.onChange = CvarList_Filter_Change;
			e.onChangeEntity = cvarlist;
			cvarlist.controlledTextbox = e; // this COULD also be the Value box, but this leads to accidentally editing stuff
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "menu_cvarlist_onlymodified", _("Modified cvars only")));
			e.color = e.colorC = e.colorF = e.colorD = SKINCOLOR_CVARLIST_CONTROLS;
			e.onClickEntity = cvarlist;
			e.onClick = CvarList_Filter_ModifiedCvars;
	me.TR(me);
		me.TD(me, me.rows - me.currentRow - 9, me.columns, cvarlist);
	me.gotoRC(me, me.rows - 8, 0);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Setting:")));
		me.TD(me, 1, me.columns - 1, e = makeXonoticTextLabel(0, string_null));
			e.colorL = '1 1 0'; // draw the cvar name yellow
			cvarlist.cvarNameBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Type:")));
		me.TD(me, 1, me.columns - 1, e = makeXonoticTextLabel(0, string_null));
			cvarlist.cvarTypeBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Value:")));
		me.TD(me, 1, me.columns - 2, e = makeXonoticInputBox(0, string_null));
			cvarlist.cvarValueBox = e;
			e.color = e.colorF = SKINCOLOR_CVARLIST_CONTROLS;
			e.cb_color = e.cb_colorC = e.cb_colorF = SKINCOLOR_CVARLIST_CONTROLS;
			e.onChange = CvarList_Value_Change;
			e.onChangeEntity = cvarlist;
			e.onEnter = CvarList_End_Editing;
			e.onEnterEntity = cvarlist;
		me.TD(me, 1, 1, e = makeXonoticButton_T(string_null, SKINCOLOR_CVARLIST_CONTROLS, _("Reset to default")));
			cvarlist.cvarDefaultBox = e;
			e.onClick = CvarList_Revert_Click;
			e.onClickEntity = cvarlist;
			e.allowCut = true;
			e.marginLeft = e.marginRight = 0.5;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Description:")));
		me.TD(me, 1, me.columns - 1, e = makeXonoticTextLabel(0, string_null));
			cvarlist.cvarDescriptionBox = e;
			e.allowWrap = true;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), SKINCOLOR_CVARLIST_CONTROLS));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
