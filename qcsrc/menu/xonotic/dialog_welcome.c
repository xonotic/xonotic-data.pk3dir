#ifdef INTERFACE
CLASS(XonoticWelcomeDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticWelcomeDialog, fill, void(entity))
	ATTRIB(XonoticWelcomeDialog, title, string, _("Welcome"))
	ATTRIB(XonoticWelcomeDialog, color, vector, SKINCOLOR_DIALOG_WELCOME)
	ATTRIB(XonoticWelcomeDialog, intendedWidth, float, 0.7)
	ATTRIB(XonoticWelcomeDialog, rows, float, 16)
	ATTRIB(XonoticWelcomeDialog, columns, float, 4)
	ATTRIB(XonoticWelcomeDialog, name, string, "Welcome")

	METHOD(XonoticWelcomeDialog, configureDialog, void(entity))
	METHOD(XonoticWelcomeDialog, readInputArgs, void(entity, float, float))
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
void XonoticWelcomeDialog_readInputArgs(entity me, float starting_arg, float arg_count)
{
	float i;
	welcomeDialog_resetStrings(me);
	for(i = starting_arg; i < arg_count; ++i)
	{
		if(argv(i) == "serverinfo_name")
		{
			if(me.serverinfo_name)
				strunzone(me.serverinfo_name);
			me.serverinfo_name = strzone(argv(i + 1));
			me.serverinfo_name_ent.setText(me.serverinfo_name_ent, me.serverinfo_name);
			++i;
		}
		else if(argv(i) == "serverinfo_ip")
		{
			if(me.serverinfo_ip)
				strunzone(me.serverinfo_ip);
			me.serverinfo_ip = strzone(argv(i + 1));
			me.serverinfo_ip_ent.setText(me.serverinfo_ip_ent, me.serverinfo_ip);
			++i;
		}
		else if(argv(i) == "serverinfo_MOTD")
		{
			if(me.serverinfo_MOTD)
				strunzone(me.serverinfo_MOTD);
			me.serverinfo_MOTD = strzone(argv(i + 1));
			me.serverinfo_MOTD_ent.setText(me.serverinfo_MOTD_ent, me.serverinfo_MOTD);
			++i;
		}
	}
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
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0.5, _("MOTD")));
	me.TR(me);
		me.TD(me, 1, 4, me.serverinfo_MOTD_ent = makeXonoticTextLabel(0.5, ""));
}
#endif
