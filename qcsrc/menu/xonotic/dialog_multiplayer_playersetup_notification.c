#ifdef INTERFACE
CLASS(XonoticNotificationDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticNotificationDialog, toString, string(entity))
	METHOD(XonoticNotificationDialog, fill, void(entity))
	METHOD(XonoticNotificationDialog, showNotify, void(entity))
	ATTRIB(XonoticNotificationDialog, title, string, _("Notification settings"))
	ATTRIB(XonoticNotificationDialog, color, vector, SKINCOLOR_DIALOG_MODEL)
	ATTRIB(XonoticNotificationDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticNotificationDialog, rows, float, 7)
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
	
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Body fading:")));
		me.TD(me, 1, 2, e = makeXonoticSlider(0, 2, 0.2, "cl_deathglow"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gibs:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_nogibs"));
			e.addValue(e, ZCTX(_("GIBS^None")), "1");
			e.addValue(e, ZCTX(_("GIBS^Few")), "0.75");
			e.addValue(e, ZCTX(_("GIBS^Many")), "0.5");
			e.addValue(e, ZCTX(_("GIBS^Lots")), "0");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "cl_gentle", 0, 0);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_forceplayermodels", _("Force player models to mine")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_forceplayercolors", _("Force player colors to mine")));
	me.TR(me);
		
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif
