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
	ATTRIB(XonoticWelcomeDialog, serverinfo_pic, string, string_null)
	ATTRIB(XonoticWelcomeDialog, serverinfo_pic_ent, entity, NULL)
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

	if(me.serverinfo_pic)
		strunzone(me.serverinfo_pic);
	me.serverinfo_pic = strzone("nopic");
}
void XonoticWelcomeDialog_configureDialog(entity me)
{
	welcomeDialog_resetStrings(me);
	SUPER(XonoticWelcomeDialog).configureDialog(me);
}
void XonoticWelcomeDialog_readInputArgs(entity me, float argsbuf)
{
	int i = 0;
	string s;
	welcomeDialog_resetStrings(me);
	if(argsbuf >= 0)
	while((s = bufstr_get(argsbuf, i)) != "")
	{
		if(s == "name")
		{
			if(me.serverinfo_name)
				strunzone(me.serverinfo_name);
			me.serverinfo_name = strzone(bufstr_get(argsbuf, i + 1));
			++i;
		}
		else if(s == "ip")
		{
			if(me.serverinfo_ip)
				strunzone(me.serverinfo_ip);
			me.serverinfo_ip = strzone(bufstr_get(argsbuf, i + 1));
			++i;
		}
		else if(s == "motd")
		{
			if(me.serverinfo_MOTD)
				strunzone(me.serverinfo_MOTD);
			me.serverinfo_MOTD = strzone(bufstr_get(argsbuf, i + 1));
			++i;
		}
		else if(s == "pic")
		{
			if(me.serverinfo_pic)
				strunzone(me.serverinfo_pic);
			me.serverinfo_pic = strzone(strcat("/", bufstr_get(argsbuf, i + 1)));
			++i;
		}
		++i;
	}
	me.serverinfo_name_ent.setText(me.serverinfo_name_ent, me.serverinfo_name);
	me.serverinfo_ip_ent.setText(me.serverinfo_ip_ent, me.serverinfo_ip);
	me.serverinfo_MOTD_ent.setText(me.serverinfo_MOTD_ent, me.serverinfo_MOTD);

	if(me.serverinfo_pic_ent.src)
		strunzone(me.serverinfo_pic_ent.src);
	me.serverinfo_pic_ent.src = strzone(me.serverinfo_pic);
}

void XonoticWelcomeDialog_fill(entity me)
{
	entity e;

	me.TR(me);
		me.TD(me, 4, me.columns / 2, me.serverinfo_pic_ent = makeXonoticImage(string_null, 4.0/3.0));

	me.gotoRC(me, 1, me.columns / 2);
		me.TD(me, 1, me.columns / 2, me.serverinfo_name_ent = makeXonoticTextLabel(0, ""));
	me.gotoRC(me, 2, me.columns / 2);
		me.TD(me, 1, me.columns / 2, me.serverinfo_ip_ent = makeXonoticTextLabel(0, ""));

	me.gotoRC(me, 4, 0);
		me.TD(me, me.rows - 4 - 1, me.columns, me.serverinfo_MOTD_ent = makeXonoticTextListBox());
			me.serverinfo_MOTD_ent.allowColors = 1;
	me.gotoRC(me, me.rows - 1, 0);
		me.TDempty(me, 1);
		me.TD(me, 1, me.columns / 2, e = makeXonoticCommandButton(_("Disconnect"), '0 0 0', "disconnect", COMMANDBUTTON_CLOSE));
}
#endif
