#ifdef INTERFACE
CLASS(XonoticWelcomeDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticWelcomeDialog, fill, void(entity))
	ATTRIB(XonoticWelcomeDialog, title, string, _("Welcome"))
	ATTRIB(XonoticWelcomeDialog, color, vector, SKINCOLOR_DIALOG_WELCOME)
	ATTRIB(XonoticWelcomeDialog, intendedWidth, float, 0.7)
	ATTRIB(XonoticWelcomeDialog, rows, float, 14)
	ATTRIB(XonoticWelcomeDialog, columns, float, 4)
	ATTRIB(XonoticWelcomeDialog, name, string, "Welcome")

	METHOD(XonoticWelcomeDialog, configureDialog, void(entity))
	METHOD(XonoticWelcomeDialog, readInputArgs, void(entity, float))
	ATTRIB(XonoticWelcomeDialog, serverinfo_name, string, string_null)
	ATTRIB(XonoticWelcomeDialog, serverinfo_name_ent, entity, world)
	ATTRIB(XonoticWelcomeDialog, serverinfo_ip, string, string_null)
	ATTRIB(XonoticWelcomeDialog, serverinfo_ip_ent, entity, world)
	ATTRIB(XonoticWelcomeDialog, serverinfo_MOTD, string, string_null)
	ATTRIB(XonoticWelcomeDialog, serverinfo_MOTD_ent, entity, world)
ENDCLASS(XonoticWelcomeDialog)
#endif

#ifdef IMPLEMENTATION
void welcomeDialog_resetStrings(entity me)
{
	if(me.serverinfo_name)
		strunzone(me.serverinfo_name);
	me.serverinfo_name = strzone(_("<NO NAME>"));

	if(me.serverinfo_ip)
		strunzone(me.serverinfo_ip);
	me.serverinfo_ip = strzone(_("<NO IP>"));

	if(me.serverinfo_MOTD)
		strunzone(me.serverinfo_MOTD);
	me.serverinfo_MOTD = strzone(_("<NO MOTD>"));
}
void XonoticWelcomeDialog_configureDialog(entity me)
{
	welcomeDialog_resetStrings(me);
	SUPER(XonoticWelcomeDialog).configureDialog(me);
}
void XonoticWelcomeDialog_readInputArgs(entity me, float argsbuf)
{
	float i = 0;
	string s;
	welcomeDialog_resetStrings(me);
	while((s = bufstr_get(argsbuf, i)) != "")
	{
		if(s == "serverinfo_name")
		{
			if(me.serverinfo_name)
				strunzone(me.serverinfo_name);
			me.serverinfo_name = strzone(bufstr_get(argsbuf, i + 1));
			++i;
		}
		else if(s == "serverinfo_ip")
		{
			if(me.serverinfo_ip)
				strunzone(me.serverinfo_ip);
			me.serverinfo_ip = strzone(bufstr_get(argsbuf, i + 1));
			++i;
		}
		else if(s == "serverinfo_MOTD")
		{
			if(me.serverinfo_MOTD)
				strunzone(me.serverinfo_MOTD);
			me.serverinfo_MOTD = strzone(bufstr_get(argsbuf, i + 1));
			++i;
		}
		++i;
	}
	me.serverinfo_name_ent.setText(me.serverinfo_name_ent, me.serverinfo_name);
	me.serverinfo_ip_ent.setText(me.serverinfo_ip_ent, me.serverinfo_ip);
	me.serverinfo_MOTD_ent.setText(me.serverinfo_MOTD_ent, me.serverinfo_MOTD);
}

void XonoticWelcomeDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 4, me.serverinfo_name_ent = makeXonoticTextLabel(0.5, ""));
	me.TR(me);
		me.TD(me, 1, 4, me.serverinfo_ip_ent = makeXonoticTextLabel(0.5, ""));
	me.TR(me);
	me.TR(me);
		me.TD(me, 10, 4, me.serverinfo_MOTD_ent = makeXonoticTextListBox());
			me.serverinfo_MOTD_ent.allowColors = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TDempty(me, 1);
		me.TD(me, 1, 2, e = makeXonoticCommandButton(_("Disconnect"), '0 0 0', "disconnect", COMMANDBUTTON_CLOSE));
}
#endif
