#ifdef INTERFACE
CLASS(XonoticHUDChatDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticHUDChatDialog, fill, void(entity))
	ATTRIB(XonoticHUDChatDialog, title, string, "Chat Panel Setup")
	ATTRIB(XonoticHUDChatDialog, color, vector, SKINCOLOR_DIALOG_TEAMSELECT)
	ATTRIB(XonoticHUDChatDialog, intendedWidth, float, 0.4)
	ATTRIB(XonoticHUDChatDialog, rows, float, 15)
	ATTRIB(XonoticHUDChatDialog, columns, float, 4)
	ATTRIB(XonoticHUDChatDialog, name, string, "HUDchat")
ENDCLASS(XonoticHUDChatDialog)
#endif

#ifdef IMPLEMENTATION
void fillXonoticHUDChatDialog(entity me)
{
	entity e;
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "hud_chat", "On/Off"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Team Color:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_chat_bg_color_team"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Background Alpha:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(0, 1, 0.01, "hud_chat_bg_alpha"));
	me.TR(me);
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Font size:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(6, 16, 1, "con_chatsize"));
		me.TR(me);
			me.TD(me, 1, 2, e = makeXonoticTextLabel(0, "Message lifetime:"));
				me.TD(me, 1, 2, e = makeXonoticSlider(16, 40, 2, "con_chattime"));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "con_chatsound", "Message sound beep"));
	//me.gotoRC(me, me.rows - 1, 0);
		//me.TD(me, 1, me.columns, e = makeXonoticCommandButton("Exit Setup", '0 0 0', "_hud_configure 0", 1));
}
#endif
