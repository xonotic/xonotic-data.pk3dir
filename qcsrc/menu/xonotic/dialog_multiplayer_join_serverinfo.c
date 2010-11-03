#ifdef INTERFACE
CLASS(XonoticServerInfoDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticServerInfoDialog, fill, void(entity))
	METHOD(XonoticServerInfoDialog, loadServerInfo, void(entity, float))
	ATTRIB(XonoticServerInfoDialog, title, string, "Server Information")
	ATTRIB(XonoticServerInfoDialog, color, vector, SKINCOLOR_DIALOG_SERVERINFO)
	ATTRIB(XonoticServerInfoDialog, intendedWidth, float, 0.68)
	ATTRIB(XonoticServerInfoDialog, rows, float, 15)
	ATTRIB(XonoticServerInfoDialog, columns, float, 12)

	ATTRIB(XonoticServerInfoDialog, currentServerName, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerCName, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerType, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerMap, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerPlayers, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerNumPlayers, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerNumBots, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerMod, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerVersion, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerPing, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerKey, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerID, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerEncrypt, string, string_null)
	ATTRIB(XonoticServerInfoDialog, currentServerPure, string, string_null)

	ATTRIB(XonoticServerInfoDialog, nameLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, cnameLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, typeLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, mapLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, rawPlayerList, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, numPlayersLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, numBotsLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, modLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, versionLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, pingLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, keyLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, idLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, encryptLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, canConnectLabel, entity, NULL)
	ATTRIB(XonoticServerInfoDialog, pureLabel, entity, NULL)
ENDCLASS(XonoticServerInfoDialog)

float SLIST_FIELD_NAME;
float SLIST_FIELD_CNAME;
float SLIST_FIELD_QCSTATUS;
float SLIST_FIELD_MAP;
float SLIST_FIELD_PLAYERS;
float SLIST_FIELD_NUMHUMANS;
float SLIST_FIELD_MAXPLAYERS;
float SLIST_FIELD_NUMBOTS;
float SLIST_FIELD_MOD;
float SLIST_FIELD_PING;
void Join_Click(entity btn, entity me);
#endif

#ifdef IMPLEMENTATION
void XonoticServerInfoDialog_loadServerInfo(entity me, float i)
{
	float m, pure, j;
	string s, typestr, versionstr, numh, maxp, k, v;

	if(me.currentServerName)
		strunzone(me.currentServerName);
	me.currentServerName = string_null;
	if(me.currentServerCName)
		strunzone(me.currentServerCName);
	me.currentServerCName = string_null;
	if(me.currentServerType)
		strunzone(me.currentServerType);
	me.currentServerType = string_null;
	if(me.currentServerMap)
		strunzone(me.currentServerMap);
	me.currentServerMap = string_null;
	if(me.currentServerPlayers)
		strunzone(me.currentServerPlayers);
	me.currentServerPlayers = string_null;
	if(me.currentServerNumPlayers)
		strunzone(me.currentServerNumPlayers);
	me.currentServerNumPlayers = string_null;
	if(me.currentServerNumBots)
		strunzone(me.currentServerNumBots);
	me.currentServerNumBots = string_null;
	if(me.currentServerMod)
		strunzone(me.currentServerMod);
	me.currentServerMod = string_null;
	if(me.currentServerVersion)
		strunzone(me.currentServerVersion);
	me.currentServerVersion = string_null;
	if(me.currentServerPing)
		strunzone(me.currentServerPing);
	me.currentServerPing = string_null;
	if(me.currentServerKey)
		strunzone(me.currentServerKey);
	me.currentServerKey = string_null;
	if(me.currentServerID)
		strunzone(me.currentServerID);
	me.currentServerID = string_null;
	// not zoned!
	//if(me.currentServerEncrypt)
	//	strunzone(me.currentServerEncrypt);
	//me.currentServerEncrypt = string_null;
	if(me.currentServerPure)
		strunzone(me.currentServerPure);
	me.currentServerPure = string_null;

	SLIST_FIELD_NAME = gethostcacheindexforkey("name");
	me.currentServerName = strzone(gethostcachestring(SLIST_FIELD_NAME, i));
	me.nameLabel.setText(me.nameLabel, me.currentServerName);

	SLIST_FIELD_CNAME = gethostcacheindexforkey("cname");
	me.currentServerCName = strzone(gethostcachestring(SLIST_FIELD_CNAME, i));
	me.cnameLabel.setText(me.cnameLabel, me.currentServerCName);

	pure = -1;
	typestr = "N/A";
	versionstr = "N/A";

	SLIST_FIELD_QCSTATUS = gethostcacheindexforkey("qcstatus");
	s = gethostcachestring(SLIST_FIELD_QCSTATUS, i);
	m = tokenizebyseparator(s, ":");
	if(m >= 2)
	{
		typestr = argv(0);
		versionstr = argv(1);
	}
	for(j = 2; j < m; ++j)
	{
		if(argv(j) == "")
			break;
		k = substring(argv(j), 0, 1);
		v = substring(argv(j), 1, -1);
		if(k == "P")
			pure = stof(v);
	}

	me.currentServerType = strzone(typestr);
	me.typeLabel.setText(me.typeLabel, me.currentServerType);

	SLIST_FIELD_MAP = gethostcacheindexforkey("map");
	me.currentServerMap = strzone(gethostcachestring(SLIST_FIELD_MAP, i));
	me.mapLabel.setText(me.mapLabel, me.currentServerMap);

	SLIST_FIELD_PLAYERS = gethostcacheindexforkey("players");
	me.currentServerPlayers = strzone(gethostcachestring(SLIST_FIELD_PLAYERS, i));
	me.rawPlayerList.setPlayerList(me.rawPlayerList, me.currentServerPlayers);

	SLIST_FIELD_NUMHUMANS = gethostcacheindexforkey("numhumans");
	numh = ftos(gethostcachenumber(SLIST_FIELD_NUMHUMANS, i));
	SLIST_FIELD_MAXPLAYERS = gethostcacheindexforkey("maxplayers");
	maxp = ftos(gethostcachenumber(SLIST_FIELD_MAXPLAYERS, i));
	me.currentServerNumPlayers = strzone(strcat(numh,"/",maxp));
	me.numPlayersLabel.setText(me.numPlayersLabel, me.currentServerNumPlayers);

	SLIST_FIELD_NUMBOTS = gethostcacheindexforkey("numbots");
	s = ftos(gethostcachenumber(SLIST_FIELD_NUMBOTS, i));
	me.currentServerNumBots = strzone(s);
	me.numBotsLabel.setText(me.numBotsLabel, me.currentServerNumBots);

	SLIST_FIELD_MOD = gethostcacheindexforkey("mod");
	me.currentServerMod = strzone(gethostcachestring(SLIST_FIELD_MOD, i));
	me.modLabel.setText(me.modLabel, me.currentServerMod);

	me.currentServerVersion = strzone(versionstr);
	me.versionLabel.setText(me.versionLabel, me.currentServerVersion);

	me.currentServerPure = ((pure < 0) ? "N/A" : (pure == 0) ? "Official settings" : sprintf("%d modified settings", pure));
	me.currentServerPure = strzone(me.currentServerPure);
	me.pureLabel.setText(me.pureLabel, me.currentServerPure);

	SLIST_FIELD_PING = gethostcacheindexforkey("ping");
	s = ftos(gethostcachenumber(SLIST_FIELD_PING, i));
	me.currentServerPing = strzone(s);
	me.pingLabel.setText(me.pingLabel, me.currentServerPing);

	print(me.currentServerCName, "\n");

	s = crypto_getidfp(me.currentServerCName);
	if not(s)
		s = "N/A";
	me.currentServerID = strzone(s);
	me.idLabel.setText(me.idLabel, me.currentServerID);

	s = crypto_getkeyfp(me.currentServerCName);
	if not(s)
		s = "N/A";
	me.currentServerKey = strzone(s);
	me.keyLabel.setText(me.keyLabel, me.currentServerKey);

	s = crypto_getencryptlevel(me.currentServerCName);
	if(s == "")
	{
		if(cvar("crypto_aeslevel") >= 3)
			me.currentServerEncrypt = "N/A (can't connect)";
		else
			me.currentServerEncrypt = "N/A";
	}
	else switch(stof(substring(s, 0, 1)))
	{
		case 0:
			if(cvar("crypto_aeslevel") >= 3)
				me.currentServerEncrypt = "not supported (can't connect)";
			else
				me.currentServerEncrypt = "not supported";
			break;
		case 1:
			me.currentServerEncrypt = "supported";
			break;
		case 2:
			me.currentServerEncrypt = "requested";
			break;
		case 3:
			if(cvar("crypto_aeslevel") <= 0)
				me.currentServerEncrypt = "required (can't connect)";
			else
				me.currentServerEncrypt = "required";
			break;
	}
	me.encryptLabel.setText(me.encryptLabel, me.currentServerEncrypt);
}

void XonoticServerInfoDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticTextLabel(0.5, ""));
			e.colorL = SKINCOLOR_SERVERINFO_NAME;
			e.allowCut = 1;
			me.nameLabel = e;
	me.TR(me);
		me.TD(me, 1, me.columns, e = makeXonoticTextLabel(0.5, ""));
			e.colorL = SKINCOLOR_SERVERINFO_IP;
			e.allowCut = 1;
			me.cnameLabel = e;

	me.TR(me);
		me.TD(me, 1, 5.5, e = makeXonoticTextLabel(0, "Players:"));
	me.TR(me);
		me.TD(me, me.rows - 4, 6, e = makeXonoticPlayerList());
			me.rawPlayerList = e;

	me.gotoRC(me, 1, 6.25); me.setFirstColumn(me, me.currentColumn);

	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Type:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.typeLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Map:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.mapLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Gameplay:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.pureLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Players:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.numPlayersLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Bots:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.numBotsLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Mod:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.modLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Version:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.versionLabel = e;
	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Ping:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.pingLabel = e;

	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "CA:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.keyLabel = e;

	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Key:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.idLabel = e;

	me.TR(me);
		me.TD(me, 1, 1.75, e = makeXonoticTextLabel(0, "Encryption:"));
		me.TD(me, 1, 4.0, e = makeXonoticTextLabel(0, ""));
			e.allowCut = 1;
			me.encryptLabel = e;

	me.gotoRC(me, me.rows - 1, 0);

		me.TD(me, 1, me.columns - 6, e = makeXonoticButton("Close", '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
		me.TD(me, 1, me.columns - 6, e = makeXonoticButton("Join!", '0 0 0'));
			e.onClick = Join_Click;
			e.onClickEntity = me;
}

void Join_Click(entity btn, entity me)
{
	localcmd("connect ", me.currentServerCName, "\n");
}

#endif
