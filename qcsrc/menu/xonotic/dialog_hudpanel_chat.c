#ifdef INTERFACE
CLASS(XonoticHUDChatDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDChatDialog, fill, void(entity))
	ATTRIB(XonoticHUDChatDialog, title, string, _("Chat Panel"))
	ATTRIB(XonoticHUDChatDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDChatDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDChatDialog, rows, float, 15)
	ATTRIB(XonoticHUDChatDialog, columns, float, 4)
	ATTRIB(XonoticHUDChatDialog, name, string, "HUDchat")
ENDCLASS(XonoticHUDChatDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticHUDChatDialog_fill(entity me)
{
	entity e;
	string panelname = "chat";
	float i;

	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_panel_chat", _("Enable panel")));
	me.TR(me);
		me.TD(me, 1, 1.4, e = makeXonoticTextLabel(0, _("Background:")));
			me.TD(me, 1, 1.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg"))));
				e.addValue(e, _("Default"), "");
				e.addValue(e, _("Disable"), "0");
				e.addValue(e, strzone(strcat("border_", panelname)), strzone(strcat("border_", panelname)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Color:")));
		me.TD(me, 2, 2.4, e = makeXonoticColorpickerString(strzone(strcat("hud_panel_", panelname, "_bg_color")), "hud_panel_bg_color"));
			setDependentStringNotEqual(e, strzone(strcat("hud_panel_", panelname, "_bg_color")), "");
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticCheckBoxString("", "1 1 1", strzone(strcat("hud_panel_", panelname, "_bg_color")), _("Use default")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Border size:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_border"))));
				e.addValue(e, _("Default"), "");
				e.addValue(e, _("Disable"), "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i * 2, 0)), strzone(ftos(i * 2)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Alpha:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_alpha"))));
				e.addValue(e, _("Default"), "");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Team Color:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_color_team"))));
				e.addValue(e, _("Default"), "");
				e.addValue(e, _("Disable"), "0");
				for(i = 1; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i/10, 1)), strzone(ftos(i/10)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.4);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_configure_teamcolorforced", _("Test the team color in HUD configure mode")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Padding:")));
			me.TD(me, 1, 2.6, e = makeXonoticTextSlider(strzone(strcat("hud_panel_", panelname, "_bg_padding"))));
				e.addValue(e, _("Default"), "");
				for(i = 0; i <= 10; ++i)
					e.addValue(e, strzone(ftos_decimals(i - 5, 0)), strzone(ftos(i - 5)));
				e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Chat entries:")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Chat size:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(6, 20, 1, "con_chatsize"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Chat lifetime:")));
		me.TD(me, 1, 2.6, e = makeXonoticSlider(5, 60, 5, "con_chattime"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "con_chatsound", _("Chat beep sound")));
}
#endif
