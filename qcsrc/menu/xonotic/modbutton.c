#ifdef INTERFACE
CLASS(XonoticModButton) EXTENDS(XonoticButton)
	METHOD(XonoticModButton, configureXonoticModButton, void(entity, string))
	ATTRIB(XonoticModButton, destination, string, string_null)
ENDCLASS(XonoticModButton)
entity makeXonoticModButton(string menu);
void XonoticModButton_Click(entity me, entity other);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticModButton(string menu)
{
	entity me;
	me = spawnXonoticModButton();
	me.configureXonoticModButton(me, menu);
	return me;
}

void XonoticModButton_Click(entity me, entity other)
{
	string thecmd;
	thecmd = strcat("\ndisconnect\nmenu_restart");

	if (me.destination != "")
		thecmd = strcat(thecmd, "\ntogglemenu\ndefer 0.1 \"menu_cmd directmenu ", me.destination,"\"\n");

	if (cvar_string("menu_slist_modfilter") == "havoc")
		thecmd = strcat("\ngamedir data", thecmd);
	else
		thecmd = strcat("\ngamedir havoc", thecmd);
	cmd(thecmd);
}

void configureXonoticModButtonXonoticModButton(entity me, string menu)
{
	me.configureXonoticButton(me, "", '0 0 0');
	me.onClick = XonoticModButton_Click;
	me.onClickEntity = me;
	me.destination = menu;

	if (cvar_string("menu_slist_modfilter") == "havoc")
		me.text = "Switch to Xonotic mode";
	else
		me.text = "Switch to Havoc mode";
}
#endif
