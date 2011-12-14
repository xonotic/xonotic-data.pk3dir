#ifdef INTERFACE
CLASS(XonoticHUDItemsTimeDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDItemsTimeDialog, fill, void(entity))
	ATTRIB(XonoticHUDItemsTimeDialog, title, string, _("Items Time Panel"))
	ATTRIB(XonoticHUDItemsTimeDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDItemsTimeDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDItemsTimeDialog, rows, float, 15)
	ATTRIB(XonoticHUDItemsTimeDialog, columns, float, 4)
	ATTRIB(XonoticHUDItemsTimeDialog, name, string, "HUDitemstime")
ENDCLASS(XonoticHUDItemsTimeDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDItemsTimeDialog_fill(entity me)
{
	entity e;
	string panelname = "itemstime";

	DIALOG_HUDPANEL_COMMON();

	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Items time display:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Align icon:")));
			me.TD(me, 1, 2.4/2, e = makeXonoticRadioButton(2, "hud_panel_itemstime_iconalign", "0", _("Left")));
			me.TD(me, 1, 2.4/2, e = makeXonoticRadioButton(2, "hud_panel_itemstime_iconalign", "1", _("Right")));
}
#endif
