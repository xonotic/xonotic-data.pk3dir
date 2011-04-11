#ifdef INTERFACE
CLASS(XonoticHUDShownamesDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDShownamesDialog, fill, void(entity))
	ATTRIB(XonoticHUDShownamesDialog, title, string, _("Shownames Panel"))
	ATTRIB(XonoticHUDShownamesDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDShownamesDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDShownamesDialog, rows, float, 17)
	ATTRIB(XonoticHUDShownamesDialog, columns, float, 4)
	ATTRIB(XonoticHUDShownamesDialog, name, string, "HUDshownames")
ENDCLASS(XonoticHUDShownamesDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDShownamesDialog_fill(entity me)
{
	entity e;
	string panelname = "shownames";
	float i;

    me.TR(me);
        me.TD(me, 1, 4, e = makeXonoticTextSlider("hud_panel_shownames"));
            e.addValue(e, _("Panel disabled"), "0");
            e.addValue(e, _("Panel enabled on teammates"), "1");
            e.addValue(e, _("Panel always enabled"), "2");
            e.configureXonoticTextSliderValues(e);

    DIALOG_HUDPANEL_COMMON_NOTOGGLE();

}
#endif
