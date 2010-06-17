#ifdef INTERFACE
CLASS(XonoticCvarsDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticCvarsDialog, toString, string(entity))
	METHOD(XonoticCvarsDialog, fill, void(entity))
	METHOD(XonoticCvarsDialog, showNotify, void(entity))
	ATTRIB(XonoticCvarsDialog, title, string, "Advanced settings")
	ATTRIB(XonoticCvarsDialog, color, vector, SKINCOLOR_DIALOG_CVARS)
	ATTRIB(XonoticCvarsDialog, intendedWidth, float, 0.8)
	ATTRIB(XonoticCvarsDialog, rows, float, 25)
	ATTRIB(XonoticCvarsDialog, columns, float, 6)
ENDCLASS(XonoticCvarsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticCvarsDialog_showNotify(entity me)
{
	loadAllCvars(me);
}
string XonoticCvarsDialog_toString(entity me)
{
	return "XXX";
}
void XonoticCvarsDialog_fill(entity me)
{
	entity e, cvarlist, btn;
	cvarlist = makeXonoticCvarList();
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Cvar filter:"));
		me.TD(me, 1, 0.5, btn = makeXonoticButton("Clear", '0 0 0'));
		me.TD(me, 1, me.columns - 1.5, e = makeXonoticInputBox(0, string_null));
			e.onChange = CvarList_Filter_Change;
			e.onChangeEntity = cvarlist;
			btn.onClick = InputBox_Clear_Click;
			btn.onClickEntity = e;
			cvarlist.controlledTextbox = e; // this COULD also be the Value box, but this leads to accidentally editing stuff
	me.TR(me);
		me.TD(me, me.rows - me.currentRow - 7, me.columns, cvarlist);
	me.gotoRC(me, me.rows - 7, 0);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Setting:"));
		me.TD(me, 1, me.columns - 1, e = makeXonoticTextLabel(0, string_null));
			cvarlist.cvarNameBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Type:"));
		me.TD(me, 1, me.columns - 1, e = makeXonoticTextLabel(0, string_null));
			cvarlist.cvarTypeBox = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Value:"));
		me.TD(me, 1, me.columns - 2, e = makeXonoticInputBox(0, string_null));
			cvarlist.cvarValueBox = e;
			e.onChange = CvarList_Value_Change;
			e.onChangeEntity = cvarlist;
		me.TD(me, 1, 1, e = makeXonoticButton(string_null, SKINCOLOR_CVARLIST_REVERTBUTTON));
			cvarlist.cvarDefaultBox = e;
			e.onClick = CvarList_Revert_Click;
			e.onClickEntity = cvarlist;
			e.allowCut = 1;
			e.marginLeft = e.marginRight = 0.5;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Description:"));
		me.TD(me, 1, me.columns - 1, e = makeXonoticTextLabel(0, string_null));
			cvarlist.cvarDescriptionBox = e;
			e.allowWrap = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton("OK", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

#endif
