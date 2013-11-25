#ifdef INTERFACE
CLASS(XonoticDemoBrowserTab) EXTENDS(XonoticTab)
	METHOD(XonoticDemoBrowserTab, fill, void(entity))
	ATTRIB(XonoticDemoBrowserTab, title, string, _("Demo"))
	ATTRIB(XonoticDemoBrowserTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticDemoBrowserTab, rows, float, 21)
	ATTRIB(XonoticDemoBrowserTab, columns, float, 6.5)
	ATTRIB(XonoticDemoBrowserTab, name, string, "DemoBrowser")
ENDCLASS(XonoticDemoBrowserTab)
entity makeXonoticDemoBrowserTab();
void Demo_Confirm(entity me, entity btn);
#endif

#ifdef IMPLEMENTATION
void DemoConfirm_Check_Gamestatus(entity me, entity btn)
{
	if not(gamestatus & (GAME_CONNECTED | GAME_ISSERVER)) // we're not in a match, lets watch the demo
	{
		//TimeDemo_Click;
		//StartDemo_Click;
		return;
	}
	else // already in a match, player has to confirm
	{
		Demo_Confirm(me, btn);
	}
}

entity makeXonoticDemoBrowserTab()
{
	entity me;
	me = spawnXonoticDemoBrowserTab();
	me.configureDialog(me);
	return me;
}
void XonoticDemoBrowserTab_fill(entity me)
{
	entity e;
	entity dlist = makeXonoticDemoList();
	
	me.TR(me);
		me.TD(me, 1, 0.6, e = makeXonoticTextLabel(1, _("Filter:")));
		me.TD(me, 1, 2.9, e = makeXonoticInputBox(0, string_null));
			e.onChange = DemoList_Filter_Change;
			e.onChangeEntity = dlist;
			dlist.controlledTextbox = e;

	me.gotoRC(me, 0, 3.7);
		me.TD(me, 1, 1.5, e = makeXonoticCheckBox(0, "cl_autodemo", _("Auto record demos")));
		me.TD(me, 1, 1, e = makeXonoticButton(_("Refresh"), '0 0 0'));
			//e.onClick = DemoList_Filter_Change;
			//e.onClickEntity = dlist;


	me.gotoRC(me, 1.5, 0);
		me.TD(me, me.rows - 2.5, me.columns, dlist);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(_("Timedemo"), '0 0 0'));
			e.onClick = DemoConfirm_Check_Gamestatus;
			e.onClickEntity = dlist;
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(ZCTX(_("DEMO^Play")), '0 0 0'));
			e.onClick = DemoConfirm_Check_Gamestatus;
			e.onClickEntity = dlist;
}
#endif
