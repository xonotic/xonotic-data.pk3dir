#ifdef INTERFACE
CLASS(XonoticAdvancedDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticAdvancedDialog, fill, void(entity))
	METHOD(XonoticAdvancedDialog, showNotify, void(entity))
	METHOD(XonoticAdvancedDialog, close, void(entity))
	ATTRIB(XonoticAdvancedDialog, title, string, _("Advanced server settings"))
	ATTRIB(XonoticAdvancedDialog, color, vector, SKINCOLOR_DIALOG_ADVANCED)
	ATTRIB(XonoticAdvancedDialog, intendedWidth, float, 0.5)
	ATTRIB(XonoticAdvancedDialog, rows, float, 17)
	ATTRIB(XonoticAdvancedDialog, columns, float, 3)
	ATTRIB(XonoticAdvancedDialog, refilterEntity, entity, NULL)
ENDCLASS(XonoticAdvancedDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticAdvancedDialog_showNotify(entity me)
{
	loadAllCvars(me);
}

void XonoticAdvancedDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, makeXonoticTextLabel(0, _("Game speed:")));
		me.TD(me, 1, 1.6, makeXonoticSlider(0.5, 2.0, 0.1, "slowmo"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, makeXonoticTextLabel(0, _("Teamplay settings:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, makeXonoticTextLabel(0, _("Friendly fire scale:")));
		me.TD(me, 1, 1.6, makeXonoticSlider(0, 1.0, 0.05, "g_friendlyfire"));
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 2.6, makeXonoticCheckBox(0, "g_friendlyfire_virtual", _("Virtual friendly fire (effect only)")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, makeXonoticTextLabel(0, _("Friendly fire penalty:")));
		me.TD(me, 1, 1.6, makeXonoticSlider(0, 1.0, 0.05, "g_mirrordamage"));
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 2.6, makeXonoticCheckBox(0, "g_mirrordamage_virtual", _("Virtual penalty (effect only)")));
	me.TR(me);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}

void XonoticAdvancedDialog_close(entity me)
{
	if(me.refilterEntity)
		me.refilterEntity.refilter(me.refilterEntity);
	SUPER(XonoticAdvancedDialog).close(me);
}
#endif
