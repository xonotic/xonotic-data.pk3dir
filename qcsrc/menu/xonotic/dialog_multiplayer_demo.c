#ifdef INTERFACE
CLASS(XonoticDemoBrowserTab) EXTENDS(XonoticTab)
	METHOD(XonoticDemoBrowserTab, fill, void(entity))
	ATTRIB(XonoticDemoBrowserTab, title, string, _("Demo"))
	ATTRIB(XonoticDemoBrowserTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticDemoBrowserTab, rows, float, 22)
	ATTRIB(XonoticDemoBrowserTab, columns, float, 6.5)
	ATTRIB(XonoticDemoBrowserTab, name, string, "DemoBroswer")	
ENDCLASS(XonoticDemoBrowserTab)
entity makeXonoticDemoBrowserTab();
#endif

#ifdef IMPLEMENTATION
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
	entity btn;
	entity dlist;

	me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticCheckBox(0, "cl_autodemo", _("Record demos while playing")));
	me.TR(me);
	dlist = makeXonoticDemoList();
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticTextLabel(0, _("Filter:")));
		me.TD(me, 1, 0.5, btn = makeXonoticButton(_("Clear"), '0 0 0'));
			btn.onClick = InputBox_Clear_Click;
		me.TD(me, 1, me.columns - 1, e = makeXonoticInputBox(0, string_null));
			e.onChange = DemoList_Filter_Change;
			e.onChangeEntity = dlist;
			btn.onClickEntity = e;
			dlist.controlledTextbox = e;
	me.TR(me);
		me.TD(me, me.rows - 4, me.columns, dlist);
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(_("Timedemo"), '0 0 0'));
			e.onClick = TimeDemo_Click;
			e.onClickEntity = dlist;
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(_("DEMO^Play"), '0 0 0'));
			e.onClick = StartDemo_Click;
			e.onClickEntity = dlist;
}
#endif
